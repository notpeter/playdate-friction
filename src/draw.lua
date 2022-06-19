local geo <const> = playdate.geometry
local gfx <const> = playdate.graphics
local img <const> = playdate.graphics.image
local white <const> = playdate.graphics.kColorWhite
local black <const> = playdate.graphics.kColorBlack

local gimme_balls = nil

function draw3(radius)
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

function draw2(radius)
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

function draw1(radius)
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

function draw0(radius)
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

function loadImage(diameter, cnt)
    -- Note returns nil file not found. Which won't get stored in the Lua tbl.
    local filename = string.format("images/ball_%s-%s", diameter, cnt)
    local i = img.new( filename )
    return i
end

function makeImage(radius, draw_func)
    local image = img.new(radius * 2, radius * 2)
    gfx.lockFocus(image)
        draw_func(radius)
    gfx.unlockFocus()
    return image
end

function balls_setup()
    if gimme_balls then
        return gimme_balls
    else
        gimme_balls = {}
    end
    local min_size, max_size = 1, 175
    gfx.setLineCapStyle(playdate.graphics.kLineCapStyleSquare)
    for n, draw_func in pairs({[0]=draw0, [1]=draw1, [2]=draw2, [3]=draw3}) do
        gimme_balls[n] = {}
        for radius = min_size,max_size do
            if radius >= 9 then -- custom drawn balls are up to 16x16 (radius=8)
                gimme_balls[n][radius] = makeImage(radius, draw_func)
            else
                gimme_balls[n][radius] = loadImage(2 * radius, n)
            end
        end
    end
    return gimme_balls
end

function shooter_draw(diameter)
    local d = diameter - 1
    local center = geo.point.new(diameter // 2, diameter // 2)
    local l1 = geo.lineSegment.new(0, 0, 0, d)
    local l2 = geo.lineSegment.new(d, 0, 0, 0)
    local l3 = geo.lineSegment.new(d, d, d, 0)
    local t = table.create(181, 0)
    local at = geo.affineTransform.new()
    local center = geo.point.new(diameter // 2, diameter // 2)
    for a = 0,90 do
        local s = img.new(diameter, diameter)
        at:reset()
        at:rotate(a, center)
        print(a, l2, at:transformedLineSegment(l2))
        gfx.lockFocus(s)
            gfx.setColor(white)
            gfx.drawLine(0, center.y, d, center.y)
            gfx.drawLine(at:transformedLineSegment(l1))
            gfx.drawLine(at:transformedLineSegment(l2))
            gfx.drawLine(at:transformedLineSegment(l3))
        gfx.unlockFocus()
        t[a] = s:rotatedImage(a)
    end
    return t
end
