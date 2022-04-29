Game = {}
Game.__index = Game

-- Import Aliases (More performant and shorter)
local gfx <const> = playdate.graphics
local img <const> = playdate.graphics.image
local spr <const> = playdate.graphics.sprite
local geom <const> = playdate.geometry
local bjp <const> = playdate.buttonJustPressed
local bjr <const> = playdate.buttonJustReleased
local bip <const> = playdate.buttonIsPressed

local deg, rad = math.deg, math.rad
local math_sin, math_cos, math_tan = math.sin, math.cos, math.tan
sin = function (x) return math_sin(rad(x)) end
cos = function (x) return math_cos(rad(x)) end
tan = function (x) return math_tan(rad(x)) end

-- Global constants
local screenX <const> = 400
local screenY <const> = 240

function Game:draw()
	for _, c in pairs(game.board) do
		gfx.drawCircleAtPoint(c.x, c.y, c.radius)
	end
	if self.shot then
		print(self.shot.x, self.shot.y, self.shot.radius)
		gfx.drawCircleAtPoint(self.shot.x, self.shot.y, self.shot.radius)
	end
	self:draw_shooter()
	gfx.drawLine(50, 0, 50, screenY)
end

function Game:draw_shooter()
	gfx.setColor(playdate.graphics.kColorWhite)
	gfx.fillCircleAtPoint(10, 120, 35)
	gfx.setColor(playdate.graphics.kColorBlack)
	gfx.fillCircleAtPoint(10, 120, 20)
	gfx.fillRect(0, 100, 10, 40)

	local t = geom.affineTransform.new()
	t:rotate(self.angle)
	self.images.muzzle:drawWithTransform(t, 10, 120)
end

function Game:move_shot()
	--- Shot movement
	if not self.shot then
		return
	end

	local shot = self.shot
	local radius = 8
	shot.x = shot.x + shot.vx
	shot.y = shot.y + shot.vy
	-- this should apply as a vector shrinking
	shot.vx = shot.vx * .93
	shot.vy = shot.vy * .93
	shot.fm = shot.fm - 1
	if shot.x + shot.radius > screenX then
		shot.x = 2 * screenX - 2 * shot.radius - shot.x
		shot.vx = shot.vx * -1
	end
	if shot.y + shot.radius > screenY then
		shot.y = 2 * screenY - 2 * shot.radius - shot.y
		shot.vy = shot.vy * -1
	end
	if shot.y - shot.radius < 0 then
		shot.y = 2 * shot.radius - shot.y
		shot.vy = shot.vy * -1
	end

	self.shot_sprite:moveTo(shot.x, shot.y)
	if shot.fm <= 0 then
		local closest_wall = math.min(
			screenX - shot.x,
			math.abs(0 - shot.y),
			screenY - shot.y,
			shot.x - 10
		)

		local radius = math.min(closest_wall, self:closest_ball(shot.x, shot.y, shot.radius))
		table.insert(self.board, {x=shot.x, y=shot.y, radius=radius})
		self.shot = nil
	end
end

--- THIS IS WRONG.
function Game:closest_ball(x, y, radius)
	local ball_dist = {}
	for _, ball in pairs(self.board) do
		local xdist = ball.x - x
		local ydist = ball.y - y
		ball_dist[_] = ((xdist * xdist + ydist * ydist) -
			(ball.radius * ball.radius + radius * radius)
		)
	end
	print(math.sqrt(math.min(100000, table.unpack(ball_dist))))
	return math.sqrt(math.min(100000, table.unpack(ball_dist)))
end


function Game:update()
	--- Angle update
	self.angle = self.angle + self.angle_rate
	if self.angle >= 90 then
		self.angle = 180 - self.angle
		self.angle_rate = self.angle_rate * -1
	elseif self.angle <= -90 then
		self.angle = -180 - self.angle
		self.angle_rate = self.angle_rate * -1
	end
	self:move_shot()
end

function Game.muzzle_image()
	local image = img.new(60,15)
	gfx.lockFocus(image)
	gfx.drawRect(45,0, 15, 15)
	playdate.graphics.unlockFocus()
	return image
end

function Game.ball_image()
	local image = img.new(16,16)
	gfx.lockFocus(image)
	gfx.drawCircleAtPoint(8, 8, 8)
	gfx.drawCircleAtPoint(8, 8, 4)
	playdate.graphics.unlockFocus()
	return image
end

function Game:shoot()
	self.shot = {
		x=10, y=120, radius=8,
		vx=40*cos(self.angle),
		vy=40*sin(self.angle),
		fm=105, -- frames in motion (3.5sec @ 30fps)
	}
end

function Game.new()
	local game = {}             -- our new object
	setmetatable(game, Game)    -- make Game handle lookup
	game.board = {}
	game.board[#game.board+1] = {x=300, y=100, radius=20}
	game.images = {
		ball=Game.ball_image(),
		muzzle=Game.muzzle_image(),
	}
	game.shot_sprite = gfx.sprite.new(game.images.ball)
	game.shot_sprite:moveTo(10, 120)
	game.shot = nil
	game.angle = 0
	game.angle_rate = 2
	gfx.setScreenClipRect(80, 80, 40, 40)
	return game
end

