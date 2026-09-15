-- @description ADFX_Helper; auto rms loudness matching multiple
-- @version 1.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; auto rms loudness matching multiple
 * About: This script matches the RMS volume of the second selected item to the first one for multiple pairs
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2025-03-07)
  + Initial Release
--]]

-- Function to convert from linear to dB
function linear_to_db(value)
  if value <= 0 then return -150 end
  return 20 * math.log(value) / math.log(10)
end

-- Function to convert from dB to linear
function db_to_linear(db)
  return 10^(db/20)
end

-- Function to measure RMS using audio accessor
function measure_item_rms(item)
  local take = reaper.GetActiveTake(item)
  if not take then return nil end
  
  -- Skip MIDI takes
  if reaper.TakeIsMIDI(take) then return nil end
  
  -- Get source media
  local source = reaper.GetMediaItemTake_Source(take)
  if not source then return nil end
  
  -- Get item properties
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local take_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  
  -- Get channels and sample rate
  local num_channels = reaper.GetMediaSourceNumChannels(source)
  local sample_rate = reaper.GetMediaSourceSampleRate(source)
  
  if num_channels <= 0 or sample_rate <= 0 then return nil end
  
  -- Create audio accessor
  local accessor = reaper.CreateTakeAudioAccessor(take)
  if not accessor then return nil end
  
  -- Buffer for audio data
  local buffer_size = math.floor(sample_rate * 0.1) -- 100ms chunks
  local samples_needed = math.floor(item_len * sample_rate)
  local num_chunks = math.ceil(samples_needed / buffer_size)
  
  -- Arrays for RMS accumulation
  local sum_squares_per_channel = {}
  local sample_count_per_channel = {}
  
  for i = 1, num_channels do
    sum_squares_per_channel[i] = 0
    sample_count_per_channel[i] = 0
  end
  
  -- Process audio in chunks
  for chunk = 0, num_chunks - 1 do
    local start_time = chunk * buffer_size / sample_rate
    local samples_to_read = math.min(buffer_size, samples_needed - (chunk * buffer_size))
    if samples_to_read <= 0 then break end
    
    -- Create buffer and reset it
    local buffer = reaper.new_array(samples_to_read * num_channels)
    
    -- Read audio data
    local got_samples = reaper.GetAudioAccessorSamples(
      accessor, sample_rate, num_channels, 
      take_offset + start_time, samples_to_read, buffer
    )
    
    if got_samples then
      -- Get buffer as table for easier access
      local samples = buffer.table()
      
      -- Process samples for each channel
      for i = 0, samples_to_read - 1 do
        for ch = 0, num_channels - 1 do
          local sample_idx = i * num_channels + ch
          if sample_idx < #samples then
            local sample_value = samples[sample_idx + 1] -- Lua tables are 1-indexed
            sum_squares_per_channel[ch + 1] = sum_squares_per_channel[ch + 1] + (sample_value * sample_value)
            sample_count_per_channel[ch + 1] = sample_count_per_channel[ch + 1] + 1
          end
        end
      end
    end
  end
  
  -- Clean up
  reaper.DestroyAudioAccessor(accessor)
  
  -- Calculate RMS per channel
  local rms_values = {}
  for ch = 1, num_channels do
    if sample_count_per_channel[ch] > 0 then
      rms_values[ch] = math.sqrt(sum_squares_per_channel[ch] / sample_count_per_channel[ch])
    else
      rms_values[ch] = 0.0001
    end
  end
  
  return rms_values
end

-- Process a single pair of items
function process_item_pair(reference_item, target_item)
  -- Get takes from items
  local reference_take = reaper.GetActiveTake(reference_item)
  local target_take = reaper.GetActiveTake(target_item)
  
  if not reference_take or not target_take then
    return false, "Both items must have valid takes."
  end
  
  -- Get item names for display/logging
  local _, reference_name = reaper.GetSetMediaItemTakeInfo_String(reference_take, "P_NAME", "", false)
  local _, target_name = reaper.GetSetMediaItemTakeInfo_String(target_take, "P_NAME", "", false)
  
  -- Get track names too for better identification
  local reference_track = reaper.GetMediaItemTrack(reference_item)
  local target_track = reaper.GetMediaItemTrack(target_item)
  
  local _, reference_track_name = reaper.GetTrackName(reference_track)
  local _, target_track_name = reaper.GetTrackName(target_track)
  
  -- Measure RMS values
  local reference_rms = measure_item_rms(reference_item)
  local target_rms = measure_item_rms(target_item)
  
  if not reference_rms or not target_rms then
    return false, "Failed to measure RMS values for items."
  end
  
  -- Convert to dB
  local reference_rms_db = {}
  local target_rms_db = {}
  
  for ch = 1, #reference_rms do
    reference_rms_db[ch] = linear_to_db(reference_rms[ch])
  end
  
  for ch = 1, #target_rms do
    target_rms_db[ch] = linear_to_db(target_rms[ch])
  end
  
  -- Calculate average RMS in dB
  local reference_rms_db_avg = 0
  for ch = 1, #reference_rms_db do
    reference_rms_db_avg = reference_rms_db_avg + reference_rms_db[ch]
  end
  reference_rms_db_avg = reference_rms_db_avg / #reference_rms_db
  
  local target_rms_db_avg = 0
  for ch = 1, #target_rms_db do
    target_rms_db_avg = target_rms_db_avg + target_rms_db[ch]
  end
  target_rms_db_avg = target_rms_db_avg / #target_rms_db
  
  -- Calculate adjustment in dB (using channel 1)
  local adjustment_db_ch1 = reference_rms_db[1] - target_rms_db[1]
  
  -- Reset item volume to 1.0 (0 dB) before applying the adjustment
  reaper.SetMediaItemTakeInfo_Value(target_take, "D_VOL", 1.0)
  
  -- Apply the adjustment directly from scratch
  local volume_multiplier = db_to_linear(adjustment_db_ch1)
  local new_vol = volume_multiplier
  
  -- Set the new volume
  reaper.SetMediaItemTakeInfo_Value(target_take, "D_VOL", new_vol)
  reaper.UpdateItemInProject(target_item)
  
  return true, string.format(
    "%s (%s) → %s (%s): Applied %.2f dB adjustment (CH1: %.2f dB → %.2f dB)",
    reference_name, reference_track_name, 
    target_name, target_track_name, 
    adjustment_db_ch1, reference_rms_db[1], target_rms_db[1]
  )
end

-- Group items by position/time
function group_items_by_position()
  local item_count = reaper.CountSelectedMediaItems(0)
  local position_groups = {}
  
  -- Tolerance for considering items to be at the same position (in seconds)
  local time_tolerance = 0.001
  
  -- Group items by position
  for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    
    -- Find a matching group or create a new one
    local found_group = false
    
    for group_pos, group in pairs(position_groups) do
      if math.abs(group_pos - position) < time_tolerance then
        table.insert(group.items, item)
        -- Update group length to match smallest item
        if length < group.length then
          group.length = length
        end
        found_group = true
        break
      end
    end
    
    if not found_group then
      position_groups[position] = {
        items = {item},
        length = length
      }
    end
  end
  
  return position_groups
end

-- Process items grouped by vertical position
function process_vertical_groups()
  -- Group selected items by position
  local position_groups = group_items_by_position()
  
  -- Count groups
  local group_count = 0
  for _ in pairs(position_groups) do
    group_count = group_count + 1
  end
  
  if group_count == 0 then
    reaper.ShowMessageBox("No item groups found.", "Error", 0)
    return
  end
  
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  local results = {}
  local errors = {}
  
  -- Process each position group
  for position, group in pairs(position_groups) do
    local items = group.items
    
    -- Skip groups with only one item
    if #items < 2 then
      table.insert(errors, string.format("Position %.2f: Only one item found.", position))
      goto continue
    end
    
    -- Sort items by track index (top to bottom)
    table.sort(items, function(a, b)
      local track_a = reaper.GetMediaItemTrack(a)
      local track_b = reaper.GetMediaItemTrack(b)
      local idx_a = reaper.GetMediaTrackInfo_Value(track_a, "IP_TRACKNUMBER")
      local idx_b = reaper.GetMediaTrackInfo_Value(track_b, "IP_TRACKNUMBER")
      return idx_a < idx_b
    end)
    
    -- Use the first item (top track) as reference
    local reference_item = items[1]
    
    -- Process all other items in the group
    for i = 2, #items do
      local target_item = items[i]
      local success, message = process_item_pair(reference_item, target_item)
      
      if success then
        table.insert(results, message)
      else
        -- Get track info for error reporting
        local ref_track = reaper.GetMediaItemTrack(reference_item)
        local target_track = reaper.GetMediaItemTrack(target_item)
        local _, ref_track_name = reaper.GetTrackName(ref_track)
        local _, target_track_name = reaper.GetTrackName(target_track)
        
        table.insert(errors, string.format("Position %.2f (%s → %s): %s", 
          position, ref_track_name, target_track_name, message))
      end
    end
    
    ::continue::
  end
  
  -- End undo block
  reaper.Undo_EndBlock("Match RMS of Vertically Stacked Items", -1)
  
  -- Show results
  local result_text = "RMS Matching Results:\n\n"
  
  if #results > 0 then
    result_text = result_text .. "Successful matches:\n"
    for i, result in ipairs(results) do
      result_text = result_text .. "• " .. result .. "\n"
    end
  end
  
  if #errors > 0 then
    if #results > 0 then
      result_text = result_text .. "\n"
    end
    result_text = result_text .. "Errors:\n"
    for i, error in ipairs(errors) do
      result_text = result_text .. "• " .. error .. "\n"
    end
  end
  
  reaper.ShowMessageBox(result_text, "RMS Matching Complete", 0)
end

-- Main function
function main()
  -- Get count of selected items
  local item_count = reaper.CountSelectedMediaItems(0)
  
  -- No items selected
  if item_count == 0 then
    reaper.ShowMessageBox("Please select at least two items to match RMS.", "Error", 0)
    return
  end
  
  -- For exactly two items, use original single pair mode
  if item_count == 2 then
    -- Get both selected items
    local reference_item = reaper.GetSelectedMediaItem(0, 0)
    local target_item = reaper.GetSelectedMediaItem(0, 1)
    
    -- Get takes from items
    local reference_take = reaper.GetActiveTake(reference_item)
    local target_take = reaper.GetActiveTake(target_item)
    
    if not reference_take or not target_take then
      reaper.ShowMessageBox("Both items must have valid takes.", "Error", 0)
      return
    end
    
    -- Get item names for display
    local _, reference_name = reaper.GetSetMediaItemTakeInfo_String(reference_take, "P_NAME", "", false)
    local _, target_name = reaper.GetSetMediaItemTakeInfo_String(target_take, "P_NAME", "", false)
    
    -- Get track names too
    local reference_track = reaper.GetMediaItemTrack(reference_item)
    local target_track = reaper.GetMediaItemTrack(target_item)
    local _, reference_track_name = reaper.GetTrackName(reference_track)
    local _, target_track_name = reaper.GetTrackName(target_track)
    
    -- Measure RMS values
    local reference_rms = measure_item_rms(reference_item)
    local target_rms = measure_item_rms(target_item)
    
    if not reference_rms or not target_rms then
      reaper.ShowMessageBox("Failed to measure RMS values for the selected items.", "Error", 0)
      return
    end
    
    -- Convert to dB
    local reference_rms_db = {}
    local target_rms_db = {}
    
    for ch = 1, #reference_rms do
      reference_rms_db[ch] = linear_to_db(reference_rms[ch])
    end
    
    for ch = 1, #target_rms do
      target_rms_db[ch] = linear_to_db(target_rms[ch])
    end
    
    -- Calculate average RMS in dB
    local reference_rms_db_avg = 0
    for ch = 1, #reference_rms_db do
      reference_rms_db_avg = reference_rms_db_avg + reference_rms_db[ch]
    end
    reference_rms_db_avg = reference_rms_db_avg / #reference_rms_db
    
    local target_rms_db_avg = 0
    for ch = 1, #target_rms_db do
      target_rms_db_avg = target_rms_db_avg + target_rms_db[ch]
    end
    target_rms_db_avg = target_rms_db_avg / #target_rms_db
    
    -- Calculate adjustment in dB (average and channel 1)
    local adjustment_db_avg = reference_rms_db_avg - target_rms_db_avg
    local adjustment_db_ch1 = reference_rms_db[1] - target_rms_db[1]
    
    -- Build message - formatting depends on number of channels
    local message = string.format(
      "RMS Comparison Results:\n\n" ..
      "Item 1 (%s on %s):\n", reference_name, reference_track_name)
    
    for ch = 1, #reference_rms_db do
      message = message .. string.format("  Channel %d: %.2f dB\n", ch, reference_rms_db[ch])
    end
    
    message = message .. string.format("  Average: %.2f dB\n\n", reference_rms_db_avg)
    message = message .. string.format("Item 2 (%s on %s):\n", target_name, target_track_name)
    
    for ch = 1, #target_rms_db do
      message = message .. string.format("  Channel %d: %.2f dB\n", ch, target_rms_db[ch])
    end
    
    message = message .. string.format("  Average: %.2f dB\n\n", target_rms_db_avg)
    message = message .. string.format(
      "Required adjustment (based on Channel 1): %.2f dB\n" ..
      "Required adjustment (based on Average): %.2f dB\n\n" ..
      "Do you want to apply the Channel 1 based adjustment to the second item?",
      adjustment_db_ch1, adjustment_db_avg)
    
    -- Ask user if they want to apply the adjustment
    local user_response = reaper.MB(message, "RMS Comparison and Adjustment", 4)
    
    -- If user clicked Yes
    if user_response == 6 then
      -- Begin undo block
      reaper.Undo_BeginBlock()
      
      -- Reset item volume to 1.0 (0 dB) before applying the adjustment
      reaper.SetMediaItemTakeInfo_Value(target_take, "D_VOL", 1.0)
      
      -- Calculate volume multiplier (gain factor)
      local volume_multiplier = db_to_linear(adjustment_db_ch1)
      
      -- Apply the adjustment directly
      local new_vol = volume_multiplier
      
      -- Apply volume adjustment to target item take
      reaper.SetMediaItemTakeInfo_Value(target_take, "D_VOL", new_vol)
      reaper.UpdateItemInProject(target_item)
      
      -- End undo block
      reaper.Undo_EndBlock("Match RMS of selected items", -1)
      
      -- Confirmation dialog disabled
      --[[ 
      reaper.ShowMessageBox(
        string.format("Applied %.2f dB adjustment to %s (based on Channel 1)", 
                      adjustment_db_ch1, target_name),
        "RMS Adjustment Complete", 0)
      --]]
    end
  else
    -- More than two items, use vertical processing mode for stacked items
    process_vertical_groups()
  end
end

-- Execute script
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()