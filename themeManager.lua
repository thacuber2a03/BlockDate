local gfx <const> = playdate.graphics
local snd     <const> = playdate.sound
local disp    <const> = playdate.display

local dwidth <const>, dheight <const> = disp.getWidth(), disp.getHeight()

local theme_dir = "themes/"

-- generate table of themes from directories found within the given path
function generate_theme_list(path)

	print("Generating theme list:")

	local themes = {}
	local theme_folders = playdate.file.listFiles(path)
	for _i, theme in ipairs(theme_folders) do
		if theme:sub(#theme,#theme) == "/" then -- we check if the file is a directory
			local theme_name = theme:sub(1, #theme-1) -- removing trailing slash to get theme name
			print("adding", theme_name, "to theme list")
			table.insert( themes, theme_name )
		else
			print("ERROR: ", theme, "is not a directory. Ommitting from theme list")
		end
	end
	
	return themes

end


function load_theme(theme_name)
	local path = theme_dir .. theme_name .. "/" .. theme_name
	print("loading", theme_name, "from:", path, "...")
	theme = playdate.file.run(path) --loads theme package to "game" variable
	return theme
end
