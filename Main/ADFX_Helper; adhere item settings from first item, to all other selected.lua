--[[
 * ReaScript Name: ADFX_Helper; make variations from markered takes
 * About: A quick way to duplicate items, and consolidate items for export
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

--[[
 * NOTE: This script was designed for usaged with nvk_create, and nvk_workflow, its otherwise untested and less effective. The nvk stuff is purchaseable from nvk @ https://nvktools.gumroad.com/
 --]]

-- Get the first selected item
local src_item = reaper.GetSelectedMediaItem(0, 0)

-- Get the item state chunk (i.e. all of the item's settings)
local src_chunk = reaper.GetItemStateChunk(src_item, "", false)

-- Loop through all selected items (starting with the second one)
for i = 1, reaper.CountSelectedMediaItems(0) do
  if i ~= 1 then -- Skip the first item
    local dest_item = reaper.GetSelectedMediaItem(0, i)
    reaper.SetItemStateChunk(dest_item, src_chunk, false)
  end
end