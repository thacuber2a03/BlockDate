---@diagnostic disable lowercase-global
import "constants"
import "globals"
import "sounds"

-- initialize image table for visual effect
local starsAnimation = GFX.imagetable.new('themes/chill/assets/images/stars')
local total_frames = starsAnimation:getLength()

local scene = {

	-- set x and y locations of held block in UI for this theme
	heldPiece_x = 12,
	heldPiece_y = 5,

	bgImageTable = GFX.imagetable.new('themes/chill/assets/images/bg.gif'),
	bgImageIndex = 1,
	skyImage = GFX.image.new('themes/chill/assets/images/sky.png'),
	clouds1Image = GFX.image.new('themes/chill/assets/images/clouds1.png'),
	clouds2Image = GFX.image.new('themes/chill/assets/images/clouds2.png'),

	chill_music = SND.fileplayer.new("themes/chill/assets/music/glad_to_be_stuck_inside"),

	clouds1X = 0,
	clouds2X = 0,
	animationTimer = nil,

	setup = function(self)
		self.animationTimer = TIME.new(500, function() self:nextFrame() end)
		self.animationTimer.repeats = true

		-- set menu background
		menuBackground = GFX.image.new("themes/chill/assets/images/launchImage")

		-- initialize font
		self.font = GFX.font.new("assets/fonts/playtris")
		GFX.setFont(self.font)
		text_width, text_height = GFX.getTextSize("0")

		-- initialize music
		currentSong = self.chill_music

		-- initialize sound effects
		comboSounds = {}
		for i=1, 4 do table.insert(comboSounds, loadSound("chill/lineClear"..i)) end
		dropSound = loadSound("chill/land")
		specialSound = loadSound("chill/lineClear4")
		holdSound = loadSound("chill/hold")
		spinSound = loadSound("chill/rotate")
		moveSound = loadSound("chill/shift")
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

		GFX.drawText("HOLD", (UITimer.value-5)*uiBlockSize, 2*uiBlockSize-1)
		GFX.drawText("NEXT", DWIDTH-(UITimer.value)*uiBlockSize, 2*uiBlockSize-1)
	end,

	drawScores = function(score)
		--draw scores
		GFX.drawText("SCORE", 265,190)
		GFX.drawText(math.floor(score), 265, 203)
	end,

	drawLevelInfo = function(level)
		--draw level info
		GFX.drawText("LEVEL", 60,190)
		if level < 10 then
			GFX.drawText(level, 120, 203)
		else
			GFX.drawText(level, 120 - text_width, 203)
		end
	end,

	drawHeldPiece = function(heldPiece)
		--draw held piece
		GFX.drawText("HOLD", (UITimer.value-5)*uiBlockSize, 2*uiBlockSize-1)

		if heldPiece then
			loopThroughPieceBlocks(function(_, x, y)
				local block = pieceStructures[heldPiece][1][y][x]
				if block ~= ' ' then
					local acp = heldPiece ~= 1 and heldPiece ~= 2
					drawBlock('*', x+(UITimer.value-(acp and 3.5 or 3.9)), y+(acp and 4 or (heldPiece == 1 and 3.5 or 3)), uiBlockSize)
				end
			end)
		end
	end,

	visualEffect = function(message)
		-- visual effect to display message to player
		-- initialize our effect object here:
		local effect = {}
		effect.__index = effect

		effect.text = message
		effect.animation_frame = 1

		effect.x = 20
		effect.y = 120

		--effect.x = 135
		effect.x = 10
		effect.y = 220

		-- timer to determine how long to display effect
		TIME.new(2000,function() effect.dead = true end )

		-- update effect
		function effect:update()
			self.animation_frame = self.animation_frame + 1
			if self.animation_frame > total_frames then self.animation_frame = 1 end
		end

		-- draw effect
		function effect:draw()
			starsAnimation:drawImage(self.animation_frame, self.x - 20, self.y)
			starsAnimation:drawImage(self.animation_frame, self.x + 20, self.y)
			starsAnimation:drawImage(self.animation_frame, self.x + 60, self.y)
			GFX.drawText(self.text, self.x, self.y)
		end

		-- return our effect object
		return effect
	end
}

scene:setup()

return scene
