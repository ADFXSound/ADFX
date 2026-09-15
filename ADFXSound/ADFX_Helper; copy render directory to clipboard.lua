--[[
 * ReaScript Name: ADFX_Helper; copy render directory to clipboard
 * About: This sets the specified render directory to the clipboard
 * Author: ADFX
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 6.63
 * Extensions: SWS/S&M 2.13.1.0
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2022-07-10)
	+ Initial Release
--]]

function Main()

	retval, render_dir = reaper.GetSetProjectInfo_String(0, "RENDER_FILE", "", false)
	--This gets the render output directory as a string
	reaper.CF_SetClipboard(render_dir)
	--This sets the render directory string to the clipboard, enabling it to be pasted elsewhere
end

Main()