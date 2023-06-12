local geo <const> = playdate.geometry
local gfx <const> = playdate.graphics
local ani <const> = playdate.graphics.animator
local img <const> = playdate.graphics.image
local spr <const> = playdate.graphics.sprite
local white <const> = playdate.graphics.kColorWhite
local black <const> = playdate.graphics.kColorBlack

-- Helper functions
local function rad(deg)
    return deg * 0.017453292519943295
end

local function deg(rad)
    return rad * 57.29577951308232
end

-- Constants
local screenX <const> = 400
local screenY <const> = 240
-- Variable board shapes
local game_mode
local sidebar
local tripod_size
local shooter_radius
local ballSize
local velocity
local startX
local startY
local wallLeft
local wallRight
local wallBottom
local wallTop

local function mode_playdate()
    sidebar = 75
    ballSize = 9
    tripod_size = 21
    shooter_radius = 28
    velocity = 3.5
    startX = screenX // 2 -- was 320
    startY = screenY - 10 -- was 450
    wallLeft = sidebar + ballSize
    wallRight = screenX - sidebar - ballSize
    wallBottom = screenY - 62
    wallTop = 0
end
local function mode_classic()
    sidebar = 100
    -- local x, y = 200, 240 -- original was 400x480
    ballSize = 5          -- original was 10
    tripod_size = 16
    shooter_radius = 20
    velocity = 3.225
    startX = screenX // 2 -- was 320
    startY = screenY - 10 -- was 450
    wallLeft = sidebar + ballSize
    wallRight = screenX - sidebar - ballSize
    wallBottom = screenY - 42
    wallTop = 0
end
local function set_mode(mode)
    assert(mode ~= nil, "Attempting to set game_mode to nil, should be 1 or 2.")
    if mode % 2 == 0 then
        mode_classic()
    else
        mode_playdate()
    end
end

-- GLOBAL VARIABLES
local i = 10                -- ? number of balls
local friction = 0.975      -- coefficient of friction
local n = -1                -- Next closest ball (num)
local nd = 10000            -- Next closest ball distance
local b = nil               -- Currently active Ball {lx,ly,r,vx,vy,f,m,_rotation}
local l = {deg=180, mov=2}  -- Shooter state and step
local arrow = {}            -- Rotating shooter {_x, _y, _rotation}

barray = {}
ubarray = {}
local zeroes = {}
local firstshot = false     -- has the first shot occured
local wall = false
local news = 0              -- New Scale (growing to)
local score = 0             -- Score
local hiscore = (playdate.datastore.read("score") or {})["score"] or 0
local fsm = nil

local sound_music = playdate.sound.sampleplayer.new("sound/bgmusic")
local sound_crack = playdate.sound.sampleplayer.new("sound/crack")
local sound_shoot = playdate.sound.sampleplayer.new("sound/shoot")
local sound_wall = playdate.sound.sampleplayer.new("sound/wall")

local ball_images = {}

-- This are done globally for dumb reasons.
local image_logo = img.new("images/logo")
local title_sprite = spr.new( image_logo )

-- Images & sprites
local image_tripod
local tripod = spr.new( image_tripod )
local image_gameover
local image_background = img.new(screenX, screenY)
local score_image
local score_sprite
local hiscore_image
local hiscore_sprite
local background -- sprite
local sidebar_sprite
local goscreen -- sprite
local shooter_sprite = nil
local image_sidebar = {}


-- Images which are identical in both modes.
local function image_setup_static()
    hiscore_image = img.new( 45, 15, white)
    hiscore_sprite = spr.new ( hiscore_image )

    score_image = img.new( 45, 15, white)
    score_sprite = spr.new ( score_image )


    goscreen = spr.new( image_gameover )
    goscreen:setCenter(0.5, 0)
    goscreen:setZIndex(500)

    background = spr.setBackgroundDrawingCallback(
        function( x, y, width, height )
            gfx.setClipRect( x, y, width, height )
            image_background:draw( 0, 0 )
            gfx.clearClipRect()
        end
    )
end


-- This does mode-dependent image/sprite setup
local function image_setup_variable()
    draw.background(image_background,
        wallLeft - ballSize, -- left_x
        wallRight + ballSize, -- right_x
        wallBottom-1 -- passing_line
    )
    image_tripod = draw.tripod(tripod_size)
    image_gameover = draw.gameover(screenX - 2 * sidebar, wallBottom)
    tripod:setCenter(0.5,1)
    tripod:moveTo(199, screenY)
    tripod:add()
    tripod:setZIndex(200)


    score_sprite:moveTo(screenX - sidebar //2, 50)
    score_sprite:add()
    hiscore_sprite:moveTo(screenX - sidebar //2, 155)
    hiscore_sprite:add()

    image_sidebar = {
        tribute=    img.new("images/sidebar1"),
        credits=    draw.sidebar( img.new( 75, screenY ) ),
    }
    sidebar_sprite = spr.new( image_sidebar )

end

local small_font = playdate.graphics.font.new("fonts/gimme-small")
local digit_font = playdate.graphics.font.new("fonts/gimme-digits")

local function update_score(s)
    score = s
    if score > hiscore then
        hiscore = score
        playdate.datastore.write({score=hiscore}, "score")
    end
    draw.score(score_image, score)
    draw.score(hiscore_image, hiscore)
end

local function next_image(r, n)
    local im = ball_images[n][4]
    local new_size = 4
    for size, image in pairs(ball_images[n]) do
        if r >= size then
            im = image
            new_size = size
        end
    end
    return im
end


-- local title_screen = playdate.graphics.sprite.new(320, 200)
local function ball_str(b)
    return string.format("BallSprite(x=%s, y=%s, r=%s, vx=%s, vy=%s)", b._x, b._y, b.r, b.vx, b.vy)
end

function newball()
    i = i + 1
    b = spr.new( next_image(ballSize, 3) )
    b:moveTo( startX, startY )
    b:setVisible(true)
    b:setZIndex(100)
    b:add()
    b._xscale = ballSize
    b._yscale = ballSize
    b._x = startX
    b._y = startY
    b.r = ballSize    -- radius
    b.vx = 0          -- velocity
    b.vy = 0
    b.m = 1    -- mass?
    b.n = 3    -- frame number 1-4 (3,2,1,0)
    barray[#barray+1] = b
end

function update_shooter()
    local angle_rad = rad(l.deg)
    b.lx = math.cos(angle_rad) * shooter_radius + startX
    b.ly = math.sin(angle_rad) * shooter_radius + startY
    arrow._x = b.lx
    arrow._y = b.ly
    -- l  line = {startX, startY, b.lx, b.ly}
    local dx = b._x - b.lx
    local dy = b._y - b.ly
    arrow._rotation = deg(math.atan2(dy, dx)) -90
    if math.floor(arrow._rotation) == -270 then
        arrow._rotation += 360
    end

    gfx.setColor(black)
    -- gfx.drawLine(startX, startY, b.lx, b.ly)
    shooter_sprite:moveTo(arrow._x, arrow._y)
    -- shooter_sprite:setImage(shooter_images[math.floor(arrow._rotation)])
end

function shooter()
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
        l.deg = (l.deg + l.mov) + math.random(-10,10) * .01;
    end
    update_shooter()
end

function shootnow()
    if firstshot == false then
        firstshot = true
        title_sprite:setVisible(false)
    end
    sound_shoot:play()
    b.vx = (- (b.lx - startX)) / velocity
    b.vy = (- (b.ly - startY)) / velocity
    fsm = moveball
    playdate.AButtonDown = nil
    playdate.upButtonDown = nil
end

function moveball()
    findn()
    b.vx *= friction
    b.vy *= friction
    if(b._x - b.vx < wallLeft or b._x - b.vx > wallRight) then
        b.vx *= -1
        sound_wall:play()
    end
    if(b._y - b.vy - b.r < wallTop) then
        b.vy *= -1
        sound_wall:play()
    end
    b._x -= b.vx
    b._y -= b.vy
    b:moveTo(b._x, b._y)
    if(b.vy < 0 and b._y + b.r > wallBottom) then -- death
        sound_music:stop()
        -- createexp(b) -- create explosion
        b:remove()
        goscreen:moveTo(startX, -1 * goscreen.height)
        goscreen:setVisible(true)
        goscreen:add()
        playdate.datastore.delete("state")
        fsm = gomove
        playdate.AButtonDown = restore
        playdate.upButtonDown = restore
        playdate.cranked = nil  -- disable moving shooter when dead.
    end
    -- Use of 0.2 here is arbitrary. Playdate only supports integer x,y
    -- positions. Original (flash) could render non integer coords. Anything
    -- lower than 0.2 feels unnatural; balls move a whole extra pixel at the end
    if math.abs(b.vx) + math.abs(b.vy) < 0.2 then
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
            local ball_dist = math.sqrt(xdist_next * xdist_next + ydist_next * ydist_next) - barray[p].r
            if(ball_dist < nd) then
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
    for p = 1,#barray-1 do -- last element of barray is b, so skip
        local xdist = b._x - barray[p]._x
        local ydist = b._y - barray[p]._y
        local next_dist = math.sqrt(xdist * xdist + ydist * ydist) - barray[p].r
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
    if(wallBottom - b._y < nd) then
        nd = wallBottom - b._y
        if nd < 0 then
            ubarray[#ubarray+1] = b
            table.remove(barray, #barray)
            nd = math.abs(nd)
        end
        wall = true
    end
end

function grow2()
    local _loc1_ = news - b._xscale
    b._xscale = b._xscale + _loc1_ / 5
    b._yscale = b._yscale + _loc1_ / 5

    local img = next_image(b._xscale, b.n)
    b:setImage(img)
    -- do the above, until we're within 1pixel of the new size.
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
        b:setImage(next_image(b.r, b.n))
        newball()
        fsm = shooter
        nd = 10000
        n = -1
        wall = false
        save_state()
    end
end

function checkColl(b1, b2)
    local xdist = b2._x - b1._x
    local ydist = b2._y - b1._y
    local dist = math.sqrt(xdist * xdist + ydist * ydist) -- center to center
    if dist < b1.r + b2.r then -- Collide
        local between = dist - (b1.r + b2.r) -- between balls
        local xratio = xdist / dist
        local yratio = ydist / dist
        b1._x = b1._x + between * xratio
        b1._y = b1._y + between * yratio
        b2.n = b2.n - 1
        sound_crack:play()
        b2:setImage( next_image(b2.r, b2.n) )

        local atan2 = math.atan2(ydist, xdist)
        local cosa = math.cos(atan2)
        local sina = math.sin(atan2)
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
        if(b2.n == 0) then
            update_score(score + 1)
            b2:setImage( next_image(b2.r, b2.n))
            zeroes[#zeroes+1] = b2
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
    local stop_y = -1
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
    for j = 1,#barray do
        barray[j]:remove()
    end
    for k = 1,#ubarray do
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
    local _loc6_ = math.atan2(ydist, xdist)
    local x_pos = math.cos(_loc6_) * b1.r + b1._x
    local y_pos = math.sin(_loc6_) * b1.r + b1._y
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
    playdate.timer.updateTimers()
    playdate.graphics.sprite.update()
    -- playdate.drawFPS()
    -- eek.
    if playdate.buttonIsPressed( "right" ) then
        crank(10, 10)
    elseif playdate.buttonIsPressed( "left" ) then
        crank(-10, -10)
    end

    fsm()
    for z = #zeroes,1,-1 do
        local zero = zeroes[z]
        zero:moveBy(zero.vx, zero.vy)
        if zero.y > 250 + zero.r then
            zero:remove()
            table.remove(zeroes, z)
        end
    end
    -- shooter_image:draw(200,0)
end

function save_state()
    local balls = {}
    for _, ball in ipairs(barray) do
        local bb = {}
        for _a, attr in ipairs({"_xscale", "_yscale", "_x", "_y", "vx", "vy", "m", "n", "r"}) do
            bb[attr] = ball[attr]
        end
        balls[#balls+1] = bb
    end
    table.remove(balls) -- the last ball in barray is the unshot shot (b)
    local state = {
        l = l,
        barray = balls,
        score = score,
        game_mode = game_mode,
    }
    playdate.datastore.write(state, "state")
end

function load_state(state)
    for _, _ball in ipairs(state["barray"]) do
        local _b = spr.new( next_image(_ball.r, _ball.n) )
        _b:moveTo(_ball._x, _ball._y)
        _b:setZIndex(100)
        _b:add()
        for attr, value in pairs(_ball) do
            _b[attr] = value
        end
        barray[#barray+1] = _b
    end
    b = barray[#barray]
    l = state["l"]
    game_mode = state["game_mode"] or 1
    score = state["score"]
end

function gimme_setup()
    ball_images = balls_setup()
    if playdate.buttonIsPressed("B") then
        playdate.datastore.delete("state")
    else
        local state = playdate.datastore.read("state")
        if state then
            game_mode = 1
            load_state(state) -- maybe use pcall?
        else
            game_mode = 2
            title_sprite:moveTo(200, 100)
            title_sprite:add()
        end
    end

    set_mode(2)
    image_setup_static()
    image_setup_variable()

    gfx.setColor(black)
    update_score(score)
    newball()

    shooter_image = draw.shooter(ballSize * 2)
    shooter_sprite = spr.new( shooter_image )
    update_shooter()
    shooter_sprite:setZIndex(201)
    shooter_sprite:add()

    local function mode_toggle()
        game_mode = (game_mode + 1) % 2
        set_mode(game_mode)
        image_setup_variable()
        playdate.datastore.delete("state")
        restore()
    end

    local sidebar_callbacks = {}
    sidebar_callbacks.credits = function()
        sidebar_sprite:setImage( image_sidebar.credits )
        playdate.getSystemMenu():removeAllMenuItems()
        playdate.getSystemMenu():addMenuItem("tribute", sidebar_callbacks.tribute)
        playdate.getSystemMenu():addMenuItem("mode", mode_toggle)
    end
    sidebar_callbacks.tribute = function()
        sidebar_sprite:setImage( image_sidebar.tribute )
        playdate.getSystemMenu():removeAllMenuItems()
        playdate.getSystemMenu():addMenuItem("credits", sidebar_callbacks.credits)
        playdate.getSystemMenu():addMenuItem("mode", mode_toggle)
    end
    sidebar_callbacks.tribute()
    sidebar_sprite:setCenter(0,0)
    sidebar_sprite:moveTo((wallLeft - image_sidebar.tribute.width)//2 - 3,0)
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
