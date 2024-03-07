local geo <const> = playdate.geometry
local gfx <const> = playdate.graphics
local img <const> = playdate.graphics.image
local white <const> = playdate.graphics.kColorWhite
local black <const> = playdate.graphics.kColorBlack

-- Constants
local screenX <const> = 400
local screenY <const> = 240
local digit_font = playdate.graphics.font.new("fonts/gimme-digits")
local small_font = playdate.graphics.font.new("fonts/gimme-small")

gimme_balls = nil

draw = {}

function draw.ball3(radius)
    local right = 1.25 * radius
    local left = .75 * radius
    local left_mid = .85 * radius
    local middle = radius
    local top = .5 * radius
    local bottom = 1.5 * radius
    local line_width = radius // 5 + 1
    gfx.setColor(white)
    gfx.fillCircleInRect(0, 0, radius * 2, radius * 2)
    gfx.setLineWidth(line_width)
    gfx.setColor(black)
    gfx.drawLine(right, top, right, bottom)       -- right edge
    gfx.drawLine(right, top, left, top)           -- top
    gfx.drawLine(right, middle, left_mid, middle) -- middle
    gfx.drawLine(right, bottom, left, bottom)     -- bottom
end

function draw.ball2(radius)
    local right = 1.25 * radius
    local left = .75 * radius
    local middle = radius
    local top = .5 * radius
    local bottom = 1.5 * radius
    local line_width = radius // 5 + 1
    gfx.setColor(white)
    gfx.fillCircleInRect(0, 0, radius * 2, radius * 2)
    gfx.setLineWidth(line_width)
    gfx.setColor(black)
    gfx.drawLine(right, top, left, top)       -- top
    gfx.drawLine(right, top, right, middle)   -- up right
    gfx.drawLine(right, middle, left, middle) -- middle
    gfx.drawLine(left, bottom, left, middle)  -- bottom left
    gfx.drawLine(right, bottom, left, bottom) -- bottom
end

function draw.ball1(radius)
    local middle = radius
    local top = .5 * radius
    local bottom = 1.5 * radius
    local line_width = radius // 5 + 1
    gfx.setColor(white)
    gfx.fillCircleInRect(0, 0, radius * 2, radius * 2)
    gfx.setLineWidth(line_width)
    gfx.setColor(black)
    gfx.drawLine(middle, top, middle, bottom)
end

function draw.ball0(radius)
    local right = 1.25 * radius
    local left = .75 * radius
    local top = .5 * radius
    local bottom = 1.5 * radius
    local line_width = radius // 5 + 1
    gfx.setLineWidth(line_width)
    gfx.setColor(white)
    gfx.drawLine(right, top, left, top)
    gfx.drawLine(left, top, left, bottom)
    gfx.drawLine(left, bottom, right, bottom)
    gfx.drawLine(right, bottom, right, top)
end

local function loadImage(diameter, cnt)
    -- Note returns nil file not found. Which won't get stored in the Lua tbl.
    local filename = string.format("images/ball_%s-%s", diameter, cnt)
    local i = img.new(filename)
    return i
end

local function makeImage(radius, draw_func)
    local image = img.new(radius * 2, radius * 2)
    gfx.lockFocus(image)
    draw_func(radius)
    gfx.unlockFocus()
    return image
end

function balls_setup()
    print("ball setup")
    if gimme_balls then
        return gimme_balls
    else
        gimme_balls = {}
    end
    local min_size, max_size = 1, 175
    gfx.setLineCapStyle(playdate.graphics.kLineCapStyleSquare)
    for n, draw_func in pairs(
        { [0] = draw.ball0, [1] = draw.ball1, [2] = draw.ball2, [3] = draw.ball3 }
    ) do
        gimme_balls[n] = {}
        for radius = min_size, max_size do
            if radius >= 9 then -- custom drawn balls are up to 16x16 (radius=8)
                gimme_balls[n][radius] = makeImage(radius, draw_func)
            else
                gimme_balls[n][radius] = loadImage(2 * radius, n)
            end
        end
    end
    return gimme_balls
end

function draw.background(image_background, left_x, right_x, passing_y)
    gfx.lockFocus(image_background)
    gfx.setColor(white)
    gfx.fillRect(0, 0, screenX, screenY)
    gfx.setColor(black)
    gfx.fillRect(left_x, 0, right_x - left_x, screenY)
    gfx.setColor(white)
    gfx.drawLine(left_x, passing_y, right_x, passing_y)
    gfx.setColor(black)
    small_font:drawTextAligned("SCORE", right_x + (screenX - right_x) / 2, 15, kTextAlignment.center)
    small_font:drawTextAligned("HI\n\nSCORE", right_x + (screenX - right_x) / 2, 110, kTextAlignment.center)
    gfx.unlockFocus()
end

-- The fixed base of the shooter
function draw.tripod(tripod_size)
    local x, y = 42, 42
    local image_tripod = img.new(x, y)
    gfx.lockFocus(image_tripod)
    gfx.setColor(white)
    gfx.fillCircleAtPoint(x // 2, 30, tripod_size)
    local rx = x // 2 - tripod_size
    gfx.fillRect(rx, 25, y - 2 * rx, y - 25)
    -- TODO: Make tall/narrow digit variation instead of this ugly hack.
    local tracking = math.floor(tripod_size // 20) + 1
    digit_font:setTracking(tracking)
    digit_font:drawTextAligned("3210", x // 2, 25, kTextAlignment.center)
    gfx.unlockFocus()
    return image_tripod
end

-- The moving aimer part of the shooter.
function draw.shooter(diameter)
    local image = img.new(diameter, diameter)
    local d = diameter - 1
    gfx.lockFocus(image)
    playdate.graphics.setColor(white)
    -- playdate.graphics.drawLine(0, 0, 0, d)
    -- playdate.graphics.drawLine(0, 0, d, 0)
    -- playdate.graphics.drawLine(d, d, d, 0)
    playdate.graphics.fillCircleInRect(0, 0, diameter, diameter)
    playdate.graphics.setColor(black)
    playdate.graphics.drawCircleInRect(0, 0, diameter, diameter)
    gfx.unlockFocus()
    return image
end

function draw.gameover(width, height)
    local image = img.new(width, height, black)
    local gameover_image = img.new("images/gameover150")
    gfx.lockFocus(image)
    gameover_image:draw((width - 150) / 2, (height - 150) / 2)
    gfx.unlockFocus()
    return image
end

function draw.score(image, num)
    image:clear(white)
    gfx.lockFocus(image)
    gfx.setColor(black)
    digit_font:drawTextAligned(num, 20, 0, kTextAlignment.center)
    gfx.unlockFocus()
end

function draw.sidebar(image, font)
    local s = [[GIMME
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
    small_font:drawTextAligned(s, 37, 5, kTextAlignment.center, 2)
    gfx.unlockFocus()
    return image
end

--
-- function shooter_draw(diameter)
--     local d = diameter - 1
--     local center = geo.point.new(diameter // 2, diameter // 2)
--     local l1 = geo.lineSegment.new(0, 0, 0, d)
--     local l2 = geo.lineSegment.new(d, 0, 0, 0)
--     local l3 = geo.lineSegment.new(d, d, d, 0)
--     local t = table.create(181, 0)
--     local at = geo.affineTransform.new()
--     local center = geo.point.new(diameter // 2, diameter // 2)
--     for a = 0,90 do
--         local s = img.new(diameter, diameter)
--         at:reset()
--         at:rotate(a, center)
--         print(a, l2, at:transformedLineSegment(l2))
--         gfx.lockFocus(s)
--             gfx.setColor(white)
--             gfx.drawLine(0, center.y, d, center.y)
--             gfx.drawLine(at:transformedLineSegment(l1))
--             gfx.drawLine(at:transformedLineSegment(l2))
--             gfx.drawLine(at:transformedLineSegment(l3))
--         gfx.unlockFocus()
--         t[a] = s:rotatedImage(a)
--     end
--     return t
-- end
