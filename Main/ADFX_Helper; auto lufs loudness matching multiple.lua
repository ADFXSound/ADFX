-- @description ADFX_Helper; auto lufs loudness matching multiple
-- @version 2.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; auto lufs loudness matching multiple
 * About: This script matches the LUFS volume of the second selected item to the first one for multiple pairs
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

-- Function to measure LUFS using audio accessor
function measure_item_lufs(item)
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
  
  -- Arrays for LUFS calculation
  local channel_powers = {}
  local sample_count = 0
  
  for i = 1, num_channels do
    channel_powers[i] = 0
  end
  
  -- K-weighting filter coefficients (simplified implementation)
  -- Pre-filter (highpass)
  local b0_pre = 1.53512485958697
  local b1_pre = -2.69169618940638
  local b2_pre = 1.19839281085285
  local a1_pre = -1.69065929318241
  local a2_pre = 0.73248077421585
  
  -- High-shelf filter
  local b0_high = 1.42620795010278
  local b1_high = -2.85241590020556
  local b2_high = 1.42620795010278
  local a1_high = -1.94499125479533
  local a2_high = 0.94589803434997
  
  -- Pre-filter state variables per channel
  local pre_x1 = {}
  local pre_x2 = {}
  local pre_y1 = {}
  local pre_y2 = {}
  
  -- High-shelf filter state variables per channel
  local high_x1 = {}
  local high_x2 = {}
  local high_y1 = {}
  local high_y2 = {}
  
  for ch = 1, num_channels do
    pre_x1[ch] = 0
    pre_x2[ch] = 0
    pre_y1[ch] = 0
    pre_y2[ch] = 0
    
    high_x1[ch] = 0
    high_x2[ch] = 0
    high_y1[ch] = 0
    high_y2[ch] = 0
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
      
      -- Process samples for each channel using K-weighting
      for i = 0, samples_to_read - 1 do
        for ch = 0, num_channels - 1 do
          local sample_idx = i * num_channels + ch
          if sample_idx < #samples then
            local sample_value = samples[sample_idx + 1] -- Lua tables are 1-indexed
            local ch_idx = ch + 1
            
            -- Apply pre-filter (highpass)
            local pre_output = b0_pre * sample_value + b1_pre * pre_x1[ch_idx] + b2_pre * pre_x2[ch_idx] - 
                               a1_pre * pre_y1[ch_idx] - a2_pre * pre_y2[ch_idx]
            
            pre_x2[ch_idx] = pre_x1[ch_idx]
            pre_x1[ch_idx] = sample_value
            pre_y2[ch_idx] = pre_y1[ch_idx]
            pre_y1[ch_idx] = pre_output
            
            -- Apply high-shelf filter
            local high_output = b0_high * pre_output + b1_high * high_x1[ch_idx] + b2_high * high_x2[ch_idx] - 
                                a1_high * high_y1[ch_idx] - a2_high * high_y2[ch_idx]
            
            high_x2[ch_idx] = high_x1[ch_idx]
            high_x1[ch_idx] = pre_output
            high_y2[ch_idx] = high_y1[ch_idx]
            high_y1[ch_idx] = high_output
            
            -- Square the filtered output for power calculation
            channel_powers[ch_idx] = channel_powers[ch_idx] + (high_output * high_output)
          end
        end
      end
      
      sample_count = sample_count + samples_to_read
    end
  end
  
  -- Clean up
  reaper.DestroyAudioAccessor(accessor)
  
  -- Calculate LUFS values
  local lufs_values = {}
  
  -- Compute mean square value for each channel
  for ch = 1, num_channels do
    if sample_count > 0 then
      local mean_square = channel_powers[ch] / sample_count
      -- LUFS is calculated as -0.691 + 10*log10(mean_square)
      lufs_values[ch] = -0.691 + 10 * math.log(mean_square) / math.log(10)
    else
      lufs_values[ch] = -70.0  -- Default very low LUFS value
    end
  end
  
  return lufs_values
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
  
  -- Measure LUFS values
  local reference_lufs = measure_item_lufs(reference_item)
  local target_lufs = measure_item_lufs(target_item)
  
  if not reference_lufs or not target_lufs then
    return false, "Failed to measure LUFS values for items."
  end
  
  -- Calculate adjustment in LUFS (using channel 1)
  local adjustment_lufs_ch1 = reference_lufs[1] - target_lufs[1]
  
  -- Reset item volume to 1.0 (0 dB) before applying the adjustment
  reaper.SetMediaItemTakeInfo_Value(target_take, "D_VOL", 1.0)
  
  -- Apply the adjustment directly from scratch
  local volume_multiplier = db_to_linear(adjustment_lufs_ch1)
  local new_vol = volume_multiplier
  
  -- Set the new volume
  reaper.SetMediaItemTakeInfo_Value(target_take, "D_VOL", new_vol)
  reaper.UpdateItemInProject(target_item)
  
  return true, string.format(
    "%s (%s) → %s (%s): Applied %.2f LUFS adjustment (CH1: %.2f LUFS → %.2f LUFS)",
    reference_name, reference_track_name, 
    target_name, target_track_name, 
    adjustment_lufs_ch1, reference_lufs[1], target_lufs[1]
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
  reaper.Undo_EndBlock("Match LUFS of Vertically Stacked Items", -1)
  
  -- Show results
  local result_text = "LUFS Matching Results:\n\n"
  
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
  
  reaper.ShowMessageBox(result_text, "LUFS Matching Complete", 0)
end

-- Main function
function main()
  -- Get count of selected items
  local item_count = reaper.CountSelectedMediaItems(0)
  
  -- No items selected
  if item_count == 0 then
    reaper.ShowMessageBox("Please select at least two items to match LUFS.", "Error", 0)
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
    
    -- Measure LUFS values
    local reference_lufs = measure_item_lufs(reference_item)
    local target_lufs = measure_item_lufs(target_item)
    
    if not reference_lufs or not target_lufs then
      reaper.ShowMessageBox("Failed to measure LUFS values for the selected items.", "Error", 0)
      return
    end
    
    -- Calculate average LUFS
    local reference_lufs_avg = 0
    for ch = 1, #reference_lufs do
      reference_lufs_avg = reference_lufs_avg + reference_lufs[ch]
    end
    reference_lufs_avg = reference_lufs_avg / #reference_lufs
    
    local target_lufs_avg = 0
    for ch = 1, #target_lufs do
      target_lufs_avg = target_lufs_avg + target_lufs[ch]
    end
    target_lufs_avg = target_lufs_avg / #target_lufs
    
    -- Calculate adjustment in LUFS (average and channel 1)
    local adjustment_lufs_avg = reference_lufs_avg - target_lufs_avg
    local adjustment_lufs_ch1 = reference_lufs[1] - target_lufs[1]
    
    -- Build message - formatting depends on number of channels
    local message = string.format(
      "LUFS Comparison Results:\n\n" ..
      "Item 1 (%s on %s):\n", reference_name, reference_track_name)
    
    for ch = 1, #reference_lufs do
      message = message .. string.format("  Channel %d: %.2f LUFS\n", ch, reference_lufs[ch])
    end
    
    message = message .. string.format("  Average: %.2f LUFS\n\n", reference_lufs_avg)
    message = message .. string.format("Item 2 (%s on %s):\n", target_name, target_track_name)
    
    for ch = 1, #target_lufs do
      message = message .. string.format("  Channel %d: %.2f LUFS\n", ch, target_lufs[ch])
    end
    
    message = message .. string.format("  Average: %.2f LUFS\n\n", target_lufs_avg)
    message = message .. string.format(
      "Required adjustment (based on Channel 1): %.2f LUFS\n" ..
      "Required adjustment (based on Average): %.2f LUFS\n\n" ..
      "Do you want to apply the Channel 1 based adjustment to the second item?",
      adjustment_lufs_ch1, adjustment_lufs_avg)
    
    -- Ask user if they want to apply the adjustment
    local user_response = reaper.MB(message, "LUFS Comparison and Adjustment", 4)
    
    -- If user clicked Yes
    if user_response == 6 then
      -- Begin undo block
      reaper.Undo_BeginBlock()
      
      -- Reset item volume to 1.0 (0 dB) before applying the adjustment
      reaper.SetMediaItemTakeInfo_Value(target_take, "D_VOL", 1.0)
      
      -- Calculate volume multiplier (gain factor)
      local volume_multiplier = db_to_linear(adjustment_lufs_ch1)
      
      -- Apply the adjustment directly
      local new_vol = volume_multiplier
      
      -- Apply volume adjustment to target item take
      reaper.SetMediaItemTakeInfo_Value(target_take, "D_VOL", new_vol)
      reaper.UpdateItemInProject(target_item)
      
      -- End undo block
      reaper.Undo_EndBlock("Match LUFS of selected items", -1)
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