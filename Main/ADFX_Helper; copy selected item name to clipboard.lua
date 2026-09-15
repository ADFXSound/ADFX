-- @description ADFX_Helper; copy selected item name to clipboard
-- @version 2.0.0
-- @author ADFXSound

-- Copy Selected Item Names to Clipboard
-- This script copies all selected media item names to the clipboard

function main()
    -- Get the number of selected media items
    local num_selected_items = reaper.CountSelectedMediaItems(0)
    
    -- Check if any items are selected
    if num_selected_items == 0 then
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return
    end
    
    -- Table to store item names
    local item_names = {}
    
    -- Loop through all selected items
    for i = 0, num_selected_items - 1 do
        -- Get the selected item
        local item = reaper.GetSelectedMediaItem(0, i)
        
        if item then
            -- Get the active take from the item
            local take = reaper.GetActiveTake(item)
            
            if take then
                -- Get the take name
                local _, take_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
                
                -- If take name is empty, try to get the source file name
                if take_name == "" then
                    local source = reaper.GetMediaItemTake_Source(take)
                    if source then
                        local _, source_filename = reaper.GetMediaSourceFileName(source, "")
                        -- Extract just the filename without path
                        take_name = source_filename:match("([^/\\]+)$") or source_filename
                    end
                end
                
                -- If still no name, use a default
                if take_name == "" then
                    take_name = "Unnamed Item " .. (i + 1)
                end
                
                table.insert(item_names, take_name)
            else
                -- Item has no take, use a default name
                table.insert(item_names, "Empty Item " .. (i + 1))
            end
        end
    end
    
    -- Join all names with newlines
    local clipboard_text = table.concat(item_names, "\n")
    
    -- Copy to clipboard
    reaper.CF_SetClipboard(clipboard_text)
    
    -- Show confirmation message
    local message = string.format("Copied %d item name(s) to clipboard:\n\n%s", 
                                  num_selected_items, 
                                  clipboard_text)
    reaper.ShowMessageBox(message, "Success", 0)
end

-- Run the main function
main()