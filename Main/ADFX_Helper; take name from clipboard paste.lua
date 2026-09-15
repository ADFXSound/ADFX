--[[
 * ReaScript Name: ADFX_Helper; take name from clipboard paste
 * About: This pastes the take name into another item from the string stored in the clipboard
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
    newtakename = reaper.CF_GetClipboard()
    --This gets the takename from the clipboard and sets it as string value
    sel_items = reaper.CountSelectedMediaItems(0)
    if sel_items == 0 then
        reaper.ShowConsoleMsg("No selected media item found")
    else
        for i = 0, sel_items -1 do
        seltake = reaper.GetSelectedMediaItem(0, i) 
        take = reaper.GetActiveTake(seltake)
        reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", newtakename, true )
        end
    end

end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

Main()

reaper.UpdateArrange()
reaper.Undo_EndBlock("Undo", -1) 
reaper.PreventUIRefresh(-1)