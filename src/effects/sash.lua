-- this one class uses a LOT of timers

import "constants"

import "CoreLibs/object"

Sash = {}
class("Sash").extends()

local function setTimerEndCallback(timer, args, callback)
	if type(args) == "function" then
		callback = args
		args = {}
	end
	timer.timerEndedArgs = args
	timer.timerEndedCallback = callback
end

---@diagnostic disable: duplicate-set-field

function Sash:init(text)
	self.text = text

	-- haha bad code go brr
	self.yTimer = TIME.new(125, 0, 40, EASINGS.outBack)
	self.yTimer.discardOnCompletion = false
	local textWidth = GFX.getSystemFont("bold"):getTextWidth(text)
	setTimerEndCallback(self.yTimer, function()
		self.textPosTimer = TIME.new(250, -textWidth, textWidth/2, EASINGS.outCubic)
		setTimerEndCallback(self.textPosTimer, function()
			TIME.performAfterDelay(500, function()
				self.textPosTimer = TIME.new(250, 10+textWidth/2, DWIDTH, EASINGS.inCubic)
				setTimerEndCallback(self.textPosTimer, function()
					self.yTimer = TIME.new(250, 40, 0, EASINGS.inBack)
					setTimerEndCallback(self.yTimer, function() self.dead = true end)
				end)
			end)
		end)
	end)
end

function Sash:update() end

function Sash:draw()
	GFX.pushContext()
	if self.yTimer then
		GFX.fillRect(0, (DHEIGHT-self.yTimer.value)-5, DWIDTH, GFX.getSystemFont("bold"):getHeight()*2)
	end
	if self.textPosTimer then
		GFX.setImageDrawMode(darkMode and "fillBlack" or "fillWhite")
		GFX.drawText("*"..self.text.."*", self.textPosTimer.value, (DHEIGHT-GFX.getSystemFont("bold"):getHeight()*1.5)-5)
	end
	GFX.popContext()
end
