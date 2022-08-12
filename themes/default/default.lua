local gfx <const> = playdate.graphics
local snd     <const> = playdate.sound
local disp    <const> = playdate.display

local dwidth <const>, dheight <const> = disp.getWidth(), disp.getHeight()

local scene = {
	
	-- initialize music
	playtris_music = snd.fileplayer.new("assets/music/bgmintro"),
	
	-- initalize images
	nextFrameImage = gfx.image.new("assets/images/next-frame"),
	holdFrameImage = gfx.image.new("assets/images/hold-frame"),
	
	
	setup = function(self) 
		
		-- set system font
		self.font = gfx.getSystemFont(gfx.font.kVariantBold)
		gfx.setFont(self.font)
		self.playtris_music:setLoopRange( 36, 54 )
		currentSong = self.playtris_music
		
		-- set menu background
		--menu_background = gfx.image.new(400,240)
		menu_background = gfx.image.new("assets/images/default_menu")
		
		-- initialize sound effects
		comboSounds = {}
		for i=1, 4 do table.insert(comboSounds, loadSound("combo/combo"..i)) end
		
		dropSound = loadSound("drop")
		specialSound = loadSound("special")
		holdSound = loadSound("hold")
		spinSound = loadSound("spin")
		moveSound = loadSound("movetrimmed")
		menuScrollSound = loadSound("menu/menu-scroll")
		menuClickSound = loadSound("menu/menu-click")
		
	end,
	
	draw = function(self) 
		
		self.holdFrameImage:drawCentered((UITimer.value-2)*uiBlockSize, 5*uiBlockSize-1)
		self.nextFrameImage:drawCentered(dwidth-(UITimer.value-2)*uiBlockSize, 5*uiBlockSize-1)

	end,
	
	drawScores = function(score)
		--draw scores
		gfx.drawTextAligned("*Score*", (UITimer.value-2)*uiBlockSize, 9*uiBlockSize, kTextAlignment.center)
		gfx.drawTextAligned("*"..math.floor(score).."*", (UITimer.value-2)*uiBlockSize, 11*uiBlockSize, kTextAlignment.center)
		gfx.drawTextAligned("*Highscore*", (UITimer.value-2)*uiBlockSize, 13*uiBlockSize, kTextAlignment.center)
		gfx.drawTextAligned("*"..highscore.."*", (UITimer.value-2)*uiBlockSize, 15*uiBlockSize, kTextAlignment.center)	
	end,
	
	drawLevelInfo = function(level, completedLines) 
		--draw level info
		gfx.drawTextAligned("*Level*", dwidth-(UITimer.value-2)*uiBlockSize, 9*uiBlockSize,kTextAlignment.center)
		gfx.drawTextAligned("*"..level.."*", dwidth-(UITimer.value-2)*uiBlockSize, 11*uiBlockSize,kTextAlignment.center)
		gfx.drawTextAligned("*Lines*", dwidth-(UITimer.value-2)*uiBlockSize, 13*uiBlockSize, kTextAlignment.center)
		gfx.drawTextAligned("*"..completedLines.."*", dwidth-(UITimer.value-2)*uiBlockSize, 15*uiBlockSize, kTextAlignment.center)
	end,
	
	drawHeldPiece = function(heldPiece)
		--draw held piece
		--holdFrameImage:drawCentered((UITimer.value-2)*uiBlockSize, 5*uiBlockSize-1)
						
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
}

scene:setup()

return scene
