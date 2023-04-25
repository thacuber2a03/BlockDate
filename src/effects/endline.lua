import "constants"

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

EndLine = {}
class("EndLine").extends()

function EndLine:init(y)
	self.pos = GEOM.point.new(offsetX*blockSize,y*blockSize)
	self.max_life = 60
	self.life = self.max_life
	self.patterns = {
		{0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF},
		{0xFF, 0xDD, 0xFF, 0x77, 0xFF, 0xDD, 0xFF, 0x77},
		{0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA},
		{0x0, 0x22, 0x0, 0x88, 0x0, 0x22, 0x0, 0x88},
		{0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0},
	}
end

function EndLine:update()
	if self.life <= 0 then self.dead = true return end
	self.life = self.life - 5
end

function EndLine:draw()
	GFX.pushContext()
	local nextPattern = math.max(math.floor((self.life/self.max_life)*#self.patterns)+1, 1)
	if darkMode then nextPattern = #self.patterns-nextPattern+1 end
	GFX.setPattern(self.patterns[nextPattern])
	GFX.fillRect(self.pos.x,self.pos.y,gridXCount*blockSize,blockSize)
	GFX.popContext()
end
