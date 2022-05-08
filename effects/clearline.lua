import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx  <const> = playdate.graphics
local geom <const> = playdate.geometry

class("ClearLine").extends()

local function random(min, max)
	min = min or 0
	max = max or 1
	math.randomseed(({playdate.getSecondsSinceEpoch()})[2])
	return min + (max - min) * math.random()
end

function ClearLine:init(y)
	self.pos = geom.point.new(offsetX*blockSize,(offsetY+y)*blockSize)
	self.widthTimer = playdate.timer.new(250, gridXCount*blockSize, 0, playdate.easingFunctions.inOutCubic)
	self.particle = nil
	--self.widthTimer.reverseEasingFunction = playdate.easingFunctions.outInCubic
	--self.widthTimer.reverses = true
end

function ClearLine:update()
	if self.widthTimer.timeLeft <= 0 and not self.particleThrown then
		self.particle = {
			pos = geom.point.new(offsetX*blockSize, self.pos.y),
			delta = geom.vector2D.new(-5, -random(2.5,5)),
			update = function(self)
				self.pos += self.delta
				self.delta.y += 1

				if self.pos.y > playdate.display.getHeight() then
				self.dead = true end
			end,
			draw = function(self)
				gfx.pushContext()
				gfx.setLineWidth(blockSize)
				gfx.drawLine(
					self.pos.x,self.pos.y,
					self.pos.x + self.delta.x*2, self.pos.y + self.delta.y*2
				)
				gfx.popContext()
			end
		}
		self.particleThrown = true
	end
end

function ClearLine:draw()
	gfx.pushContext()
	gfx.setColor(darkMode and gfx.kColorWhite or gfx.kColorBlack)
	gfx.fillRect(self.pos.x, self.pos.y, self.widthTimer.value, blockSize)
	if self.particle then
		self.particle:draw()
		self.particle:update()
		if self.particle.dead then self.dead = true end
	end
	gfx.popContext()
end