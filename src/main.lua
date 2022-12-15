-- Standard libs from PlayDate SDK
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animator"
import "CoreLibs/crank"
import "draw"
import "gimme"

local function setup()
    gimme_setup()
    playdate.update = gimme_update
end
setup()
