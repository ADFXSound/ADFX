-- @description ADFX_Recorder_Util
-- @version 2.0.0
-- @author ADFXSound

--[[
  ADFX_Recorder_Util.lua
  Pure helper functions for the ADFX recorder. No REAPER or ReaImGui calls live
  here so this file can be unit tested with a plain Lua interpreter.
]]

local M = {}

M.VERSION = '1.1.0'

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

--- REAPER's GetMediaSourceFileName has returned either `filename` or
--- `retval, filename` depending on the build. Accept both.
function M.source_filename(api, source)
  if not source or type(api) ~= 'table' or type(api.GetMediaSourceFileName) ~= 'function' then
    return ''
  end
  local a, b = api.GetMediaSourceFileName(source, '')
  if type(a) == 'string' and a ~= '' then return a end
  if type(b) == 'string' and b ~= '' then return b end
  return ''
end

local function u32le(n)
  n = math.floor(n) % 4294967296
  return string.char(
    n % 256,
    math.floor(n / 256) % 256,
    math.floor(n / 65536) % 256,
    math.floor(n / 16777216) % 256)
end

local function read_u32le(s, i)
  local a, b, c, d = s:byte(i, i + 3)
  if not d then return nil end
  return a + b * 256 + c * 65536 + d * 16777216
end

--- Reads a standard RIFF/WAVE header and returns fmt bytes plus the data
--- payload offset/size. Rejects RF64 and anything that is not PCM/float WAV.
function M.read_wav_layout(path)
  local f, err = io.open(path, 'rb')
  if not f then return nil, err or ('cannot open ' .. tostring(path)) end
  local header = f:read(12)
  if not header or #header < 12 or header:sub(1, 4) ~= 'RIFF' or header:sub(9, 12) ~= 'WAVE' then
    f:close()
    return nil, 'not a RIFF/WAVE file'
  end

  local fmt, data_offset, data_size
  while true do
    local chunk = f:read(8)
    if not chunk or #chunk < 8 then break end
    local id = chunk:sub(1, 4)
    local size = read_u32le(chunk, 5)
    if not size then break end
    local payload_pos = f:seek()
    if id == 'fmt ' then
      fmt = f:read(size)
      if not fmt or #fmt < 16 then
        f:close()
        return nil, 'truncated fmt chunk'
      end
    elseif id == 'data' then
      data_offset = payload_pos
      data_size = size
      f:seek('cur', size)
    else
      f:seek('cur', size)
    end
    if size % 2 == 1 then f:seek('cur', 1) end
  end
  f:close()
  if not fmt or not data_offset or not data_size then
    return nil, 'WAVE is missing fmt or data'
  end
  return { fmt = fmt, data_offset = data_offset, data_size = data_size }
end

--[[
  Concatenates same-format PCM/float WAV files into one file. Used to join the
  recorder's JSFX export chunks without depending on REAPER's Glue action,
  which ignores hidden tracks or respects an unrelated time selection.

  Returns dest on success, or nil plus a reason.
]]
function M.concat_wav_files(paths, dest)
  if type(paths) ~= 'table' or #paths == 0 then return nil, 'no files' end
  if #paths == 1 then return paths[1] end
  if type(dest) ~= 'string' or dest == '' then return nil, 'no destination' end

  local layouts = {}
  local total = 0
  local fmt
  for i = 1, #paths do
    local layout, why = M.read_wav_layout(paths[i])
    if not layout then return nil, why end
    if fmt then
      if layout.fmt ~= fmt then return nil, 'WAV format mismatch between chunks' end
    else
      fmt = layout.fmt
    end
    layouts[i] = layout
    total = total + layout.data_size
  end

  local fmt_pad = #fmt % 2
  local data_pad = total % 2
  local riff_size = 4 + 8 + #fmt + fmt_pad + 8 + total + data_pad

  local out, err = io.open(dest, 'wb')
  if not out then return nil, err or 'cannot write merged WAV' end
  out:write('RIFF')
  out:write(u32le(riff_size))
  out:write('WAVE')
  out:write('fmt ')
  out:write(u32le(#fmt))
  out:write(fmt)
  if fmt_pad == 1 then out:write('\0') end
  out:write('data')
  out:write(u32le(total))

  local BLOCK = 1024 * 1024
  for i = 1, #paths do
    local src = io.open(paths[i], 'rb')
    if not src then
      out:close()
      return nil, 'cannot re-open ' .. tostring(paths[i])
    end
    src:seek('set', layouts[i].data_offset)
    local left = layouts[i].data_size
    while left > 0 do
      local n = math.min(BLOCK, left)
      local bytes = src:read(n)
      if not bytes or #bytes == 0 then
        src:close()
        out:close()
        return nil, 'truncated WAV data in ' .. tostring(paths[i])
      end
      out:write(bytes)
      left = left - #bytes
    end
    src:close()
  end
  if data_pad == 1 then out:write('\0') end
  out:close()
  return dest
end

--- Directory of a file path, including the trailing separator when present.
function M.dirname(path)
  if type(path) ~= 'string' or path == '' then return '' end
  return path:match('^(.*[/\\])') or ''
end

return M
