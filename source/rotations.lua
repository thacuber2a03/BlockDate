PIECE_NONE = 0
PIECE_I = 1
PIECE_O = 2
PIECE_J = 3
PIECE_L = 4
PIECE_T = 5
PIECE_S = 6
PIECE_Z = 7

ROTATION_SRS = 1

rotations = {
	[ROTATION_SRS] = {
		rotate = function(rotation)
			local testRotation = piece.rotation + rotation
			testRotation %= #rotations[ROTATION_SRS].pieces[piece.type]

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

			local chosenWallKickTests = rotations[ROTATION_SRS].kickdata[(piece.type ~= PIECE_I and 1 or 2)][chosenRotation][(rotation==1 and "cw" or "ccw")]
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
		end,

		pieces = {
			[PIECE_I] = {
				{
					{ 0, 0, 0, 0 },
					{ 1, 1, 1, 1 },
					{ 0, 0, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 0, 1, 0 },
					{ 0, 0, 1, 0 },
					{ 0, 0, 1, 0 },
					{ 0, 0, 1, 0 },
				},
				{
					{ 0, 0, 0, 0 },
					{ 0, 0, 0, 0 },
					{ 1, 1, 1, 1 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 1, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 1, 0, 0 },
				},
			},
			[PIECE_O] = {
				{
					{ 0, 0, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 0, 0, 0 },
				},
			},
			[PIECE_J] = {
				{
					{ 1, 0, 0, 0 },
					{ 1, 1, 1, 0 },
					{ 0, 0, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 1, 1, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 0, 0, 0 },
					{ 1, 1, 1, 0 },
					{ 0, 0, 1, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 1, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 1, 1, 0, 0 },
					{ 0, 0, 0, 0 },
				},
			},
			[PIECE_L] = {
				{
					{ 0, 0, 1, 0 },
					{ 1, 1, 1, 0 },
					{ 0, 0, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 1, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 0, 0, 0 },
					{ 1, 1, 1, 0 },
					{ 1, 0, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 1, 1, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 0, 0, 0 },
				},
			},
			[PIECE_T] = {
				{
					{ 0, 1, 0, 0 },
					{ 1, 1, 1, 0 },
					{ 0, 0, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 1, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 0, 0, 0 },
					{ 1, 1, 1, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 1, 0, 0 },
					{ 1, 1, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 0, 0, 0 },
				},
			},
			[PIECE_S] = {
				{
					{ 0, 1, 1, 0 },
					{ 1, 1, 0, 0 },
					{ 0, 0, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 1, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 0, 1, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 0, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 1, 1, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 1, 0, 0, 0 },
					{ 1, 1, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 0, 0, 0 },
				},
			},
			[PIECE_Z] = {
				{
					{ 1, 1, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 0, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 0, 1, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 0, 0, 0 },
					{ 1, 1, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 0, 0, 0 },
				},
				{
					{ 0, 1, 0, 0 },
					{ 1, 1, 0, 0 },
					{ 1, 0, 0, 0 },
					{ 0, 0, 0, 0 },
				},
			},
		},

		-- Not required for rotations!
		kickdata = {
			{
				{
					cw  = { {  0,  0 }, { -1,  0 }, { -1,  1 }, {  0, -2 }, { -1, -2 } },
					ccw = { {  0,  0 }, {  1,  0 }, {  1, -1 }, {  0,  2 }, {  1,  2 } },
				},
				{
					cw  = { {  0,  0 }, {  1,  0 }, {  1, -1 }, {  0,  2 }, {  1,  2 } },
					ccw = { {  0,  0 }, { -1,  0 }, { -1,  1 }, {  0, -2 }, { -1, -2 } },
				},
				{
					cw  = { {  0,  0 }, {  1,  0 }, {  1,  1 }, {  0, -2 }, {  1, -2 } },
					ccw = { {  0,  0 }, { -1,  0 }, { -1, -1 }, {  0,  2 }, { -1,  2 } },
				},
				{
					cw  = { {  0,  0 }, { -1,  0 }, { -1, -1 }, {  0,  2 }, { -1,  2 } },
					ccw = { {  0,  0 }, {  1,  0 }, {  1,  1 }, {  0, -2 }, {  1, -2 } },
				},
			},
			{
				{
					cw  = { {  0,  0 }, { -2,  0 }, {  1,  0 }, { -2, -1}, {  1 , 2 } },
					ccw = { {  0,  0 }, {  2,  0 }, { -1,  0 }, {  2,  1}, { -1 ,-2 } },
				},
				{
					cw  = { {  0,  0 }, { -1,  0 }, {  2,  0 }, { -1,  2}, {  2 ,-1 } },
					ccw = { {  0,  0 }, {  1,  0 }, { -2,  0 }, {  1, -2}, { -2 , 1 } },
				},
				{
					cw  = { {  0,  0 }, {  2,  0 }, { -1,  0 }, {  2,  1}, { -1 ,-2 } },
					ccw = { {  0,  0 }, { -2,  0 }, {  1,  0 }, { -2, -1}, {  1 , 2 } },
				},
				{
					cw  = { {  0,  0 }, {  1,  0 }, { -2,  0 }, {  1, -2}, { -2 , 1 } },
					ccw = { {  0,  0 }, { -1,  0 }, {  2,  0 }, { -1,  2}, {  2 ,-1 } },
				},
			},
		}
	}
}