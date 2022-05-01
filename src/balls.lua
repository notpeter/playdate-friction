local gfx <const> = playdate.graphics
local img <const> = playdate.graphics.image

gimme = gimme or {}
gimme.balls = {[1]={}, [2]={}, [3]={}}

function draw3(radius)
    local right = 1.25 * radius
    local left = .75 * radius
    local left_mid = .85 * radius
    local middle = radius
    local top = .5 * radius
    local bottom = 1.5 * radius
    local line_width = radius // 5 + 1
    gfx.setLineWidth(line_width)
    gfx.setColor(playdate.graphics.kColorBlack)
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
    gfx.setLineWidth(line_width)
    gfx.setColor(playdate.graphics.kColorBlack)
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
    gfx.setLineWidth(line_width)
    gfx.setColor(playdate.graphics.kColorBlack)
    gfx.drawLine(middle, top, middle, bottom)
end


function makeImage(radius, draw_func)
    local r2 = radius * 2
    local image = img.new(r2, r2)
    gfx.lockFocus(image)
        gfx.setColor(playdate.graphics.kColorWhite)
        gfx.fillCircleInRect(0, 0, r2, r2)
        draw_func(radius)
    gfx.unlockFocus()
    return image
end

function setup()
    gfx.setLineCapStyle(playdate.graphics.kLineCapStyleSquare)
    for n, draw_func in pairs({[1]=draw1, [2]=draw2, [3]=draw3, [4]=draw4}) do
        for radius = 1,175 do
            gimme.balls[n][radius] = makeImage(radius, draw_func)
        end
    end
end

setup()
