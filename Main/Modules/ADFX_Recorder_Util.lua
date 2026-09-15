-- @description ADFX_Recorder_Util
-- @version 1.0.0
-- @author ADFXSound

--[[
  ADFX_Recorder_Util.lua
  Pure helper functions for the ADFX recorder. No REAPER or ReaImGui calls live
  here so this file can be unit tested with a plain Lua interpreter.
]]

local M = {}

M.VERSION = '1.0.0'

function M.clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

--- Formats seconds as m:ss.mmm, the layout REAPER uses in the transport.
function M.format_time(seconds)
  seconds = seconds or 0
  local sign = ''
  if seconds < 0 then
    sign = '-'
    seconds = -seconds
  end
  local minutes = math.floor(seconds / 60)
  local rest = seconds - minutes * 60
  return string.format('%s%d:%06.3f', sign, minutes, rest)
end

--- Formats a duration compactly for tooltips and labels.
function M.format_duration(seconds)
  seconds = seconds or 0
  if seconds < 1 then return string.format('%d ms', math.floor(seconds * 1000 + 0.5)) end
  if seconds < 60 then return string.format('%.2f s', seconds) end
  return M.format_time(seconds)
end

function M.time_to_x(t, t0, t1, x0, x1)
  if t1 <= t0 then return x0 end
  return x0 + (t - t0) / (t1 - t0) * (x1 - x0)
end

function M.x_to_time(x, x0, x1, t0, t1)
  if x1 <= x0 then return t0 end
  return t0 + (x - x0) / (x1 - x0) * (t1 - t0)
end

--- Returns the two values in ascending order.
function M.sorted_pair(a, b)
  if a <= b then return a, b end
  return b, a
end

--[[
  Builds an isolation section from two anchor times.
  Returns nil when the range collapses below min_len, which lets the caller
  treat a right-click without movement as "menu" instead of "isolate".
]]
function M.make_section(anchor_a, anchor_b, total_len, min_len)
  min_len = min_len or 0.005
  local lo, hi = M.sorted_pair(anchor_a, anchor_b)
  lo = M.clamp(lo, 0, total_len)
  hi = M.clamp(hi, 0, total_len)
  if hi - lo < min_len then return nil end
  return { start = lo, len = hi - lo }
end

--- The section to act on: the isolated range, or the whole recording.
function M.effective_section(section, total_len)
  if section and section.len and section.len > 0 then
    local start = M.clamp(section.start, 0, total_len)
    return { start = start, len = M.clamp(section.len, 0, total_len - start) }
  end
  return { start = 0, len = total_len }
end

--[[
  Collapses a ReaImGui/REAPER peak buffer into per-bucket min/max pairs.
  `buf` is a 1-indexed flat table laid out as REAPER returns it: all maximum
  values first (bucket-major, channel-minor), then all minimum values.
]]
function M.fold_peaks(buf, n_buckets, n_channels)
  local out = {}
  if n_buckets <= 0 or n_channels <= 0 then return out end
  local max_block = 0
  local min_block = n_buckets * n_channels
  for bucket = 1, n_buckets do
    local hi, lo = 0, 0
    for ch = 1, n_channels do
      local idx = (bucket - 1) * n_channels + ch
      local mx = buf[max_block + idx] or 0
      local mn = buf[min_block + idx] or 0
      if mx > hi then hi = mx end
      if mn < lo then lo = mn end
    end
    out[bucket] = { max = M.clamp(hi, -1, 1), min = M.clamp(lo, -1, 1) }
  end
  return out
end

--[[
  Converts REAPER's meter hold reading (dB * 0.01, so 0 = 0 dBFS and
  -0.06 = -6 dB) into a 0..1-ish sample amplitude. Anything below -90 dB counts
  as silence; overs are capped so one clipped hit cannot flatten the display.
]]
function M.hold_db_to_amplitude(hold)
  if type(hold) ~= 'number' then return 0 end
  local db = hold * 100
  if db <= -90 then return 0 end
  if db > 12 then db = 12 end
  return 10 ^ (db / 20)
end

--- Sample amplitude as dB, or nil for silence (which has no dB value).
function M.amplitude_to_db(amplitude)
  if type(amplitude) ~= 'number' or amplitude <= 0 then return nil end
  return 20 * math.log(amplitude, 10)
end

--- Merges neighbouring buckets, halving the resolution of a live capture.
function M.halve_peaks(peaks)
  local out = {}
  for i = 1, #peaks, 2 do
    local a = peaks[i]
    local b = peaks[i + 1] or a
    out[#out + 1] = {
      max = math.max(a.max, b.max),
      min = math.min(a.min, b.min),
    }
  end
  return out
end

--- Picks the peak bucket covering a normalised 0..1 position across the strip.
function M.peak_at(peaks, position)
  local n = #peaks
  if n == 0 then return nil end
  local idx = math.floor(M.clamp(position, 0, 1) * (n - 1)) + 1
  return peaks[idx]
end

--- Largest absolute sample in the folded peaks, used to normalise the display.
function M.peak_ceiling(peaks)
  local ceiling = 0
  for i = 1, #peaks do
    local p = peaks[i]
    local hi = math.max(math.abs(p.max or 0), math.abs(p.min or 0))
    if hi > ceiling then ceiling = hi end
  end
  return ceiling
end

--- Trims a filename down to something that fits in a narrow footer strip.
function M.short_name(path, max_len)
  if not path or path == '' then return '' end
  max_len = max_len or 34
  local name = path:match('[^/\\]+$') or path
  if #name <= max_len then return name end
  return '…' .. name:sub(#name - max_len + 2)
end

function M.take_name(prefix, index, section)
  local base = string.format('%s_%03d', prefix or 'ADFX', index or 1)
  if section and section.start and section.start > 0 then
    return string.format('%s_@%.2fs', base, section.start)
  end
  return base
end

return M
