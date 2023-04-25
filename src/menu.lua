-- I basically just reinvented playdate.ui.gridview

---@diagnostic disable: need-check-nil

import "constants"
import "globals"

local patternTimer

local patterns = {
	{0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0, 0, 0, 0, 0}, -- white
	{0xFF, 0xDD, 0xFF, 0x77, 0xFF, 0xDD, 0xFF, 0x77, 0, 34, 0, 136, 0, 34, 0, 136}, -- lightgray 1
	{0x77, 0x77, 0xDD, 0xDD, 0x77, 0x77, 0xDD, 0xDD, 136, 136, 34, 34, 136, 136, 34, 34}, -- lightgray 2
	{0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 170, 85, 170, 85, 170, 85, 170, 85}, -- gray
}

local menuOpen = false
local menuCursor = 0
local bold = GFX.getSystemFont("bold")
local menuYTimer, menuWidth
local backgroundImage

local function closeMenu()
	menuOpen = false

	-- sorry, I love back easing XD
	menuYTimer = TIME.new(250, DHEIGHT/2, DHEIGHT, EASINGS.inBack)
	patternTimer = TIME.new(250, #patterns, 1,EASINGS.inBack)
end

local menu = {
	{
		name = "Continue",
		type = "button",
		onpress = function()
			closeMenu()
		end,
	},
	{
		name = "Ghost",
		type = "crossmark",
		state = ghost,
		ontoggle = function(val)
			ghost = val
			saveData("ghost", ghost)
		end,
	},
	{
		name = "Shake",
		type = "crossmark",
		state = shake,
		ontoggle = function(val)
			shake = val
			saveData("shake", shake)
		end,
	},
	--[[ commenting sash option out to remove it from the options menu
	{
		name = "Sash",
		type = "crossmark",
		state = sash,
		ontoggle = function(val)
			sash = val
			saveData("sash", sash)
		end,
	},
	]]
	-- code to add chill mode to options menu
	{
		name = "Chill mode",
		type = "crossmark",
		state = chill_mode,
		ontoggle = function(val)
			chill_mode = val
			saveData("chill_mode", chill_mode)
		end,
	},
	{
		name = "Grid",
		type = "crossmark",
		state = grid,
		ontoggle = function(val)
			grid = val
			saveData("grid", grid)
		end,
	},
	{
		name = "Dark mode",
		type = "crossmark",
		state = darkMode,
		ontoggle = function(val)
			darkMode = val
			saveData("darkMode", darkMode)
		end,
	},
	{
		name = "Invert Rotation",
		type = "crossmark",
		state = inverseRotation,
		ontoggle = function(val)
			inverseRotation = val
			saveData("inverseRotation", inverseRotation)
		end
	},
	{
		name = "Big blocks",
		type = "crossmark",
		state = bigBlocks,
		ontoggle = function(val)
			bigBlocks = val
			if bigBlocks then
				blockSize = 13
			else
				blockSize = 11
			end
			offsetX = ((DWIDTH  / blockSize)/2) - (gridXCount/2)
			offsetY = ((DHEIGHT / blockSize)/2) - (gridYCount/2)

			saveData("bigBlocks", bigBlocks)
		end,
	},
	{
		name = "Music",
		type = "slider",
		min = 0,
		max = 1,
		value = musicVolume,
		onchange = function(val)
			musicVolume = val
			saveData("music", musicVolume)
			updateMusicVolume()
			currentSong:setVolume(musicVolume)
		end,
	},
	{
		name = "Sound",
		type = "slider",
		min = 0,
		max = 1,
		value = soundsVolume,
		onchange = function(val)
			soundsVolume = val
			saveData("sounds", soundsVolume)
			sfx = {	specialSound, holdSound, menuScrollSound, menuClickSound, dropSound, spinSound, moveSound }
			updateSoundVolume(sfx)
			updateSoundVolume(comboSounds)
		end,
	},
}

local menuHeight = #menu*bold:getHeight()

function updateMenu()
	if menuYTimer.value == DHEIGHT/2 then
		if PD.buttonJustPressed("down") then
			menuScrollSound:play()
			menuCursor = menuCursor + 1
		elseif PD.buttonJustPressed("up") then
			menuScrollSound:play()
			menuCursor = menuCursor - 1
		end
		menuCursor = menuCursor % #menu

		local menuItem = menu[menuCursor+1]
		if PD.buttonJustPressed("a") then
			if menuItem.type == "button" then
				menuItem.onpress()
				menuClickSound:play()
			elseif menuItem.type == "crossmark" then
				menuItem.state = not menuItem.state
				menuItem.ontoggle(menuItem.state)
				menuClickSound:play()
			end

			commitSaveData()
		end

		if PD.buttonJustPressed("b") then
			menuClickSound:play()
			closeMenu()
		end

		if menuItem.type == "slider" then
			if PD.buttonIsPressed("right") then
				menuItem.value = math.max(menuItem.min, math.min(menuItem.value + menuItem.max / 50, menuItem.max))
				menuItem.onchange(menuItem.value)
				commitSaveData()
			elseif PD.buttonIsPressed("left") then
				menuItem.value = math.max(menuItem.min, math.min(menuItem.value - menuItem.max / 50, menuItem.max))
				menuItem.onchange(menuItem.value)
				commitSaveData()
			end
		end
	end

	if math.abs(DHEIGHT-menuYTimer.value) < 0.5 then
		screenClearNeeded = true
		forceInertGridRefresh = true
		playdate.inputHandlers.push(inputHandlers)
		_update = updateGame
		_draw = drawGame
	end
	TIME.updateTimers()
end

function drawMenu()
  GFX.clear(darkMode and GFX.kColorBlack or GFX.kColorWhite)
  GFX.pushContext()
  backgroundImage:draw(0, 0)
  GFX.setPattern(patterns[math.floor(patternTimer.value)])
  GFX.fillRect(0, 0, DWIDTH, DHEIGHT)
  GFX.setPattern(patterns[1])

  local rect = GEOM.rect.new(
  	DWIDTH/2-(menuWidth/2+10),
  	menuYTimer.value-(menuHeight/2+10),
  	menuWidth+20, menuHeight+20
  )
  local rad = 5
	GFX.setColor(GFX.kColorWhite)
	GFX.fillRoundRect(rect, rad)
	GFX.setColor(GFX.kColorBlack)
	GFX.drawRoundRect(rect, rad)

	local bheight = bold:getHeight()
	for i, v in ipairs(menu) do
		if v.type == "crossmark" then
			GFX.drawText("*"..v.name.."*", DWIDTH/2-menuWidth/2 + 20, menuYTimer.value-menuHeight/2+((i-1)*bheight)+1)
			local _, cheight = crossmarkFieldImage:getSize()
			local pos = GEOM.point.new(
				(DWIDTH/2-menuWidth/2)+8,
				menuYTimer.value-menuHeight/2+((i-1)*bheight)+cheight/2
			)
			crossmarkFieldImage:drawCentered(pos:unpack())
			if v.state then crossmarkImage:drawCentered(pos:unpack()) end
		elseif v.type == "slider" then
			GFX.drawText("*"..v.name.."*", DWIDTH/2-bold:getTextWidth(v.name)/2, menuYTimer.value-menuHeight/2+((i-1)*bheight))
			GFX.setColor(GFX.kColorXOR)
			GFX.fillRect(
				DWIDTH/2-menuWidth/2,
				menuYTimer.value-menuHeight/2+((i-1)*bheight)-1,
				v.value*menuWidth,
				bold:getHeight()
			)
			GFX.setColor(GFX.kColorBlack)
		else
			GFX.drawText("*"..v.name.."*", DWIDTH/2-menuWidth/2, menuYTimer.value-menuHeight/2+((i-1)*bheight)+1)
		end
	end

	local menuItem = menu[menuCursor+1]
	local x = DWIDTH/2-menuWidth/2
	local w = bold:getTextWidth(menu[menuCursor+1].name)
	if menuItem.type == "crossmark" then x = x + 20
	elseif menuItem.type == "slider" then w = menuWidth end
	GFX.drawRect(x, ((menuYTimer.value-menuHeight/2)+menuCursor*bheight)-2.5, w, bheight)
	GFX.popContext()
end

PD.getSystemMenu():addMenuItem("options", function()
	if not lost then
		menuOpen = not menuOpen
		if not menuOpen then closeMenu()
		else
			menuYTimer = TIME.new(250, 0, DHEIGHT/2, EASINGS.outBack)
			menuHeight = #menu*bold:getHeight()
			local longestString = ""
			for _, v in pairs(menu) do
				if #v.name > #longestString then
					longestString = v.name
				end
			end

			local cfiwidth, _ = crossmarkFieldImage:getSize()
			menuWidth = bold:getTextWidth(longestString) + cfiwidth
			menuCursor = 1

			backgroundImage = GFX.image.new(DWIDTH, DHEIGHT)
			GFX.pushContext(backgroundImage)
			drawGame()
			GFX.popContext()

			PD.inputHandlers.pop()
			patternTimer = TIME.new(250, 1, #patterns, EASINGS.outBack)
		end
		_update = updateMenu
		_draw = drawMenu
	end
end)
