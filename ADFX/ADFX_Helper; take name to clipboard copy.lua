--[[
 * ReaScript Name: ADFX_Helper; take name from clipboard copy
 * About: This copies the take name from an item into the clipboard
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
    selitem = reaper.CountSelectedMediaItems(0)
    if selitem == 0 then
        reaper.ShowConsoleMsg("No selected media item found")
    else
        seltake = reaper.GetSelectedMediaItem(0, 0) 
        take = reaper.GetActiveTake(seltake)
        retval, takename = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
        --This gets the take name and set it as a string

        reaper.CF_SetClipboard( takename )
        --Sets the render_dir to the clipboard
    end
end

Main()