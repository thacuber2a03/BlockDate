import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx  <const> = playdate.graphics
local geom <const> = playdate.geometry

class("EndLine").extends()

function EndLine:init(y)
	self.pos = geom.point.new(offsetX*blockSize,y*blockSize)
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
	self.life -= 5
end

function EndLine:draw()
	gfx.pushContext()
	--gfx.setColor(darkMode and gfx.kColorWhite or gfx.kColorBlack)
	local nextPattern = math.max(math.floor((self.life/self.max_life)*#self.patterns)+1, 1)
	if darkMode then nextPattern = #self.patterns-nextPattern+1 end
	gfx.setPattern(self.patterns[nextPattern])
	gfx.fillRect(self.pos.x,self.pos.y,gridXCount*blockSize,blockSize)
	gfx.popContext()
end