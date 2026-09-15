-- Organize SELECTED Items by Core Name
-- Groups selected items with the same core name onto the same track
-- Example: FS_BOOT_Add_Run_01 through FS_BOOT_Add_Run_12 → ALL go to ONE track "FS_BOOT_Add_Run"

function Msg(str)
    reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

function GetCoreName(itemName)
    -- Debug: show exactly what we're processing
    Msg(string.format("  Processing name: '%s' (length: %d)", itemName, string.len(itemName)))
    
    -- Remove numeric suffix to get the core name
    -- Try to match everything up to the last underscore followed by numbers
    local core = string.match(itemName, "(.*)_%d+")
    
    if core then
        Msg(string.format("    → Extracted core: '%s'", core))
        return core
    end
    
    -- Try other separators
    core = string.match(itemName, "(.*)%-%d+")
    if core then
        Msg(string.format("    → Extracted core (hyphen): '%s'", core))
        return core
    end
    
    core = string.match(itemName, "(.*)%.%d+")
    if core then
        Msg(string.format("    → Extracted core (period): '%s'", core))
        return core
    end
    
    -- No pattern matched - use full name
    Msg(string.format("    → No numeric suffix found, using full name: '%s'", itemName))
    return itemName
end

function GetItemName(item)
    local take = reaper.GetActiveTake(item)
    if take then
        local _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        return name
    end
    return nil
end

function FindOrCreateTrack(trackName, trackIndex)
    -- Check if a track with this name already exists
    local numTracks = reaper.CountTracks(0)
    for i = 0, numTracks - 1 do
        local track = reaper.GetTrack(0, i)
        local _, existingName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        if existingName == trackName then
            return track, false  -- Return track and "not newly created" flag
        end
    end
    
    -- Track doesn't exist, create a new one
    reaper.InsertTrackAtIndex(trackIndex, true)
    local newTrack = reaper.GetTrack(0, trackIndex)
    reaper.GetSetMediaTrackInfo_String(newTrack, "P_NAME", trackName, true)
    return newTrack, true  -- Return track and "newly created" flag
end

function Main()
    -- Check if any items are selected
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    if numSelectedItems == 0 then
        Msg("No items selected! Please select items to organize.")
        return
    end
    
    -- Start undo block
    reaper.Undo_BeginBlock()
    
    Msg("=== ORGANIZING SELECTED ITEMS BY CORE NAME ===")
    Msg(string.format("Processing %d selected items...", numSelectedItems))
    Msg("")
    
    -- First, let's see what we're working with
    Msg("Item names found:")
    local itemGroups = {}
    
    for i = 0, numSelectedItems - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local itemName = GetItemName(item)
        
        if itemName and itemName ~= "" then
            -- Get core name by removing numeric suffix
            local coreName = GetCoreName(itemName)
            
            -- Create group if it doesn't exist
            if not itemGroups[coreName] then
                itemGroups[coreName] = {}
                Msg(string.format("NEW GROUP CREATED: '%s'", coreName))
            end
            
            -- Add item to the group
            table.insert(itemGroups[coreName], {
                item = item,
                name = itemName,
                originalTrack = reaper.GetMediaItem_Track(item),
                position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            })
        else
            Msg(string.format("  Item %d has no name or take", i+1))
        end
    end
    
    -- Show summary of groups
    Msg("")
    Msg("=== GROUPS FOUND ===")
    for coreName, items in pairs(itemGroups) do
        Msg(string.format("Group '%s': %d items", coreName, #items))
        for _, item in ipairs(items) do
            Msg(string.format("  - %s", item.name))
        end
    end
    
    -- Sort core names for consistent track order
    local coreNames = {}
    for coreName, _ in pairs(itemGroups) do
        table.insert(coreNames, coreName)
    end
    table.sort(coreNames)
    
    -- Process each group
    local newTracksCreated = 0
    local existingTracksUsed = 0
    local itemsMoved = 0
    local currentTrackIndex = reaper.CountTracks(0)
    
    Msg("")
    Msg("=== MOVING ITEMS TO TRACKS ===")
    
    for _, coreName in ipairs(coreNames) do
        local items = itemGroups[coreName]
        
        -- Get or create ONE track for ALL items with this core name
        local targetTrack, isNew = FindOrCreateTrack(coreName, currentTrackIndex)
        
        if targetTrack then
            if isNew then
                Msg(string.format("Created new track: '%s'", coreName))
                newTracksCreated = newTracksCreated + 1
                currentTrackIndex = currentTrackIndex + 1
            else
                Msg(string.format("Using existing track: '%s'", coreName))
                existingTracksUsed = existingTracksUsed + 1
            end
            
            -- Move ALL items with this core name to the SAME track
            for _, itemData in ipairs(items) do
                if itemData.originalTrack ~= targetTrack then
                    reaper.MoveMediaItemToTrack(itemData.item, targetTrack)
                    itemsMoved = itemsMoved + 1
                    Msg(string.format("  Moved: %s", itemData.name))
                else
                    Msg(string.format("  Already on track: %s", itemData.name))
                end
            end
        end
    end
    
    -- Report results
    Msg("")
    Msg("=== SUMMARY ===")
    Msg(string.format("Selected items: %d", numSelectedItems))
    Msg(string.format("Unique core names found: %d", #coreNames))
    Msg(string.format("New tracks created: %d", newTracksCreated))
    Msg(string.format("Existing tracks used: %d", existingTracksUsed))
    Msg(string.format("Items moved: %d", itemsMoved))
    
    -- Update arrange view
    reaper.UpdateArrange()
    
    -- End undo block
    reaper.Undo_EndBlock("Organize selected items by core name", -1)
end

-- Check if we're in Reaper
if reaper then
    Main()
else
    Msg("This script must be run from within REAPER")
end