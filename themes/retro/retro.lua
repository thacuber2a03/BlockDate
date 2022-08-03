local gfx <const> = playdate.graphics
local snd     <const> = playdate.sound
local disp    <const> = playdate.display

local dwidth <const>, dheight <const> = disp.getWidth(), disp.getHeight()

-- initialize image table for visual effect
local firework_animation = gfx.imagetable.new('themes/retro/assets/images/fireworks')
local total_frames = firework_animation:getLength()

local scene = {
	
	-- x and y of held and next pieces
	--heldPiece_x = 12,
	--heldPiece_x = -5, -- put piece off screen to keep the retro aesthetic?
	--heldPiece_y = 5,
	nextPiece_x = 16.5,
	nextPiece_y = 16.5,
	
	--retro_music = loadMusic("Korobeiniki"),
	retro_music = snd.fileplayer.new("themes/retro/assets/music/Korobeiniki"),
	
	setup = function(self) 
		self.image = gfx.image.new('themes/retro/assets/images/retro_background')
		retro_font = gfx.font.new("themes/retro/assets/fonts/gamekid_m")
		gfx.setFont(retro_font)
		currentSong = self.retro_music
		
		-- set menu background
		menu_background = gfx.image.new("themes/retro/assets/images/menu_background")
		
		-- initialize sound effects
		comboSounds = {}
		for i=1, 4 do table.insert(comboSounds, loadSound("combo/combo"..i)) end

		dropSound = snd.sampleplayer.new("assets/sounds/drop")
		specialSound = snd.sampleplayer.new("themes/retro/assets/sounds/clear4")
		spinSound = snd.sampleplayer.new("themes/retro/assets/sounds/rotate")
		moveSound = snd.sampleplayer.new("themes/retro/assets/sounds/move")		
		
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
	end,
	
	-- visual effect to display message to player
	visualEffect = function(message)
		
		-- initialize our effect object here:
		local effect = {}
				
		-- initialize our fireworks
		fireworks = {}
		local _x = 0
		local _y = 64
		
		for i = 1, 3 do
			-- initialize firework
			local firework = {}
			
			firework.x = _x
			firework.y = _y + math.random(-15,15)
			firework.animation_frame = 1
			
			fireworks[i] = firework
			
			_x += 32 -- increment x for next firework	
		end
		
		
		-- update effect
		function effect:update()
			
			for i, firework in ipairs(fireworks) do  -- #v is the size of v for lists.
				
				if not firework.exploded then 
					-- move firework up in the sky
					firework.y -= 1
				
					-- detonate firework randomly
					if math.random(1,32) == 1 or firework.y < 16 then
						firework.exploded = true
					end
				end
				
				-- draw firework
				firework_animation:drawImage(math.floor(firework.animation_frame), firework.x, firework.y)
				
				-- increase animation if firework has already exploded
				if firework.exploded then 				
					firework.animation_frame += 0.5
					if firework.animation_frame > total_frames then 
						table.remove(fireworks, i) -- remove firework from table
					end	
				end
				
				-- end effect after all fireworks have ended
				if #fireworks == 0 then effect.dead = true end
				
			end			
			
		end
		
		-- draw effect
		function effect:draw()
			-- drawing done in effect:update()
		end
		
		-- return our effect object
		return effect		
	end
	
}

scene:setup()

return scene
