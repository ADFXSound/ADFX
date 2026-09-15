-- @description ADFX_Helper; sort selected item by loudness
-- @version 2.0.0
-- @author ADFXSound

-- Sort Selected Items by Loudness
-- This script analyzes the RMS loudness of selected items and sorts them

function GetItemRMS(item)
    local take = reaper.GetActiveTake(item)
    if not take then return -math.huge end
    
    local source = reaper.GetMediaItemTake_Source(take)
    if not source then return -math.huge end
    
    local accessor = reaper.CreateTakeAudioAccessor(take)
    if not accessor then return -math.huge end
    
    local channels = reaper.GetMediaSourceNumChannels(source)
    local samplerate = reaper.GetMediaSourceSampleRate(source)
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local samples = math.floor(item_len * samplerate)
    
    -- Limit samples for very long items to avoid excessive processing
    samples = math.min(samples, samplerate * 30) -- Max 30 seconds
    
    local buffer_size = samples
    local buffer = reaper.new_array(buffer_size * channels)
    
    -- Get audio data
    reaper.GetAudioAccessorSamples(accessor, samplerate, channels, 0, samples, buffer)
    
    -- Calculate RMS
    local sum = 0
    local sample_count = buffer_size * channels
    
    for i = 1, sample_count do
        local sample = buffer[i]
        sum = sum + (sample * sample)
    end
    
    reaper.DestroyAudioAccessor(accessor)
    
    local rms = math.sqrt(sum / sample_count)
    -- Convert to dB (using natural log since log10 might not be available)
    local rms_db = 20 * (math.log(math.max(rms, 0.0000001)) / math.log(10))
    
    return rms_db
end

function main()
    reaper.Undo_BeginBlock()
    
    local item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return
    end
    
    -- Collect items and their loudness
    local items = {}
    
    reaper.ShowConsoleMsg("Analyzing item loudness...\n")
    
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItem_Track(item)
        local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local rms = GetItemRMS(item)
        
        table.insert(items, {
            item = item,
            track = track,
            position = position,
            rms = rms,
            index = i
        })
        
        reaper.ShowConsoleMsg(string.format("Item %d: %.2f dB RMS\n", i + 1, rms))
    end
    
    -- Sort by loudness (descending - loudest first)
    -- Change to "a.rms < b.rms" for ascending order (quietest first)
    table.sort(items, function(a, b) return a.rms > b.rms end)
    
    -- Find the minimum position to start placing items
    local min_position = math.huge
    for _, item_data in ipairs(items) do
        min_position = math.min(min_position, item_data.position)
    end
    
    -- Reposition items
    local current_position = min_position
    
    for i, item_data in ipairs(items) do
        local item = item_data.item
        local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
        -- Move item to new position
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", current_position)
        
        -- Update position for next item (with small gap)
        current_position = current_position + item_length + 0.01
    end
    
    reaper.ShowConsoleMsg("\nItems sorted by loudness (loudest to quietest)\n")
    reaper.UpdateArrange()
    
    reaper.Undo_EndBlock("Sort selected items by loudness", -1)
end

-- Run the script
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)