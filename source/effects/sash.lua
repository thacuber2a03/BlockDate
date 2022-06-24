-- This one class uses a LOT of timers.

import "CoreLibs/object"

local gfx   <const> = playdate.graphics
local timer <const> = playdate.timer
local ease  <const> = playdate.easingFunctions

local Timer <const> = playdate.timer.new

local dwidth <const>, dheight <const> = playdate.display.getWidth(), playdate.display.getHeight()

class("Sash").extends()

local function setTimerEndCallback(timer, args, callback)
	if type(args) == "function" then
		callback = args
		args = {}
	end
	timer.timerEndedArgs = args
	timer.timerEndedCallback = callback
end

function Sash:init(text)
	self.text = text

	-- haha bad code go brr
	self.yTimer = Timer(125, 0, 40, ease.outBack)
	self.yTimer.discardOnCompletion = false
	local textWidth = gfx.getSystemFont("bold"):getTextWidth(text)
	setTimerEndCallback(self.yTimer, function()
		self.textPosTimer = Timer(250, -textWidth, textWidth/2, ease.outCubic)
		setTimerEndCallback(self.textPosTimer, function()
			timer.performAfterDelay(500, function()
				self.textPosTimer = Timer(250, 10+textWidth/2, dwidth, ease.inCubic)
				setTimerEndCallback(self.textPosTimer, function()
					self.yTimer = Timer(250, 40, 0, ease.inBack)
					setTimerEndCallback(self.yTimer, function() self.dead = true end)
				end)
			end)
		end)
	end)
end

function Sash:update() end

function Sash:draw()
	gfx.pushContext()
	if self.yTimer then
		gfx.fillRect(0, (dheight-self.yTimer.value)-5, dwidth, gfx.getSystemFont("bold"):getHeight()*2)
	end
	if self.textPosTimer then
		gfx.setImageDrawMode(darkMode and "fillBlack" or "fillWhite")
		gfx.drawText("*"..self.text.."*", self.textPosTimer.value, (dheight-gfx.getSystemFont("bold"):getHeight()*1.5)-5)
	end
	gfx.popContext()
end