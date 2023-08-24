---@diagnostic disable lowercase-global
import "constants"

-- If there's no game DATA available make some
savedData = DATA.read("gamedata") or {}

function loadData(key, defaultValue)
	local saved = savedData[key]
	if saved == nil then
		return defaultValue
	end

	return saved
end

function saveData(key, value) savedData[key] = value end

function commitSaveData()
	-- pretty print cuz why not
	DATA.write(savedData, "gamedata", true)
end

highscore = loadData("highscore") or 0

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
	bigBlocks,
	chill_mode
=
	loadData("shake", true), loadData("sash", true), loadData("ghost", true),
	loadData("grid", false), loadData("darkMode", false),
	loadData("inverseRotation", false),
	loadData("music", 1), loadData("sounds", 1),
	loadData("bigBlocks", false),
	loadData("chill_mode", false)

if bigBlocks then
	blockSize = bigBlockSize
else 
	blockSize = defaultBlockSize
end

offsetX = ((DWIDTH  / blockSize)/2) - (gridXCount/2)
offsetY = ((DHEIGHT / blockSize)/2) - (gridYCount/2)

menuBackground = GFX.image.new("assets/images/default_menu")
