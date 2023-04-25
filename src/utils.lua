---@diagnostic disable undefined-global

function random(min, max, float)
	math.randomseed(playdate.getSecondsSinceEpoch())

	if not min then return math.random() end
	if not max then max = min min = 1 end

	if not float then return math.random(min, max)
	else return min + (max - min) * math.random() end
end

SOUNDSDIR = "assets/sounds/"
function loadSound(name)
	return assert(SND.sampleplayer.new(SOUNDSDIR..name))
end

MUSICDIR = "assets/music/"
function loadMusic(name)
	return assert(SND.fileplayer.new(MUSICDIR..name))
end

IMAGESDIR = "assets/images/"

function loadImage(name)
	return assert(GFX.image.new(IMAGESDIR..name))
end

function loadImagetable(name)
	return assert(GFX.imagetable.new(IMAGESDIR..name))
end

function loopThroughPieceBlocks(func)
	for y=1, pieceYCount do
		for x=1, pieceXCount do
			func(pieceStructures[piece.type][piece.rotation+1][y][x], x, y)
		end
	end
end

