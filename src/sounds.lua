---@diagnostic disable undefined-global lowercase-global

import "utils"

comboSounds = {}
for i=1, 4 do table.insert(comboSounds, loadSound("combo/combo"..i)) end

function stopAllComboSounds()
	for i=1, 4 do
		if comboSounds[i]:isPlaying() then comboSounds[i]:stop() end
	end
end

function updateMusicVolume()
	if currentSong:getVolume() ~= musicVolume then
		currentSong:setVolume(musicVolume)
	end
	--[[
	for i,v in pairs(songs) do
		if v:getVolume() ~= musicVolume then
			v:setVolume(musicVolume)
		end
	end
	--]]
end

function updateSoundVolume(soundTable)
	for i,v in ipairs(soundTable) do
		if v:getVolume() ~= soundsVolume then
			v:setVolume(soundsVolume)
		end
	end
end


dropSound = loadSound("drop")
specialSound = loadSound("special")
holdSound = loadSound("hold")
holdFailSound = loadSound "holdfail"
spinSound = loadSound("spin")
moveSound = loadSound("movetrimmed")
menuScrollSound = loadSound("menu/menu-scroll")
menuClickSound = loadSound("menu/menu-click")

sfx = {
	specialSound,
	holdSound, holdFailSound,
	menuScrollSound, menuClickSound,
	dropSound, spinSound, moveSound,
}

--local bgmIntro = loadMusic("bgmintro")
--local bgmLoop = loadMusic("bgmloop")
local playtris_music = loadMusic("bgmintro")
playtris_music:setLoopRange( 36, 54 )

currentSong = playtris_music -- current song is 

