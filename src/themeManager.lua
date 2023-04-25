import "constants"

local theme_dir = "themes/"

-- generate table of themes from directories found within the given path
function generate_theme_list(path)

	print("Generating theme list:")

	local themes = {}
	local theme_folders = PD.file.listFiles(path)
	for _, theme in ipairs(theme_folders) do
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
	local theme = PD.file.run(path) --loads theme package to "game" variable
	return theme
end
