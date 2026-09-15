--[[
 * ReaScript Name: ADFX_Helper; togglemute.lua
 * About: This toggles mute on selected items
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

  count_sel_items =  reaper.CountSelectedMediaItems( 0 )

  for i = 0, count_sel_items -1 do
    item = reaper.GetSelectedMediaItem(0, i)
    item_mute = reaper.GetMediaItemInfo_Value(item, "B_MUTE")

    ToggleMute()

  end

end

function ToggleMute()
  if item_mute == 0
  then
  reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
  elseif item_mute == 1
  then
  reaper.SetMediaItemInfo_Value(item, "B_MUTE", 0)
  end

end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

Main()

reaper.UpdateArrange()
reaper.Undo_EndBlock("Undo End Block", 0)
reaper.PreventUIRefresh(-1)
