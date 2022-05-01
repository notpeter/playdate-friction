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
    gfx.setColor(playdate.graphics.kColorBlack)
    gfx.drawLine(middle, top, middle, bottom)
end


function makeImage(radius, n)
    local r2 = radius * 2
    local image = img.new(r2, r2)
    gfx.lockFocus(image)
        gfx.setColor(playdate.graphics.kColorWhite)
        gfx.fillCircleInRect(0, 0, r2, r2)
        if n == 3 then
            draw3(radius)
        elseif n == 2 then
            draw2(radius)
        elseif n == 1 then
            draw1(radius)
        end
    gfx.unlockFocus()
    return image
end

for j = 1,3 do
    for i = 1,200 do
        gimme.balls[j][i] = makeImage(i, j)
    end
end
