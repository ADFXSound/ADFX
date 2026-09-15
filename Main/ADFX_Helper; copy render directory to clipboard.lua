function Main()

	retval, render_dir = reaper.GetSetProjectInfo_String(0, "RENDER_FILE", "", false)
	--This gets the render output directory as a string
	reaper.CF_SetClipboard(render_dir)
	--This sets the render directory string to the clipboard, enabling it to be pasted elsewhere
end

Main()