-- MIT License

-- Copyright (c) 2022 @thacuber2a03

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

--[[
	DONE:
	- add theme array
	- set background based on theme
	- set music based on them
	- set Font based on theme
	- create function to update theme (in menu)
	- set UI placement based on theme

	TO-DO:
	- set sound effects based on theme
	- update sound logic to simply looking of track:
		-> use fp:setLoopRange( 10, 20 )
	- Set effects based on theme
	
	- disable "hold" functionality for "retro" theme
	- prevent level from increasing for "chill" theme	
	- polish retro UI
	- make logic for themes modular so it can be maintained in a separate file
	
	- save/load theme when entering/exiting the game
	
	- Fix bug where "shake" effect whites out the screen under the playing field
]]

import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/crank"

import "pieces"
import "tspindata"
import "wallkickdata"
import "constants"

import "effects/endline"
import "effects/clearline"
import "effects/sash"

-- adding for creating rainblock aesthetic
Scene = import "scene"

local gfx     <const> = playdate.graphics
local snd     <const> = playdate.sound
local geom    <const> = playdate.geometry
local time    <const> = playdate.timer
local data    <const> = playdate.datastore
local disp    <const> = playdate.display
local easings <const> = playdate.easingFunctions

local btn  <const> = playdate.buttonIsPressed
local btnp <const> = playdate.buttonJustPressed
local dwidth <const>, dheight <const> = disp.getWidth(), disp.getHeight()

---------------
-- Save data --
---------------

-- If there's no game data available make some
savedData = data.read("gamedata") or {}

local function loadData(key)
	return savedData[key]
end

local function saveData(key, value)
	savedData[key] = value
end

local function commitSaveData()
	-- pretty print cuz why not
	data.write(savedData, "gamedata", true)
end

local function computeGridOffset()
  offsetY = ((dheight/blockSize)/2) - (gridYCount/2)
  offsetX = ((dwidth / blockSize) / 2) - (gridXCount/2)
end

----------------------
-- Global variables --
----------------------

gridXCount, gridYCount = 10, 18

pieceXCount, pieceYCount = 4, 4

uiBlockSize = 11
defaultBlockSize = 11
bigBlockSize = 13
maxLockDelayRotations = 15

-- this looks so weird
	shake, sash, ghost,
	grid, darkMode,
	inverseRotation,
	musicVolume, soundsVolume,
	bigBlocks
=
	loadData("shake") or true, loadData("sash") or true, loadData("ghost") or true,
	loadData("grid") or false, loadData("darkMode") or false,
	loadData("inverseRotation") or false,
	loadData("music") or 1, loadData("sounds") or 1,
	loadData("bigBlocks") or false

if bigBlocks then
	blockSize = bigBlockSize
else 
	blockSize = defaultBlockSize
end

computeGridOffset()

------------------------
-- "Global" variables --
------------------------

local introRectT = time.new(100, 400, 0, easings.outCubic)
introRectT.updateCallback = function(timer)
	screenClearNeeded = true
end

--local highscore = loadData("highscore") or 0
--REPLACING WITH LOCAL VARIABLE SO I CAN READ THIS FROM OUR SCENE SCRIPTS
highscore = loadData("highscore") or 0

-- t spin detection here :)
local lastAction = ""

-----------
-- Utils --
-----------

local function random(min, max, float)
	math.randomseed(playdate.getSecondsSinceEpoch())

	if not min then return math.random() end
	if not max then max = min min = 1 end

	if not float then return math.random(min, max)
	else return min + (max - min) * math.random() end
end

SOUNDSDIR = "assets/sounds/"
function loadSound(name)
	return assert(snd.sampleplayer.new(SOUNDSDIR..name))
end

MUSICDIR = "assets/music/"
function loadMusic(name)
	return assert(snd.fileplayer.new(MUSICDIR..name))
end

IMAGESDIR = "assets/images/"
local function loadImage(name)
	return assert(gfx.image.new(IMAGESDIR..name))
end

local function loadImagetable(name)
	return assert(gfx.imagetable.new(IMAGESDIR..name))
end



----------
-- Font --
----------

--blockdate_font = gfx.font.new("assets/fonts/playtris")
--retro_font = gfx.font.new("assets/fonts/gamekid_m")
gfx.setFont(blockdate_font)
text_width, text_height = gfx.getTextSize("0")


------------
-- Sounds --
------------

local comboSounds = {}
for i=1, 4 do table.insert(comboSounds, loadSound("combo/combo"..i)) end

local function stopAllComboSounds()
	for i=1, 4 do
		if comboSounds[i]:isPlaying() then comboSounds[i]:stop() end
	end
end

local dropSound = loadSound("drop")
local specialSound = loadSound("special")
local holdSound = loadSound("hold")
local spinSound = loadSound("spin")
local moveSound = loadSound("movetrimmed")

local menuScrollSound = loadSound("menu/menu-scroll")
local menuClickSound = loadSound("menu/menu-click")


local sfx = {
	specialSound,
	holdSound,
	menuScrollSound, menuClickSound,
	dropSound, spinSound, moveSound,
}

local bgmIntro = loadMusic("bgmintro")
local bgmLoop = loadMusic("bgmloop")
local playtris_music = loadMusic("bgmintro")
playtris_music:setLoopRange( 36, 54 )
local chill_music = loadMusic("glad_to_be_stuck_inside")
local retro_music = loadMusic("Korobeiniki")

local songs = {
	intro = bgmIntro, 
	--playtris = bgmLoop, 
	playtris = playtris_music, 
	chill = chill_music,
	retro = retro_music
}

--currentSong = songs.intro
currentSong = songs.playtris

-- generate song list to use in menu
local song_list = {}
local n=0
for k,v in pairs(songs) do
  n=n+1
  song_list[n]=k
end
--song_list.intro = nil	-- remove intro from song list


------------
-- images --
------------

local nextFrameImage = loadImage("next-frame")
local holdFrameImage = loadImage("hold-frame")

local crossmarkFieldImage = loadImage("crossmark-field")
local crossmarkImage = loadImage("crossmark")

local ghostBlockImagetable = loadImagetable("ghost-block/normal/ghost-block")
local ghostBlockImagetableBig = loadImagetable("ghost-block/big/ghost-block")

local gridImage = gfx.image.new(defaultBlockSize * gridXCount, defaultBlockSize * gridYCount)
local gridImageBig = gfx.image.new(bigBlockSize * gridXCount, bigBlockSize * gridYCount)
local inertGridImage = gfx.image.new(defaultBlockSize * gridXCount, defaultBlockSize * gridYCount)
local inertGridImageBig = gfx.image.new(bigBlockSize * gridXCount, bigBlockSize * gridYCount)
local menu_background = gfx.image.new("assets/rainblock_images/launchImage")

--local lineClearAnimation = gfx.imagetable.new('images/clear.gif')

------------
-- Themes --
------------
-- DO I REALLY NEED THIS LIST THOUGH?
local themes = {
	"default",
	"chill",
	"retro"
}
-- ALTERNATIVE: READ THEMES FROM scene.lua
local theme = "chill"

-- set up scene for selected theme
local scene = Scene.init(theme)

------------------------------------------
-- Game related functions and variables --
------------------------------------------

local displayYPos = 0

local completedLines = 0
local combo, level = 0, 0
local levelIncreased = false

local lostY = 1
local lost = false

local clearLines, lines, sashes = {}, {}, {}

local holdDir = 0
local heldPiece

local pieceHasChanged = false

local UITimer
local inert = {}

local timer = 0
local timerLimit = 30
local lockDelayRotationsRemaining = maxLockDelayRotations
local lockDelay = 15
local score = 0
local scoreGoal = score

local refreshNeeded = true
local screenClearNeeded = false
local forceInertGridRefresh = false

--[[
-- scene for  "rainblocks" aesthetic
local scene = {}
scene = Scene.create()
scene:setup()
]]

local lastAction = "none"

local function spawnSash(message)
	if sash then table.insert(sashes, Sash(message)) end
end

local function canPieceMove(testX, testY, testRotation)
	for y=1, pieceYCount do
		for x=1, pieceXCount do
			local testBlockX = testX + x
			local testBlockY = testY + y
			if not inert[testY+1] then return false end
			if pieceStructures[piece.type][testRotation+1][y][x] ~= ' ' and (
				testBlockX < 1 or testBlockX > gridXCount
				or testBlockY < 1 or testBlockY > gridYCount
				or inert[testBlockY][testBlockX] ~= " "
			) then
				return false
			end
		end
	end
	return true
end

local function newSequence()
	sequence = {}
	for i = 1, #pieceStructures do
		table.insert(sequence, random(#sequence + 1), i)
	end
end

local function newPiece(type)
	piece = {
		x = 3,
		y = 0,
		rotation = 0,
		type = type,
	}
	updateGhost()
	pieceHasChanged = true
	if #sequence == 0 then newSequence() end

	screenClearNeeded = true
end

local function finishRotation(tx, ty, testRotation)
	piece.x = tx
	piece.y = ty
	piece.rotation = testRotation
	refreshNeeded = true
	lastAction = "rotation"
end

function updateGhost()
	ghostPieceY = piece.y
	while canPieceMove(piece.x, ghostPieceY + 1, piece.rotation) do
		ghostPieceY += 1
	end
end

local function rotate(rotation)
	local testRotation = piece.rotation + rotation
	testRotation %= #pieceStructures[piece.type]

	-- temporary solve until I can figure out how to compact it
	local chosenRotation = 1
	if rotation == 1 then
		if piece.rotation == 0 then end -- no changes
		if piece.rotation == 1 then chosenRotation = 2 end
		if piece.rotation == 2 then chosenRotation = 3 end
		if piece.rotation == 3 then chosenRotation = 4 end
	else
		if piece.rotation == 0 then chosenRotation = 4 end
		if piece.rotation == 1 then chosenRotation = 1 end
		if piece.rotation == 2 then chosenRotation = 2 end
		if piece.rotation == 3 then chosenRotation = 3 end
	end

	--assert(testRotation+1 == chosenRotation,
	--	"Correct rotation and actual rotation aren't equal.\nChosen rotation: "..chosenRotation.."\nActual rotation: "..testRotation+1)

	local chosenWallKickTests = wallkickdata[(piece.type~=1 and 1 or 2)][chosenRotation][(rotation==1 and "cw" or "ccw")]
	for i=1, #chosenWallKickTests do
		local tx = piece.x+chosenWallKickTests[i][1]
		local ty = piece.y-chosenWallKickTests[i][2]
		local pieceCanMove = canPieceMove(tx, ty, testRotation)
		if pieceCanMove
		and lockDelayRotationsRemaining == maxLockDelayRotations then
			finishRotation(tx, ty, testRotation)
			break
		elseif (pieceCanMove or canPieceMove(tx, ty-1, testRotation))
		and lockDelayRotationsRemaining > 0 then
			lockDelayRotationsRemaining -= 1
			lockDelay = 15
			finishRotation(tx, ty, testRotation)
			if not pieceCanMove then piece.y -= 1 end
			break
		end
	end

	updateGhost()
	spinSound:play()
end

local function resetLockDelay()
	lockDelayRotationsRemaining = maxLockDelayRotations
	lockDelay = 15
end

local function move(direction)
	local testX = piece.x + direction

	if canPieceMove(testX, piece.y, piece.rotation) then
		piece.x = testX
		resetLockDelay()
		refreshNeeded = true
		moveSound:play()
		lastAction = "movement"
	end

	updateGhost()
end

local function holdDirection(dir)
	if holdDir == 0 or holdDir > 5 then move(dir) end
	holdDir += 1
end

local function loopThroughBlocks(func)
	for y=1, pieceYCount do
		for x=1, pieceXCount do
			func(pieceStructures[piece.type][piece.rotation+1][y][x], x, y)
		end
	end
end

local function addPieceToInertGrid()
	loopThroughBlocks(function(block, x, y)
		if block ~= ' ' then inert[piece.y + y][piece.x + x] = block end
	end)
end

local function lose()
	timer = 0
	resetLockDelay()
	lost = true
	if them == "chill" then
		UITimer = time.new(500, 12, -4, easings.outCubic)
	else
		UITimer = time.new(500, 8, -4, easings.outCubic)
	end
	playdate.inputHandlers.pop()
end

local function lock()
	local tspin = false
	if piece.type == TPIECE and lastAction == "rotation" then
		local tpiece = pieceStructures[TPIECE][piece.rotation+1]
		local squaresCount = 0
		for i=1, 4 do
			local tst = tspindata[i] -- t-spin test
			local b
			xpcall(function()
				b=inert[piece.y+(2+tst[2])][piece.x+(2+tst[1])]
				squaresCount = ((b == nil or b == '*') and squaresCount + 1 or squaresCount)
			end, function()
				-- assume it was because the piece got out of bounds and increase square count
				squaresCount += 1
			end)
		end
		--print(squaresCount)
		if squaresCount >= 3 then
			-- it's a tspin! but which one? right now it doesn't matter.
			print("T-Spin!")
			tspin = true
		end
	end

	addPieceToInertGrid()

	-- Find complete rows
	local completedLine = false
	local clearedLines = 0
	for y = 1, gridYCount do

		local complete = true
		for x = 1, gridXCount do
			if inert[y][x] == ' ' then
				complete = false
				break
			end
		end

		if complete then
			completedLine = true

			completedLines += 1
			if completedLines ~= 0 and completedLines%10 == 0 and not levelIncreased then
				levelIncreased = true
				level += 1
			elseif completedLines%10 ~= 0 then levelIncreased = false end

			table.insert(clearLines, ClearLine(y-1))
			for removeY = y, 2, -1 do
				for removeX = 1, gridXCount do
					inert[removeY][removeX] =
					inert[removeY - 1][removeX]
				end
			end

			for removeX = 1, gridXCount do inert[1][removeX] = " " end

			scoreGoal += 10 * combo

			--synth:setWaveform(sound.kWaveSquare)
			--synth:setADSR(0, 0, 0.5, 0.05)
			--synth:playNote("C5", 0.5, 0.001)
			stopAllComboSounds()
			comboSounds[math.min(combo, 4)]:play()
			combo += 1

			clearedLines += 1
		end
	end

	local allclear = true
	for y = 1, gridYCount do
		for x = 1, gridXCount do
			if inert[y][x] ~= " " then
				-- Exit both loops if found a block
				allclear = false
				break
			end
		end
		-- I said both
		if not allclear then break end
	end

	for i=0, 4 do
		local lineClearNames = {"SINGLE", "DOUBLE", "TRIPLE", "PLAYTRIS"}
		if clearedLines == i then
			scoreGoal += (10+(tspin and 20 or 0))*i * combo
			if tspin or clearedLines >= 4 then
				if clearedLines == 0 then
					spawnSash("T-SPIN!")
				else
					stopAllComboSounds()
					specialSound:play()
					spawnSash((tspin and "T-SPIN " or "")..lineClearNames[clearedLines])
				end
			end
		end
	end

	--[[
	if clearedLines == 0 then
		-- Same points as a single.
		stopAllComboSounds()
		scoreGoal += 10 * combo
		spawnSash("T-Spin Single!")
	elseif clearedLines == 1 then
		stopAllComboSounds()
		scoreGoal += 20 * combo
		spawnSash("T-Spin")
	elseif clearedLines >= 4 then
		stopAllComboSounds()
		specialSound:play()
		spawnSash((tspin and "T-Spin " or "").."Playtris!")
		scoreGoal += (15 + (tspin and 10 or 0)) * combo
	end
	]]

	if allclear then
		scoreGoal += 25 * combo
		spawnSash("ALL CLEAR!")
	end

	if not completedLine then
		dropSound:play()
		combo = 1
	end

	newPiece(table.remove(sequence))
	hasHeldPiece = false

	if not canPieceMove(piece.x, piece.y, piece.rotation) then lose() end
end -- lock function

local inputHandlers = {
	upButtonDown = function()
		if not lost and not menuOpen then
			local dist = 0
			while canPieceMove(piece.x, piece.y + 1, piece.rotation) do
				piece.y += 1
				dist += 1
			end
			if dist ~= 0 then lastAction = "movement" end
			dropSound:play()
			--timer = timerLimit
			lockDelay = 0
			lock()
			forceInertGridRefresh = true
			if shake and theme ~= "retro" then displayYPos = dist*1.25 end
		end
	end,
	-- Skip the O piece when rotating.
	AButtonDown = function()
		if not lost then
			if piece.type ~= OPIECE then rotate(inverseRotation and -1 or 1)
			else spinSound:play() end -- give the illusion that the o piece is rotating
		end
	end,
	BButtonDown = function()
		if not lost then
			if piece.type ~= OPIECE then rotate(inverseRotation and 1 or -1)
			else spinSound:play() end -- read above
		end
	end
}

local function reset()
	levelIncreased = false
	displayYPos = 0
	completedLines = 0
	combo, level = 1, 1
	lostY = 1
	lost = false
	clearLines, lines, sashes = {}, {}, {}
	holdDir = 0
	heldPiece = nil
	pieceHasChanged = false

	local function timerCallback(timer)
		screenClearNeeded = true
	end

	if theme == "chill" then
		UITimer = time.new(500, -4, 12, easings.outCubic)
	else
		UITimer = time.new(500, -4, 8, easings.outCubic)		
	end
	UITimer.updateCallback = timerCallback
	UITimer.timerEndedCallback = timerCallback
	inert = {}
	for y = 1, gridYCount do
		inert[y] = {}
		for x = 1, gridXCount do
			inert[y][x] = ' '
		end
	end

	playdate.inputHandlers.push(inputHandlers)

	newSequence()
	newPiece(table.remove(sequence))

	timer = 0
	score = 0
	scoreGoal = score
	resetLockDelay()
end

local function drawBlock(block, x, y, size)
	local rect = geom.rect.new(
		(x-1)*size,
		(y-1)*size,
		size-1,
		size-1
	)

	if block ~= " " then
		gfx.fillRect(rect)
	end
end

local function drawTexturedBlock(image, x, y, size)
	image:draw((x-1)*size, (y-1)*size)
end

reset()

local function updateGame()
	if not lost then
		local crankTicks = playdate.getCrankTicks(4)
		if crankTicks ~= 0 then rotate(crankTicks) end

		if scoreGoal ~= score then
			score += (scoreGoal - score) * .25
			if scoreGoal - score < 1 then score = scoreGoal end
		end

		if scoreGoal > highscore then
			saveData("highscore", scoreGoal)
			highscore = scoreGoal
		end

		timerLimit = 30
		if btn("down") and not pieceHasChanged then
			timerLimit = 0
			lastAction = "movement"
		elseif not btn("down") then
			pieceHasChanged = false
		end

		if btn("right") then holdDirection(1)
		elseif btn("left") then holdDirection(-1)
		else holdDir = 0 end

		if (btn("a") and btn("b")) and theme ~= "retro" and not hasHeldPiece then
			local nextType
			if not heldPiece then
				heldPiece = piece.type
				nextType = table.remove(sequence)
			else
				local temp = heldPiece
				heldPiece = piece.type
				nextType = temp
			end
			newPiece(nextType)
			hasHeldPiece = true
			holdSound:play()
		end

		timer += level
		lockDelay -= 1
		if timer >= timerLimit then
			refreshNeeded = true
			
			local testY = piece.y + 1

			local pieceCanMove = canPieceMove(piece.x, testY, piece.rotation)
			if pieceCanMove
			and lockDelayRotationsRemaining == maxLockDelayRotations then
				piece.y = testY
				resetLockDelay()
				lastAction = "movement"
			else
				if lockDelay > 0 then
					if pieceCanMove then
						piece.y = testY
					end
					return
				end
				
				resetLockDelay()
				
				lock()
			end -- complete a row
			
			timer = 0
		end -- timer is over timerLimit
	else
		refreshNeeded = true
		if not e then
			inert[lostY] = {}
			for i=1, gridXCount do inert[lostY][i] = ' ' end
			table.insert(lines, EndLine((lostY-1)+offsetY))

			if lostY < gridYCount then lostY += 1
			else e = true end
		else
			if #lines == 0 then
				e = false
				commitSaveData()
				reset()
			end
		end
	end -- state machine
end

local function drawScores()
	if theme == "chill" then
		gfx.drawText("SCORE", 265,190)
		gfx.drawText(math.floor(score), 265, 203)
	elseif theme == "retro" then
		gfx.drawText("SCORE", 298, 8)
		gfx.drawText(math.floor(score), 298, 48)		
	else
		gfx.drawTextAligned("*Score*", (UITimer.value-2)*uiBlockSize, 9*uiBlockSize, kTextAlignment.center)
		gfx.drawTextAligned("*"..math.floor(score).."*", (UITimer.value-2)*uiBlockSize, 11*uiBlockSize, kTextAlignment.center)
		gfx.drawTextAligned("*Highscore*", (UITimer.value-2)*uiBlockSize, 13*uiBlockSize, kTextAlignment.center)
		gfx.drawTextAligned("*"..highscore.."*", (UITimer.value-2)*uiBlockSize, 15*uiBlockSize, kTextAlignment.center)
	end

end

local function drawLevelInfo()
	if theme == "chill" then
		gfx.drawText("LEVEL", 60,190)
		if level < 10 then
			gfx.drawText(level, 120, 203)
		else
			gfx.drawText(level, 120 - text_width, 203)
		end

	elseif theme == "retro" then
		gfx.drawText("LEVEL", 300, 80)
		gfx.drawText(level, 316, 96)
		gfx.drawText("LINES", 300, 128)
		gfx.drawText(completedLines, 316, 144)
	else
		gfx.drawTextAligned("*Level*", dwidth-(UITimer.value-2)*uiBlockSize, 9*uiBlockSize,kTextAlignment.center)
		gfx.drawTextAligned("*"..level.."*", dwidth-(UITimer.value-2)*uiBlockSize, 11*uiBlockSize,kTextAlignment.center)
		gfx.drawTextAligned("*Lines*", dwidth-(UITimer.value-2)*uiBlockSize, 13*uiBlockSize, kTextAlignment.center)
		gfx.drawTextAligned("*"..completedLines.."*", dwidth-(UITimer.value-2)*uiBlockSize, 15*uiBlockSize, kTextAlignment.center)
	end
end

local function drawHeldPiece() -- draw held piece
	if theme == "chill" then
		gfx.drawText("HOLD", (UITimer.value-5)*uiBlockSize, 2*uiBlockSize-1)

	elseif theme == "retro" then
		-- do nothing
			
	else
		holdFrameImage:drawCentered((UITimer.value-2)*uiBlockSize, 5*uiBlockSize-1)
	end
	
	if heldPiece and theme ~= "retro" then
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
	if theme == "chill" then
		gfx.drawText("NEXT", dwidth-(UITimer.value)*uiBlockSize, 2*uiBlockSize-1)

	elseif theme == "retro" then
		-- do nothing
			
	else
		nextFrameImage:drawCentered(dwidth-(UITimer.value-2)*uiBlockSize, 5*uiBlockSize-1)
	end
	loopThroughBlocks(function(_, x, y)
		local nextPiece = sequence[#sequence]
		local block = pieceStructures[nextPiece][1][y][x]
		if block ~= ' ' then
			local acp = nextPiece ~= 1 and nextPiece ~= 2
			if theme == "retro" then
				--drawBlock('*', x+(dwidth/uiBlockSize)-(UITimer.value-(acp and 0.625 or 0.125)), y+(acp and 17 or (nextPiece == 1 and 16.5 or 16)),uiBlockSize)
				drawBlock('*', x+(dwidth/uiBlockSize)-(acp and 7.5 or 7), y+(acp and 17 or (nextPiece == 1 and 16.5 or 16)),uiBlockSize)
			else
				drawBlock('*', x+(dwidth/uiBlockSize)-(UITimer.value-(acp and 0.625 or 0.125)), y+(acp and 4 or (nextPiece == 1 and 3.5 or 3)),uiBlockSize)
			end
		end
	end)
end

local function color() gfx.setColor(darkMode and gfx.kColorBlack or gfx.kColorWhite) end
		local function opcolor()  gfx.setColor(darkMode and gfx.kColorWhite or gfx.kColorBlack) end

local function drawGame()
	if refreshNeeded or screenClearNeeded then
		refreshNeeded = false
		local screenWasCleared = false
		gfx.pushContext()

		if darkMode then
			gfx.setColor(gfx.kColorWhite)
			gfx.setImageDrawMode("fillWhite")
		else
			gfx.setColor(gfx.kColorBlack)
			gfx.setImageDrawMode("copy")
		end

		-- Only clear the screen when we absolutely need to
		if screenClearNeeded then
			gfx.clear(darkMode and gfx.kColorBlack or gfx.kColorWhite)
			screenClearNeeded = false
			screenWasCleared = true
		end
		
		-- draw beautiful background scene from rainblocks
		scene:draw()
		
		-- draw on-screen effects
		local function updateEffect(t,i,e)
			if e.dead then
				pcall(function() table.remove(t, i) end)
			else
				e:update()
				e:draw()
				screenClearNeeded = true
			end
		end
		
		if #sashes > 0 then	updateEffect(sashes, #sashes, sashes[#sashes]) end
		
		-- Update screen shake
		if displayYPos ~= 0 then
			refreshNeeded = true
			displayYPos+=((0-displayYPos)*0.25)
			
			-- Just clean up the area below the grid instead of a full screen clear
			color()
			gfx.fillRect(
				offsetX*blockSize,    dheight-offsetY*blockSize,
				gridXCount*blockSize, offsetY*blockSize
			)

			gfx.setDrawOffset(0,displayYPos)

			-- Round to zero so we don't keep refreshing forever
			if displayYPos < 0.25 then
				displayYPos = 0
			end
		end

		color()
		gfx.fillRect(
			offsetX*blockSize,    offsetY*blockSize,
			gridXCount*blockSize, gridYCount*blockSize
		)

		for i,l in ipairs(lines) do updateEffect(lines,i,l) end

		if not grid then
			opcolor()
			gfx.drawRect(
				offsetX*blockSize,    offsetY*blockSize,
				gridXCount*blockSize, gridYCount*blockSize
			)
		else
			if bigBlocks then
				gridImageBig:draw(offsetX * blockSize, offsetY * blockSize)
			else
				gridImage:draw(offsetX * blockSize, offsetY * blockSize)
			end
		end

		for i, l in ipairs(clearLines) do updateEffect(clearLines,i,l) end

		-- draw inert grid
		if pieceHasChanged or forceInertGridRefresh then
			forceInertGridRefresh = false
			if bigBlocks then
				inertGridImageBig:clear(gfx.kColorClear)
				gfx.pushContext(inertGridImageBig)
			else
				inertGridImage:clear(gfx.kColorClear)
				gfx.pushContext(inertGridImage)
			end
			
			opcolor()
			for y = 1, gridYCount do
				for x = 1, gridXCount do
					drawBlock(inert[y][x], x, y, blockSize)
				end
			end
			gfx.popContext()
		end

		if bigBlocks then
			inertGridImageBig:draw(offsetX * blockSize, offsetY * blockSize)
		else
			inertGridImage:draw(offsetX * blockSize, offsetY * blockSize)
		end

		opcolor()
		loopThroughBlocks(function(_, x, y)
			if not lost then
				local block = pieceStructures[piece.type][piece.rotation+1][y][x]
				if block ~= ' ' then
					drawBlock(block, x + piece.x + offsetX, y + piece.y + offsetY,blockSize)
					if ghost then
						local _, millis = playdate.getSecondsSinceEpoch()
						local selectedImagetable = (bigBlocks and ghostBlockImagetableBig or ghostBlockImagetable)
						drawTexturedBlock(
							selectedImagetable:getImage(1+math.floor(millis/100%#selectedImagetable)),
							x + piece.x + offsetX, y + ghostPieceY + offsetY,
							blockSize
						)
					end
				end
			end
		end)

		if piece.type == IPIECE and false then
			gfx.setColor(gfx.kColorXOR)
			local rect = geom.rect.new(
				(piece.x+1.5+offsetX)*blockSize,
				(piece.y+1.5+offsetY)*blockSize,
				blockSize-1,
				blockSize-1
			)
			gfx.fillEllipseInRect(rect)
			opcolor()
		end

		gfx.setDrawOffset(0,0)

		--DREW: COMMENTING OUT IF-STATEMENT SO THAT HELD AND NEXT PIECES ARE DRAWN EVERY DRAW CYCLE
		--if pieceHasChanged or screenWasCleared then
			drawHeldPiece()
			drawNextPiece()
			drawScores()
			drawLevelInfo()
		--end
		gfx.fillRect(0, 0, 400, introRectT.value)

		gfx.popContext()
		
	end
	
	time.updateTimers()
end

function generateGridImage(image, gridBlockSize)
	gfx.pushContext(image)
	image:clear(gfx.kColorClear)
	opcolor()
	for y = 1, gridYCount do
		for x = 1, gridXCount do
			local rect = geom.rect.new(
				(x-1)*gridBlockSize,
				(y-1)*gridBlockSize,
				gridBlockSize-1,
				gridBlockSize-1
			)
			gfx.drawRect(rect)
		end
	end

	gfx.popContext()
end

generateGridImage(gridImage, defaultBlockSize)
generateGridImage(gridImageBig, bigBlockSize)

local _update, _draw = updateGame, drawGame

---------------
-- Game menu --
---------------

-- I basically just reinvented playdate.ui.gridview

local patternTimer

local patterns = {
	{0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0, 0, 0, 0, 0}, -- white
	{0xFF, 0xDD, 0xFF, 0x77, 0xFF, 0xDD, 0xFF, 0x77, 0, 34, 0, 136, 0, 34, 0, 136}, -- lightgray 1
	{0x77, 0x77, 0xDD, 0xDD, 0x77, 0x77, 0xDD, 0xDD, 136, 136, 34, 34, 136, 136, 34, 34}, -- lightgray 2
	{0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 170, 85, 170, 85, 170, 85, 170, 85}, -- gray
}

local menuOpen = false
local bold = gfx.getSystemFont("bold")
local menuYTimer, menuWidth

local function closeMenu()
	menuOpen = false

	-- Sorry, I love back easing XD
	menuYTimer = time.new(250, dheight/2, dheight, easings.inBack)
	patternTimer = time.new(250, #patterns, 1,easings.inBack)
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
	{
		name = "Sash",
		type = "crossmark",
		state = sash,
		ontoggle = function(val)
			sash = val
			saveData("sash", sash)
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
			computeGridOffset()
			
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
			updateSoundVolume(sfx)
			updateSoundVolume(comboSounds)
		end,
	},
}

local menuHeight = #menu*bold:getHeight()

function updateMenu()
	if menuYTimer.value == dheight/2 then
		if btnp("down") then
			menuScrollSound:play()
			menuCursor += 1
		elseif btnp("up") then
			menuScrollSound:play()
			menuCursor -= 1
		end
		menuCursor %= #menu
		
		local menuItem = menu[menuCursor+1]
		if btnp("a") then
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
		
		if btnp("b") then
			menuClickSound:play()
			closeMenu()
		end

		if menuItem.type == "slider" then
			if btn("right") then
				menuItem.value = math.max(menuItem.min, math.min(menuItem.value + menuItem.max / 50, menuItem.max))
				menuItem.onchange(menuItem.value)
				commitSaveData()
			elseif btn("left") then
				menuItem.value = math.max(menuItem.min, math.min(menuItem.value - menuItem.max / 50, menuItem.max))
				menuItem.onchange(menuItem.value)
				commitSaveData()
			end
		end
	end

	if math.abs(dheight-menuYTimer.value) < 0.5 then
		screenClearNeeded = true
		forceInertGridRefresh = true
		playdate.inputHandlers.push(inputHandlers)
		_update = updateGame
		_draw = drawGame
	end
	time.updateTimers()
end

function drawMenu()
  gfx.clear(darkMode and gfx.kColorBlack or gfx.kColorWhite)
  gfx.pushContext()
  backgroundImage:draw(0, 0)
  gfx.setPattern(patterns[math.floor(patternTimer.value)])
  gfx.fillRect(0, 0, dwidth, dheight)
  gfx.setPattern(patterns[1])

  local rect = geom.rect.new(
  	dwidth/2-(menuWidth/2+10),
  	menuYTimer.value-(menuHeight/2+10),
  	menuWidth+20, menuHeight+20
  )
  local rad = 5
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(rect, rad)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(rect, rad)

	local bheight = bold:getHeight()
	for i, v in ipairs(menu) do
		if v.type == "crossmark" then
			gfx.drawText("*"..v.name.."*", dwidth/2-menuWidth/2 + 20, menuYTimer.value-menuHeight/2+((i-1)*bheight)+1)
			-- _ is a throwaway variable. Just using it to get cheight.
			local _, cheight = crossmarkFieldImage:getSize()
			local pos = geom.point.new(
				(dwidth/2-menuWidth/2)+8,--bold:getTextWidth(v.name)/2+5,
				menuYTimer.value-menuHeight/2+((i-1)*bheight)+cheight/2
			)
			crossmarkFieldImage:drawCentered(pos:unpack())
			if v.state then crossmarkImage:drawCentered(pos:unpack()) end
		elseif v.type == "slider" then
			gfx.drawText("*"..v.name.."*", dwidth/2-bold:getTextWidth(v.name)/2, menuYTimer.value-menuHeight/2+((i-1)*bheight))
			gfx.setColor(gfx.kColorXOR)
			gfx.fillRect(
				dwidth/2-menuWidth/2,
				menuYTimer.value-menuHeight/2+((i-1)*bheight)-1,
				v.value*menuWidth,
				bold:getHeight()
			)
			gfx.setColor(gfx.kColorBlack)
		else
			gfx.drawText("*"..v.name.."*", dwidth/2-menuWidth/2, menuYTimer.value-menuHeight/2+((i-1)*bheight)+1)
		end
	end

	local menuItem = menu[menuCursor+1]
	local x = dwidth/2-menuWidth/2
	local w = bold:getTextWidth(menu[menuCursor+1].name)
	if menuItem.type == "crossmark" then x += 20
	elseif menuItem.type == "slider" then w = menuWidth end
	gfx.drawRect(
		x, ((menuYTimer.value-menuHeight/2)+menuCursor*bheight)-2.5, w, bheight, 2
	)
	gfx.popContext()
end

----------------------------
-- Playdate-related stuff --
----------------------------

local sysmenu = playdate.getSystemMenu()
sysmenu:addMenuItem("options", function()
	if not lost then
		menuOpen = not menuOpen
		if not menuOpen then closeMenu()
		else
			menuYTimer = time.new(250, 0, dheight/2, easings.outBack)
			menuHeight = #menu*bold:getHeight()
			local longestString = ""
			for k, v in pairs(menu) do
				if #v.name > #longestString then
					longestString = v.name
				end
			end

			-- playdate.graphics.image:getSize() returns two values. By using it like this,
			-- I am taking the first value and discarding the rest,
			-- the first value being the width, which is what i need.
			menuWidth = bold:getTextWidth(longestString) + crossmarkFieldImage:getSize()
			menuCursor = 1

			backgroundImage = gfx.image.new(dwidth, dheight)
			gfx.pushContext(backgroundImage)
			drawGame()
			gfx.popContext()

			playdate.inputHandlers.pop()
			patternTimer = time.new(250, 1, #patterns, easings.outBack)
		end
		_update = updateMenu
		_draw = drawMenu
	end
end)

sysmenu:addMenuItem("restart", function()
	if not lost and UITimer.timeLeft == 0 then
		addPieceToInertGrid()
		lose()
		commitSaveData()
	end
end)

sysmenu:addOptionsMenuItem("theme", themes, theme, function(selectedTheme)
	currentSong:stop()
	scene = Scene.init(selectedTheme)
	screenClearNeeded = true
	currentSong:play(0)
	theme = selectedTheme
end)


function updateMusicVolume()
	for i,v in pairs(songs) do
		if v:getVolume() ~= musicVolume then
			v:setVolume(musicVolume)
		end
	end
end

function updateSoundVolume(soundTable)
	for i,v in ipairs(soundTable) do
		if v:getVolume() ~= soundsVolume then
			v:setVolume(soundsVolume)
		end
	end
end

updateMusicVolume()
updateSoundVolume(sfx)
updateSoundVolume(comboSounds)
currentSong:play()

function playdate.update()
	--Once intro is over move to main bgm loop
	--[[
	if not bgmIntro:isPlaying() and not currentSong:isPlaying() then
		currentSong = songs["playtris"]
		currentSong:play(0)
	end
	]]
	_update()
	_draw()
end

function playdate.gameWillPause()
	
	local img = gfx.image.new(dwidth, dheight, gfx.kColorWhite)
	local number_x = 115
	local text_x = 30
	
	gfx.lockFocus(img)
	
	menu_background:drawIgnoringOffset(0, 0)

	gfx.drawText("LEVEL", text_x, 40)
	gfx.drawText(level, number_x, 40)
	gfx.drawText("LINES", text_x, 65)
	gfx.drawText(completedLines, number_x, 65)

	gfx.drawText("SCORE", text_x, 150)
	gfx.drawText(math.floor(score), number_x, 150)
	gfx.drawText("HI SCORE", text_x+32, 195)
	gfx.drawText(highscore, number_x, 210)

	gfx.unlockFocus()

	img:setInverted(darkMode)

	playdate.setMenuImage(img)

end

function playdate.gameWillTerminate() commitSaveData() end

function playdate.deviceWillSleep() commitSaveData() end

-----------
-- Debug --
-----------

function playdate.keyPressed(key)
	if key == "L" then
		forceInertGridRefresh = true
		for i=1, 4 do table.remove(inert) end
		for i=1, 4 do
			table.insert(inert, (function()
				local almostFull = {}
				for i=1, gridXCount - 1 do
					table.insert(almostFull, '*')
				end
				table.insert(almostFull, ' ')
				return almostFull
			end)())
		end
	elseif key == "T" then
		forceInertGridRefresh = true
		-- Generate a TSpin scenario
		for i=1, 5 do table.remove(inert) end
		table.insert(inert, {"*", "*", "*", " ", " ", " ", " ", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", "*", " ", " ", "*", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", "*", " ", " ", "*", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", "*", " ", " ", "*", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", " ", " ", " ", "*", "*", "*", "*"})
	elseif key == "D" then
		forceInertGridRefresh = true
		for i=1, 3 do table.remove(inert) end
		table.insert(inert, {"*", "*", "*", "*", " ", " ", "*", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", " ", " ", " ", "*", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", "*", " ", "*", "*", "*", "*", "*"})
	end
end
