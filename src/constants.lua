PD      = playdate
GFX     = PD.graphics
SND     = PD.sound
GEOM    = PD.geometry
TIME    = PD.timer
DATA    = PD.datastore
DISP    = PD.display
EASINGS = PD.easingFunctions

DWIDTH, DHEIGHT = DISP.getWidth(), DISP.getHeight()

IPIECE, OPIECE, JPIECE, LPIECE, TPIECE, SPIECE, ZPIECE = 1, 2, 3, 4, 5, 6, 7

-- Taken from https://harddrop.com/wiki/SRS
-- and tuned into a lua table

-- `name` is a debug field

-- Format:

--JLSTZ
--	0->R->0
--		CW
--		CCW
--	R->2->R
--		CW
--		CCW
--	2->L->2
--		CW
--		CCW
--	L->0->L
--		CW
--		CCW
--I
--	0->R->0
--		CW
--		CCW
--	R->2->R
--		CW
--		CCW
--	2->L->2
--		CW
--		CCW
--	L->0->L
--		CW
--		CCW

WALL_KICK_DATA = {
	{
		{
			name = "0->R->0",
			cw  = {{0, 0}, {-1, 0}, {-1, 1}, {0,-2}, {-1,-2}},
			ccw = {{0, 0}, { 1, 0}, { 1,-1}, {0, 2}, { 1, 2}},
		},
		{
			name = "R->2->R",
			cw  = {{0, 0}, { 1, 0}, { 1,-1}, {0, 2}, { 1, 2}},
			ccw = {{0, 0}, {-1, 0}, {-1, 1}, {0,-2}, {-1,-2}},
		},
		{
			name = "2->L->2",
			cw  = {{0, 0}, { 1, 0}, { 1, 1}, {0,-2}, { 1,-2}},
			ccw = {{0, 0}, {-1, 0}, {-1,-1}, {0, 2}, {-1, 2}},
		},
		{
			name = "L->0->L",
			cw  = {{0, 0}, {-1, 0}, {-1,-1}, {0, 2}, {-1, 2}},
			ccw = {{0, 0}, { 1, 0}, { 1, 1}, {0,-2}, { 1,-2}},
		},
	},
	{
		{
			name = "0->R->0",
			cw  = {{0, 0}, {-2, 0}, { 1, 0}, {-2,-1}, { 1, 2}},
			ccw = {{0, 0}, { 2, 0}, {-1, 0}, { 2, 1}, {-1,-2}},
		},
		{
			name = "R->2->R",
			cw  = {{0, 0}, {-1, 0}, { 2, 0}, {-1, 2}, { 2,-1}},
			ccw = {{0, 0}, { 1, 0}, {-2, 0}, { 1,-2}, {-2, 1}},
		},
		{
			name = "2->L->2",
			cw  = {{0, 0}, { 2, 0}, {-1, 0}, { 2, 1}, {-1,-2}},
			ccw = {{0, 0}, {-2, 0}, { 1, 0}, {-2,-1}, { 1, 2}},
		},
		{
			name = "L->0->L",
			cw  = {{0, 0}, { 1, 0}, {-2, 0}, { 1,-2}, {-2, 1}},
			ccw = {{0, 0}, {-1, 0}, { 2, 0}, {-1, 2}, { 2,-1}},
		},
	},
}

TSPIN_DATA = {
	{-1,-1},
	{ 1,-1},
	{ 1, 1},
	{-1, 1},
}
