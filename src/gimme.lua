local gfx <const> = playdate.graphics
local spr <const> = playdate.graphics.sprite
local white <const> = playdate.graphics.kColorWhite
local black <const> = playdate.graphics.kColorBlack
local img_new <const> = playdate.graphics.image.new

local math_cos <const> = math.cos
local math_sin <const> = math.sin
local math_atan <const> = math.atan
local math_abs <const> = math.abs
local math_floor <const> = math.floor
local math_random <const> = math.random
local math_sqrt <const> = math.sqrt

--- Convert from degrees to radians
---@param degrees number
---@return number radians
local function rad(degrees)
    return degrees * 0.017453292519943295
end

--- Convert from radians to degrees
---@param radians number
---@return number degrees
local function deg(radians)
    return radians * 57.29577951308232
end

-- Constants
local screenX <const> = 400
local screenY <const> = 240
local ballSize <const> = 9          -- was 10
local startX <const> = screenX // 2 -- was 320
local startY <const> = screenY - 20 -- was 450
local wallLeft <const> = 75 + ballSize
local wallRight <const> = screenX - wallLeft
local wallBottom <const> = screenY - 62
local wallTop <const> = 0

-- GLOBAL VARIABLES

local i = 10                     --- number of balls
local friction = 0.975           --- coefficient of friction
local n = -1                     --- Next closest ball (num)
local nd = 10000                 --- Next closest ball distance
---@class _BallSprite: _Sprite
local b = nil                    --- Currently active Ball {lx,ly,r,vx,vy,f,m,_rotation}
local l = { deg = 180, mov = 2 } --- Shooter state and step
---@class Arrow
local arrow = {}                 --- Rotating shooter {_x, _y, _rotation}

barray = {} ---@type _BallSprite[]
ubarray = {} ---@type _BallSprite[]
local zeroes = {} ---@type _BallSprite[]
local firstshot = false -- has the first shot occured
local wall = false
local news = 0          -- New Scale (growing to)
local score = 0         -- Score
local hiscore = (playdate.datastore.read("score") or {})["score"] or 0
local fsm = function() end

local sound_music = playdate.sound.sampleplayer.new("sound/bgmusic")
local sound_crack = playdate.sound.sampleplayer.new("sound/crack")
local sound_shoot = playdate.sound.sampleplayer.new("sound/shoot")
local sound_wall = playdate.sound.sampleplayer.new("sound/wall")

local ball_images = {}
local shooter_image = img_new(2 * ballSize, 2 * ballSize)
local shooter_sprite = spr.new(shooter_image)

local image_background = img_new("images/background") or error("Failed to load background image")
local image_sidebar = {}
local sidebar_sprite = nil
local image_tripod = img_new("images/tripod")
local image_gameover = img_new("images/gameover250")
local goscreen = spr.new(image_gameover)
goscreen:setZIndex(500)
local image_logo = img_new("images/logo")
local title_sprite = spr.new(image_logo)
local background = nil

local small_font = playdate.graphics.font.new("fonts/gimme-small")
local digit_font = playdate.graphics.font.new("fonts/gimme-digits")
local score_image = img_new(40, 15, white)
local score_sprite = spr.new(score_image)
score_sprite:moveTo(362, 50)
score_sprite:add()
local hiscore_image = img_new(45, 15, white)
local hiscore_sprite = spr.new(hiscore_image)
hiscore_sprite:moveTo(362, 155)
hiscore_sprite:add()

local tripod = spr.new(image_tripod)

local function draw_shooter(image)
    gfx.lockFocus(image)
    playdate.graphics.setColor(white)
    playdate.graphics.fillCircleInRect(0, 0, 2 * ballSize, 2 * ballSize)
    playdate.graphics.setColor(black)
    playdate.graphics.drawCircleInRect(0, 0, 2 * ballSize, 2 * ballSize)
    gfx.unlockFocus()
    return image
end

local function draw_score(image, num)
    image:clear(white)
    gfx.lockFocus(image)
    gfx.setColor(black)
    digit_font:drawTextAligned(num, 20, 0, kTextAlignment.center)
    gfx.unlockFocus()
end

local function draw_sidebar(image)
    local b_text = [[GIMME
FRICTION
BABY


CONCEPT
CODE
DESIGN
WOUTER
VISSER

MUSICSAMPLE
WE VS DEATH

PLAYDATE
PORT
PETER
TRIPP
]]
    gfx.lockFocus(image)
    gfx.clear(white)
    gfx.setColor(black)
    small_font:drawTextAligned(b_text, 37, 5, kTextAlignment.center, 2)
    gfx.unlockFocus()
    return image
end

local function update_score(s)
    score = s
    if score > hiscore then
        hiscore = score
        playdate.datastore.write({ score = hiscore }, "score")
    end
    draw_score(score_image, score)
    draw_score(hiscore_image, hiscore)
end


-- local title_screen = playdate.graphics.sprite.new(320, 200)

--- Print a string representation of a BallSprite
---@param b _BallSprite
---@return string
local function ball_str(b)
    return string.format("BallSprite(x=%s, y=%s, r=%s, vx=%s, vy=%s)", b._x, b._y, b.r, b.vx, b.vy)
end

function newball()
    i = i + 1
    ---@class _BallSprite
    local ball = spr.new(get_ball(ballSize, 3))
    ball:moveTo(startX, startY)
    ball:setVisible(true)
    ball:setZIndex(100)
    ball:add()
    ball._xscale = ballSize
    ball._yscale = ballSize
    ball._x = startX  --- starting x
    ball._y = startY  --- starting y
    ball.r = ballSize --- radius
    ball.vx = 0       --- x velocity
    ball.vy = 0       --- y velocity
    ball.m = 1        --- mass?
    ball.n = 3        --- frame number 1-4 (3,2,1,0)
    b = ball
    barray[#barray + 1] = ball
end

function update_shooter()
    local angle_rad = rad(l.deg)
    b.lx = math_cos(angle_rad) * (3.1 * ballSize) + startX
    b.ly = math_sin(angle_rad) * (3.1 * ballSize) + startY
    arrow._x = b.lx
    arrow._y = b.ly
    -- l  -- line = {startX, startY, b.lx, b.ly}
    local dx = b._x - b.lx
    local dy = b._y - b.ly
    arrow._rotation = deg(math_atan(dy, dx)) - 90 --- Rotation as degrees
    shooter_sprite:moveTo(arrow._x, arrow._y)
end

function shooter()
    --- Clamp to a range
    ---@param num number Number
    ---@param min number Minimum value
    ---@param max number Maximum value
    ---@return number
    function _clamp(num, min, max)
        if num > max then return max end
        if num < min then return min end
        return num
    end

    playdate.AButtonDown = shootnow
    playdate.upButtonDown = shootnow
    if playdate.isCrankDocked() then
        if l.deg > 360 or l.deg < 180 then
            l.mov = -1 * l.mov
            l.deg = _clamp(l.deg, 180, 360)
        end
        -- original game only supported 0,180; step=2.
        -- this rand term at the end keeps things interesting.
        l.deg = (l.deg + l.mov) + math_random(-10, 10) * .01;
    end
    update_shooter()
end

function shootnow()
    if firstshot == false then
        firstshot = true
        title_sprite:setVisible(false)
    end
    sound_shoot:play()
    b.vx = (-(b.lx - startX)) / 3.5
    b.vy = (-(b.ly - startY)) / 3.5
    fsm = moveball
    playdate.AButtonDown = nil
    playdate.upButtonDown = nil
end

function moveball()
    findn()
    b.vx *= friction
    b.vy *= friction
    if (b._x - b.vx < wallLeft or b._x - b.vx > wallRight) then
        b.vx *= -1
        sound_wall:play()
    end
    if (b._y - b.vy - b.r < wallTop) then
        b.vy *= -1
        sound_wall:play()
    end
    b._x -= b.vx
    b._y -= b.vy
    b:moveTo(b._x, b._y)
    if (b.vy < 0 and b._y + b.r > wallBottom) then -- death
        sound_music:stop()
        -- createexp(b) -- create explosion
        b:remove()
        goscreen:moveTo(startX, -80)
        goscreen:setVisible(true)
        goscreen:add()
        playdate.datastore.delete("state")
        fsm = gomove
        playdate.AButtonDown = restore
        playdate.upButtonDown = restore
        playdate.cranked = nil -- disable moving shooter when dead.
    end
    -- Use of 0.2 here is arbitrary. Playdate only supports integer x,y
    -- positions. Original (flash) could render non integer coords. Anything
    -- lower than 0.2 feels unnatural; balls move a whole extra pixel at the end
    if math_abs(b.vx) + math_abs(b.vy) < 0.2 then
        calc();
        b.m = 100000;
        b.vx = 0
        b.vy = 0
        news = nd
        fsm = grow2
    end
end

function findn()
    -- Find the closest ball
    if #barray > 1 then
        local p = 1
        while p < #barray do
            local xdist_next = b._x - b.vx - barray[p]._x
            local ydist_next = b._y - b.vy - barray[p]._y
            local ball_dist = math_sqrt(xdist_next * xdist_next + ydist_next * ydist_next) - barray[p].r
            if (ball_dist < nd) then
                nd = ball_dist
                n = p
            end
            p = p + 1 -- this skips barray[#barray] (current shot)
        end
        checkColl(b, barray[n])
    end
    n = -1
    nd = 10000
end

function calc()
    for p = 1, #barray - 1 do -- last element of barray is b, so skip
        local xdist = b._x - barray[p]._x
        local ydist = b._y - barray[p]._y
        local next_dist = math_sqrt(xdist * xdist + ydist * ydist) - barray[p].r
        if next_dist < nd then
            n = p
            nd = next_dist
        end
    end

    if b._x - wallLeft + b.r < nd then
        nd = b._x - wallLeft + b.r
        wall = true
    end
    if wallRight - b._x + b.r < nd then
        nd = wallRight - b._x + b.r
        wall = true
    end
    if b._y - wallTop < nd then
        nd = b._y - wallTop
        wall = true
    end
    if (wallBottom - b._y < nd) then
        nd = wallBottom - b._y
        if nd < 0 then
            ubarray[#ubarray + 1] = b
            table.remove(barray, #barray)
            nd = math_abs(nd)
        end
        wall = true
    end
end

function grow2()
    local _loc1_ = news - b._xscale
    b._xscale = b._xscale + _loc1_ / 5
    b._yscale = b._yscale + _loc1_ / 5
    local image = get_ball(b._xscale, b.n)
    b:setImage(image)
    if _loc1_ < 1 then
        b._xscale = news
        b._yscale = news
        -- this is arbitrary because of the resolution of our display (400x240).
        -- smaller balls are rare (only when close to the bottom line)
        -- and have images drawn by hand. 7x7 (r=3.5) is the smallest we can do
        -- so I've named the 7x7 as the 6x6 (images/balls_6-{3,2,1,0}.png)
        -- which will be used here.
        if nd < 3 then
            nd = 3
        end
        b.r = nd
        b:setImage(get_ball(b.r, b.n))
        newball()
        fsm = shooter
        nd = 10000
        n = -1
        wall = false
        save_state()
    end
end

--- Check for a collision between two balls
---@param b1 _BallSprite
---@param b2 _BallSprite
function checkColl(b1, b2)
    local xdist = b2._x - b1._x
    local ydist = b2._y - b1._y
    local dist = math_sqrt(xdist * xdist + ydist * ydist) -- center to center
    if dist < b1.r + b2.r then                            -- Collide
        local between = dist - (b1.r + b2.r)              -- between balls
        local xratio = xdist / dist
        local yratio = ydist / dist
        b1._x = b1._x + between * xratio
        b1._y = b1._y + between * yratio
        b2.n = b2.n - 1
        sound_crack:play()
        b2:setImage(get_ball(b2.r, b2.n))

        local atan2 = math_atan(ydist, xdist)
        local cosa = math_cos(atan2)
        local sina = math_sin(atan2)
        local vx1p = cosa * b1.vx + sina * b1.vy
        local vy1p = cosa * b1.vy - sina * b1.vx
        local vx2p = cosa * b2.vx + sina * b2.vy
        local vy2p = cosa * b2.vy - sina * b2.vx
        local P = vx1p * b1.m + vx2p * b2.m
        local V = vx1p - vx2p
        vx1p = (P - b2.m * V) / (b1.m + b2.m)
        vx2p = V + vx1p
        b1.vx = cosa * vx1p - sina * vy1p
        b1.vy = cosa * vy1p + sina * vx1p
        local diff = (b1.r + b2.r - dist) / 2
        cosd = cosa * diff
        sind = sina * diff
        if (b2.n == 0) then
            update_score(score + 1)
            b2:setImage(get_ball(b2.r, b2.n))
            zeroes[#zeroes + 1] = b2
            b2.vx = 0
            b2.vy = 5
            table.remove(barray, n)
            return
        end
    end
end

-- game over screen move down
function gomove()
    if playdate.buttonIsPressed(playdate.kButtonB) then
        goscreen:setVisible(false)
    else
        goscreen:setVisible(true)
    end
    local stop_y = 88
    if goscreen.y < stop_y then
        goscreen:moveBy(0, 5)
        if goscreen.y > stop_y then
            goscreen:moveTo(goscreen.x, stop_y)
        end
    end
end

function restore()
    update_score(0)
    goscreen:remove()
    for j = 1, #barray do
        barray[j]:remove()
    end
    for k = 1, #ubarray do
        ubarray[k]:remove()
    end
    ubarray = {}
    barray = {}
    i = 10
    n = -1
    nd = 10000
    wall = false
    news = 0
    fsm = shooter
    newball()
    sound_music:play(9999)
    playdate.AButtonDown = shootnow
    playdate.upButtonDown = shootnow
    if not playdate.isCrankDocked() then
        playdate.cranked = crank
    end
end

-- Create parts of ball that fall
function createpart(b1, b2)
    sound_crack:play()
    local xdist = b2._x - b1._x
    local ydist = b2._y - b1._y
    local _loc6_ = math_atan(ydist, xdist)
    local x_pos = math_cos(_loc6_) * b1.r + b1._x
    local y_pos = math_sin(_loc6_) * b1.r + b1._y
end

function crank(change, acceleratedChange)
    l.deg = l.deg + acceleratedChange / 4
    if l.deg > 360 then
        l.deg = 360
    elseif l.deg < 180 then
        l.deg = 180
    end
    update_shooter()
end

function playdate.crankDocked()
    playdate.cranked = nil
end

function playdate.crankUndocked()
    playdate.cranked = crank
end

function gimme_update()
    playdate.graphics.sprite.update()
    playdate.timer.updateTimers()

    fsm()
    for z = #zeroes, 1, -1 do
        local zero = zeroes[z]
        zero:moveBy(zero.vx, zero.vy)
        if zero.y > 250 + zero.r then
            zero:remove()
            table.remove(zeroes, z)
        end
    end
end

function save_state()
    local balls = {}
    for _, ball in ipairs(barray) do
        local bb = {}
        for _a, attr in ipairs({ "_xscale", "_yscale", "_x", "_y", "vx", "vy", "m", "n", "r" }) do
            bb[attr] = ball[attr]
        end
        balls[#balls + 1] = bb
    end
    table.remove(balls) -- the last ball in barray is the unshot shot (b)
    local state = {
        l = l,
        barray = balls,
        score = score,
    }
    playdate.datastore.write(state, "state")
end

function load_state(state)
    for _, _ball in ipairs(state["barray"]) do
        local _b = spr.new(get_ball(_ball.r, _ball.n)) ---@class _BallSprite
        _b:moveTo(_ball._x, _ball._y)
        _b:setZIndex(100)
        _b:add()
        for attr, value in pairs(_ball) do
            _b[attr] = value
        end
        barray[#barray + 1] = _b
    end
    b = barray[#barray]
    l = state["l"]
    score = state["score"]
end

function gimme_setup()
    ball_images = balls_setup()
    if playdate.buttonIsPressed(playdate.kButtonB) then
        playdate.datastore.delete("state")
    else
        local state = playdate.datastore.read("state")
        if state then
            load_state(state) -- maybe use pcall?
        else
            title_sprite:moveTo(200, 100)
            title_sprite:add()
        end
    end
    background = spr.setBackgroundDrawingCallback(
        function(x, y, width, height)
            gfx.setClipRect(x, y, width, height)
            image_background:draw(0, 0)
            gfx.clearClipRect()
        end
    )
    gfx.setColor(black)
    update_score(score)
    newball()

    tripod:moveTo(startX, screenY - 20)
    tripod:add()
    tripod:setZIndex(200)

    draw_shooter(shooter_image)
    update_shooter()
    shooter_sprite:setZIndex(201)
    shooter_sprite:add()


    local sidebar_x = 75
    image_sidebar = {
        tribute = img_new("images/sidebar1"),
        credits = draw_sidebar(img_new(sidebar_x, screenY)),
    }
    sidebar_sprite = spr.new(image_sidebar.tribute)
    local sidebar_callbacks = {}
    sidebar_callbacks.credits = function()
        sidebar_sprite:setImage(image_sidebar.credits)
        playdate.getSystemMenu():removeAllMenuItems()
        playdate.getSystemMenu():addMenuItem("tribute", sidebar_callbacks.tribute)
    end
    sidebar_callbacks.tribute = function()
        sidebar_sprite:setImage(image_sidebar.tribute)
        playdate.getSystemMenu():removeAllMenuItems()
        playdate.getSystemMenu():addMenuItem("credits", sidebar_callbacks.credits)
    end
    sidebar_callbacks.tribute()
    sidebar_sprite:setCenter(0, 0)
    sidebar_sprite:moveTo(0, 0)
    sidebar_sprite:add()

    sound_music:setVolume(0.1)
    sound_music:play(9999)
    fsm = shooter
    playdate.AButtonDown = shootnow
    playdate.upButtonDown = shootnow

    playdate.setCrankSoundsDisabled(true)
    if not playdate.isCrankDocked() then
        playdate.cranked = crank
    end
end
