--[[
 * ReaScript Name: ADFX_Helper; auto rms loudness matching
 * About: This script matches the RMS volume of the second selected item to the first one
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

function main()
  -- Get count of selected items
  local item_count = reaper.CountSelectedMediaItems(0)
  
  -- Check if exactly two items are selected
  if item_count ~= 2 then
    reaper.ShowMessageBox("Please select exactly two media items. The first item will be the reference.", "Error", 0)
    return
  end
  
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
    "Item 1 (%s):\n", reference_name)
  
  for ch = 1, #reference_rms_db do
    message = message .. string.format("  Channel %d: %.2f dB\n", ch, reference_rms_db[ch])
  end
  
  message = message .. string.format("  Average: %.2f dB\n\n", reference_rms_db_avg)
  message = message .. string.format("Item 2 (%s):\n", target_name)
  
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
    
    -- Get current volume adjustment of target item
    local current_vol = reaper.GetMediaItemTakeInfo_Value(target_take, "D_VOL")
    
    -- Calculate volume multiplier (gain factor)
    local volume_multiplier = db_to_linear(adjustment_db_ch1)
    
    -- Calculate new volume value
    local new_vol = current_vol * volume_multiplier
    
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
end

-- Execute script
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()