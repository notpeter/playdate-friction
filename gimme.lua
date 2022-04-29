Gimme = {}
Gimme.__index = Gimme

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
local startX <const> = screenX // 2 -- was 320
local startY <const> = screenY - 23 -- was 450
local wallLeft <const> = 75
local wallRight <const> = screenX - wallLeft
local wallBottom <const> = screenY - 62
local wallTop <const> = 0

-- GLOBAL VARIABLES
local i = 10                -- ? number of balls
local friction = 0.975      -- coefficient of friction
local n = -1                -- Next closest ball (num)
local nd = 10000            -- Next closest ball distance
local b = {}                -- Currently active Ball {lx,ly,r,vx,vy,f,m,_rotation}
local l = {deg=182, mov=2}              -- Shooter state and step
local arrow = {}             -- Rotating shooter {_x, _y, _rotation}

local barray = {}
local firstshot = false     -- has the first shot occured
local wall = false
local news = 0
local score = 0      -- Score
local hiscore = 0    -- High Score
local fsm = nil

local sound_music = playdate.sound.sampleplayer.new("sound/bgmusic")
local sound_crack = playdate.sound.sampleplayer.new("sound/crack")
local sound_shoot = playdate.sound.sampleplayer.new("sound/shoot")
local sound_wall = playdate.sound.sampleplayer.new("sound/wall")

local image_background = playdate.graphics.image.new("images/background")
local image_ball = playdate.graphics.image.new("images/ball3")
local image_tripod = playdate.graphics.image.new("images/tripod")
local image_gameover = playdate.graphics.image.new("images/gameover135")
local goscreen = playdate.graphics.sprite.new( image_gameover )

local tripod = playdate.graphics.sprite.new( image_tripod )
local background = playdate.graphics.sprite.setBackgroundDrawingCallback(
    function( x, y, width, height )
        playdate.graphics.setClipRect( x, y, width, height )
        image_background:draw( 0, 0 )
        playdate.graphics.clearClipRect()
    end
)


-- local high_score = playdate.graphics.sprite.new(0,0)
-- local title_screen = playdate.graphics.sprite.new(320, 200)

function newball()
    i = i + 1
    b = playdate.graphics.sprite.new( image_ball )
    b:moveTo( startX, startY )
    b:setVisible(true)
    b:setZIndex(10000)
    b:add()
    b._x = startX
    b._y = startY
    b.r = 10    -- radius
    b.vx = 0    -- velocity
    b.vy = 0
    b.m = 1    -- mass?
    b.f = 1    -- frame number 1-4 (3,2,1,0)
    barray[#barray+1] = b
end

function shooter()
    playdate.AButtonDown = shootnow
    -- FIXME: Add continuous support; assumes 2degree steps.
    if l.deg == 360 or l.deg == 180 then
        l.mov = -1 * l.mov
    end

    l.deg = l.deg + l.mov;
    local angle_rad = rad(l.deg)
    b.lx = math.cos(angle_rad) * 25 + startX
    b.ly = math.sin(angle_rad) * 25 + startY
    arrow._x = b.lx
    arrow._y = b.ly
    -- l  -- line = {320, 450, b.lx, b.ly}
    local dx = b._x - b.lx
    local dy = b._y - b.ly
    arrow._rotation = deg(math.atan2(dy, dx)) -90
    playdate.graphics.setColor(playdate.graphics.kColorWhite)
    playdate.graphics.fillCircleInRect(arrow._x-8, arrow._y, 16, 16)
    playdate.graphics.setColor(playdate.graphics.kColorBlack)
    playdate.graphics.drawCircleInRect(arrow._x-8, arrow._y, 16, 16)
    -- playdate.graphics.drawArc(arrow._x, arrow._y, 10, arrow._rotation - 25, arrow._rotation + 25)
end

function shootnow()
    print("SHOOT")
    if firstshot == false then
        firstshot = true
        -- blend away opening
    end
    sound_shoot:play()
    b.vx = (- (b.lx - startX)) / 4
    b.vy = (- (b.ly - startY)) / 4
    print("b.v", b.vx, b.vy)
    fsm = moveball
    -- l.clear()
end

function moveball()
    findn()
    b.vx *= friction
    b.vy *= friction
    if(b._x - b.vx < 130 or b._x - b.vx > 510) then
        b.vx *= -1
        sound_wall:play()
    end
    if(b._y - b.vy < 15) then
        b.vy *= -1
        sound_wall:play()
    end
    b._x -= b.vx
    b._y -= b.vy
    if(b.vy < 0 and b._y + b.r > 395) then -- death
        sound_music:stop()
        -- createexp(b) -- create explosion
        -- b.removeMovieClip()
        goscreen:moveTo(startX, -160)
        goscreen:add()
        goscreen:setVisible(true)
        fsm = gomove
        playdate.AButtonDown = restore
    end
    if math.abs(b.vx) + math.abs(b.vy) < 0.2 then
        calc();
        b.m = 100000;
        b.vx = 0
        b.vy = 0
        news = nd / b.r * 100
        fsm = grow2
    end
end

function findn()
    -- Find the closest ball
    if #barray > 1 then
        local p = 0
        while p < #barray do
            local xdist_next = b._x - b.vx - barray[p]._x
            local ydist_next = b._y - b.vy - barray[p]._y
            local ball_dist = math.sqrt(xdist_next * xdist_next + ydist_next * ydist_next) - barray[p].r
            if(ball_dist < nd) then
                nd = ball_dist
                n = p
            end
            p = p + 1
        end
        -- Collision check with closest ball
        print("CHECK", b, barray[n])
        checkColl(b, barray[n])
    end
    n = -1
    nd = 10000
end

function calc()
    for p = 1,#barray do
        local xdist = b._x - barray[p]._x
        local ydist = b._y - barray[p]._y
        local next_dist = math.sqrt(xdist * xdist + ydist * ydist) - barray[p].r
        if next_dist < nd then
            n = p
            nd = next_dist
        end
    end

    if b._x - wallLeft < nd then
        nd = b._x - wallLeft
        wall = true
    end
    if wallRight - b._x < nd then
        nd = wallRight - b._x
        wall = true
    end
    if b._y - wallTop < nd then
        nd = b._y - wallTop
        wall = true
    end
    if(wallBottom - b._y < nd) then
        nd = wallBottom - b._y
        wall = true
    end
end

function grow2()
    local _loc1_ = news - b._xscale
    b._xscale = b._xscale + _loc1_ / 5
    b._yscale = b._yscale + _loc1_ / 5
    if _loc1_ < 10 then
        b._xscale = news
        b._yscale = news
        -- b.cacheAsBitmap = true
        b.r = nd
        newball()
        fsm = shooter
        nd = 10000
        n = -1
        wall = false
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
        b2.f = b2.f + 1
        if b2.f == 4 then -- Ball pop
            print("ZERO")
            -- Draw a zero falling
            -- zero = _root.attachMovie("zero","zero",_root.getNextHighestDepth());
            -- zero._x = b2._x
            -- zero._y = b2._y
            -- zero._xscale = b2._xscale
            -- zero._yscale = b2._xscale
            -- zero._rotation = b2._rotation
            -- local _loc9_ = math.sqrt(b.vx * b.vx + b.vy * b.vy);
            -- zero.vx = xratio * _loc9_
            -- zero.vy = yratio * _loc9_
            -- zero.rot = math.random() * 4 - 2
            -- zero.onEnterFrame = function()
            -- this.vy = this.vy + 0.2
            -- this._x = this._x + this.vx
            -- this._y = this._y + this.vy
            -- this._rotation = this._rotation + this.rot
            -- if this._y > 1000 then
            --     -- delete this.onEnterFrame
            --     this.removeMovieClip()
            -- end
        end
        score = score + 1
        if score > hiscore then
            -- so.data.hi = score
            -- so.flush()
            hiscore = score
        end
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
        if(b2.f == 4) then
            -- createexp(b2)
            -- b2.removeMovieClip()
            table.remove(barray, n)
            return
        end
        -- b2.gotoAndStop(b2.f)
        -- createpart(b1,b2)
    end
end

 -- game over screen move down
function gomove()
    goscreen:moveBy(0, -10)
    -- goscreen._y -= (goscreen._y - 240) / 10;
end

function restore()
   score = 0
   goscreen:remove()
   for j = 1,#barray do
       barray[j]:remove()
   end
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
end


-- Create parts of ball that fall
function createpart(b1, b2)
    sound_crack:play()
    local xdist = b2._x - b1._x
    local ydist = b2._y - b1._y
    local _loc6_ = math.atan2(ydist, xdist)
    local x_pos = math.cos(_loc6_) * b1.r + b1._x
    local y_pos = math.sin(_loc6_) * b1.r + b1._y
    -- for pc = 0,9 do
    --     local part = {}
    --     -- part = _root.attachMovie("part","part",_root.getNextHighestDepth())
    --     part._x = x_pos
    --     part._y = y_pos
    --     part.vx = Math.random() * 10 - 5
    --     part.vy = Math.random() * 10 - 5
    --     part.gotoAndStop(random(2) + 1)
    --     part.onEnterFrame = function()
    --         this.vy = this.vy + 0.1
    --         this._x += this.vx
    --         this._y += this.vy
    --         this._alpha -= 1
    --         if this._alpha < 10 then
    --             -- delete this.onEnterFrame;
    --             this.removeMovieClip()
    --         end
    --     end
    -- end
end



-- Create explosion
-- function Game:createexp(b2)
--   Game.sound_crack:play()
--   for pc = 0, 19 do
--     -- cut = _root.createEmptyMovieClip("cut",_root.getNextHighestDepth());
--     cut = {} -- Sprite on top
--     -- lineTo(random(30) - 15, random(30) - 15)
--     -- lineTo(random(30) - 15, random(30) - 15)
--     cut._x = b2._x
--     cut._y = b2._y
--     cut.vx = math.random() * 16 - 8
--     cut.vy = math.random() * 16 - 8
--     cut.rotspeed = math.random(6) - 3
--     cut.onEnterFrame = function()
--       this._x = this._x + this.vx
--       this._y = this._y + this.vy
--       this._rotation = this._rotation + this.rotspeed
--       this._alpha = this._alpha - 0.5
--
--       if this._alpha < 1 then
--         -- delete this.onEnterFrame
--         this.removeclip()
--       end
--     end
--   end
-- end

function setup()
    newball()
    -- (moveball, gomove, grow2, shooter)
    tripod:moveTo(startX, screenY - 20)
    tripod:add()
    tripod:setZIndex(11000)
    -- sound_music:play(9999)
    fsm = shooter
    playdate.AButtonDown = shootnow
end

setup()

function Gimme.update()
    playdate.graphics.sprite.update()
    playdate.timer.updateTimers()
    fsm()
end

