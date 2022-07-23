local Gfx <const> = playdate.graphics

local scene = {
	create = function()
		local s = {
			bgImageTable = Gfx.imagetable.new('assets/rainblock_images/bg.gif'),
			bgImageIndex = 1,
			skyImage = Gfx.image.new('assets/rainblock_images/sky.png'),
			clouds1Image = Gfx.image.new('assets/rainblock_images/clouds1.png'),
			clouds2Image = Gfx.image.new('assets/rainblock_images/clouds2.png'),
			clouds1X = 0,
			clouds2X = 0,
			animationTimer = nil,
			setup = function(self)
				self.animationTimer = playdate.timer.new(500, function() self:nextFrame() end)
				self.animationTimer.repeats = true
			end,
			nextFrame = function(self)
				self.clouds1X = self.clouds1X + 0.24
				self.clouds2X = self.clouds2X + 0.51
				if self.clouds1X > 800 then
					self.clouds1X = 0
				end
				if self.clouds2X > 800 then
					self.clouds2X = 0
				end
				self.bgImageIndex = self.bgImageIndex + 1
				if self.bgImageIndex > self.bgImageTable:getLength() then
					self.bgImageIndex = 1
				end
			end,
			draw = function(self)
				self.skyImage:drawIgnoringOffset(0, 0)
				self.clouds1Image:drawIgnoringOffset(math.floor(self.clouds1X) - 800, 0)
				self.clouds1Image:drawIgnoringOffset(math.floor(self.clouds1X), 0)
				self.clouds2Image:drawIgnoringOffset(math.floor(self.clouds2X) - 800, 0)
				self.clouds2Image:drawIgnoringOffset(math.floor(self.clouds2X), 0)
				local bgImage = self.bgImageTable:getImage(self.bgImageIndex)
				bgImage:drawIgnoringOffset(0, 0)
			end
		}

		s:setup()
		return s
	end
}

return scene