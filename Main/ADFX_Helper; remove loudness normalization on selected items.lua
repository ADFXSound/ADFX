-- @description ADFX_Helper; remove loudness normalization on selected items
-- @version 2.0.0
-- @author ADFXSound

-- Remove Loudness / Gain Normalization from Selected Items
-- Resets item volume, take volume, and removes take volume envelopes

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local itemCount = reaper.CountSelectedMediaItems(0)

for i = 0, itemCount - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)

    -- Reset item volume (0.0 dB = 1.0)
    reaper.SetMediaItemInfo_Value(item, "D_VOL", 1.0)

    -- Clear item normalization gain if present
    reaper.SetMediaItemInfo_Value(item, "D_VOL_NORM", 0.0)

    local take = reaper.GetActiveTake(item)
    if take then
        -- Reset take volume
        reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", 1.0)

        -- Remove take volume envelope if it exists
        local env = reaper.GetTakeEnvelopeByName(take, "Volume")
        if env then
            reaper.DeleteEnvelopePointRange(env, -1e10, 1e10)
            reaper.Envelope_SortPoints(env)
        end
    end
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Remove loudness normalization from selected items", -1)

