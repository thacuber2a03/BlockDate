local gfx <const> = playdate.graphics
local snd     <const> = playdate.sound
local disp    <const> = playdate.display

local dwidth <const>, dheight <const> = disp.getWidth(), disp.getHeight()

print('Retro theme selected!')
local scene = {
	
	-- x and y of held nad next pieces
	--heldPiece_x = 12,
	--heldPiece_y = 5,
	nextPiece_x = 16.5,
	nextPiece_y = 16.5,
	
	retro_music = loadMusic("Korobeiniki"),
	
	setup = function(self) 
		self.image = gfx.image.new('assets/images/retro_background')
		retro_font = gfx.font.new("assets/fonts/gamekid_m")
		gfx.setFont(retro_font)
		currentSong = self.retro_music
		
		-- initialize sound effects
		comboSounds = {}
		for i=1, 4 do table.insert(comboSounds, loadSound("combo/combo"..i)) end
		dropSound = loadSound("drop")
		specialSound = loadSound("retro/clear4")
		spinSound = loadSound("retro/rotate")
		moveSound = loadSound("retro/move")
		
	end,
	
	drawScores = function(score)
		--draw scores
		gfx.drawText("SCORE", 298, 8)
		gfx.drawText(math.floor(score), 298, 28)	
	end,
	
	drawLevelInfo = function(level, completedLines) 
		gfx.drawText("LEVEL", 300, 64)
		gfx.drawText(level, 316, 80)
		gfx.drawText("LINES", 300, 116)
		gfx.drawText(completedLines, 316, 132)
	end,
	
	draw = function(self) 
		self.image:drawIgnoringOffset(0, 0)
	end
}

scene:setup()

return scene
