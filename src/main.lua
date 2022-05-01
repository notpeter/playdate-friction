-- Standard libs from PlayDate SDK
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animator"
import "CoreLibs/crank"
import "balls"
import "gimme"

local function setup()
    playdate.update = gimme.update
end
setup()
