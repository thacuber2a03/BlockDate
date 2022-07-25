local gfx <const> = playdate.graphics

local scene = {}
--[[]
local scene = {
	init = function()
		local s = {
			bgImageTable = gfx.imagetable.new('assets/rainblock_images/bg.gif'),
			bgImageIndex = 1,
			skyImage = gfx.image.new('assets/rainblock_images/sky.png'),
			clouds1Image = gfx.image.new('assets/rainblock_images/clouds1.png'),
			clouds2Image = gfx.image.new('assets/rainblock_images/clouds2.png'),
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
]]

function scene.init(theme)

	if theme == "chill" then
		print("Chill theme selected!")
		local s = {
			bgImageTable = gfx.imagetable.new('assets/rainblock_images/bg.gif'),
			bgImageIndex = 1,
			skyImage = gfx.image.new('assets/rainblock_images/sky.png'),
			clouds1Image = gfx.image.new('assets/rainblock_images/clouds1.png'),
			clouds2Image = gfx.image.new('assets/rainblock_images/clouds2.png'),
			chill_music = loadMusic("glad_to_be_stuck_inside"),
			clouds1X = 0,
			clouds2X = 0,
			animationTimer = nil,
			setup = function(self)
				self.animationTimer = playdate.timer.new(500, function() self:nextFrame() end)
				self.animationTimer.repeats = true
				-- initalize font
				self.font = gfx.font.new("assets/fonts/playtris")
				gfx.setFont(self.font)
				-- initialize music
				currentSong = self.chill_music
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
			end,
			drawScores = function(score)
				--draw scores
				gfx.drawText("SCORE", 265,190)
				gfx.drawText(math.floor(score), 265, 203)
			end,
			drawLevelInfo = function(level)
				--draw level info
				gfx.drawText("LEVEL", 60,190)
				if level < 10 then
					gfx.drawText(level, 120, 203)
				else
					gfx.drawText(level, 120 - text_width, 203)
				end
			end,
			drawHeldPiece = function(self)
				--draw held piece
			end
		}
		
		s:setup()
		return s
		
	elseif theme == "retro" then
		print('Retro theme chosen')
		local s = {
			retro_music = loadMusic("Korobeiniki"),
			setup = function(self) 
				self.image = gfx.image.new('assets/images/retro_background')
				retro_font = gfx.font.new("assets/fonts/gamekid_m")
				gfx.setFont(retro_font)
				currentSong = self.retro_music
			end,
			draw = function(self) 
				self.image:drawIgnoringOffset(0, 0)
			end
		}
		s:setup()
		return s
		
	else
		print('Default theme chosen')
		local s = {
			playtris_music = loadMusic("bgmintro"),
			setup = function(self) 
				--self.font = gfx.font.new("assets/fonts/playtris")
				self.font = gfx.getSystemFont(gfx.font.kVariantBold)
				gfx.setFont(self.font)
				self.playtris_music:setLoopRange( 36, 54 )
				currentSong = self.playtris_music
			end,
			draw = function(self) end,
			drawScores = function(self)
				--draw scores
				gfx.drawTextAligned("*Score*", (UITimer.value-2)*uiBlockSize, 9*uiBlockSize, kTextAlignment.center)
				--blockdate_font:drawTextAligned("*SCORE*", (UITimer.value-2)*uiBlockSize, 9*uiBlockSize, kTextAlignment.center)
				gfx.drawText("SCORE", (UITimer.value-2)*uiBlockSize, 9*uiBlockSize)
				gfx.drawTextAligned("*"..math.floor(score).."*", (UITimer.value-2)*uiBlockSize, 11*uiBlockSize, kTextAlignment.center)
				--gfx.drawTextAligned(math.floor(score), (UITimer.value-2)*uiBlockSize, 11*uiBlockSize, kTextAlignment.center)
				gfx.drawText(math.floor(score), (UITimer.value-2)*uiBlockSize, 11*uiBlockSize)
				gfx.drawTextAligned("*Highscore*", (UITimer.value-2)*uiBlockSize, 13*uiBlockSize, kTextAlignment.center)
				gfx.drawTextAligned("*"..highscore.."*", (UITimer.value-2)*uiBlockSize, 15*uiBlockSize, kTextAlignment.center)
			end,
			drawLevelInfo = function(self)
				--draw level info
			end,
			drawHeldPiece = function(self)
				--draw held piece
			end
		}
		s:setup()
		return s
	end

end

return scene



--- REFERENCE CODE ---
--[[
local function drawScores()
	gfx.drawText("SCORE", 265,190)
	gfx.drawText(math.floor(score), 265, 203)
end

local function drawLevelInfo()
	gfx.drawText("LEVEL", 60,190)
	if level < 10 then
		gfx.drawText(level, 120, 203)
	else
		gfx.drawText(level, 120 - text_width, 203)
	end
end

local function drawHeldPiece() -- draw held piece
	gfx.drawText("HOLD", (UITimer.value-5)*uiBlockSize, 2*uiBlockSize-1)
	if heldPiece then
		loopThroughBlocks(function(_, x, y)
			local block = pieceStructures[heldPiece][1][y][x]
			if block ~= ' ' then
				local acp = heldPiece ~= 1 and heldPiece ~= 2
				drawBlock('*', x+(UITimer.value-(acp and 3.5 or 3.9)), y+(acp and 4 or (heldPiece == 1 and 3.5 or 3)), uiBlockSize)
			end
		end)
	end
end

local function drawNextPiece() -- draw next piece
	gfx.drawText("NEXT", dwidth-(UITimer.value)*uiBlockSize, 2*uiBlockSize-1)
	loopThroughBlocks(function(_, x, y)
		local nextPiece = sequence[#sequence]
		local block = pieceStructures[nextPiece][1][y][x]
		if block ~= ' ' then
			local acp = nextPiece ~= 1 and nextPiece ~= 2
			drawBlock('*', x+(dwidth/uiBlockSize)-(UITimer.value-(acp and 0.625 or 0.125)), y+(acp and 4 or (nextPiece == 1 and 3.5 or 3)),uiBlockSize)
		end
	end)
end
]]