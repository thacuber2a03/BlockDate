-- This one class uses a LOT of timers.

import "CoreLibs/object"

local gfx   <const> = playdate.graphics
local timer <const> = playdate.timer
local ease  <const> = playdate.easingFunctions

local Timer <const> = playdate.timer.new

local dwidth <const>, dheight <const> = playdate.display.getWidth(), playdate.display.getHeight()
local text_x_alignment <const> = 10
class("Sash").extends()

local starsAnimation = gfx.imagetable.new('assets/images/stars')
local total_frames = starsAnimation:getLength()

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
	self.animation_frame = 1
	local textWidth, text_height = gfx.getTextSize(self.text)

	-- haha bad code go brr
	self.yTimer = Timer(125, 0, text_height*2, ease.outBack)
	self.yTimer.discardOnCompletion = false
	setTimerEndCallback(self.yTimer, function()
		self.textPosTimer = Timer(250, -textWidth, text_x_alignment, ease.outCubic)
		setTimerEndCallback(self.textPosTimer, function()
			timer.performAfterDelay(500, function()
				self.textPosTimer = Timer(250, text_x_alignment, dwidth, ease.inCubic)
				setTimerEndCallback(self.textPosTimer, function()
					self.yTimer = Timer(250, 40, text_height*2, ease.inBack)
					setTimerEndCallback(self.yTimer, function() self.dead = true end)
				end)
			end)
		end)
	end)
end

function Sash:update() end

function Sash:draw()
	gfx.pushContext()
	local text_width, text_height = gfx.getTextSize(self.text)
	if self.yTimer then
		self.animation_frame = self.animation_frame + 1 
		if self.animation_frame > total_frames then self.animation_frame = 1 end
		starsAnimation:drawImage(self.animation_frame, text_x_alignment, (dheight-self.yTimer.value)-5)
	end
	if self.textPosTimer then
		gfx.drawText(self.text, self.textPosTimer.value, (dheight-text_height*1.5)-5)
	end
	gfx.popContext()
end