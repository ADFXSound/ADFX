-- @description ADFX_Helper; set selected items to full source length
-- @version 2.0.0
-- @author ADFXSound

-- Set selected items to full source length

reaper.Undo_BeginBlock()

local item_count = reaper.CountSelectedMediaItems(0)

for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
        local take = reaper.GetActiveTake(item)
        if take then
            local source = reaper.GetMediaItemTake_Source(take)
            local src_len, isQN = reaper.GetMediaSourceLength(source)

            if not isQN then
                -- Set item length to source length
                reaper.SetMediaItemInfo_Value(item, "D_LENGTH", src_len)
            end
        end
    end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Set items to source length", -1)
