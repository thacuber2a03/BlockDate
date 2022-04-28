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

-- Please note that this code is a disaster.

import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "pieces"
import "effects/endline"
import "effects/clearline"
import "effects/sash"

local gfx     <const> = playdate.graphics
local geom    <const> = playdate.geometry
local sound   <const> = playdate.sound
local time    <const> = playdate.timer
local data    <const> = playdate.datastore
local disp    <const> = playdate.display
local easings <const> = playdate.easingFunctions

-- If there's no game data available make some
savedData = data.read("gamedata") or {}

function loadData(key)
	return savedData[key]
end

function saveData(key, value)
	savedData[key] = value
end

function commitSaveData()
	-- pretty print cuz why not
	data.write(savedData, "gamedata", true)
end

introRectT = time.new(100, 400, 0, easings.outCubic)

function newPiece()
	piece = {
		x = 3,
		y = 0,
		rotation = 0,
		type = table.remove(sequence),
	}
	pieceHasChanged = true

	if #sequence == 0 then newSequence() end
end

function newSequence()
	sequence = {}
	for i = 1, #pieceStructures do
		table.insert(sequence, random(#sequence + 1), i)
	end
end

--[[
function getDeltaTime()
	local dt = 0

	if not lastTime then
		lastTime = playdate.getElapsedTime()
	else
		local curTime = playdate.getElapsedTime()
		dt = curTime - lastTime
		lastTime = curTime
	end

	return dt
end
--]]

function random(min, max, float)
	math.randomseed(playdate.getSecondsSinceEpoch())

	if not min then return math.random() end
	if not max then max = min min = 1 end

	if not float then return math.random(min, max)
	else return min + (max - min) * math.random() end
end

function canPieceMove(testX, testY, testRotation)
	for y=1, pieceYCount do
		for x=1, pieceXCount do
	  	local testBlockX = testX + x
	  	local testBlockY = testY + y
	    if pieceStructures[piece.type][testRotation+1][y][x] ~= ' ' and (
	    	testBlockX < 1
	    	or testBlockX > gridXCount or testBlockY > gridYCount
	    	or inert[testBlockY][testBlockX] ~= " "
	    ) then return false end
		end
	end
	return true
end

function drawBlock(block, x, y)
	local rect = geom.rect.new(
		(x-1)*blockSize,
		(y-1)*blockSize,
		blockSize - 1,
		blockSize - 1
	)
	
	gfx[(block == '*' and "fillRect" or "drawRect")](rect)
end

function addPieceToInertGrid()
	loopThroughBlocks(function(block, x, y)
		if block ~= ' ' then inert[piece.y + y][piece.x + x] = block end
	end)
end

function loopThroughBlocks(func)
	for y=1, pieceYCount do
		for x=1, pieceXCount do
			func(pieceStructures[piece.type][piece.rotation+1][y][x], x, y)
		end
	end
end

gridXCount, gridYCount = 10, 18

pieceXCount, pieceYCount = 4, 4

-- grid offset
offsetX, offsetY = 13, 2

blockSize = 11

highscore = loadData("highscore") or 0

shake, sash = true, true

playdate.getSystemMenu():addCheckmarkMenuItem("shake", true, function(val) shake = val end)
playdate.getSystemMenu():addCheckmarkMenuItem("sash", true, function(val) sash = val end)

--synth = sound.synth.new()

SOUNDSDIR = "assets/sounds/"
function loadSound(name)
	return assert(playdate.sound.sampleplayer.new(SOUNDSDIR..name))
end

comboSounds = {}
for i=1, 4 do
	table.insert(comboSounds, loadSound("combo"..i))
end
dropSound = loadSound("drop")
tetrisSound = loadSound("tetris")

playdate.inputHandlers.push({
	upButtonDown = function()
		if not lost then
			local dist = 0
			while canPieceMove(piece.x, piece.y + 1, piece.rotation) do
				piece.y += 1
				dist += 1
			end
			--synth:setWaveform(sound.kWaveSquare)
	    --synth:setADSR(0, 0, 0.5, 0.05)
	    --synth:playNote("C3", 0.5, 0.001)
	    dropSound:play()
			timer = timerLimit
			if shake then displayYPos = dist*1.25 end
		end
	end,
	AButtonDown = function() rotate(-1) end,
	BButtonDown = function() rotate(1) end
})

function rotate(rotation)
	local testRotation = piece.rotation + rotation
	testRotation %= #pieceStructures[piece.type]

  if canPieceMove(piece.x, piece.y, testRotation) then
    piece.rotation = testRotation
  end
end

function move(direction)
	local testX = piece.x + direction

  if canPieceMove(testX, piece.y, piece.rotation) then
    piece.x = testX
  end
end

function reset()
	levelIncreased = false
	displayYPos = 0
	completedLines = 0
	combo = 1
	level = 1
	lostY = 1
	lost = false
	clearLines, lines, sashes = {}, {}, {}
	holdDir = 0
	pieceHasChanged = false

	leftUIT = playdate.timer.new(500, -4, 8, easings.outCubic)

  inert = {}
	for y = 1, gridYCount do
    inert[y] = {}
    for x = 1, gridXCount do
      inert[y][x] = ' '
    end
  end

  newSequence()
	newPiece()

  timer = 0
  score = 0
end

function holdDirection(dir)
	if holdDir == 0 or holdDir > 5 then move(dir) end
	holdDir += 1
end

reset()

function playdate.update()
	_update()
	_draw()
end

function _update()
	if not lost then
		local crankTicks = playdate.getCrankTicks(4)
		if crankTicks ~= 0 then rotate(-crankTicks) end

		if score > highscore then
			saveData("highscore", score)
			highscore = score
		end

		timerLimit = 30
		if playdate.buttonIsPressed("down") and not pieceHasChanged then
			timerLimit = 0
		elseif not playdate.buttonIsPressed("down") then
			pieceHasChanged = false
		end

		if playdate.buttonIsPressed("right") then holdDirection(1)
		elseif playdate.buttonIsPressed("left") then holdDirection(-1)
		else holdDir = 0 end

		timer += level
		if timer >= timerLimit then
			timer = 0
			
			local testY = piece.y + 1

			if canPieceMove(piece.x, testY, piece.rotation) then
				piece.y = testY
			else
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
	  	    	comboSounds[math.min(combo, 4)]:stop()
	  	    	completedLine = true

	  	    	completedLines += 1
	  	    	if completedLines ~= 0 and completedLines%10 == 0 and not levelIncreased then
							levelIncreased = true
							level += 1
						elseif completedLines%10 ~= 0 then levelIncreased = false end

	  	    	table.insert(clearLines, ClearLine(y+1))
		        for removeY = y, 2, -1 do
		        	for removeX = 1, gridXCount do
		        		inert[removeY][removeX] =
		        		inert[removeY - 1][removeX]
		        	end
		        end

		        for removeX = 1, gridXCount do inert[1][removeX] = " " end

		        score += 10 * combo

		        --synth:setWaveform(sound.kWaveSquare)
		        --synth:setADSR(0, 0, 0.5, 0.05)
		        --synth:playNote("C5", 0.5, 0.001)		    
		        comboSounds[math.min(combo, 4)]:play()
		        combo += 1

		        clearedLines += 1
			    end
	      end

	      if clearedLines >= 4 then -- unlikely to be bigger than 4 but idc
	      	-- and at this point the only
	      	-- combo sound playing is the fourth one
	      	for i=1, 4 do
	      		comboSounds[i]:stop()
	      	end
	      	tetrisSound:play()
	      	if sash then table.insert(sashes, Sash("Tetris!")) end
	      end

	      if not completedLine then
	      	--synth:setWaveform(sound.kWaveSquare)
		      --synth:setADSR(0, 0, 0.5, 0.05)
		      --synth:playNote("C3", 0.5, 0.001)
		      dropSound:stop()
		      dropSound:play()
		      combo = 1
		    end

				newPiece()

				if not canPieceMove(piece.x, piece.y, piece.rotation) then
					timer = 0
					lost = true
					leftUIT = playdate.timer.new(500, 8, -4, easings.outCubic)
				end -- check if lost
			end -- complete a row
		end -- timer is over timerLimit
	else
		if not e then
			inert[lostY] = {}
			for i=1, gridXCount do inert[lostY][i] = ' ' end
			table.insert(lines, EndLine((lostY-1)+offsetY))

			--synth:setWaveform(sound.kWaveSquare)
			--synth:setADSR(0, 0, 0.2, 0.1)
			--synth:playNote("C5", 0.5, 0.00001)

			if lostY < gridYCount then lostY += 1
			else e = true end
		else
			if #lines == 0 then
				e = false
				reset()
			end
		end
	end -- state machine
end

function _draw()
	gfx.pushContext()
	gfx.clear(gfx.kColorWhite)

	gfx.fillRect(0, 0, 400, introRectT.value)

	if displayYPos ~= 0 then
		displayYPos+=((0-displayYPos)*0.25)
		gfx.setBackgroundColor(gfx.kColorBlack)
		gfx.setDrawOffset(0,displayYPos)
	end

	local function updateEffect(t,i,l)
		if l.dead then pcall(function() table.remove(t, i) end) else
			l:update()
			l:draw()
		end
	end

	for i,l in ipairs(lines) do updateEffect(lines,i,l) end

	for y = 1, gridYCount do
		for x = 1, gridXCount do
			drawBlock(inert[y][x], x + offsetX, y + offsetY)
		end
	end

	for i, l in ipairs(clearLines) do updateEffect(clearLines,i,l) end

	loopThroughBlocks(function(block, x, y)
		if not lost then
			local block = pieceStructures[piece.type][piece.rotation+1][y][x]
			if block ~= ' ' then
				drawBlock(block, x + piece.x + offsetX, y + piece.y + offsetY)
			end
		end
	end)

	gfx.setDrawOffset(0,0)

	loopThroughBlocks(function(_, x, y)
		local block = pieceStructures[sequence[#sequence]][1][y][x]
		if block ~= ' ' then
			drawBlock('*', x+(leftUIT.value-2.5), y+4)
		end
	end)

	local bold = gfx.getSystemFont("bold")
	gfx.drawText("*Score*", (leftUIT.value-3)*blockSize, 9*blockSize)
	gfx.drawText("*"..score.."*", (leftUIT.value-3.5)*blockSize+bold:getTextWidth("Score")/2, 11*blockSize)
	gfx.drawText("*Highscore*", (leftUIT.value-4.5)*blockSize, 13*blockSize)
	gfx.drawText("*"..highscore.."*", (leftUIT.value-5.5)*blockSize+bold:getTextWidth("Highscore")/2, 15*blockSize)

	gfx.drawText("*Level*", disp.getWidth()-(leftUIT.value+2)*blockSize, 7*blockSize)
	gfx.drawText("*"..math.floor(level).."*", (disp.getWidth()+bold:getTextWidth(level)/2)-(leftUIT.value+0.5)*blockSize, 9*blockSize)
	gfx.drawText("*Lines*", disp.getWidth()-(leftUIT.value+2)*blockSize, 11*blockSize)
	gfx.drawText("*"..completedLines.."*", (disp.getWidth()+bold:getTextWidth(completedLines)/2)-(leftUIT.value+1)*blockSize, 13*blockSize)
	gfx.popContext()

	for i, s in ipairs(sashes) do updateEffect(sashes, i, s) end

	playdate.timer.updateTimers()
end

function playdate.gameWillTerminate() commitSaveData() end

function playdate.deviceWillSleep() commitSaveData() end

-- Debug
function playdate.keyPressed(key)
	if key == "L" then
		for i=1, 4 do
			table.remove(inert)
		end
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
	end
end
