-- @description ADFX_Helper; align item end to edit cursor
-- @version 1.0.0
-- @author ADFXSound

-- Align Item End to Edit Cursor
-- Moves selected item(s) so their end aligns with the edit cursor position

function main()
    local item_count = reaper.CountSelectedMediaItems(0)
    
    if item_count == 0 then
        reaper.ShowMessageBox("Please select at least one item.", "No Items Selected", 0)
        return
    end
    
    local cursor_pos = reaper.GetCursorPosition()
    
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local new_position = cursor_pos - item_length
        
        -- Prevent negative position
        if new_position < 0 then
            new_position = 0
        end
        
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_position)
    end
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Align item end to cursor", -1)
end

main()
