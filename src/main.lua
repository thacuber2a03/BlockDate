-- MIT License

-- Copyright (c) 2022-2023 @thacuber2a03

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

import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/crank"

import "globals"
import "utils"

import "constants"
import "pieces"
import "menu"
import "images"
import "sounds"

import "effects/endline"
import "effects/clearline"
import "effects/sash"

import "themeManager"

------------
-- Themes --
------------

local themes = generate_theme_list("themes/")
local theme = loadData("theme") or "default" -- load last used theme from saved game data

-- set up scene for selected theme
local success, scene = pcall(load_theme, theme)
if not success then
	print("ERROR: Could not load theme ", theme)
	print("Check that there is a valid scene file under /themes/" .. theme .. "/" .. theme .. ".lua")
	print("Loading default theme...")
	theme = "default"
	error, scene = pcall(load_theme, theme)
	if error then
		print("ERROR: Could not load default theme!")
	end
end

------------------------------------------
-- Game related functions and variables --
------------------------------------------

local e = false -- NOTE(thacuber2a03): this variable is for the end anim
local ghostPieceY
local sequence

local introRectT = TIME.new(100, 400, 0, EASINGS.outCubic)
introRectT.updateCallback = function()
	---@diagnostic disable-next-line: lowercase-global
	screenClearNeeded = true
end

local displayYPos = 0

local completedLines = 0
local combo, level = 0, 0
local levelIncreased = false

local lostY = 1
lost = false

local clearLines, lines, effects = {}, {}, {}

local holdDir = 0
local heldPiece
---@diagnostic disable-next-line: need-check-nil
local heldPiece_x = scene.heldPiece_x or 8
local hasHeldPiece = false
local heldBothButtons = false

local pieceHasChanged = false

UITimer = nil
local inert = {}

local timer = 0
local timerLimit = 30
local lockDelayRotationsRemaining = maxLockDelayRotations
local lockDelay = 15
local score = 0
local scoreGoal = score

refreshNeeded = true
screenClearNeeded = false
forceInertGridRefresh = false

local lastAction = "none"

local function visualEffect(message)
	if sash then
		if scene and scene.visualEffect then
			table.insert(effects, scene.visualEffect(message))
		else
			table.insert(effects, Sash(message))
		end
	end
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

local function updateGhost()
	ghostPieceY = piece.y
	while canPieceMove(piece.x, ghostPieceY + 1, piece.rotation) do
		ghostPieceY = ghostPieceY + 1
	end
end

local function newPiece(type)
	---@diagnostic disable-next-line lowercase-global
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

local function rotate(rotation)
	local testRotation = piece.rotation + rotation
	testRotation = testRotation % #pieceStructures[piece.type]

	-- TODO(thacuber2a03): temporary solve until I can figure out how to compact it
	-- TODO(thacuber2a03): still don't know how to compact it, might have to refactor piece.rotation
	local chosenRotation
	if rotation == 1 then
		if piece.rotation == 0 then chosenRotation = 1 end
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

	local chosenWallKickTests = WALL_KICK_DATA[(piece.type~=1 and 1 or 2)][chosenRotation][(rotation==1 and "cw" or "ccw")]
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
			lockDelayRotationsRemaining = lockDelayRotationsRemaining - 1
			lockDelay = 15
			finishRotation(tx, ty, testRotation)
			if not pieceCanMove then piece.y = piece.y - 1 end
			break
		end
	end

	updateGhost()
	spinSound:play()
end

local function handleCrankRotation()
	local ticksPerRevolution = 4
	local tick = PD.getCrankTicks(ticksPerRevolution)

	if tick == 0 then
		return
	end

	if piece.type == OPIECE then
		return
	end

	if inverseRotation then
		tick *= -1
	end

	rotate(tick)
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
	holdDir = holdDir + 1
end

local function addPieceToInertGrid()
	loopThroughPieceBlocks(function(block, x, y)
		if block ~= ' ' then inert[piece.y + y][piece.x + x] = block end
	end)
end

local function lose()
	timer = 0
	resetLockDelay()
	lost = true
	UITimer = TIME.new(500, heldPiece_x, -4, EASINGS.outCubic)
	PD.inputHandlers.pop()
end

local function lock()
	local tspin = false
	if piece.type == TPIECE and lastAction == "rotation" then
		local squaresCount = 0
		for i=1, 4 do
			local tst = TSPIN_DATA[i] -- t-spin test
			local b
			xpcall(function()
				b=inert[piece.y+(2+tst[2])][piece.x+(2+tst[1])]
				squaresCount = ((b == nil or b == '*') and squaresCount + 1 or squaresCount)
			end, function()
				-- NOTE(thacuber2a03): assume it was because the piece got out of bounds and increase squaresCount
				squaresCount = squaresCount + 1
			end)
		end
		--print(squaresCount)
		if squaresCount >= 3 then
			-- ~~it's a tspin! but which one? right now it doesn't matter.~~
			-- TODO(thacuber2a03): I better make it matter soon
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

			completedLines = completedLines + 1
			if completedLines ~= 0 and completedLines%10 == 0 and not levelIncreased then
				levelIncreased = true
				level = level + 1
			elseif completedLines%10 ~= 0 then levelIncreased = false end

			table.insert(clearLines, ClearLine(y-1))
			for removeY = y, 2, -1 do
				for removeX = 1, gridXCount do
					inert[removeY][removeX] =
					inert[removeY - 1][removeX]
				end
			end

			for removeX = 1, gridXCount do inert[1][removeX] = " " end

			scoreGoal = scoreGoal + 10 * combo

			stopAllComboSounds()
			comboSounds[math.min(combo, 4)]:play()
			combo = combo + 1

			clearedLines = clearedLines + 1
		end
	end

	local allclear = true
	for y = 1, gridYCount do
		for x = 1, gridXCount do
			if inert[y][x] ~= " " then
				allclear = false
				goto noallclear
			end
		end
	end
	::noallclear::

	local lineClearNames = {"Single", "Double", "Triple", "Playtris"}
	for i=0, 4 do
		if clearedLines == i then
			scoreGoal = scoreGoal + ((10+(tspin and 20 or 0))*i * combo)
			if tspin or clearedLines >= 4 then
				if clearedLines == 0 then
					visualEffect("T-SPIN!")
				else
					stopAllComboSounds()
					specialSound:play()
					visualEffect((tspin and "T-SPIN " or "")..lineClearNames[clearedLines])
				end
			end
		end
	end


	if allclear then
		scoreGoal = scoreGoal + 25 * combo
		visualEffect("ALL CLEAR!")
	end

	if not completedLine then
		dropSound:play()
		combo = 1
	end

	newPiece(table.remove(sequence))
	hasHeldPiece = false

	if not canPieceMove(piece.x, piece.y, piece.rotation) then lose() end
end -- lock function

inputHandlers = {
	upButtonDown = function()
		if not lost then
			local dist = 0
			while canPieceMove(piece.x, piece.y + 1, piece.rotation) do
				piece.y = piece.y + 1
				dist = dist + 1
			end
			if dist ~= 0 then lastAction = "movement" end
			dropSound:play()
			lockDelay = 0
			lock()
			forceInertGridRefresh = true
			if shake and theme ~= "retro" then displayYPos = dist*1.25 end
		end
	end,
	AButtonDown = function()
		if PD.buttonIsPressed "b" then return end
		if not lost then
			if piece.type ~= OPIECE then rotate(inverseRotation and -1 or 1)
			else spinSound:play() end -- give the illusion that the o piece is rotating
		end
	end,
	BButtonDown = function()
		if PD.buttonIsPressed "a" then return end
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
	clearLines, lines, effects = {}, {}, {}
	holdDir = 0
	heldPiece = nil
	pieceHasChanged = false

	local function timerCallback() screenClearNeeded = true end

	UITimer = TIME.new(500, -4, heldPiece_x, EASINGS.outCubic)
	UITimer.updateCallback = timerCallback
	UITimer.timerEndedCallback = timerCallback
	inert = {}
	for y = 1, gridYCount do
		inert[y] = {}
		for x = 1, gridXCount do
			inert[y][x] = ' '
		end
	end

	PD.inputHandlers.push(inputHandlers)

	newSequence()
	newPiece(table.remove(sequence))

	timer = 0
	score = 0
	scoreGoal = score
	resetLockDelay()
end

function drawBlock(block, x, y, size)
	if block ~= " " then
		GFX.fillRect(GEOM.rect.new(
			(x-1)*size,
			(y-1)*size,
			size-1,
			size-1
		))
	end
end

function drawTexturedBlock(image, x, y, size)
	image:draw((x-1)*size, (y-1)*size)
end

reset()

function updateGame()
	if not lost then
		if scoreGoal ~= score then
			score = score + (scoreGoal - score) * .25
			if scoreGoal - score < 1 then score = scoreGoal end
		end

		if scoreGoal > highscore then
			saveData("highscore", scoreGoal)
			highscore = scoreGoal
		end

		timerLimit = 30
		if PD.buttonIsPressed("down") and not pieceHasChanged then
			timerLimit = 0
			lastAction = "movement"
		elseif not PD.buttonIsPressed("down") then
			pieceHasChanged = false
		end

		if PD.buttonIsPressed("right") then holdDirection(1)
		elseif PD.buttonIsPressed("left") then holdDirection(-1)
		else holdDir = 0 end

		handleCrankRotation()

		local current, _, released = PD.getButtonState()
		if current == (PD.kButtonA | PD.kButtonB) and not heldBothButtons then
			if not hasHeldPiece then
				local nextType
				if not heldPiece then
					heldPiece = piece.type
					nextType = table.remove(sequence)
				else
					-- the mighty swap
					local temp = heldPiece
					heldPiece = piece.type
					nextType = temp
				end
				newPiece(nextType)
				hasHeldPiece = true
				holdSound:play()
			else
				holdFailSound:play()
			end
			heldBothButtons = true
		elseif (released & (PD.kButtonA | PD.kButtonB)) ~= 0 then
			-- if either or both buttons are released
			-- bitwise magic, I know
			heldBothButtons = false
		end

		if chill_mode then
			-- chill mode always drops pieces at minimum speed
			timer = timer + 1
		else
			-- otherwise drop speed increases with the level
			timer = timer + level
		end
		lockDelay = lockDelay - 1
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

			if lostY < gridYCount then lostY = lostY + 1
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


local function drawHeldPiece() -- draw held piece
	if heldPiece and theme ~= "retro" then
		loopThroughPieceBlocks(function(_, x, y)
			local block = pieceStructures[heldPiece][1][y][x]
			if block ~= ' ' then
				local acp = heldPiece ~= 1 and heldPiece ~= 2
				drawBlock('*', x+(UITimer.value-(acp and 3.5 or 3.9)), y+(acp and 4 or (heldPiece == 1 and 3.5 or 3)), uiBlockSize)
			end
		end)
	end
end

local function drawNextPiece() -- draw next piece
	loopThroughPieceBlocks(function(_, x, y)
		local nextPiece = sequence[#sequence]
		local block = pieceStructures[nextPiece][1][y][x]
		if block ~= ' ' then
			local acp = nextPiece ~= 1 and nextPiece ~= 2

			if theme == "retro" then
				drawBlock('*',
					x+(DWIDTH/uiBlockSize)-(UITimer.value-(acp and 0.625 or 0.125)),
					y+(acp and 17 or (nextPiece == 1 and 16.5 or 16)),
					uiBlockSize
				)
			else
				drawBlock('*',
					x+(DWIDTH/uiBlockSize)-(UITimer.value-(acp and 0.625 or 0.125)),
					y+(acp and 4 or (nextPiece == 1 and 3.5 or 3)),
					uiBlockSize
				)
			end
		end
	end)
end

local function color() GFX.setColor(darkMode and GFX.kColorBlack or GFX.kColorWhite) end
local function opcolor()  GFX.setColor(darkMode and GFX.kColorWhite or GFX.kColorBlack) end

function drawGame()
	if refreshNeeded or screenClearNeeded then
		refreshNeeded = false
		--local screenWasCleared = false
		GFX.pushContext()

		if darkMode then
			GFX.setColor(GFX.kColorWhite)
			GFX.setImageDrawMode("fillWhite")
		else
			GFX.setColor(GFX.kColorBlack)
			GFX.setImageDrawMode("copy")
		end

		-- Only clear the screen when we absolutely need to
		if screenClearNeeded then
			GFX.clear(darkMode and GFX.kColorBlack or GFX.kColorWhite)
			screenClearNeeded = false
			--screenWasCleared = true
		end

		-- draw theme-specific elements
		---@diagnostic disable-next-line: need-check-nil
		scene:draw()

		-- draw on-screen effects
		local function updateEffect(t,i,e) ---@diagnostic disable-line: redefined-local
			if e.dead then
				pcall(function() table.remove(t, i) end)
			else
				e:update()
				e:draw()
				screenClearNeeded = true
			end
		end

		if #effects > 0 then	updateEffect(effects, #effects, effects[#effects]) end

		-- Update screen shake
		if displayYPos ~= 0 then
			refreshNeeded = true
			displayYPos = displayYPos + ((0-displayYPos)*0.25)

			-- Just clean up the area below the grid instead of a full screen clear
			color()
			GFX.fillRect(
				offsetX*blockSize,    DHEIGHT-offsetY*blockSize,
				gridXCount*blockSize, offsetY*blockSize
			)

			GFX.setDrawOffset(0,displayYPos)

			-- Round to zero so we don't keep refreshing forever
			if displayYPos < 0.25 then
				displayYPos = 0
			end
		end

		color()
		GFX.fillRect(
			offsetX*blockSize,    offsetY*blockSize,
			gridXCount*blockSize, gridYCount*blockSize
		)

		for i,l in ipairs(lines) do updateEffect(lines,i,l) end

		if not grid then
			opcolor()
			GFX.drawRect(
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
				inertGridImageBig:clear(GFX.kColorClear)
				GFX.pushContext(inertGridImageBig)
			else
				inertGridImage:clear(GFX.kColorClear)
				GFX.pushContext(inertGridImage)
			end

			opcolor()
			for y = 1, gridYCount do
				for x = 1, gridXCount do
					drawBlock(inert[y][x], x, y, blockSize)
				end
			end
			GFX.popContext()
		end

		if bigBlocks then
			inertGridImageBig:draw(offsetX * blockSize, offsetY * blockSize)
		else
			inertGridImage:draw(offsetX * blockSize, offsetY * blockSize)
		end

		opcolor()
		loopThroughPieceBlocks(function(_, x, y)
			if not lost then
				local block = pieceStructures[piece.type][piece.rotation+1][y][x]
				if block ~= ' ' then
					drawBlock(block, x + piece.x + offsetX, y + piece.y + offsetY,blockSize)
					if ghost then
						local _, millis = PD.getSecondsSinceEpoch()
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

		--NOTE(thacuber2a03): if you want to deactivate an if statement, do it well
		--if piece.type == IPIECE and false then
		if false and piece.type == IPIECE then
			GFX.setColor(GFX.kColorXOR)
			local rect = GEOM.rect.new(
				(piece.x+1.5+offsetX)*blockSize,
				(piece.y+1.5+offsetY)*blockSize,
				blockSize-1,
				blockSize-1
			)
			GFX.fillEllipseInRect(rect)
			opcolor()
		end

		GFX.setDrawOffset(0,0)

		--DREW: COMMENTING OUT IF-STATEMENT SO THAT HELD AND NEXT PIECES ARE DRAWN EVERY DRAW CYCLE
		-- NOTE(thacuber2a03): whi
		--if pieceHasChanged or screenWasCleared then
			drawHeldPiece()
			drawNextPiece()
			---@diagnostic disable: need-check-nil
			scene.drawScores(score)
			scene.drawLevelInfo(level, completedLines)
			---@diagnostic enable: need-check-nil
		--end
		GFX.fillRect(0, 0, 400, introRectT.value)

		GFX.popContext()

	end

	TIME.updateTimers()
end

local function generateGridImage(image, gridBlockSize)
	GFX.pushContext(image)
	image:clear(GFX.kColorClear)
	opcolor()
	for y = 1, gridYCount do
		for x = 1, gridXCount do
			local rect = GEOM.rect.new(
				(x-1)*gridBlockSize,
				(y-1)*gridBlockSize,
				gridBlockSize-1,
				gridBlockSize-1
			)
			GFX.drawRect(rect)
		end
	end

	GFX.popContext()
end

generateGridImage(gridImage, defaultBlockSize)
generateGridImage(gridImageBig, bigBlockSize)

_update, _draw = updateGame, drawGame

----------------------------
-- Playdate-related stuff --
----------------------------

local sysmenu = PD.getSystemMenu()

sysmenu:addMenuItem("restart", function()
	if not lost and UITimer.timeLeft == 0 then
		addPieceToInertGrid()
		lose()
		commitSaveData()
	end
end)

sysmenu:addOptionsMenuItem("theme", themes, theme, function(selectedTheme)
	currentSong:stop()

	success, scene = pcall(load_theme, selectedTheme)
	if not success then
		print("ERROR: Could not load theme ", selectedTheme)
		print("Check that there is a valid scene file under /themes/" .. selectedTheme .. "/" .. selectedTheme .. ".lua")
		print("Loading default theme...")
		selectedTheme = "default"
		success, scene = pcall(load_theme, selectedTheme)
		if not success then
			print("ERROR: Could not load default theme")
		end
	else
		print(selectedTheme, "loaded successfully!")
	end

	currentSong:play(0)
	theme = selectedTheme
	--if theme == "chill" then visualEffect("CHILL MODE!") end

	---@diagnostic disable-next-line: need-check-nil
	heldPiece_x = scene.heldPiece_x or 8

	local function timerCallback(_) screenClearNeeded = true end
	UITimer = TIME.new(500, -4, heldPiece_x, EASINGS.outCubic)
	UITimer.updateCallback = timerCallback
	UITimer.timerEndedCallback = timerCallback

	updateMusicVolume()
	sfx = {	specialSound, holdSound, menuScrollSound, menuClickSound, dropSound, spinSound, moveSound }
	updateSoundVolume(sfx)
	updateSoundVolume(comboSounds)
	currentSong:setVolume(musicVolume)

	-- save theme 
	saveData("theme", theme)
end)

updateMusicVolume()
sfx = {	specialSound, holdSound, menuScrollSound, menuClickSound, dropSound, spinSound, moveSound }
updateSoundVolume(sfx)
updateSoundVolume(comboSounds)
currentSong:play(0)
currentSong:setVolume(musicVolume)

function PD.update()
	_update()
	_draw()
end

function PD.gameWillPause()
	local img = GFX.image.new(DWIDTH, DHEIGHT, GFX.kColorWhite)
	local number_x = 115
	local text_x = 30

	GFX.lockFocus(img)

	menuBackground:drawIgnoringOffset(0, 0)

	GFX.drawText("Level", text_x, 40)
	GFX.drawText(level, number_x, 40)
	GFX.drawText("Lines", text_x, 65)
	GFX.drawText(completedLines, number_x, 65)

	GFX.drawText("Score", text_x, 150)
	GFX.drawText(math.floor(score), number_x, 150)
	GFX.drawText("Hi Score", text_x+32, 195)
	GFX.drawText(highscore, number_x, 210)

	GFX.unlockFocus()

	img:setInverted(darkMode)

	PD.setMenuImage(img)

end

function PD.gameWillTerminate() commitSaveData() end

function PD.deviceWillSleep() commitSaveData() end

-----------
-- Debug --
-----------

function PD.keyPressed(key)
	if key == "l" then
		forceInertGridRefresh = true
		for _=1, 4 do table.remove(inert) end
		for _=1, 4 do
			table.insert(inert, (function()
				local almostFull = {}
				for _=1, gridXCount - 1 do
					table.insert(almostFull, '*')
				end
				table.insert(almostFull, ' ')
				return almostFull
			end)())
		end
	elseif key == "t" then
		forceInertGridRefresh = true
		-- generate a TSpin scenario
		for _=1, 5 do table.remove(inert) end
		table.insert(inert, {"*", "*", "*", " ", " ", " ", " ", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", "*", " ", " ", "*", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", "*", " ", " ", "*", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", "*", " ", " ", "*", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", " ", " ", " ", "*", "*", "*", "*"})
	elseif key == "d" then
		forceInertGridRefresh = true
		for _=1, 3 do table.remove(inert) end
		table.insert(inert, {"*", "*", "*", "*", " ", " ", "*", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", " ", " ", " ", "*", "*", "*", "*"})
		table.insert(inert, {"*", "*", "*", "*", " ", "*", "*", "*", "*", "*"})
	end
end
