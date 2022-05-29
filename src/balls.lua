local gfx <const> = playdate.graphics
local img <const> = playdate.graphics.image
local white <const> = playdate.graphics.kColorWhite
local black <const> = playdate.graphics.kColorBlack

gimme_balls = nil

local function draw3(radius)
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
    gfx.drawLine(right, top, right, bottom)     -- right edge
    gfx.drawLine(right, top, left, top)         -- top
    gfx.drawLine(right, middle, left_mid, middle)   -- middle
    gfx.drawLine(right, bottom, left, bottom)   -- bottom
end

local function draw2(radius)
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
    gfx.drawLine(right, top, left, top)         -- top
    gfx.drawLine(right, top, right, middle)     -- up right
    gfx.drawLine(right, middle, left, middle)   -- middle
    gfx.drawLine(left, bottom, left, middle)    -- bottom left
    gfx.drawLine(right, bottom, left, bottom)   -- bottom
end

local function draw1(radius)
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

local function draw0(radius)
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
    local i = img.new( filename )
    return i
end

local function makeImage(radius, draw_func)
    local image = img.new(radius * 2, radius * 2)
    gfx.lockFocus(image)
        draw_func(radius)
    gfx.unlockFocus()
    return image
end

local draw_funcs = {[0]=draw0, [1]=draw1, [2]=draw2, [3]=draw3}
function get_ball(r, n)
    local rint = math.floor(r)
    if rint < 4 then
        rint = 4
    end
    local ball = gimme_balls[n][rint]
    if not ball then
        ball = makeImage(rint, draw_funcs[n])
        gimme_balls[n][rint] = ball
    end
    return ball
end

function balls_setup()
    if gimme_balls then
        return gimme_balls
    end
    gimme_balls = {[0]={}, [1]={}, [2]={}, [3]={}}
    gfx.setLineCapStyle(playdate.graphics.kLineCapStyleSquare)
    n = 3 -- only load 3s. 0/1/2 generated on-demand during update()
    for radius = 1,90 do
        if radius >= 9 then
            gimme_balls[n][radius] = makeImage(radius, draw3)
        else
            gimme_balls[n][radius] = loadImage(2 * radius, n)
        end
    end
    return gimme_balls
end
