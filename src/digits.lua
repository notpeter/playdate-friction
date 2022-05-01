local gfx <const> = playdate.graphics
local img <const> = playdate.graphics.image

gimme = gimme or {}
gimme.digits = {}
gimme.digits.images = {}

for i = 0,9 do
    gimme.digits.images[i] = img.new( "images/digit" .. i )
end
