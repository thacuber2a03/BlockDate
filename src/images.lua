import "utils"

crossmarkFieldImage = loadImage("crossmark-field")

ghostBlockImagetable = loadImagetable("ghost-block/normal/ghost-block")
ghostBlockImagetableBig = loadImagetable("ghost-block/big/ghost-block")

gridImage = GFX.image.new(defaultBlockSize * gridXCount, defaultBlockSize * gridYCount)
gridImageBig = GFX.image.new(bigBlockSize * gridXCount, bigBlockSize * gridYCount)
inertGridImage = GFX.image.new(defaultBlockSize * gridXCount, defaultBlockSize * gridYCount)
inertGridImageBig = GFX.image.new(bigBlockSize * gridXCount, bigBlockSize * gridYCount)
menuBackground = GFX.image.new("assets/images/default_menu")

