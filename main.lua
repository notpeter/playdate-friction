-- Standard libs from PlayDate SDK
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "game"

-- Globals
game = nil -- Game

function playdate.update()
    playdate.graphics.sprite.update()
    playdate.timer.updateTimers()
    -- game:handle_input()
    -- game:draw_scoreboard()
    game:update()
    game:draw()
end

function playdate.AButtonDown()
    game:shoot()
end

local function game_setup()
    math.randomseed(playdate.getSecondsSinceEpoch())

--     menu = playdate.getSystemMenu()
--     menu:addMenuItem("retile", function() game:retile("easy") end)
--
--     local file = "poop"
--     menu:addMenuItem("save", function() game:Write(file) end)
--     menu:addMenuItem("size", function() game:set_size(48) end)
    game = Game.new()
end

game_setup()
