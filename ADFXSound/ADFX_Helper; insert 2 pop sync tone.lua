--[[
 * ReaScript Name: Insert 2 Pop Sync Tone
 * About: A quick way to add a Sync Tone
 * Author: ADFXSound
 * Author URI: http://www.adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 6.61
 * Version: 1.0
 * @provides [nomain] Media/TwoPop1KhzTone.wav
--]]

--[[
 * Changelog:
 * v1.0 (2022-06-20)
  + Initial Release
--]]

platform = reaper.GetOS() --determine OS for pathing seperators / or \
    if platform == "OSX64" or platform == "OSX32" or platform == "OSX" or platform  == "Other" or platform == "macOS-arm64" then
        slash = [[/]]
    else
        slash = [[\]] --win
    end

function Main()
path = reaper.GetResourcePath() .. slash .. 'Scripts' .. slash .. 'ADFXSound' .. slash .. 'Media' .. slash .. 'TwoPop1KhzTone.wav'

  if reaper.file_exists( path ) then
    reaper.InsertMedia( path, 0 )
  else
    reaper.MB("Download TwoPop1KhzTone.wav on https://www.adfxsound.com/reaper-scripts" .. "\n\nSave to directory of missing media file:" .. "\n\nMissing media file:\n" .. path, "Error", 0)
    return false
  end
end

Main()




