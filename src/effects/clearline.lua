import "constants"

import "CoreLibs/graphics"
import "CoreLibs/object"

ClearLine = {}
class("ClearLine").extends()

local function random(min, max)
	min = min or 0
	max = max or 1
	math.randomseed(({playdate.getSecondsSinceEpoch()})[2])
	return min + (max - min) * math.random()
end

function ClearLine:init(y)
	self.pos = GEOM.point.new(offsetX*blockSize,(offsetY+y)*blockSize)
	self.widthTimer = playdate.timer.new(250, gridXCount*blockSize, 0, EASINGS.inOutCubic)
	self.particle = nil
end

function ClearLine:update()
	if self.widthTimer.timeLeft <= 0 and not self.particleThrown then
		---@diagnostic disable: redefined-local
		self.particle = {
			pos = GEOM.point.new(offsetX*blockSize, self.pos.y),
			delta = GEOM.vector2D.new(-5, -random(2.5,5)),
			update = function(self)
				self.pos = self.pos + self.delta
				self.delta.y = self.delta.y + 1

				if self.pos.y > DHEIGHT then
				self.dead = true end
			end,
			draw = function(self)
				GFX.pushContext()
				GFX.setLineWidth(blockSize)
				GFX.drawLine(
					self.pos.x,self.pos.y,
					self.pos.x + self.delta.x*2, self.pos.y + self.delta.y*2
				)
				GFX.popContext()
			end
		}
		---@diagnostic enable: redefined-local
		self.particleThrown = true
	end
end

function ClearLine:draw()
	GFX.pushContext()
	GFX.setColor(darkMode and GFX.kColorWhite or GFX.kColorBlack)
	GFX.fillRect(self.pos.x, self.pos.y, self.widthTimer.value, blockSize)
	if self.particle then
		self.particle:draw()
		self.particle:update()
		if self.particle.dead then self.dead = true end
	end
	GFX.popContext()
end
