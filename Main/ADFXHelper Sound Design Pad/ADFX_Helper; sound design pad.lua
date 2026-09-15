-- @description ADFX_Helper; sound design pad
-- @version 2.0.0
-- @author ADFXSound

--[[
ADFXSound Sound Design Pad v1.0.7
REAPER + ReaImGui + ADFX Varispeed JSFX + optional Windows Wacom Bridge

v1.0.7:
- Renamed bundled/installed Varispeed JSFX to ADFX_Varispeed.jsfx
- Varispeed now installs to Effects/ADFX/ADFX_Varispeed.jsfx

v1.0.6:
- FOLLOW (ms) writes Varispeed Smooth; 0 follows on the next audio sample
- Rate/Pitch also go through gmem so the JSFX applies them at sample rate
- Unique XY values still arrive at the pad loop; that is not Kyma

v1.0.5:
- Opening the pad no longer overwrites Effects/ADFX or replaces track instances
- A missing install is still copied once; RELOAD JSFX is the only forced overwrite
- Load / Has Sample / Delay / Xfade stay hidden so that 10-slider UI cannot return

v1.0.4:
- ADFX Varispeed is the original v1.2 file again (visible Load / Delay / Xfade)
- Opening the pad copies that file into Effects/ADFX when it differs
- Existing track instances are replaced so REAPER recompiles; JSFX has no VST rescan
- RELOAD JSFX on the transport row does the same thing on demand

v1.0.3:
- Wacom bridge launches hidden from the pad; no PowerShell console to keep open
- Connection is four-state: OFFLINE / STARTING / READY / LIVE
- Bridge writes PID + heartbeat so READY stays honest while the pen is idle

v1.0.2:
- Recorder dependency warning now runs before the ReaImGui context is created,
  preventing the missing-module dialog from invalidating ctx on the first frame
- Recorder load/init failures after startup are reported in the pad status instead
  of opening a modal dialog while ReaImGui is live

v1.0.1:
- Missing ADFX_Recorder.lua now shows a clear install message instead of silently
  removing the recorder footer; the pad still opens and runs without the module

v1.0:
- Input assignment bus rows now use one fixed horizontal grid for X, Y, PRESSURE,
  TILT X and TILT Y so every action button starts at the exact same X position
- No vertical dividers were added; alignment is handled only by fixed placement

v0.9.10:
- Increased the main window first-open size so the complete interface, including
  INPUT RESPONSE, TRANSPORT, and RECORDER, is visible without manual resizing
- Default main window is now 1480 x 960

v0.9.8:
- INPUT RESPONSE rebuilt on fixed columns so X / Y / PRESS-Z / TILT X / TILT Y
  all use the same slider, checkbox, and label positions
- Added two subtle vertical dividers with equal 10 px padding on both sides,
  separating ATTACK/MULTIPLIER, RELEASE/RETURN ON RELEASE, and RETURN TIME/INVERT

v0.9.7:
- Tab / Shift+Tab jump to the next or previous item while the pad is
  focused, set loop points to that selection, and snap the playhead if
  the arrange is rolling. LOOP SELECTED ITEMS ON PLAY also turns Repeat
  on. The jump is ADFX_Tab to Transient.lua; the pad dofiles that
  action script instead of embedding the commands. The previous-item
  action is the same file used on its own from the Action List. The
  pad consumes Tab so it never walks CONFIG / PRESET widgets

v0.9.6:
- Each assignment has RETURN TO RELEASE, off by default. INPUT RESPONSE
  RETURN ON RELEASE still returns every lane on that bus. The lane box
  returns that assignment even when the input's return is off, using
  the same RETURN TIME and default

v0.9.5:
- ADFX Varispeed 1.2: Delay and Xfade sliders, loop/resync crossfade,
  anti-alias when Rate > 1. Rate / Pitch LEARN indices are unchanged

v0.9.4:
- Recorder footer uses the same buffer capture path as S-Layer, so the
  post-stop preview matches the bounced file (and the dragged item)

v0.9.3:
- + SAMPLE RATE / + SAMPLE PITCH insert ADFX Varispeed on the selected
  track and LEARN Rate or Pitch. + TRACK RATE is gone
- Spacebar, PLAY and STOP drive the arrange again while the pad is focused

v0.9.2:
- ADFX Varispeed now varispeeds the track input while Play is Stopped,
  so Rate / Pitch are audible as a normal insert. Play=Playing still
  reads the RAM sample the pad loaded. Section WAVs are 16-bit PCM.

v0.9.1:
- PLAY decodes the selected items into RAM and plays them through the
  ADFX Varispeed JSFX on each item's track. Rate is a slewed,
  interpolated read head, not CF_Preview D_PLAYRATE
- + SAMPLE RATE / + TRACK RATE / + SAMPLE PITCH write JSFX sliders
- Pitch is extra varispeed in semitones on the same head (tape-locked)
- SWS is no longer required for the engine

v0.9.0:
- PLAY loads the selected items into an SWS CF_Preview sample engine
  instead of rolling the arrange. Pitch and rate are live preview
  properties (resampling varispeed by default), not project or take
  playrate, so the timeline no longer artefacts the sound
- + PROJECT RATE and + TRACK RATE write D_PLAYRATE on those voices
- + SAMPLE PITCH writes independent D_PITCH in semitones
- PRESERVE PITCH is off unless you ask for it; leaving it off is the
  high-fidelity path (rate and pitch stay locked, like tape)
- REC timestamps against the loaded item positions, not GetPlayPosition
- ADFX recorder footer is optional; the pad runs without that module

v0.8.60:
- INPUT RESPONSE sliders read ATTACK / RELEASE instead of
  PICKUP GLIDE ATTACK / PICKUP GLIDE RELEASE

v0.8.59:
- Removed the captions beside PROJECT LINK, ARM, MODULATORS, POP OUT XY PAD
  and the one on every empty input bus
- PRESS GAIN / PRESS CURVE / PRESS FALLBACK on one line instead of two.
  Sliders share what is left after their own measured label widths
- Dropped the two inline pressure hints; the pad surface already says
  which pressure source is live

v0.8.58:
- REC toggle at the right-hand end of the transport row. While armed, the
  next playback writes everything the pad sends into each plugin
  parameter's FX automation lane, committed when the transport stops
- Removed the raw pen telemetry beside START BRIDGE and the two captions
  next to WACOM INPUT and LIVE INPUT VALUES
- TRANSPORT is now a fixed footer of the performance column, on one line, so
  the default window height no longer crops it off the bottom edge
- PLAY / STOP give up width to the loop toggle on a narrow column instead of
  pushing its label out of view
- GLOBAL RANGE cut from three rows to one, roughly a quarter of the height
- Kept RANGE plus hard MIN / MAX limits and RESET; the heading is now the
  enable checkbox itself, and the explanation moved into its tooltip
- Removed PIVOT (always shrinks toward the middle now), OFFSET, the
  100/75/50/25/10% shortcuts, and APPLY TO ROUTES / UNDO APPLY
- Presets and sessions written here still load in a v0.8.57 build

v0.8.57:
- Spacebar plays/stops while the pad window has focus, instead of being
  swallowed by ReaImGui until you clicked back into REAPER
- Pad controls rebuilt as two even columns with one shared slider width,
  so PRESSURE GAIN's label is no longer pushed off the right edge
- Removed the SMOOTH slider: nothing read it, per-input PICKUP GLIDE
  replaced it long ago. The state field is kept so old sessions load

v0.8.56:
- TRANSPORT row at the foot of the performance column: PLAY, STOP, and an
  option to loop the selected items each time PLAY is pressed
- Loop behaviour is the standalone "set loops points for selected items"
  action (v1.3) folded in, minus its focus hand-off to the arrange view

v0.8.55:
- GLOBAL RANGE section between MODULATORS and the input buses
- One RANGE control restrains every assignment's MIN / CENTER / MAX at once
- Non-destructive: per-route MIN / CENTER / MAX are never modified
- Saved per session and in presets (preset format v5)

v0.4:
- Native Windows pen bridge support: X/Y/pressure/tilt/buttons
- Bridge overlay only covers the Paint Pad, so REAPER UI remains usable
- Pressure/Z bus is now driven by real pen pressure when bridge is connected
- Tilt X and Tilt Y buses added, each with unlimited assignments
- Preserves v0.3 X/Y/Z project assignments by using the same ext-state section
- Falls back to ordinary mouse + manual pressure when bridge is not running

Windows bridge files are packaged under this script folder:
  Bridge\Start Wacom Bridge.bat
  Bridge\SDPP_WacomBridge.ps1
The pad launches the .ps1 hidden. The .bat is a manual Explorer fallback.
]]

local r = reaper

if not r.ImGui_CreateContext then
  r.MB("Sound Design Paint Pad requires ReaImGui.\nInstall ReaImGui via ReaPack.", "Missing dependency", 0)
  return
end

-- v1.0.2: Preflight optional Recorder dependency BEFORE creating the ReaImGui
-- context. A native REAPER message box opened after CreateContext but before the
-- first frame can invalidate ctx, causing SetNextWindowSize/Begin to fail.
local RECORDER_PATH = r.GetResourcePath() .. package.config:sub(1, 1) .. "Scripts" ..
  package.config:sub(1, 1) .. "ADFX" .. package.config:sub(1, 1) .. "Modules" ..
  package.config:sub(1, 1) .. "ADFX_Recorder.lua"
local RECORDER_MISSING = not r.file_exists(RECORDER_PATH)
if RECORDER_MISSING then
  r.MB(
    "ADFX Recorder is not installed.\n\n" ..
    "Install ADFX_Recorder.lua in:\n" ..
    r.GetResourcePath() .. package.config:sub(1,1) .. "Scripts" .. package.config:sub(1,1) ..
    "ADFX" .. package.config:sub(1,1) .. "Modules" ..
    "\n\nSound Design Pad will continue without the Recorder.",
    "ADFX Recorder Required", 0)
end

package.path = r.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.10'
local ctx = ImGui.CreateContext('ADFXHelper; sound design pad v1.0.7')
-- Tab is item-to-item navigation, not ImGui widget focus. Turn off
-- keyboard nav so Tab / Shift+Tab never walk CONFIG / PRESET buttons.
pcall(function()
  local flags = ImGui.GetConfigFlags(ctx)
  local nav = ImGui.ConfigFlags_NavEnableKeyboard
  if type(nav) == "function" then nav = nav() end
  if flags and nav then ImGui.SetConfigFlags(ctx, flags & ~nav) end
end)
local input_heading_font = ImGui.CreateFont("sans-serif", 18)
ImGui.Attach(ctx, input_heading_font)
-- v0.8.59: the three pressure sliders share one line.
-- v0.8.58: REC records the pad into FX automation lanes; GLOBAL RANGE is one row.
-- v0.8.57: spacebar transport, and the pad controls fit their column.
-- v0.8.56: TRANSPORT row adds PLAY / STOP and loop-the-selection on play.
-- v0.8.55: GLOBAL RANGE section restrains every assignment from one place.
-- v0.8.54: removed the TYPE caption above the compact modulator shape controls.
-- v0.8.53: modulator shape labels are SINE / TRI / SQR / UP / DOWN on one row.
-- v0.8.50: larger assignment title font using the ReaImGui-compatible two-argument CreateFont call.
-- Rendered once for crisp text; avoids the double-draw faux-bold blur from v0.8.49.
local assignment_title_font = ImGui.CreateFont("sans-serif", 20)
ImGui.Attach(ctx, assignment_title_font)

-- Keep v0.3 section so existing routes survive the upgrade.
local EXT_SECTION = "SoundDesignPaintPad_v03" -- legacy project state; no longer auto-loaded
local SESSION_SECTION = "SoundDesignPaintPad_v063_SESSION"
local PROJECT_LINK_SECTION = "SoundDesignPaintPad_v065_PRESET_LINK"
local PRESET_DIR = r.GetResourcePath() .. package.config:sub(1,1) .. "Data" .. package.config:sub(1,1) .. "Sound Design Paint Pad Presets"

-- Forward declaration so every helper closes over the same local state table.
local state
-- Forward declarations for helpers used across sections.
local mark_self_write
local sync_last_fields_from_inputs
local clear_range_preview
local set_assignment_preview
local set_bus
local apply_lfo

local TEMP = os.getenv("TEMP") or os.getenv("TMP") or "."
local SEP = package.config:sub(1,1)
-- One table for every bridge path/helper so the main chunk stays under
-- Lua's 200-local limit.
local BR = {
  STATE     = TEMP .. SEP .. "SDPP_WacomBridge_state.txt",
  RECT      = TEMP .. SEP .. "SDPP_WacomBridge_rect.txt",
  STOP      = TEMP .. SEP .. "SDPP_WacomBridge_stop.txt",
  PID       = TEMP .. SEP .. "SDPP_WacomBridge_pid.txt",
  INFO      = TEMP .. SEP .. "SDPP_WacomBridge_info.txt",
  HEARTBEAT = TEMP .. SEP .. "SDPP_WacomBridge_heartbeat.txt",
  poll_last = 0,
  rect_write_last = 0,
  primed = false,
  baseline_seq = nil,
  baseline_hb = nil,
}

-- v0.8.42: Resolve the script from REAPER's runtime action context first.
-- Compiled Lua bytecode can retain the original source filename from luac,
-- which may point back into the build Source folder instead of the installed
-- Release folder. get_action_context() reports the file REAPER actually ran,
-- so Bridge/ and Assets/ remain relative to the installed script in both
-- plain-Lua and bytecode releases.
local _, runtime_script_path = r.get_action_context()
local SCRIPT_PATH = runtime_script_path or ""
if SCRIPT_PATH == "" then
  local source = debug.getinfo(1, "S").source or ""
  SCRIPT_PATH = source:sub(1,1) == "@" and source:sub(2) or source
end
local SCRIPT_DIR = SCRIPT_PATH:match("^(.*[\\/])") or ""
BR.BAT = SCRIPT_DIR .. "Bridge" .. SEP .. "Start Wacom Bridge.bat"
BR.PS1 = SCRIPT_DIR .. "Bridge" .. SEP .. "SDPP_WacomBridge.ps1"

-- v0.9.0 sample-engine math. Prefer the sibling source file so the unit
-- tests and the script cannot drift; fall back to the same functions
-- inlined below when the script is installed on its own.
local MATH
do
  local math_path = SCRIPT_DIR .. "source" .. SEP .. "adfx_sample_engine_math.lua"
  if math_path ~= "" and r.file_exists(math_path) then
    local ok, mod = pcall(dofile, math_path)
    if ok and type(mod) == "table" then MATH = mod end
  end
end
if not MATH then
  MATH = {}
  function MATH.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
  end
  function MATH.section_source_length(item_len, take_rate)
    item_len = tonumber(item_len) or 0
    take_rate = tonumber(take_rate) or 1
    if take_rate < 0.000001 then take_rate = 0.000001 end
    if item_len <= 0 then return 0 end
    return item_len * take_rate
  end
  function MATH.combine_playrate(project_rate, track_rate)
    project_rate = tonumber(project_rate) or 1
    track_rate = tonumber(track_rate) or 1
    local rate = project_rate * track_rate
    if rate < 0.01 then return 0.01 end
    if rate > 100 then return 100 end
    return rate
  end
  MATH.PITCH_MIN_ST, MATH.PITCH_MAX_ST = -24, 24
  function MATH.pitch_to_normalized(st)
    st = tonumber(st) or 0
    return MATH.clamp((st - MATH.PITCH_MIN_ST) / (MATH.PITCH_MAX_ST - MATH.PITCH_MIN_ST), 0, 1)
  end
  function MATH.normalized_to_pitch(norm)
    norm = MATH.clamp(tonumber(norm) or 0.5, 0, 1)
    return MATH.PITCH_MIN_ST + norm * (MATH.PITCH_MAX_ST - MATH.PITCH_MIN_ST)
  end
  function MATH.playrate_to_normalized(rate)
    rate = tonumber(rate) or 1
    return MATH.clamp((rate - 0.25) / 3.75, 0, 1)
  end
  function MATH.normalized_to_playrate(norm)
    norm = MATH.clamp(tonumber(norm) or 0.5, 0, 1)
    return 0.25 + norm * 3.75
  end
  function MATH.rec_time(item_pos, preview_pos, source_len)
    item_pos = tonumber(item_pos) or 0
    preview_pos = tonumber(preview_pos) or 0
    source_len = tonumber(source_len) or 0
    if preview_pos < 0 then preview_pos = 0 end
    if source_len > 0 then preview_pos = preview_pos % source_len end
    return item_pos + preview_pos
  end
  function MATH.preview_volume(item_vol, take_vol)
    item_vol = tonumber(item_vol) or 1
    take_vol = tonumber(take_vol) or 1
    local vol = item_vol * take_vol
    if vol < 0 then return 0 end
    if vol > 16 then return 16 end
    return vol
  end
  MATH.JSFX_GAIN_MAX = 4
  function MATH.gain_to_jsfx(vol)
    return MATH.clamp(tonumber(vol) or 1, 0, MATH.JSFX_GAIN_MAX)
  end
  function MATH.hermite4(y0, y1, y2, y3, t)
    local c0 = y1
    local c1 = 0.5 * (y2 - y0)
    local c2 = y0 - 2.5 * y1 + 2 * y2 - 0.5 * y3
    local c3 = 0.5 * (y3 - y0) + 1.5 * (y1 - y2)
    return c0 + (c1 + (c2 + c3 * t) * t) * t
  end
  function MATH.aa_cutoff(rate, srate)
    rate = tonumber(rate) or 1
    srate = tonumber(srate) or 48000
    if srate < 1 then srate = 1 end
    if rate < 1 then rate = 1 end
    return 0.45 * srate / rate
  end
  function MATH.xfade_gain(t)
    t = MATH.clamp(tonumber(t) or 0, 0, 1)
    return 1 - t, t
  end
  function MATH.loop_fade_t(pos, frames, fade)
    pos = tonumber(pos) or 0
    frames = tonumber(frames) or 0
    fade = tonumber(fade) or 0
    if fade <= 0 or frames <= 0 then return 0 end
    local start = frames - fade
    if pos < start then return 0 end
    return MATH.clamp((pos - start) / fade, 0, 1)
  end
  function MATH.loop_fade_in_pos(pos, frames, fade)
    return (tonumber(pos) or 0) - (tonumber(frames) or 0) + (tonumber(fade) or 0)
  end
  function MATH.ring_fade_samples(xfade_ms, srate, target_delay)
    local n = math.floor((tonumber(xfade_ms) or 0) * 0.001 * (tonumber(srate) or 1))
    local cap = math.floor((tonumber(target_delay) or 0) * 0.25)
    if n > cap then n = cap end
    if n < 0 then n = 0 end
    return n
  end
  function MATH.delay_frames(ms, srate, ring_len)
    local d = (tonumber(ms) or 80) * 0.001 * (tonumber(srate) or 48000)
    if d < 64 then d = 64 end
    local cap = (tonumber(ring_len) or 1) * 0.4
    if d > cap then d = cap end
    return d
  end
end

-- v0.9.0 sample engine state. Functions are attached later; the table is
-- created here so playrate setters defined above the engine body can call it.
local SE = {
  voices = {},
  playing = false,
  project_rate = 1.0,
  track_rates = {},
  project_pitch = 0.0,
  started_wall = 0,
}

-- v0.8.32: branded ADFX Sound banner with safe right-side padding.
-- v0.8.35: logo ~5% smaller and centered with balanced header padding.
-- v0.8.36: removed the redundant PERFORMANCE heading from the right pane.
-- v0.8.38: package support files into Assets/ and Bridge/ subfolders.
local LOGO_PATH = SCRIPT_DIR .. "Assets" .. SEP .. "ADFX_LOGO_BG_BANNER_CLEAR.png"
local logo_image = nil
if r.file_exists(LOGO_PATH) then
  logo_image = ImGui.CreateImage(LOGO_PATH)
  ImGui.Attach(ctx, logo_image)
end

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function lerp(a, b, t) return a + (b - a) * t end

local function smooth(old, new, amount)
  amount = clamp(amount, 0.0, 0.999)
  return old * amount + new * (1.0 - amount)
end

-- >>> ADFX_GLOBAL_RANGE_CORE_BEGIN
-- v0.8.55 GLOBAL RANGE, cut back to its three useful controls in v0.8.58.
-- One row that restrains every assignment at once, so a fully dialled-in setup
-- can be reined in without walking through each route by hand.
--
--   RANGE    how much of each route's own sweep the pad is allowed to use
--   MIN/MAX  hard limits in normalized parameter space that no route may cross
--
-- The transform is non-destructive. An assignment's stored MIN / CENTER / MAX
-- are never modified; they are reshaped on the way out, inside
-- map_assignment_value(). Returning RANGE to 100% with MIN 0 / MAX 1 restores
-- exactly what was dialled in.
--
-- Everything between these markers is pure: it depends on nothing but its own
-- arguments plus clamp(), so tests/global_range_test.lua lifts this block
-- straight out of this file and exercises the code that actually ships.

-- A single file-level local keeps this feature's footprint at one slot of
-- Lua's 200-locals-per-chunk budget, which this script is well into.
local GR = {}

function GR.new()
  return {
    enabled = false,
    scale   = 1.0, -- 0..2 multiplier on each endpoint's distance from the middle
    floor   = 0.0, -- hard low limit, normalized
    ceiling = 1.0, -- hard high limit, normalized
  }
end

function GR.sanitize(g)
  local out = GR.new()
  if type(g) ~= "table" then return out end

  out.enabled = g.enabled and true or false
  out.scale   = clamp(tonumber(g.scale) or out.scale, 0.0, 2.0)

  local lo = clamp(tonumber(g.floor) or 0.0, 0.0, 1.0)
  local hi = clamp(tonumber(g.ceiling) or 1.0, 0.0, 1.0)
  if lo > hi then lo, hi = hi, lo end
  out.floor, out.ceiling = lo, hi

  return out
end

-- True when the current settings would leave every assignment untouched.
function GR.is_neutral(g)
  if not g or not g.enabled then return true end
  return (tonumber(g.scale) or 1.0) == 1.0
     and (tonumber(g.floor) or 0.0) == 0.0
     and (tonumber(g.ceiling) or 1.0) == 1.0
end

-- Reshape one assignment's MIN / CENTER / MAX.
--
-- Endpoints are scaled toward the middle of the route rather than rebuilt from
-- a span. That keeps reversed routes (MIN > MAX, a legitimate inverted sweep
-- here) pointing the same way, and keeps a bipolar assignment's CENTER
-- consistent with its endpoints instead of drifting away from them.
function GR.transform(min_v, center_v, max_v, centered, g)
  min_v    = tonumber(min_v) or 0.0
  max_v    = tonumber(max_v) or 1.0
  center_v = tonumber(center_v) or 0.5

  if GR.is_neutral(g) then return min_v, center_v, max_v end

  local scale = clamp(tonumber(g.scale) or 1.0, 0.0, 2.0)

  -- The point every endpoint is pulled toward. A bipolar route already has a
  -- meaningful home value, so shrink around that instead of the midpoint.
  local pivot = centered and center_v or (min_v + max_v) * 0.5

  local new_min    = pivot + (min_v - pivot) * scale
  local new_max    = pivot + (max_v - pivot) * scale
  local new_center = pivot + (center_v - pivot) * scale

  local floor_v = clamp(tonumber(g.floor) or 0.0, 0.0, 1.0)
  local ceil_v  = clamp(tonumber(g.ceiling) or 1.0, 0.0, 1.0)
  if floor_v > ceil_v then floor_v, ceil_v = ceil_v, floor_v end

  return clamp(new_min, floor_v, ceil_v),
         clamp(new_center, floor_v, ceil_v),
         clamp(new_max, floor_v, ceil_v)
end

-- Short status line for the section heading, e.g. "40%  0.10-0.90".
function GR.summary(g)
  if not g or not g.enabled then return "OFF" end
  if GR.is_neutral(g) then return "100%  full range" end

  local parts = { string.format("%d%%", math.floor((tonumber(g.scale) or 1.0) * 100 + 0.5)) }
  if (tonumber(g.floor) or 0.0) > 0.0 or (tonumber(g.ceiling) or 1.0) < 1.0 then
    parts[#parts + 1] = string.format("%.2f-%.2f", g.floor, g.ceiling)
  end
  return table.concat(parts, "  ")
end

-- Tab-delimited so it drops straight into both the session state and the
-- preset file without any extra escaping. Fields 3 and 4 are the retired PIVOT
-- and OFFSET slots, still written so a preset saved here loads in a v0.8.57
-- build and vice versa.
function GR.serialize(g)
  g = GR.sanitize(g)
  return string.format("%d\t%.17g\tCENTER\t0\t%.17g\t%.17g",
    g.enabled and 1 or 0, g.scale, g.floor, g.ceiling)
end

function GR.deserialize(s)
  local out = GR.new()
  if type(s) ~= "string" or s == "" then return out end

  local fields = {}
  for token in (s .. "\t"):gmatch("(.-)\t") do fields[#fields + 1] = token end

  out.enabled = fields[1] == "1"
  out.scale   = tonumber(fields[2]) or out.scale
  out.floor   = tonumber(fields[5]) or out.floor
  out.ceiling = tonumber(fields[6]) or out.ceiling
  return GR.sanitize(out)
end

-- Effective range for one assignment under the current settings. `state` is
-- the forward-declared local near the top of the file, so this closes over the
-- same table every other helper uses.
function GR.effective(a)
  return GR.transform(a.min, a.center or 0.5, a.max, a.centered, state.global_range)
end
-- <<< ADFX_GLOBAL_RANGE_CORE_END

local function boolstr(v) return v and "1" or "0" end
local function strbool(v) return v == "1" end

local function track_from_index(idx)
  if idx == -1 then return r.GetMasterTrack(0) end
  if idx and idx >= 0 then return r.GetTrack(0, idx) end
  return nil
end

local function track_name(track)
  if not track then return "(no track)" end
  if track == r.GetMasterTrack(0) then return "MASTER" end
  local _, name = r.GetTrackName(track)
  return name ~= "" and name or "(unnamed track)"
end

local function fx_name(track, fx)
  if not track or fx == nil then return "(no FX)" end
  local ok, name = r.TrackFX_GetFXName(track, fx, "")
  return ok and name or "(invalid FX)"
end

local function param_name(track, fx, param)
  if not track or fx == nil or param == nil then return "(unassigned)" end
  local ok, name = r.TrackFX_GetParamName(track, fx, param, "")
  return ok and name or "(invalid parameter)"
end

local function new_assignment()
  return {
    target_type = "fx_param",
    track_idx = nil, fx = nil, param = nil,
    track_guid = nil, fx_guid = nil,
    min = 0.0, max = 1.0,
    center = 0.5,
    centered = false,
    invert = false, enabled = true,
    use_amplitude = false,
    use_lfo = false,
    lfo_index = 1,
    amplitude_threshold_db = -40.0,
    amplitude_scale = 3.0,
    amplitude_follow_ms = 45.0,
    -- Opt-in: return this lane when the bus INPUT RESPONSE return is
    -- off. When that input return is on, every lane still returns.
    return_on_release = false,
    _amplitude_smoothed = nil,
    _amplitude_last_time = nil
  }
end


local function track_guid(track)
  if not track then return nil end
  if track == r.GetMasterTrack(0) then return "__MASTER__" end
  if not r.GetTrackGUID then return nil end
  local guid = r.GetTrackGUID(track)
  return (guid and guid ~= "") and guid or nil
end

local function fx_guid(track, fx)
  if not track or fx == nil or not r.TrackFX_GetFXGUID then return nil end
  local guid = r.TrackFX_GetFXGUID(track, fx)
  return (guid and guid ~= "") and guid or nil
end

local function find_track_by_guid(guid)
  if not guid or guid == "" then return nil, nil end
  if guid == "__MASTER__" then return r.GetMasterTrack(0), -1 end
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    if track_guid(tr) == guid then return tr, i end
  end
  return nil, nil
end

local function find_fx_by_guid(track, guid)
  if not track or not guid or guid == "" then return nil end
  local count = r.TrackFX_GetCount(track)
  for i = 0, count - 1 do
    if fx_guid(track, i) == guid then return i end
  end
  return nil
end

local function is_project_playrate(a)
  return a and a.target_type == "project_playrate"
end

local function is_track_playrate(a)
  return a and a.target_type == "track_playrate"
end

local function is_sample_pitch(a)
  return a and a.target_type == "sample_pitch"
end

local function is_track_pan(a)
  return a and a.target_type == "track_pan"
end

local function is_track_volume(a)
  return a and a.target_type == "track_volume"
end

local function is_native_track_control(a)
  return is_track_playrate(a) or is_track_pan(a) or is_track_volume(a)
end

local function is_native_control(a)
  return is_project_playrate(a) or is_sample_pitch(a) or is_native_track_control(a)
end

local function is_native_playrate(a)
  return is_project_playrate(a) or is_track_playrate(a)
end

local function playrate_to_normalized(rate)
  rate = tonumber(rate) or 1.0
  if r.Master_NormalizePlayRate then
    return clamp(r.Master_NormalizePlayRate(rate, false), 0, 1)
  end
  -- Conservative fallback matching REAPER's common project-rate range.
  return clamp((rate - 0.25) / 3.75, 0, 1)
end

local function normalized_to_playrate(norm)
  norm = clamp(tonumber(norm) or 0.5, 0, 1)
  if r.Master_NormalizePlayRate then
    return r.Master_NormalizePlayRate(norm, true)
  end
  return 0.25 + norm * 3.75
end

local function set_project_playrate_normalized(norm)
  -- v0.9.0: write the sample-engine master rate, never the project playrate.
  -- CSurf_OnPlayRateChange was the source of the timeline artefacts.
  SE.project_rate = normalized_to_playrate(norm)
  if SE.apply_rates then SE.apply_rates() end
end

local function resolve_track_assignment(a)
  if not a then return nil, nil end
  local tr, tridx
  if a.track_guid and a.track_guid ~= "" then
    tr, tridx = find_track_by_guid(a.track_guid)
  end
  if not tr and a.track_idx ~= nil then
    tr = track_from_index(a.track_idx)
    tridx = a.track_idx
    if tr and not a.track_guid then a.track_guid = track_guid(tr) end
  end
  if tr then
    a.track_idx = tridx
    if not a.track_guid then a.track_guid = track_guid(tr) end
  end
  return tr, tridx
end

local function get_track_playrate(a)
  local tr = resolve_track_assignment(a)
  if not tr then return 1.0 end
  local guid = track_guid(tr)
  if guid and SE.track_rates[guid] then return SE.track_rates[guid] end
  return 1.0
end

local function set_track_playrate_normalized(a, norm)
  local tr = resolve_track_assignment(a)
  if not tr then return end
  local guid = track_guid(tr)
  if not guid then return end
  SE.track_rates[guid] = normalized_to_playrate(norm)
  if SE.apply_rates then SE.apply_rates() end
end

local function set_sample_pitch_normalized(norm)
  SE.project_pitch = MATH.normalized_to_pitch(norm)
  if SE.apply_rates then SE.apply_rates() end
end

local function pan_to_normalized(pan)
  return clamp(((tonumber(pan) or 0.0) + 1.0) * 0.5, 0, 1)
end

local function normalized_to_pan(norm)
  return clamp(tonumber(norm) or 0.5, 0, 1) * 2.0 - 1.0
end

local function volume_to_normalized(vol)
  vol = math.max(tonumber(vol) or 1.0, 0.000000001)
  local db = 20.0 * math.log(vol, 10)
  return clamp((db + 60.0) / 72.0, 0, 1)
end

local function normalized_to_volume(norm)
  local db = -60.0 + clamp(tonumber(norm) or 0.0, 0, 1) * 72.0
  return 10.0 ^ (db / 20.0)
end

local function get_track_pan(a)
  local tr = resolve_track_assignment(a)
  if not tr then return 0.0 end
  return tonumber(r.GetMediaTrackInfo_Value(tr, "D_PAN")) or 0.0
end

local function set_track_pan_normalized(a, norm)
  local tr = resolve_track_assignment(a)
  if not tr then return end
  r.SetMediaTrackInfo_Value(tr, "D_PAN", normalized_to_pan(norm))
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
end

local function get_track_volume(a)
  local tr = resolve_track_assignment(a)
  if not tr then return 1.0 end
  return tonumber(r.GetMediaTrackInfo_Value(tr, "D_VOL")) or 1.0
end

local function set_track_volume_normalized(a, norm)
  local tr = resolve_track_assignment(a)
  if not tr then return end
  r.SetMediaTrackInfo_Value(tr, "D_VOL", normalized_to_volume(norm))
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
end

local function resolve_assignment(a)
  if is_project_playrate(a) or is_sample_pitch(a) then return nil, nil end
  if is_native_track_control(a) then return resolve_track_assignment(a), nil end
  if not a or a.param == nil then return nil, nil end

  local tr, tridx
  if a.track_guid and a.track_guid ~= "" then
    tr, tridx = find_track_by_guid(a.track_guid)
  end
  if not tr and a.track_idx ~= nil then
    tr = track_from_index(a.track_idx)
    tridx = a.track_idx
    if tr and not a.track_guid then a.track_guid = track_guid(tr) end
  end
  if not tr then return nil, nil end

  local fx = a.fx
  if a.fx_guid and a.fx_guid ~= "" then
    -- Fast path: cached index is still the same FX.
    if fx == nil or fx_guid(tr, fx) ~= a.fx_guid then
      fx = find_fx_by_guid(tr, a.fx_guid)
    end
  elseif fx ~= nil then
    a.fx_guid = fx_guid(tr, fx)
  end
  if fx == nil then return nil, nil end

  a.track_idx = tridx
  a.fx = fx
  if not a.track_guid then a.track_guid = track_guid(tr) end
  if not a.fx_guid then a.fx_guid = fx_guid(tr, fx) end
  return tr, fx
end

local function valid_assignment(a)
  if is_project_playrate(a) or is_sample_pitch(a) then return true end
  if is_native_track_control(a) then return resolve_track_assignment(a) ~= nil end
  if not a or a.param == nil then return false end
  local tr, fx = resolve_assignment(a)
  if not tr or fx == nil then return false end
  local count = r.TrackFX_GetNumParams(tr, fx)
  return a.param >= 0 and a.param < count
end

local function assignment_label(a)
  if is_project_playrate(a) then return "ENGINE  •  Sample Rate (all voices)" end
  if is_sample_pitch(a) then return "ENGINE  •  Sample Pitch (all voices)" end
  if is_track_playrate(a) then
    local tr = resolve_track_assignment(a)
    return tr and ("ENGINE  •  " .. track_name(tr) .. "  •  Sample Rate") or "Invalid track-rate assignment"
  end
  if is_track_pan(a) then
    local tr = resolve_track_assignment(a)
    return tr and ("REAPER  •  " .. track_name(tr) .. "  •  Track Pan") or "Invalid track-pan assignment"
  end
  if is_track_volume(a) then
    local tr = resolve_track_assignment(a)
    return tr and ("REAPER  •  " .. track_name(tr) .. "  •  Track Volume") or "Invalid track-volume assignment"
  end
  if not valid_assignment(a) then return "Invalid assignment" end
  local tr = track_from_index(a.track_idx)
  return string.format("%s  •  %s  •  %s",
    track_name(tr), fx_name(tr, a.fx), param_name(tr, a.fx, a.param))
end

local function assignment_param_label(a)
  if is_project_playrate(a) then return "Sample Rate (all voices)" end
  if is_sample_pitch(a) then return "Sample Pitch (all voices)" end
  if is_track_playrate(a) then return "Sample Rate (track voices)" end
  if is_track_pan(a) then return "Track Pan" end
  if is_track_volume(a) then return "Track Volume" end
  if not valid_assignment(a) then return "Invalid assignment" end
  local tr, fx = resolve_assignment(a)
  return param_name(tr, fx, a.param)
end

local function plugin_instance_parts(a)
  if is_project_playrate(a) then return "SAMPLE ENGINE", "ALL VOICES" end
  if is_sample_pitch(a) then return "SAMPLE ENGINE", "ALL VOICES" end
  if is_native_track_control(a) then
    local tr = resolve_track_assignment(a)
    return "REAPER CONTROL", tr and track_name(tr) or "MISSING TRACK"
  end
  if not valid_assignment(a) then return "Invalid plugin instance", "" end
  local tr, fx = resolve_assignment(a)
  return fx_name(tr, fx), track_name(tr)
end

local function plugin_instance_key(a, fallback_index)
  if is_project_playrate(a) then return "__SE_PROJECT_PLAYRATE__" end
  if is_sample_pitch(a) then return "__SE_SAMPLE_PITCH__" end
  if is_native_track_control(a) then
    resolve_track_assignment(a)
    return "__REAPER_TRACK_CONTROL__|" .. tostring(a.track_guid or a.track_idx or fallback_index or 0)
  end
  if a then resolve_assignment(a) end
  if a and a.track_guid and a.fx_guid then
    return a.track_guid .. "|" .. a.fx_guid
  end
  if a and a.track_idx ~= nil and a.fx ~= nil then
    return tostring(a.track_idx) .. "|" .. tostring(a.fx)
  end
  return "invalid|" .. tostring(fallback_index or 0)
end


local function same_target(a, b)
  if is_project_playrate(a) or is_project_playrate(b) then
    return is_project_playrate(a) and is_project_playrate(b)
  end
  if is_sample_pitch(a) or is_sample_pitch(b) then
    return is_sample_pitch(a) and is_sample_pitch(b)
  end
  if is_native_track_control(a) or is_native_track_control(b) then
    if not (is_native_track_control(a) and is_native_track_control(b)) then return false end
    if a.target_type ~= b.target_type then return false end
    resolve_track_assignment(a); resolve_track_assignment(b)
    return (a.track_guid and b.track_guid and a.track_guid == b.track_guid)
      or (a.track_guid == nil and b.track_guid == nil and a.track_idx == b.track_idx)
  end
  return a and b
    and a.track_idx == b.track_idx
    and a.fx == b.fx
    and a.param == b.param
end


local function assignment_current_normalized(a)
  if is_project_playrate(a) then return playrate_to_normalized(SE.project_rate or 1.0) end
  if is_sample_pitch(a) then return MATH.pitch_to_normalized(SE.project_pitch or 0.0) end
  if is_track_playrate(a) then return playrate_to_normalized(get_track_playrate(a)) end
  if is_track_pan(a) then return pan_to_normalized(get_track_pan(a)) end
  if is_track_volume(a) then return volume_to_normalized(get_track_volume(a)) end
  if not valid_assignment(a) then return 0.0 end
  local tr = track_from_index(a.track_idx)
  return r.TrackFX_GetParamNormalized(tr, a.fx, a.param)
end

local function formatted_value_at_normalized(a, norm)
  if is_native_playrate(a) then return string.format("%.3fx", normalized_to_playrate(norm)) end
  if is_sample_pitch(a) then
    local st = MATH.normalized_to_pitch(norm)
    if math.abs(st) < 0.05 then return "0 st" end
    return string.format("%+.1f st", st)
  end
  if is_track_pan(a) then
    local pan = normalized_to_pan(norm)
    if math.abs(pan) < 0.005 then return "CENTER" end
    return pan < 0 and string.format("L %.0f%%", math.abs(pan) * 100.0) or string.format("R %.0f%%", pan * 100.0)
  end
  if is_track_volume(a) then
    local vol = normalized_to_volume(norm)
    local db = 20.0 * math.log(math.max(vol, 0.000000001), 10)
    return string.format("%+.1f dB", db)
  end
  if not valid_assignment(a) then return string.format("%.3f", norm) end
  local tr = track_from_index(a.track_idx)
  norm = clamp(norm, 0, 1)

  -- IMPORTANT v0.4.6:
  -- Never change a parameter merely to format its display value.
  -- TrackFX_SetParamNormalized() can update REAPER's last-touched FX state,
  -- which caused the UI itself to steal Last Touched and made later LEARN
  -- operations repeatedly capture the first assignment.
  --
  -- REAPER provides a non-destructive formatter specifically for a supplied
  -- normalized value.
  if r.TrackFX_FormatParamValueNormalized then
    local ok, txt = r.TrackFX_FormatParamValueNormalized(tr, a.fx, a.param, norm, "")
    if ok and txt and txt ~= "" then return txt end
  end

  -- Fallback: show normalized value. Do NOT mutate the FX to obtain text.
  return string.format("%.4f", norm)
end

set_assignment_preview = function(a, norm)
  if not valid_assignment(a) then return end
  if is_project_playrate(a) then
    set_project_playrate_normalized(norm)
    return
  elseif is_sample_pitch(a) then
    set_sample_pitch_normalized(norm)
    return
  elseif is_track_playrate(a) then
    set_track_playrate_normalized(a, norm)
    return
  elseif is_track_pan(a) then
    set_track_pan_normalized(a, norm)
    return
  elseif is_track_volume(a) then
    set_track_volume_normalized(a, norm)
    return
  end
  local tr = track_from_index(a.track_idx)
  r.TrackFX_SetParamNormalized(tr, a.fx, a.param, clamp(norm, 0, 1))
  mark_self_write(a)
  if SE.gmem_write_mapped then
    SE.gmem_write_mapped(tr, a.fx, a.param, clamp(norm, 0, 1))
  end
end


local function preview_matches(a)
  local p = state.range_preview
  return p.active
    and a
    and ((is_project_playrate(a) and p.target_type == "project_playrate") or
      (is_sample_pitch(a) and p.target_type == "sample_pitch") or
      (is_native_track_control(a) and p.target_type == a.target_type and a.track_idx == p.track_idx) or
      (not is_native_control(a)
    and a.track_idx == p.track_idx
    and a.fx == p.fx
    and a.param == p.param))
end


-- v0.8.58 REC: record the pad's output into FX parameter automation lanes.
--
-- Points are buffered in Lua for the length of the pass and committed to the
-- project only once the transport stops. Nothing touches an envelope while
-- playback is running, which keeps the per-frame capture cheap, keeps the
-- write out of the undo history until there is something worth undoing, and
-- means a pass that is abandoned cannot leave half-written envelopes behind.
--
-- Namespaced under one table for the same reason as GR: Lua allows 200 locals
-- per chunk and this script is well into that budget.
local RC = {}

RC.MIN_INTERVAL = 1.0 / 60.0  -- seconds between points on any one parameter
RC.MIN_DELTA    = 0.0005      -- normalized movement worth its own point
RC.MAX_POINTS   = 200000      -- so a pass left running cannot grow forever

function RC.new()
  return {
    armed  = false, -- the REC button
    active = false, -- a pass is in progress
    lanes  = {},    -- lane key -> { track_idx, fx, param, label, points }
    order  = {},    -- lane keys, in the order they were first touched
    points = 0,
    full   = false, -- MAX_POINTS reached, capture has stopped
    native = 0,     -- routes skipped because they have no FX parameter lane
  }
end

-- Only FX parameters have an FX automation lane. Project playrate, track
-- playrate, pan and volume live on their own envelope types, so they are
-- counted and reported rather than silently dropped.
function RC.can_record(a)
  return a ~= nil
    and not is_native_control(a)
    and a.track_idx ~= nil and a.fx ~= nil and a.param ~= nil
end

function RC.lane_key(a)
  return tostring(a.track_idx) .. "|" .. tostring(a.fx) .. "|" .. tostring(a.param)
end

-- Called from set_assignment() for every value the pad pushes, so it has to
-- stay cheap: one table lookup when no pass is running.
function RC.capture(a, value)
  local rec = state.rec
  if not rec.active or rec.full then return end

  if not RC.can_record(a) then
    rec.native = rec.native + 1
    return
  end

  local t = r.GetPlayPosition()
  if not t then return end

  local key = RC.lane_key(a)
  local lane = rec.lanes[key]
  if not lane then
    lane = { track_idx = a.track_idx, fx = a.fx, param = a.param,
             label = assignment_label(a), points = {} }
    rec.lanes[key] = lane
    rec.order[#rec.order + 1] = key
  end

  -- A point per frame per parameter would be tens of thousands of redundant
  -- points on a held pen. One when the value actually moves is enough; the
  -- envelope interpolates between them. The first point of a lane always
  -- lands, so the envelope starts from where the pad already was.
  local last = lane.points[#lane.points]
  if last then
    local moved = math.abs(value - last.v) >= RC.MIN_DELTA
    local elapsed = t - last.t
    -- A negative elapsed time means the transport looped back on itself.
    if elapsed >= 0 and (elapsed < RC.MIN_INTERVAL or not moved) then return end
  end

  lane.points[#lane.points + 1] = { t = t, v = clamp(value, 0.0, 1.0) }
  rec.points = rec.points + 1
  if rec.points >= RC.MAX_POINTS then
    rec.full = true
    state.status = string.format(
      "REC buffer full at %d points. Stop playback to write what was captured.",
      rec.points)
  end
end

-- Set next to the loop, because apply_input_outputs() is defined much further
-- down the file than this core.
RC.prime_outputs = nil

function RC.begin()
  local rec = state.rec
  rec.active = true
  rec.lanes, rec.order = {}, {}
  rec.points, rec.native, rec.full = 0, 0, false
  state.status = state.armed
    and "REC armed and rolling. Move the pen to record automation."
    or "REC is rolling but the pad is not ARMED, so nothing is being written."

  -- The pad only writes a parameter when its value actually moves, so with the
  -- pen already resting where the last pass left it, a route would contribute
  -- no point until it next changed and the envelope would keep whatever start
  -- value it had before. Push every bus once here so each lane is anchored at
  -- the value the pad is really holding as the pass opens.
  if RC.prime_outputs then RC.prime_outputs() end
end

-- Commit the pass. Every lane is rewritten across exactly the span it was
-- captured over, so recording the same move twice replaces it instead of
-- layering a second set of points on top of the first.
function RC.commit()
  local rec = state.rec
  local lanes, points, failed = 0, 0, 0

  for _, key in ipairs(rec.order) do
    local lane = rec.lanes[key]
    if lane and #lane.points > 0 then
      local tr = track_from_index(lane.track_idx)
      local env = tr and r.GetFXEnvelope(tr, lane.fx, lane.param, true)
      if env then
        local lo, hi = lane.points[1].t, lane.points[1].t
        for _, p in ipairs(lane.points) do
          if p.t < lo then lo = p.t end
          if p.t > hi then hi = p.t end
        end
        r.DeleteEnvelopePointRange(env, lo - 0.000000001, hi + 0.000000001)
        for _, p in ipairs(lane.points) do
          -- FX parameter envelopes hold normalized values, which is the same
          -- domain set_assignment() writes in, so no conversion is needed.
          -- noSortIn is set; the sort happens once per lane below.
          r.InsertEnvelopePoint(env, p.t, p.v, 0, 0.0, false, true)
        end
        r.Envelope_SortPoints(env)
        lanes = lanes + 1
        points = points + #lane.points
      else
        failed = failed + 1
      end
    end
  end

  return lanes, points, failed
end

function RC.finish()
  local rec = state.rec
  rec.active = false

  if rec.points == 0 then
    rec.lanes, rec.order = {}, {}
    state.status = rec.native > 0
      and "REC captured nothing: the assigned routes have no FX parameter lane."
      or "REC captured nothing. Is the pad ARMED, and did the pen move?"
    return
  end

  r.Undo_BeginBlock2(0)
  local lanes, points, failed = RC.commit()
  r.Undo_EndBlock2(0, "ADFX pad: record tablet automation", -1)

  rec.lanes, rec.order = {}, {}
  rec.points, rec.native, rec.full = 0, 0, false

  if lanes == 0 then
    state.status = "REC could not open an automation lane for any assigned parameter."
  else
    state.status = string.format("REC wrote %d point%s to %d automation lane%s.%s",
      points, points == 1 and "" or "s",
      lanes, lanes == 1 and "" or "s",
      failed > 0 and string.format(" %d lane%s unavailable.",
        failed, failed == 1 and "" or "s") or "")
  end

  r.UpdateArrange()
end

-- Drives the pass off the arrange transport, so PLAY / STOP / spacebar
-- (and REAPER's own transport) all record.
function RC.update()
  local rec = state.rec
  local playing = (r.GetPlayState() & 1) == 1

  if rec.armed and playing and not rec.active then
    RC.begin()
  elseif rec.active and (not playing or not rec.armed) then
    RC.finish()
  end
end

local function hold_assignment_preview(a, norm)
  if not valid_assignment(a) then return end
  local p = state.range_preview
  p.active = true
  p.target_type = a.target_type
  p.track_idx = a.track_idx
  p.fx = a.fx
  p.param = a.param
  p.value = clamp(norm, 0, 1)
  set_assignment_preview(a, p.value)
end

clear_range_preview = function()
  state.range_preview.active = false
  state.range_preview.target_type = nil
  state.range_preview.track_idx = nil
  state.range_preview.fx = nil
  state.range_preview.param = nil
end

state = {
  mode = 0,
  smoothing = 0.00, -- retained for compatibility; per-input response is primary
  armed = true,
  pressure = 0.0,
  pressure_gain = 1.0,
  pressure_curve = 2.50, -- 1=linear, >1 softer/slower rise
  follow_ms = 8.0, -- Varispeed Smooth; 0 = apply on the next audio sample
  -- Global Tilt Y polarity. Enabled by default so physical +Y tilt maps to
  -- decreasing normalized TY. This is applied before the TY response engine,
  -- so every Tilt Y assignment sees the same inverted source.
  invert_tilt_y = true,

  -- Per-input response controls.
  -- pickup_attack_time / pickup_release_time: asymmetric live pen-follow glide
  -- while the pen is down. Attack is used when the target is rising; release
  -- is used when the target is falling. This is separate from Return Time.
  -- return_enabled: on pen release, glide to default_value.
  -- return_time: exact duration of that post-release return glide.
  inputs = {
    X  = {value=0.5, default_value=0.5, multiplier=2.0, pickup_attack_time=0.20, pickup_release_time=0.20, return_enabled=false, return_time=1.00},
    Y  = {value=0.5, default_value=0.5, multiplier=2.0, pickup_attack_time=0.20, pickup_release_time=0.20, return_enabled=false, return_time=1.00},
    Z  = {value=0.0, default_value=0.0, multiplier=2.0, pickup_attack_time=0.05, pickup_release_time=0.05, return_enabled=true,  return_time=0.35},
    TX = {value=0.5, default_value=0.5, multiplier=2.0, pickup_attack_time=0.20, pickup_release_time=0.20, return_enabled=true,  return_time=0.50},
    TY = {value=0.5, default_value=0.5, multiplier=2.0, pickup_attack_time=0.20, pickup_release_time=0.20, return_enabled=true,  return_time=0.50},
  },

  -- Transition state is runtime-only.
  input_runtime = {
    pen_was_down = false,
    release_started = false,
    pickup_start_time = 0,
    release_start_time = 0,
    last_update_time = nil,
    pickup_from = {},
    release_from = {},
  },

  last_x = 0.5,
  last_y = 0.5,
  last_p = 0.0,
  last_tx = 0.5,
  last_ty = 0.5,
  freeze_x = false,
  freeze_y = false,

  buses = { X = {}, Y = {}, Z = {}, TX = {}, TY = {} },

  -- v0.8.55: global restraint applied on top of every bus assignment. See the
  -- GLOBAL RANGE core block near the top of this file.
  global_range = GR.new(),

  -- v0.8.58: automation recording. Deliberately not persisted anywhere: an
  -- armed REC that survived a restart would start writing envelopes on the
  -- next playback without anyone having asked for it this session.
  rec = RC.new(),

  -- v0.8.56: performance-column transport. This is a workflow preference
  -- rather than part of a sound, so reset_state_to_empty() and preset loads
  -- deliberately leave it alone.
  transport = { loop_selected_on_play = true, preserve_pitch = false },

  -- v0.8.16 internal modulators. These are Paint Pad input sources rather
  -- than wrappers around REAPER's parameter-modulation LFO. Assignment MIN /
  -- CENTER / MAX defines the modulation range, so a separate depth control is
  -- intentionally unnecessary.
  lfos = {
    {active=false, rate_hz=0.50, shape=0, value=0.5},
    {active=false, rate_hz=1.00, shape=1, value=0.5},
    {active=false, rate_hz=2.00, shape=2, value=0.5},
  },

  -- Legacy v0.8.13 REAPER-LFO state retained only so old presets/session data
  -- can still be read without errors. It is no longer used by the UI/runtime.
  lfo_target = new_assignment(),
  lfo_active = false,
  lfo_rate = 0.35,
  lfo_depth = 0.50,
  lfo_phase = 0.0,
  lfo_shape = 0,

  bridge = {
    connected = false,
    running = false,
    live = false,
    seq = -1,
    heartbeat = -1,
    x = 0.5, y = 0.5, pressure = 0.0,
    tilt_x = 0.0, tilt_y = 0.0,
    tip = false, button1 = false, button2 = false,
    eraser = false,
    contact_hold_until = -1000.0,
    last_seq_change = -1000.0,
    last_heartbeat_change = -1000.0,
    pen_present = nil
  },

  status = "Start the Wacom Bridge, then press on the pad.",

  -- Range audition hold:
  -- MIN/MAX/CENTER edits can otherwise be overwritten later in the same frame
  -- by the live X/Y/Z/Tilt bus output. While active, the selected assignment
  -- stays at the auditioned endpoint until the user touches the Paint Pad.
  range_preview = {
    active = false,
    track_idx = nil,
    fx = nil,
    param = nil,
    value = 0.0
  },

  -- Last-touched protection. Paint Pad writes FX parameters continuously,
  -- which can overwrite REAPER's global last-touched parameter. We sample
  -- external touches before our own writes and LEARN from this cache.
  touch_cache = {
    valid = false,
    track_idx = nil,
    fx = nil,
    param = nil,
    value = 0.0,
    time = 0.0
  },

  -- All Paint Pad-driven parameter writes are tracked briefly so none of
  -- them can pollute REAPER's Last Touched source used by LEARN.
  recent_self_writes = {},

  preset_name = "My Preset",
  preset_index = 0,
  preset_names = {},
  linked_preset = "",
  bridge_launch_requested_at = -1000.0
}


local function shape_pressure(p)
  p = clamp(p, 0, 1)
  local curve = math.max(0.10, state.pressure_curve or 1.0)
  -- 1.0 = linear. Values >1 make the response softer while
  -- still allowing full physical pressure to reach 1.0.
  return clamp((p ^ curve) * state.pressure_gain, 0, 1)
end


local function target_key(track_idx, fx, param)
  return tostring(track_idx) .. ":" .. tostring(fx) .. ":" .. tostring(param)
end

mark_self_write = function(a)
  if not a then return end
  state.recent_self_writes[target_key(a.track_idx, a.fx, a.param)] = r.time_precise()
end

local function was_recent_self_write(track_idx, fx, param, now)
  local key = target_key(track_idx, fx, param)
  local t = state.recent_self_writes[key]
  if not t then return false end
  return (now - t) < 0.35
end

local function prune_recent_self_writes(now)
  for key, t in pairs(state.recent_self_writes) do
    if (now - t) >= 0.50 then
      state.recent_self_writes[key] = nil
    end
  end
end

local function sample_external_last_touched()
  local ok, tridx, itemidx, takeidx, fxidx, parm = r.GetTouchedOrFocusedFX(0)
  if not ok or itemidx ~= -1 then return end

  local tr = track_from_index(tridx)
  if not tr then return end

  local now = r.time_precise()
  prune_recent_self_writes(now)

  -- Ignore ANY parameter that Paint Pad itself has written recently,
  -- not merely the final write of the previous frame.
  if was_recent_self_write(tridx, fxidx, parm, now) then
    return
  end

  local cache = state.touch_cache
  cache.valid = true
  cache.track_idx = tridx
  cache.fx = fxidx
  cache.param = parm
  cache.value = r.TrackFX_GetParamNormalized(tr, fxidx, parm)
  cache.time = now
end

local function get_project_linked_preset()
  local rv, val = r.GetProjExtState(0, PROJECT_LINK_SECTION, "preset")
  if rv == 1 and val and val ~= "" then return val end
  return ""
end

local function set_project_linked_preset(name)
  name = tostring(name or "")
  r.SetProjExtState(0, PROJECT_LINK_SECTION, "preset", name)
  state.linked_preset = name
end

local function current_project_key()
  local guid = ""
  if r.GetProjectGUID then
    guid = r.GetProjectGUID(0) or ""
  end
  if guid == "" then
    -- Unsaved/new projects can still be isolated during this REAPER run.
    guid = tostring(0)
  end
  return guid:gsub("[^%w%-_]", "_")
end

local function session_key(key)
  return current_project_key() .. "::" .. key
end

local function get_session_ext(key, default)
  local val = r.GetExtState(SESSION_SECTION, session_key(key))
  if val ~= nil and val ~= "" then return val end
  return default
end

local function set_session_ext(key, value)
  r.SetExtState(SESSION_SECTION, session_key(key), tostring(value or ""), false)
end

local function ensure_preset_dir()
  if r.RecursiveCreateDirectory then
    r.RecursiveCreateDirectory(PRESET_DIR, 0)
  end
end

local function safe_preset_name(name)
  name = tostring(name or "")
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  name = name:gsub('[<>:"/\\|%?%*]', "_")
  if name == "" then name = "Untitled" end
  return name
end

local function preset_path(name)
  ensure_preset_dir()
  return PRESET_DIR .. package.config:sub(1,1) .. safe_preset_name(name) .. ".sdpp"
end

local function serialize_assignment(a)
  return table.concat({
    tostring(a.track_idx ~= nil and a.track_idx or ""),
    tostring(a.fx ~= nil and a.fx or ""),
    tostring(a.param ~= nil and a.param or ""),
    tostring(a.min or 0),
    tostring(a.max or 1),
    tostring(a.center or 0.5),
    a.centered and "1" or "0",
    a.invert and "1" or "0",
    a.enabled and "1" or "0",
    a.use_amplitude and "1" or "0",
    tostring(a.amplitude_scale or 3.0),
    tostring(a.amplitude_follow_ms or 45.0),
    tostring(a.amplitude_threshold_db or -40.0),
    tostring(a.track_guid or ""),
    tostring(a.fx_guid or ""),
    a.use_lfo and "1" or "0",
    tostring(a.lfo_index or 1),
    tostring(a.target_type or "fx_param"),
    a.return_on_release and "1" or "0"
  }, "\t")
end

local function deserialize_assignment(line)
  local vals = {}
  for token in (line .. "\t"):gmatch("(.-)\t") do vals[#vals+1] = token end
  if #vals < 9 then return nil end
  local a = new_assignment()
  a.track_idx = vals[1] ~= "" and tonumber(vals[1]) or nil
  a.fx = vals[2] ~= "" and tonumber(vals[2]) or nil
  a.param = vals[3] ~= "" and tonumber(vals[3]) or nil
  a.min = tonumber(vals[4]) or 0
  a.max = tonumber(vals[5]) or 1
  a.center = tonumber(vals[6]) or 0.5
  a.centered = vals[7] == "1"
  a.invert = vals[8] == "1"
  a.enabled = vals[9] ~= "0"
  a.use_amplitude = vals[10] == "1"
  a.amplitude_scale = tonumber(vals[11]) or 3.0
  a.amplitude_follow_ms = tonumber(vals[12]) or 45.0
  a.amplitude_threshold_db = tonumber(vals[13]) or -40.0
  a.track_guid = vals[14] ~= "" and vals[14] or nil
  a.fx_guid = vals[15] ~= "" and vals[15] or nil
  a.use_lfo = vals[16] == "1"
  a.lfo_index = clamp(tonumber(vals[17]) or 1, 1, 3)
  a.target_type = (vals[18] ~= "" and vals[18]) or "fx_param"
  a.return_on_release = vals[19] == "1"
  -- Backward compatibility: older presets/session rows only stored indexes.
  -- Resolve once here to capture GUIDs while those indexes are still valid.
  if not is_project_playrate(a) and not is_sample_pitch(a) then resolve_assignment(a) end
  return a
end


local function save_assignment(prefix, a)
  r.SetProjExtState(0, EXT_SECTION, prefix.."_track", a.track_idx ~= nil and tostring(a.track_idx) or "")
  r.SetProjExtState(0, EXT_SECTION, prefix.."_fx", a.fx ~= nil and tostring(a.fx) or "")
  r.SetProjExtState(0, EXT_SECTION, prefix.."_param", a.param ~= nil and tostring(a.param) or "")
  r.SetProjExtState(0, EXT_SECTION, prefix.."_target_type", tostring(a.target_type or "fx_param"))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_min", tostring(a.min))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_max", tostring(a.max))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_center", tostring(a.center or 0.5))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_centered", boolstr(a.centered))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_invert", boolstr(a.invert))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_enabled", boolstr(a.enabled))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_use_amplitude", boolstr(a.use_amplitude))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_use_lfo", boolstr(a.use_lfo))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_lfo_index", tostring(a.lfo_index or 1))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_amplitude_scale", tostring(a.amplitude_scale or 3.0))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_amplitude_follow_ms", tostring(a.amplitude_follow_ms or 45.0))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_amplitude_threshold_db", tostring(a.amplitude_threshold_db or -40.0))
  r.SetProjExtState(0, EXT_SECTION, prefix.."_return_on_release", boolstr(a.return_on_release))
end

local function load_assignment(prefix)
  local a = new_assignment()
  local t = get_ext(prefix.."_track", "")
  local f = get_ext(prefix.."_fx", "")
  local p = get_ext(prefix.."_param", "")
  a.track_idx = t ~= "" and tonumber(t) or nil
  a.fx = f ~= "" and tonumber(f) or nil
  a.param = p ~= "" and tonumber(p) or nil
  a.target_type = get_ext(prefix.."_target_type", "fx_param")
  a.min = tonumber(get_ext(prefix.."_min", "0.0")) or 0.0
  a.max = tonumber(get_ext(prefix.."_max", "1.0")) or 1.0
  a.center = tonumber(get_ext(prefix.."_center", "0.5")) or 0.5
  a.centered = strbool(get_ext(prefix.."_centered", "0"))
  a.invert = strbool(get_ext(prefix.."_invert", "0"))
  a.enabled = strbool(get_ext(prefix.."_enabled", "1"))
  a.use_amplitude = strbool(get_ext(prefix.."_use_amplitude", "0"))
  a.use_lfo = strbool(get_ext(prefix.."_use_lfo", "0"))
  a.lfo_index = clamp(tonumber(get_ext(prefix.."_lfo_index", "1")) or 1, 1, 3)
  a.amplitude_scale = tonumber(get_ext(prefix.."_amplitude_scale", "3.0")) or 3.0
  a.amplitude_follow_ms = tonumber(get_ext(prefix.."_amplitude_follow_ms", "45.0")) or 45.0
  a.amplitude_threshold_db = tonumber(get_ext(prefix.."_amplitude_threshold_db", "-40.0")) or -40.0
  a.return_on_release = strbool(get_ext(prefix.."_return_on_release", "0"))
  return a
end

local function clear_old_bus_storage(bus_name, old_count)
  for i = 1, old_count do
    local prefix = string.format("%s_%d", bus_name, i)
    for _, k in ipairs({"track","fx","param","min","max","center","centered","invert","enabled","use_amplitude","use_lfo","lfo_index","amplitude_scale","amplitude_follow_ms","amplitude_threshold_db","return_on_release"}) do
      r.SetProjExtState(0, EXT_SECTION, prefix.."_"..k, "")
    end
  end
end

local function save_state()
  -- SESSION-ONLY AUTORECALL.
  -- This survives closing/reopening the script during the current REAPER run,
  -- but is intentionally NOT written into the .RPP project file.
  set_session_ext("mode", state.mode)
  set_session_ext("smoothing", state.smoothing)
  set_session_ext("pressure_gain", state.pressure_gain)
  set_session_ext("pressure_curve", state.pressure_curve)
  set_session_ext("follow_ms", state.follow_ms)
  set_session_ext("invert_tilt_y", boolstr(state.invert_tilt_y))

  for _, name in ipairs({"X","Y","Z","TX","TY"}) do
    local cfg = state.inputs[name]
    set_session_ext("input_"..name.."_default", cfg.default_value)
    set_session_ext("input_"..name.."_multiplier", cfg.multiplier)
    set_session_ext("input_"..name.."_pickup_attack", cfg.pickup_attack_time)
    set_session_ext("input_"..name.."_pickup_release", cfg.pickup_release_time)
    -- Keep the legacy key populated so older script builds still have a
    -- sensible single Pickup Glide value if this session is reopened there.
    set_session_ext("input_"..name.."_pickup", cfg.pickup_attack_time)
    set_session_ext("input_"..name.."_return_enabled", boolstr(cfg.return_enabled))
    set_session_ext("input_"..name.."_return_time", cfg.return_time)
  end

  set_session_ext("global_range", GR.serialize(state.global_range))
  set_session_ext("transport_loop_on_play", boolstr(state.transport.loop_selected_on_play))
  set_session_ext("transport_preserve_pitch", boolstr(state.transport.preserve_pitch))

  set_session_ext("lfo_rate", state.lfo_rate)
  set_session_ext("lfo_depth", state.lfo_depth)
  set_session_ext("lfo_phase", state.lfo_phase)
  set_session_ext("lfo_shape", state.lfo_shape)
  set_session_ext("lfo_active", boolstr(state.lfo_active))
  set_session_ext("lfo_target", serialize_assignment(state.lfo_target))
  for i, lfo in ipairs(state.lfos) do
    set_session_ext("internal_lfo_"..i.."_active", boolstr(lfo.active))
    set_session_ext("internal_lfo_"..i.."_rate_hz", tostring(lfo.rate_hz))
    set_session_ext("internal_lfo_"..i.."_shape", tostring(lfo.shape))
  end

  for _, bus_name in ipairs({"X","Y","Z","TX","TY"}) do
    local bus = state.buses[bus_name]
    set_session_ext(bus_name.."_count", #bus)
    for i, a in ipairs(bus) do
      set_session_ext(bus_name.."_"..i, serialize_assignment(a))
    end

    -- Clear stale session rows left over from a previously longer list.
    local old_count = tonumber(get_session_ext(bus_name.."_last_saved_count", "0")) or 0
    for i = #bus + 1, old_count do
      set_session_ext(bus_name.."_"..i, "")
    end
    set_session_ext(bus_name.."_last_saved_count", #bus)
  end

  set_session_ext("has_state", "1")
end

local function reset_state_to_empty()
  state.mode = 0
  state.smoothing = 0.0
  state.pressure = 0.0
  state.pressure_gain = 1.0
  state.pressure_curve = 2.50
  state.follow_ms = 8.0
  state.invert_tilt_y = true

  state.inputs.X  = {value=0.5, default_value=0.5, multiplier=2.0, pickup_attack_time=0.20, pickup_release_time=0.20, return_enabled=false, return_time=1.00}
  state.inputs.Y  = {value=0.5, default_value=0.5, multiplier=2.0, pickup_attack_time=0.20, pickup_release_time=0.20, return_enabled=false, return_time=1.00}
  state.inputs.Z  = {value=0.0, default_value=0.0, multiplier=2.0, pickup_attack_time=0.05, pickup_release_time=0.05, return_enabled=true,  return_time=0.35}
  state.inputs.TX = {value=0.5, default_value=0.5, multiplier=2.0, pickup_attack_time=0.20, pickup_release_time=0.20, return_enabled=true,  return_time=0.50}
  state.inputs.TY = {value=0.5, default_value=0.5, multiplier=2.0, pickup_attack_time=0.20, pickup_release_time=0.20, return_enabled=true,  return_time=0.50}

  state.buses = {X={}, Y={}, Z={}, TX={}, TY={}}
  state.global_range = GR.new()
  state.lfo_target = new_assignment()
  state.lfo_active = false
  state.lfo_rate = 0.35
  state.lfo_depth = 0.50
  state.lfo_phase = 0.0
  state.lfo_shape = 0
  state.lfos = {
    {active=false, rate_hz=0.50, shape=0, value=0.5},
    {active=false, rate_hz=1.00, shape=1, value=0.5},
    {active=false, rate_hz=2.00, shape=2, value=0.5},
  }

  state.range_preview.active = false
  state.touch_cache.valid = false
  state.status = "Empty configuration."
  sync_last_fields_from_inputs()
end

local function load_state()
  -- Smart behavior:
  -- * Same REAPER run/project => recall session snapshot.
  -- * Fresh REAPER run but project is linked to a preset => auto-load preset.
  -- * Brand-new/unlinked project => start empty.
  state.linked_preset = get_project_linked_preset()
  if state.linked_preset ~= "" then state.preset_name = state.linked_preset end

  if get_session_ext("has_state", "") ~= "1" then
    if state.linked_preset ~= "" then
      -- load_preset_from_disk is defined later, so startup linked-preset load
      -- is deferred via state.pending_linked_preset.
      reset_state_to_empty()
      state.pending_linked_preset = state.linked_preset
      state.status = "Linked preset pending: " .. state.linked_preset
      return
    end
    reset_state_to_empty()
    return
  end

  -- v0.8.15 always operates the tablet buses directly. Old MOD mode is
  -- migrated automatically because modulators now live per assignment.
  state.mode = 0
  state.smoothing = tonumber(get_session_ext("smoothing", "0")) or 0
  state.pressure_gain = tonumber(get_session_ext("pressure_gain", "1.0")) or 1.0
  state.pressure_curve = tonumber(get_session_ext("pressure_curve", "2.50")) or 2.50
  state.follow_ms = tonumber(get_session_ext("follow_ms", "8")) or 8.0
  if state.follow_ms < 0 then state.follow_ms = 0 end
  if state.follow_ms > 40 then state.follow_ms = 40 end
  state.invert_tilt_y = strbool(get_session_ext("invert_tilt_y", "1"))
  local legacy_input_multiplier = tonumber(get_session_ext("input_multiplier", "2.0")) or 2.0

  for _, name in ipairs({"X","Y","Z","TX","TY"}) do
    local cfg = state.inputs[name]
    cfg.default_value = tonumber(get_session_ext("input_"..name.."_default", tostring(cfg.default_value))) or cfg.default_value
    cfg.multiplier = tonumber(get_session_ext("input_"..name.."_multiplier", tostring(legacy_input_multiplier))) or legacy_input_multiplier
    local legacy_pickup = tonumber(get_session_ext("input_"..name.."_pickup", tostring(cfg.pickup_attack_time))) or cfg.pickup_attack_time
    cfg.pickup_attack_time = tonumber(get_session_ext("input_"..name.."_pickup_attack", tostring(legacy_pickup))) or legacy_pickup
    cfg.pickup_release_time = tonumber(get_session_ext("input_"..name.."_pickup_release", tostring(legacy_pickup))) or legacy_pickup
    cfg.return_enabled = strbool(get_session_ext("input_"..name.."_return_enabled", boolstr(cfg.return_enabled)))
    cfg.return_time = tonumber(get_session_ext("input_"..name.."_return_time", tostring(cfg.return_time))) or cfg.return_time
  end

  -- Absent in pre-v0.8.55 sessions, which deserializes to a neutral, disabled
  -- GLOBAL RANGE so older sessions sound exactly as they did.
  state.global_range = GR.deserialize(get_session_ext("global_range", ""))
  state.transport.loop_selected_on_play =
    strbool(get_session_ext("transport_loop_on_play", "1"))
  state.transport.preserve_pitch =
    strbool(get_session_ext("transport_preserve_pitch", "0"))

  state.lfo_rate = tonumber(get_session_ext("lfo_rate", "0.35")) or 0.35
  state.lfo_depth = tonumber(get_session_ext("lfo_depth", "0.5")) or 0.5
  state.lfo_phase = tonumber(get_session_ext("lfo_phase", "0.0")) or 0.0
  state.lfo_shape = tonumber(get_session_ext("lfo_shape", "0")) or 0
  state.lfo_active = strbool(get_session_ext("lfo_active", "0"))
  for i, lfo in ipairs(state.lfos) do
    lfo.active = strbool(get_session_ext("internal_lfo_"..i.."_active", boolstr(lfo.active)))
    lfo.rate_hz = clamp(tonumber(get_session_ext("internal_lfo_"..i.."_rate_hz", tostring(lfo.rate_hz))) or lfo.rate_hz, 0.01, 20.0)
    lfo.shape = clamp(math.floor(tonumber(get_session_ext("internal_lfo_"..i.."_shape", tostring(lfo.shape))) or lfo.shape), 0, 4)
  end

  local lfo_line = get_session_ext("lfo_target", "")
  if lfo_line ~= "" then
    state.lfo_target = deserialize_assignment(lfo_line) or new_assignment()
  else
    state.lfo_target = new_assignment()
  end

  for _, bus_name in ipairs({"X","Y","Z","TX","TY"}) do
    state.buses[bus_name] = {}
    local count = tonumber(get_session_ext(bus_name.."_count", "0")) or 0
    for i = 1, count do
      local line = get_session_ext(bus_name.."_"..i, "")
      local a = line ~= "" and deserialize_assignment(line) or nil
      if a then table.insert(state.buses[bus_name], a) end
    end
  end

  for _, name in ipairs({"X","Y","Z","TX","TY"}) do
    state.inputs[name].value = clamp(state.inputs[name].default_value, 0, 1)
  end
  sync_last_fields_from_inputs()
  state.status = "Session configuration recalled."
end

local function save_preset_to_disk(name)
  name = safe_preset_name(name)
  local path = preset_path(name)
  local f = io.open(path, "w")
  if not f then
    state.status = "Could not save preset: " .. path
    return false
  end

  -- v5 adds the globalrange line. Older builds skip unrecognised lines, so a
  -- v5 preset still loads there, just without the global restraint.
  f:write("SDPP_PRESET\t5\n")
  f:write("mode\t"..tostring(state.mode).."\n")
  f:write("globalrange\t"..GR.serialize(state.global_range).."\n")
  f:write("pressure_gain\t"..tostring(state.pressure_gain).."\n")
  f:write("pressure_curve\t"..tostring(state.pressure_curve).."\n")
  f:write("invert_tilt_y\t"..tostring(state.invert_tilt_y and 1 or 0).."\n")

  for _, n in ipairs({"X","Y","Z","TX","TY"}) do
    local c = state.inputs[n]
    f:write(string.format("input\t%s\t%.17g\t%.17g\t%.17g\t%d\t%.17g\t%.17g\n",
      n, c.default_value, c.pickup_attack_time, c.pickup_release_time,
      c.return_enabled and 1 or 0, c.return_time, c.multiplier or 1.0))
  end

  for _, bus_name in ipairs({"X","Y","Z","TX","TY"}) do
    for _, a in ipairs(state.buses[bus_name]) do
      f:write("route\t"..bus_name.."\t"..serialize_assignment(a).."\n")
    end
  end

  -- Keep the legacy line for backwards readability, then persist the new
  -- internal LFOs independently.
  f:write("lfo\t"..serialize_assignment(state.lfo_target).."\t"..
    tostring(state.lfo_active and 1 or 0).."\t"..
    tostring(state.lfo_rate).."\t"..
    tostring(state.lfo_depth).."\t"..
    tostring(state.lfo_phase).."\t"..
    tostring(state.lfo_shape).."\n")
  for i, lfo in ipairs(state.lfos) do
    f:write(string.format("modulator\t%d\t%d\t%.17g\t%d\n",
      i, lfo.active and 1 or 0, lfo.rate_hz, lfo.shape))
  end

  f:close()
  state.preset_name = name
  set_project_linked_preset(name)
  save_state()
  state.status = "Preset saved and linked to project: " .. name
  return true
end

local function load_preset_from_disk(name)
  name = safe_preset_name(name)
  local path = preset_path(name)
  local f = io.open(path, "r")
  if not f then
    state.status = "Preset not found: " .. name
    return false
  end

  reset_state_to_empty()
  local preset_version = 1

  for line in f:lines() do
    if line:match("^SDPP_PRESET\t") then
      preset_version = tonumber(line:match("^SDPP_PRESET\t(%d+)")) or 1

    elseif line:match("^mode\t") then
      state.mode = tonumber(line:match("^mode\t(.+)$")) or 0

    elseif line:match("^pressure_gain\t") then
      state.pressure_gain = tonumber(line:match("^pressure_gain\t(.+)$")) or 1.0

    elseif line:match("^pressure_curve\t") then
      state.pressure_curve = tonumber(line:match("^pressure_curve\t(.+)$")) or 2.5

    elseif line:match("^invert_tilt_y\t") then
      state.invert_tilt_y = line:match("^invert_tilt_y\t(.+)$") ~= "0"

    elseif line:match("^globalrange\t") then
      state.global_range = GR.deserialize(line:match("^globalrange\t(.+)$"))

    elseif line:match("^input_multiplier\t") then
      -- v0.6.5 compatibility: remember old global multiplier and apply it
      -- to input records that do not contain their own multiplier.
      state._legacy_preset_multiplier = tonumber(line:match("^input_multiplier\t(.+)$")) or 1.0

    elseif line:match("^input\t") then
      local parts = {}
      for token in (line .. "\t"):gmatch("(.-)\t") do parts[#parts+1] = token end
      local n = parts[2]
      if n and state.inputs[n] then
        local c = state.inputs[n]
        c.default_value = tonumber(parts[3]) or c.default_value
        if preset_version >= 3 then
          c.pickup_attack_time = tonumber(parts[4]) or c.pickup_attack_time
          c.pickup_release_time = tonumber(parts[5]) or c.pickup_release_time
          c.return_enabled = parts[6] == "1"
          c.return_time = tonumber(parts[7]) or c.return_time
          c.multiplier = tonumber(parts[8]) or state._legacy_preset_multiplier or 1.0
        else
          -- v1/v2 had one Pickup Glide value. Migrate it to both sides.
          local legacy_pickup = tonumber(parts[4]) or c.pickup_attack_time
          c.pickup_attack_time = legacy_pickup
          c.pickup_release_time = legacy_pickup
          c.return_enabled = parts[5] == "1"
          c.return_time = tonumber(parts[6]) or c.return_time
          c.multiplier = tonumber(parts[7]) or state._legacy_preset_multiplier or 1.0
        end
        c.value = c.default_value
      end

    elseif line:match("^route\t") then
      local bus_name, rest = line:match("^route\t([^\t]+)\t(.+)$")
      if bus_name and state.buses[bus_name] then
        local a = deserialize_assignment(rest)
        if a then table.insert(state.buses[bus_name], a) end
      end

    elseif line:match("^modulator\t") then
      local idx, active, rate, shape = line:match("^modulator\t(%d+)\t(%d+)\t([^\t]+)\t(%d+)$")
      idx = tonumber(idx)
      if idx and state.lfos[idx] then
        state.lfos[idx].active = active == "1"
        state.lfos[idx].rate_hz = clamp(tonumber(rate) or state.lfos[idx].rate_hz, 0.01, 20.0)
        state.lfos[idx].shape = clamp(tonumber(shape) or state.lfos[idx].shape, 0, 4)
      end

    elseif line:match("^lfo\t") then
      local payload = line:sub(5)
      local fields = {}
      for token in (payload .. "\t"):gmatch("(.-)\t") do fields[#fields+1] = token end
      if #fields >= 15 then
        local assignment_field_count
        if #fields >= 19 then
          assignment_field_count = 13 -- accept v0.8.9 presets; threshold field is ignored
        elseif #fields >= 18 then
          assignment_field_count = 12 -- v0.8.4+: amplitude flag + scale + follow time
        elseif #fields >= 17 then
          assignment_field_count = 11 -- v0.8.3: amplitude flag + amplitude scale
        elseif #fields >= 16 then
          assignment_field_count = 10 -- v0.8.2: amplitude flag
        else
          assignment_field_count = 9  -- older presets
        end
        local assignment_fields = {}
        for i = 1, assignment_field_count do assignment_fields[#assignment_fields+1] = fields[i] end
        local assignment_line = table.concat(assignment_fields, "\t")
        state.lfo_target = deserialize_assignment(assignment_line) or new_assignment()

        local base = assignment_field_count + 1
        state.lfo_active = fields[base] == "1"
        state.lfo_rate = tonumber(fields[base + 1]) or 0.35
        state.lfo_depth = tonumber(fields[base + 2]) or 0.5
        state.lfo_phase = tonumber(fields[base + 3]) or 0.0
        state.lfo_shape = tonumber(fields[base + 4]) or 0
      end
    end
  end

  f:close()
  state._legacy_preset_multiplier = nil
  sync_last_fields_from_inputs()
  state.preset_name = name
  set_project_linked_preset(name)
  save_state() -- loaded preset becomes session snapshot for this project
  state.status = "Preset loaded and linked to project: " .. name
  return true
end

local function list_presets()
  ensure_preset_dir()
  local out = {}
  local i = 0
  while true do
    local fn = r.EnumerateFiles(PRESET_DIR, i)
    if not fn then break end
    if fn:lower():sub(-5) == ".sdpp" then
      out[#out+1] = fn:sub(1, -6)
    end
    i = i + 1
  end
  table.sort(out, function(a,b) return a:lower() < b:lower() end)
  return out
end

local function delete_preset_from_disk(name)
  name = safe_preset_name(name)
  local path = preset_path(name)
  local ok, err = os.remove(path)
  if not ok then
    state.status = "Could not delete preset: " .. name .. (err and (" (" .. tostring(err) .. ")") or "")
    return false
  end

  if state.linked_preset == name then
    set_project_linked_preset("")
  end
  if state.preset_name == name then
    state.preset_name = "Untitled"
  end

  state.status = "Preset deleted: " .. name
  return true
end


local function capture_last_touched(bus_name)
  local tridx, fxidx, parm, current

  if state.touch_cache.valid then
    tridx = state.touch_cache.track_idx
    fxidx = state.touch_cache.fx
    parm = state.touch_cache.param
    current = state.touch_cache.value
  else
    -- Fallback for the first learn before the cache has seen a user touch.
    local ok, t, itemidx, takeidx, f, p = r.GetTouchedOrFocusedFX(0)
    if not ok then return nil, "No user-touched FX parameter found." end
    if itemidx ~= -1 then
      return nil, "v0.5.8 currently supports track/master FX, not take FX."
    end

    local now = r.time_precise()
    if was_recent_self_write(t, f, p, now) then
      return nil, "Touch the desired plugin parameter again, then click + LEARN."
    end

    tridx, fxidx, parm = t, f, p
    local tr = track_from_index(tridx)
    if not tr then return nil, "Could not resolve touched track." end
    current = r.TrackFX_GetParamNormalized(tr, fxidx, parm)
  end

  local tr = track_from_index(tridx)
  if not tr then return nil, "Could not resolve cached touched track." end

  -- Refresh current value at the moment of learning, but keep the cached
  -- parameter identity so Paint Pad routing cannot steal the destination.
  current = r.TrackFX_GetParamNormalized(tr, fxidx, parm)

  local a = new_assignment()
  a.track_idx, a.fx, a.param = tridx, fxidx, parm
  a.track_guid = track_guid(tr)
  a.fx_guid = fx_guid(tr, fxidx)
  a.center = current

  if bus_name == "X" or bus_name == "Y" or bus_name == "TX" or bus_name == "TY" then
    a.centered = true
    a.min = 0.0
    a.max = 1.0
  else
    a.centered = false
    a.min = current
    a.max = 1.0
  end

  return a
end

local function find_project_playrate_assignment()
  for existing_bus_name, existing_bus in pairs(state.buses) do
    for i, existing in ipairs(existing_bus) do
      if is_project_playrate(existing) then
        return existing_bus_name, i, existing
      end
    end
  end
  return nil, nil, nil
end

local function find_fx_param_assignment(track_guid_to_find, fx_guid_to_find, param)
  if not track_guid_to_find or not fx_guid_to_find or param == nil then
    return nil, nil, nil
  end
  for existing_bus_name, existing_bus in pairs(state.buses) do
    for i, existing in ipairs(existing_bus) do
      if existing and not is_native_control(existing) then
        resolve_assignment(existing)
        if existing.track_guid == track_guid_to_find
            and existing.fx_guid == fx_guid_to_find
            and existing.param == param then
          return existing_bus_name, i, existing
        end
      end
    end
  end
  return nil, nil, nil
end

-- Insert ADFX Varispeed on the selected track (or reuse the first instance)
-- and LEARN its Rate or Pitch slider onto this bus.
local function add_varispeed_param_to_bus(bus_name, param, label)
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    state.status = "Select a track first, then click + " .. label .. "."
    return
  end
  if not SE.ensure_installed or not SE.ensure_installed() then
    state.status = "Could not find ADFX_Varispeed.jsfx. Put it next to this script, or in an effects subfolder."
    return
  end
  local fx = SE.ensure_jsfx(tr, 0)
  if fx == nil then
    state.status = "Could not add ADFX Varispeed to the selected track."
    return
  end

  local tr_guid = track_guid(tr)
  local fxg = fx_guid(tr, fx)
  local existing_bus_name, existing_index = find_fx_param_assignment(tr_guid, fxg, param)
  if existing_bus_name then
    state.status = string.format(
      "%s on '%s' is already assigned to %s assignment %02d.",
      label, track_name(tr), existing_bus_name, existing_index)
    return
  end

  local current = r.TrackFX_GetParamNormalized(tr, fx, param)
  local a = new_assignment()
  a.target_type = "fx_param"
  a.track_idx = math.floor((r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") or 1) - 1)
  a.fx = fx
  a.param = param
  a.track_guid = tr_guid
  a.fx_guid = fxg
  a.center = current
  if bus_name == "X" or bus_name == "Y" or bus_name == "TX" or bus_name == "TY" then
    a.centered = true
    if param == SE.P_RATE then
      a.min = MATH.playrate_to_normalized(0.25)
      a.max = MATH.playrate_to_normalized(2.0)
    else
      a.min = MATH.pitch_to_normalized(-12)
      a.max = MATH.pitch_to_normalized(12)
    end
  else
    a.centered = false
    a.min = current
    if param == SE.P_RATE then
      a.max = MATH.playrate_to_normalized(2.0)
    else
      a.max = MATH.pitch_to_normalized(12)
    end
  end
  table.insert(state.buses[bus_name], a)
  state.status = string.format("%s assignment %d added: %s  •  %s",
    bus_name, #state.buses[bus_name], track_name(tr), label)
  save_state()
end

local function add_project_playrate_to_bus(bus_name)
  add_varispeed_param_to_bus(bus_name, SE.P_RATE, "ADFX Varispeed Rate")
end

local function find_sample_pitch_assignment()
  for existing_bus_name, existing_bus in pairs(state.buses) do
    for i, existing in ipairs(existing_bus) do
      if is_sample_pitch(existing) then
        return existing_bus_name, i, existing
      end
    end
  end
  return nil, nil, nil
end

local function add_sample_pitch_to_bus(bus_name)
  add_varispeed_param_to_bus(bus_name, SE.P_PITCH, "ADFX Varispeed Pitch")
end

local function find_track_playrate_assignment(track_guid_to_find)
  if not track_guid_to_find or track_guid_to_find == "" then return nil, nil, nil end
  for existing_bus_name, existing_bus in pairs(state.buses) do
    for i, existing in ipairs(existing_bus) do
      if is_track_playrate(existing) then
        resolve_track_assignment(existing)
        if existing.track_guid == track_guid_to_find then
          return existing_bus_name, i, existing
        end
      end
    end
  end
  return nil, nil, nil
end

local function add_track_playrate_to_bus(bus_name)
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    state.status = "Select a track first, then click + TRACK RATE."
    return
  end

  local tr_guid = track_guid(tr)
  local existing_bus_name, existing_index = find_track_playrate_assignment(tr_guid)
  if existing_bus_name then
    local name = track_name(tr)
    local message = string.format(
      "Track Rate can only be assigned once per track.\n\n'%s' already has Track Rate assigned to %s assignment %02d.\n\nRemove that assignment before assigning Track Rate for this track elsewhere.",
      name, existing_bus_name, existing_index)
    state.status = string.format(
      "Track Rate denied: %s is already assigned to %s assignment %02d.",
      name, existing_bus_name, existing_index)
    r.MB(message, "Track Rate Already Assigned", 0)
    return
  end

  local current = playrate_to_normalized(get_track_playrate({track_guid=tr_guid, track_idx=r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") - 1}))
  local a = new_assignment()
  a.target_type = "track_playrate"
  a.track_guid = tr_guid
  a.track_idx = math.floor((r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") or 1) - 1)
  a.center = current
  if bus_name == "X" or bus_name == "Y" or bus_name == "TX" or bus_name == "TY" then
    a.centered = true
    a.min = playrate_to_normalized(0.25)
    a.max = playrate_to_normalized(2.0)
  else
    a.centered = false
    a.min = current
    a.max = playrate_to_normalized(2.0)
  end
  table.insert(state.buses[bus_name], a)
  state.status = string.format("%s assignment %d added: %s Sample Rate", bus_name, #state.buses[bus_name], track_name(tr))
  save_state()
end

local function find_track_control_assignment(target_type, track_guid_to_find)
  if not track_guid_to_find or track_guid_to_find == "" then return nil, nil, nil end
  for existing_bus_name, existing_bus in pairs(state.buses) do
    for i, existing in ipairs(existing_bus) do
      if existing and existing.target_type == target_type then
        resolve_track_assignment(existing)
        if existing.track_guid == track_guid_to_find then
          return existing_bus_name, i, existing
        end
      end
    end
  end
  return nil, nil, nil
end

local function add_track_pan_to_bus(bus_name)
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    state.status = "Select a track first, then click + TRACK PAN."
    return
  end
  local tr_guid = track_guid(tr)
  local existing_bus_name, existing_index = find_track_control_assignment("track_pan", tr_guid)
  if existing_bus_name then
    local name = track_name(tr)
    local message = string.format(
      "Track Pan can only be assigned once per track.\n\n'%s' already has Track Pan assigned to %s assignment %02d.\n\nRemove that assignment before assigning Track Pan for this track elsewhere.",
      name, existing_bus_name, existing_index)
    state.status = string.format("Track Pan denied: %s is already assigned to %s assignment %02d.", name, existing_bus_name, existing_index)
    r.MB(message, "Track Pan Already Assigned", 0)
    return
  end
  local idx = math.floor((r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") or 1) - 1)
  local current = pan_to_normalized(r.GetMediaTrackInfo_Value(tr, "D_PAN"))
  local a = new_assignment()
  a.target_type, a.track_guid, a.track_idx = "track_pan", tr_guid, idx
  a.centered, a.min, a.center, a.max = true, 0.0, current, 1.0
  table.insert(state.buses[bus_name], a)
  state.status = string.format("%s assignment %d added: %s Track Pan", bus_name, #state.buses[bus_name], track_name(tr))
  save_state()
end

local function add_track_volume_to_bus(bus_name)
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    state.status = "Select a track first, then click + TRACK VOL."
    return
  end
  local tr_guid = track_guid(tr)
  local existing_bus_name, existing_index = find_track_control_assignment("track_volume", tr_guid)
  if existing_bus_name then
    local name = track_name(tr)
    local message = string.format(
      "Track Volume can only be assigned once per track.\n\n'%s' already has Track Volume assigned to %s assignment %02d.\n\nRemove that assignment before assigning Track Volume for this track elsewhere.",
      name, existing_bus_name, existing_index)
    state.status = string.format("Track Volume denied: %s is already assigned to %s assignment %02d.", name, existing_bus_name, existing_index)
    r.MB(message, "Track Volume Already Assigned", 0)
    return
  end
  local idx = math.floor((r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") or 1) - 1)
  local current = volume_to_normalized(r.GetMediaTrackInfo_Value(tr, "D_VOL"))
  local a = new_assignment()
  a.target_type, a.track_guid, a.track_idx = "track_volume", tr_guid, idx
  a.centered, a.min, a.center, a.max = true, 0.0, current, 1.0
  table.insert(state.buses[bus_name], a)
  state.status = string.format("%s assignment %d added: %s Track Volume", bus_name, #state.buses[bus_name], track_name(tr))
  save_state()
end

local function learn_into_bus(bus_name)
  local a, err = capture_last_touched(bus_name)
  if not a then state.status = err; return end

  -- Guard against accidentally learning the exact same target repeatedly.
  -- A single parameter can still be assigned to different buses, but within
  -- one bus duplicate routes are almost always an indication that Last Touched
  -- did not change as expected.
  for i, existing in ipairs(state.buses[bus_name]) do
    if same_target(existing, a) then
      state.status = string.format(
        "%s already contains this target as assignment %02d: %s",
        bus_name, i, assignment_label(a))
      return
    end
  end

  table.insert(state.buses[bus_name], a)
  state.status = string.format("%s assignment %d added: %s",
    bus_name, #state.buses[bus_name], assignment_label(a))
  save_state()
end

local function learn_lfo_target()
  local a, err = capture_last_touched("Z")
  if not a then state.status = err; return end
  state.lfo_target = a
  state.status = "LFO target learned: " .. assignment_label(a)
  save_state()
end

local function show_envelope(a)
  if is_native_control(a) then
    if is_project_playrate(a) then
      state.status = "Sample Rate is a sample-engine control and has no FX envelope."
    elseif is_sample_pitch(a) then
      state.status = "Sample Pitch is a sample-engine control and has no FX envelope."
    elseif is_track_playrate(a) then
      state.status = "Track Sample Rate is a sample-engine control and has no FX envelope."
    elseif is_track_pan(a) then
      state.status = "Track Pan is a native REAPER track control and has no FX envelope in Sound Design Pad."
    else
      state.status = "Track Volume is a native REAPER track control and has no FX envelope in Sound Design Pad."
    end
    return
  end
  if not valid_assignment(a) then state.status = "Assignment is invalid."; return end
  local tr = track_from_index(a.track_idx)
  local env = r.GetFXEnvelope(tr, a.fx, a.param, true)
  if not env then state.status = "Could not create/show envelope."; return end
  r.GetSetEnvelopeInfo_String(env, "ACTIVE", "1", true)
  r.GetSetEnvelopeInfo_String(env, "VISIBLE", "1", true)
  r.GetSetEnvelopeInfo_String(env, "SHOWLANE", "1", true)
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
  state.status = "Envelope shown: " .. param_name(tr, a.fx, a.param)
end

local function map_assignment_value(a, norm)
  local t = clamp(norm, 0, 1)
  if a.invert then t = 1 - t end

  -- v0.8.55: every bus, LFO, amplitude and preview write reaches a parameter
  -- through here, so GLOBAL RANGE only has to be applied at this one point.
  local min_v, center_v, max_v = GR.effective(a)

  local v
  if a.centered then
    local center = clamp(center_v, 0, 1)
    if t <= 0.5 then
      v = lerp(min_v, center, t * 2.0)
    else
      v = lerp(center, max_v, (t - 0.5) * 2.0)
    end
  else
    v = lerp(min_v, max_v, t)
  end

  return clamp(v, 0, 1)
end

local function assignment_input_peak(a)
  if not valid_assignment(a) then return 0.0 end
  local tr = track_from_index(a.track_idx)
  if not tr or not r.Track_GetPeakInfo then return 0.0 end
  local left = tonumber(r.Track_GetPeakInfo(tr, 0)) or 0.0
  local right = tonumber(r.Track_GetPeakInfo(tr, 1)) or 0.0
  return math.max(left, right)
end

local function assignment_amplitude_raw(a)
  -- Threshold is evaluated against the RAW host-track peak before any
  -- amplitude modifiers. Below threshold the source target is 0.0, which
  -- maps to this assignment's MIN value. At/above threshold the signal
  -- qualifies for USE AMPLITUDE, then AMP SCALE is applied and FOLLOW MS
  -- smooths that normalized target.
  local raw = assignment_input_peak(a)

  local threshold_db = clamp(tonumber(a.amplitude_threshold_db) or -40.0, -80.0, 0.0)
  local threshold_amp = 10.0 ^ (threshold_db / 20.0)
  if raw < threshold_amp then
    return 0.0
  end

  local scale = math.max(0.0, tonumber(a.amplitude_scale) or 3.0)
  return clamp(raw * scale, 0.0, 1.0)
end

local function assignment_threshold_meter_pos(a)
  -- The output meter is in the post-scale normalized domain, so convert the
  -- raw dB threshold through AMP SCALE for a useful visual marker.
  local threshold_db = clamp(tonumber(a.amplitude_threshold_db) or -40.0, -80.0, 0.0)
  local threshold_amp = 10.0 ^ (threshold_db / 20.0)
  local scale = math.max(0.0, tonumber(a.amplitude_scale) or 3.0)
  return clamp(threshold_amp * scale, 0.0, 1.0)
end

local function assignment_amplitude(a, now)
  local target = assignment_amplitude_raw(a)
  now = now or r.time_precise()
  local follow_ms = math.max(0.0, tonumber(a.amplitude_follow_ms) or 45.0)

  if follow_ms <= 0.0 or a._amplitude_smoothed == nil or a._amplitude_last_time == nil then
    a._amplitude_smoothed = target
    a._amplitude_last_time = now
    return target
  end

  local dt = math.max(0.0, now - a._amplitude_last_time)
  a._amplitude_last_time = now
  local tau = follow_ms / 1000.0
  local alpha = 1.0 - math.exp(-dt / math.max(tau, 0.000001))
  a._amplitude_smoothed = lerp(a._amplitude_smoothed, target, clamp(alpha, 0.0, 1.0))
  return clamp(a._amplitude_smoothed, 0.0, 1.0)
end

local function set_assignment(a, norm)
  if not state.armed or not a.enabled or not valid_assignment(a) then return end

  -- Do not let the live bus overwrite a range audition while its slider
  -- is actively being manipulated.
  if preview_matches(a) then return end

  local mapped = map_assignment_value(a, norm)
  if is_project_playrate(a) then
    set_project_playrate_normalized(mapped)
  elseif is_sample_pitch(a) then
    set_sample_pitch_normalized(mapped)
  elseif is_track_playrate(a) then
    set_track_playrate_normalized(a, mapped)
  elseif is_track_pan(a) then
    set_track_pan_normalized(a, mapped)
  elseif is_track_volume(a) then
    set_track_volume_normalized(a, mapped)
  else
    local tr = track_from_index(a.track_idx)
    r.TrackFX_SetParamNormalized(tr, a.fx, a.param, mapped)
    mark_self_write(a)
    if SE.gmem_write_mapped then
      SE.gmem_write_mapped(tr, a.fx, a.param, mapped)
    end
  end

  -- Every live value the pad pushes passes through here, whatever drove it, so
  -- this is the one place REC has to listen.
  RC.capture(a, mapped)
end

local function restore_assignment_to_input_default(a, bus_name)
  if not valid_assignment(a) then return end
  local cfg = state.inputs[bus_name]
  if not cfg then return end

  clear_range_preview()

  local input_default = clamp(cfg.default_value or 0, 0, 1)
  local mapped = map_assignment_value(a, input_default)
  if is_project_playrate(a) then
    set_project_playrate_normalized(mapped)
  elseif is_sample_pitch(a) then
    set_sample_pitch_normalized(mapped)
  elseif is_track_playrate(a) then
    set_track_playrate_normalized(a, mapped)
  elseif is_track_pan(a) then
    set_track_pan_normalized(a, mapped)
  elseif is_track_volume(a) then
    set_track_volume_normalized(a, mapped)
  else
    local tr = track_from_index(a.track_idx)
    r.TrackFX_SetParamNormalized(tr, a.fx, a.param, mapped)
    mark_self_write(a)
    if SE.gmem_write_mapped then
      SE.gmem_write_mapped(tr, a.fx, a.param, mapped)
    end
  end

  state.status = string.format(
    "%s range saved • returned to input default %.3f (%s)",
    bus_name,
    input_default,
    formatted_value_at_normalized(a, mapped)
  )
end

local function internal_lfo_value(lfo, now)
  now = now or r.time_precise()
  local hz = clamp(tonumber(lfo.rate_hz) or 1.0, 0.01, 20.0)
  local phase = (now * hz) % 1.0
  local shape = math.floor(tonumber(lfo.shape) or 0)

  if shape == 1 then
    -- Triangle: 0 -> 1 -> 0.
    return phase < 0.5 and (phase * 2.0) or (2.0 - phase * 2.0)
  elseif shape == 2 then
    -- Square.
    return phase < 0.5 and 1.0 or 0.0
  elseif shape == 3 then
    -- Ramp UP: 0 -> 1, then reset.
    return phase
  elseif shape == 4 then
    -- Ramp Down: 1 -> 0, then reset.
    return 1.0 - phase
  end

  -- Sine, normalized to 0..1.
  return 0.5 + 0.5 * math.sin((phase * math.pi * 2.0) - (math.pi * 0.5))
end

local function assignment_lfo_value(a)
  local idx = clamp(math.floor(tonumber(a.lfo_index) or 1), 1, #state.lfos)
  local lfo = state.lfos[idx]
  return lfo and clamp(lfo.value or 0.5, 0.0, 1.0) or 0.5
end

set_bus = function(bus_name, norm)
  for _, a in ipairs(state.buses[bus_name]) do
    -- Autonomous sources own the route while selected. Tablet input should not
    -- momentarily overwrite an LFO route when the pen moves.
    if not a.use_lfo then
      local source_norm = a.use_amplitude and assignment_amplitude(a) or norm
      set_assignment(a, source_norm)
    end
  end
end

local function update_modulator_assignments()
  local now = r.time_precise()
  for _, lfo in ipairs(state.lfos) do
    lfo.value = internal_lfo_value(lfo, now)
  end

  for _, bus_name in ipairs({"X","Y","Z","TX","TY"}) do
    for _, a in ipairs(state.buses[bus_name]) do
      if a.use_lfo then
        local idx = clamp(math.floor(tonumber(a.lfo_index) or 1), 1, #state.lfos)
        local lfo = state.lfos[idx]
        if lfo and lfo.active then
          set_assignment(a, lfo.value)
        end
      end
    end
  end
end

local function update_amplitude_assignments()
  -- Amplitude-driven routes must update continuously, even when the pen is not
  -- touching the tablet and the normal input response engine is retaining data.
  local now = r.time_precise()
  for _, bus_name in ipairs({"X","Y","Z","TX","TY"}) do
    for _, a in ipairs(state.buses[bus_name]) do
      if a.use_amplitude and not a.use_lfo then
        set_assignment(a, assignment_amplitude(a, now))
      end
    end
  end
end

local function cfg_set(a, suffix, value)
  if not valid_assignment(a) then return false end
  local tr = track_from_index(a.track_idx)
  return r.TrackFX_SetNamedConfigParm(tr, a.fx,
    string.format("param.%d.%s", a.param, suffix), tostring(value))
end

local function cfg_get(a, suffix)
  if not valid_assignment(a) then return nil end
  local tr = track_from_index(a.track_idx)
  local ok, value = r.TrackFX_GetNamedConfigParm(tr, a.fx,
    string.format("param.%d.%s", a.param, suffix))
  return ok and value or nil
end

apply_lfo = function()
  if not valid_assignment(state.lfo_target) then return end
  cfg_set(state.lfo_target, "mod.active", 1)
  cfg_set(state.lfo_target, "mod.visible", 1)
  cfg_set(state.lfo_target, "lfo.active", state.lfo_active and 1 or 0)
  cfg_set(state.lfo_target, "lfo.speed", clamp(state.lfo_rate, 0, 1))
  cfg_set(state.lfo_target, "lfo.strength", clamp(state.lfo_depth, 0, 1))
  cfg_set(state.lfo_target, "lfo.phase", clamp(state.lfo_phase, 0, 1))
  cfg_set(state.lfo_target, "lfo.shape", math.floor(state.lfo_shape))
end

local function sync_lfo_from_reaper()
  if not valid_assignment(state.lfo_target) then return end
  local a = cfg_get(state.lfo_target, "lfo.active")
  local s = cfg_get(state.lfo_target, "lfo.speed")
  local d = cfg_get(state.lfo_target, "lfo.strength")
  local p = cfg_get(state.lfo_target, "lfo.phase")
  local sh = cfg_get(state.lfo_target, "lfo.shape")
  if a then state.lfo_active = tonumber(a) == 1 end
  if s then state.lfo_rate = tonumber(s) or state.lfo_rate end
  if d then state.lfo_depth = tonumber(d) or state.lfo_depth end
  if p then state.lfo_phase = tonumber(p) or state.lfo_phase end
  if sh then state.lfo_shape = tonumber(sh) or state.lfo_shape end
end

local INPUT_NAMES = {"X","Y","Z","TX","TY"}

local function apply_input_multiplier(name, value)
  local cfg = state.inputs[name]
  if not cfg then return clamp(value, 0, 1) end
  local pivot = clamp(cfg.default_value or 0, 0, 1)
  local mult = math.max(0, cfg.multiplier or 1.0)
  return clamp(pivot + (value - pivot) * mult, 0, 1)
end


sync_last_fields_from_inputs = function()
  state.last_x  = state.inputs.X.value
  state.last_y  = state.inputs.Y.value
  state.last_p  = state.inputs.Z.value
  state.last_tx = state.inputs.TX.value
  state.last_ty = state.inputs.TY.value
end

local function begin_pickup_transition(now)
  local rt = state.input_runtime
  rt.pickup_start_time = now
  rt.release_started = false
  for _, name in ipairs(INPUT_NAMES) do
    rt.pickup_from[name] = state.inputs[name].value
  end
end

local function begin_release_transition(now)
  local rt = state.input_runtime
  rt.release_start_time = now
  rt.release_started = true
  for _, name in ipairs(INPUT_NAMES) do
    rt.release_from[name] = state.inputs[name].value
  end
end

local function apply_input_outputs()
  set_bus("X",  apply_input_multiplier("X",  state.inputs.X.value))
  set_bus("Y",  apply_input_multiplier("Y",  state.inputs.Y.value))
  set_bus("Z",  apply_input_multiplier("Z",  state.inputs.Z.value))
  set_bus("TX", apply_input_multiplier("TX", state.inputs.TX.value))
  set_bus("TY", apply_input_multiplier("TY", state.inputs.TY.value))
  sync_last_fields_from_inputs()
end

local function update_input_response(pen_down, targets, now)
  local rt = state.input_runtime

  if pen_down and state.range_preview.active then
    clear_range_preview()
  end

  if pen_down and not rt.pen_was_down then
    begin_pickup_transition(now)
  elseif (not pen_down) and rt.pen_was_down then
    begin_release_transition(now)
  end

  local changed_inputs = {}

  if pen_down then
    local dt = rt.last_update_time and math.max(0, now - rt.last_update_time) or 0
    for _, name in ipairs(INPUT_NAMES) do
      local cfg = state.inputs[name]
      local old_value = cfg.value
      local target = clamp(targets[name] or cfg.value, 0, 1)

      -- Pickup Glide is now an asymmetric, frame-rate-independent live follow.
      -- ATTACK handles rising tablet values; RELEASE handles falling values.
      -- This occurs only while the pen is down and is intentionally separate
      -- from RETURN TIME, which begins only after pen-up.
      local glide_time = target >= old_value
        and math.max(0, cfg.pickup_attack_time or 0)
        or math.max(0, cfg.pickup_release_time or 0)
      local alpha = glide_time <= 0 and 1.0
        or (1.0 - math.exp(-dt / glide_time))
      cfg.value = lerp(old_value, target, clamp(alpha, 0, 1))

      if math.abs(cfg.value - old_value) > 0.0000001 then
        changed_inputs[name] = true
      end
    end

  else
    for _, name in ipairs(INPUT_NAMES) do
      local cfg = state.inputs[name]

      if cfg.return_enabled then
        if not rt.release_started then begin_release_transition(now) end

        local old_value = cfg.value
        local t = cfg.return_time <= 0 and 1.0
          or clamp((now - rt.release_start_time) / cfg.return_time, 0, 1)

        local from = rt.release_from[name] or cfg.value
        cfg.value = lerp(from, clamp(cfg.default_value, 0, 1), t)

        if math.abs(cfg.value - old_value) > 0.0000001 then
          changed_inputs[name] = true
        end
      else
        -- Input return off: the bus value holds. Lanes that opted into
        -- RETURN TO RELEASE still glide home on this input's RETURN TIME.
        if not rt.release_started then begin_release_transition(now) end
        local t = cfg.return_time <= 0 and 1.0
          or clamp((now - rt.release_start_time) / cfg.return_time, 0, 1)
        local from = rt.release_from[name] or cfg.value
        local lane_norm = apply_input_multiplier(name,
          lerp(from, clamp(cfg.default_value, 0, 1), t))
        for _, a in ipairs(state.buses[name] or {}) do
          if a.return_on_release and not a.use_lfo and not a.use_amplitude then
            set_assignment(a, lane_norm)
          end
        end
      end
    end
  end

  rt.pen_was_down = pen_down
  rt.last_update_time = now

  if state.mode == 0 then
    for name, _ in pairs(changed_inputs) do
      set_bus(name, apply_input_multiplier(name, state.inputs[name].value))
    end
    sync_last_fields_from_inputs()
  else
    local mod_changed = changed_inputs.X or changed_inputs.Y
    if mod_changed then
      state.lfo_rate = apply_input_multiplier("X", state.inputs.X.value)
      state.lfo_depth = apply_input_multiplier("Y", state.inputs.Y.value)
      apply_lfo()
    end
    sync_last_fields_from_inputs()
  end
end



-- Bridge ---------------------------------------------------------------

function BR.read_text(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local txt = f:read("*a")
  f:close()
  return txt
end

function BR.pen_info()
  -- nil = unknown (bridge has never written info), true/false = last probe.
  local txt = BR.read_text(BR.INFO)
  if not txt then return nil end
  if txt:find("pen=0", 1, true) then return false end
  if txt:find("pen=1", 1, true) then return true end
  return nil
end

function BR.parse_line(line)
  -- seq,x,y,pressure,tiltx,tilty,tip,b1,b2,eraser[,heartbeat]
  local vals = {}
  for token in line:gmatch("[^,]+") do vals[#vals+1] = token end
  if #vals < 10 then return false end

  local seq = tonumber(vals[1])
  if not seq then return false end

  local b = state.bridge
  local hb = tonumber(vals[11])
  local now = r.time_precise()

  -- First read after the pad opens is leftover temp from a previous run.
  -- Do not treat that snapshot as LIVE/READY.
  if not BR.primed then
    BR.baseline_seq = seq
    BR.baseline_hb = hb
    BR.primed = true
    b.seq = seq
    if hb then b.heartbeat = hb end
  else
    if seq ~= b.seq then
      b.seq = seq
      if seq ~= BR.baseline_seq then
        b.last_seq_change = now
        BR.baseline_seq = seq
      end
    end
    if hb and hb ~= b.heartbeat then
      b.heartbeat = hb
      if hb ~= BR.baseline_hb then
        b.last_heartbeat_change = now
        BR.baseline_hb = hb
      end
    end
  end

  b.x = clamp(tonumber(vals[2]) or b.x, 0, 1)
  b.y = clamp(tonumber(vals[3]) or b.y, 0, 1)
  b.pressure = clamp(tonumber(vals[4]) or 0, 0, 1)
  b.tilt_x = clamp(tonumber(vals[5]) or 0, -1, 1)
  b.tilt_y = clamp(tonumber(vals[6]) or 0, -1, 1)
  b.tip = tonumber(vals[7]) == 1
  b.button1 = tonumber(vals[8]) == 1
  b.button2 = tonumber(vals[9]) == 1
  b.eraser = tonumber(vals[10]) == 1
  return true
end

function BR.poll_heartbeat()
  local txt = BR.read_text(BR.HEARTBEAT)
  if not txt then return end
  local hb = tonumber(txt:match("%d+"))
  if not hb then return end
  local b = state.bridge
  if not BR.primed then
    BR.baseline_hb = hb
    BR.primed = true
    b.heartbeat = hb
    return
  end
  if hb ~= b.heartbeat then
    b.heartbeat = hb
    if hb ~= BR.baseline_hb then
      b.last_heartbeat_change = r.time_precise()
      BR.baseline_hb = hb
    end
  end
end

function BR.refresh_flags()
  local b = state.bridge
  local now = r.time_precise()
  local starting = now - (state.bridge_launch_requested_at or -1000.0) < 5.0
  -- seq only increments on real pen packets. Heartbeats reuse the last seq.
  b.live = (b.seq or 0) > 0 and (now - (b.last_seq_change or -1000.0)) < 1.5
  b.running = starting
    or ((b.heartbeat or -1) >= 0 and (now - (b.last_heartbeat_change or -1000.0)) < 1.5)
  b.connected = b.live
  b.pen_present = BR.pen_info()
end

function BR.poll()
  local now = r.time_precise()
  if now - BR.poll_last < 0.008 then return end -- max ~125 Hz file polling
  BR.poll_last = now

  local line = BR.read_text(BR.STATE)
  if line then BR.parse_line(line:match("[^\r\n]+") or line) end
  BR.poll_heartbeat()
  BR.primed = true
  BR.refresh_flags()
end

function BR.write_rect(sx, sy, pad_w, pad_h)
  local now = r.time_precise()
  if now - BR.rect_write_last < 0.03 then return end
  BR.rect_write_last = now

  local f = io.open(BR.RECT, "w")
  if not f then return end
  f:write(string.format("%d,%d,%d,%d,1",
    math.floor(sx + 0.5), math.floor(sy + 0.5),
    math.floor(pad_w + 0.5), math.floor(pad_h + 0.5)))
  f:close()
end

function BR.has_fresh_heartbeat()
  local b = state.bridge
  return (b.heartbeat or -1) >= 0
    and (r.time_precise() - (b.last_heartbeat_change or -1000.0)) < 1.5
end

function BR.clear_stop_file()
  os.remove(BR.STOP)
end

function BR.launch_hidden()
  local launcher = BR.BAT
  if launcher == "" or not r.file_exists(launcher) then
    launcher = BR.PS1
  end
  if launcher == "" or not r.file_exists(launcher) then
    return false, "Bridge launcher not found beside the Lua script."
  end

  BR.clear_stop_file()

  -- Detach with start.exe. reaper.ExecProcess can reap a resident
  -- PowerShell overlay as soon as its timeout hits, which looks like a
  -- flashing console and an immediate OFFLINE.
  os.execute(string.format('start /min "" "%s"', launcher))
  return true
end

function BR.start()
  BR.poll()
  if BR.has_fresh_heartbeat() then
    state.status = "Wacom Bridge is already running."
    return
  end

  local now = r.time_precise()
  if now - (state.bridge_launch_requested_at or -1000.0) < 5.0 then
    state.status = "Wacom Bridge start is already in progress."
    return
  end

  state.bridge_launch_requested_at = now
  local ok, err = BR.launch_hidden()
  if not ok then
    state.bridge_launch_requested_at = -1000.0
    state.status = err or "Bridge launcher not found beside the Lua script."
    return
  end
  state.status = "Wacom Bridge starting. Hover the pen over the Paint Pad."
end

function BR.stop()
  local f = io.open(BR.STOP, "w")
  if f then
    f:write("stop")
    f:close()
    state.bridge_launch_requested_at = -1000.0
    state.bridge.running = false
    state.bridge.live = false
    state.bridge.connected = false
    state.status = "Wacom Bridge stop requested."
  else
    state.status = "Could not write bridge stop request."
  end
end

function BR.deactivate_overlay()
  local f = io.open(BR.RECT, "w")
  if f then f:write("0,0,1,1,0"); f:close() end
  BR.stop()
end

-- UI -------------------------------------------------------------------

local function draw_assignment_row(bus_name, index, a)
  ImGui.PushID(ctx, bus_name .. tostring(index))
  -- v0.8.23: assignment rows live inside a plugin-instance group.
  ImGui.Indent(ctx, 24)
  local changed, c = false, false

  c, a.enabled = ImGui.Checkbox(ctx, "##enabled", a.enabled); changed = changed or c
  -- v0.8.48: make the parameter/control title a strong visual anchor.
  -- This applies to FX parameter names and native targets such as RATE/PAN/VOLUME.
  ImGui.SameLine(ctx)
  ImGui.PushFont(ctx, assignment_title_font, 20)
  -- v0.8.50: single-pass title rendering keeps the larger green label sharp.
  local title_text = assignment_param_label(a)
  ImGui.TextColored(ctx, 0x45D483FF, title_text)
  ImGui.PopFont(ctx)
  if not is_native_control(a) then
    ImGui.SameLine(ctx); if ImGui.SmallButton(ctx, "ENV") then show_envelope(a) end
  end
  ImGui.SameLine(ctx); local remove = ImGui.SmallButton(ctx, "REMOVE")

  -- v0.8.55: report what the pad will actually reach. With GLOBAL RANGE at
  -- 100% these are the dialled-in values; below that they are the restrained
  -- ones, which is the number worth reading while performing.
  local eff_min, eff_center, eff_max = GR.effective(a)
  local min_text = formatted_value_at_normalized(a, eff_min)
  local max_text = formatted_value_at_normalized(a, eff_max)
  local center_text = formatted_value_at_normalized(a, eff_center)

  -- Assignment details are nested farther beneath the assignment header.
  ImGui.Indent(ctx, 36)
  ImGui.TextDisabled(ctx, "MAPPING")
  ImGui.SameLine(ctx)

  c, a.centered = ImGui.Checkbox(ctx, "CENTERED / BIPOLAR", a.centered)
  if c then
    changed = true
    if a.centered then
      -- When switching an existing route to centered mode, capture the
      -- parameter's present value as the center so it does not jump.
      a.center = assignment_current_normalized(a)
    else
      -- Switching to FROM CURRENT makes the present value the new MIN.
      a.min = assignment_current_normalized(a)
    end
  end

  ImGui.SameLine(ctx)
  -- v0.8.20: active autonomous input-source toggles use green frames so
  -- the source currently driving the assignment is obvious at a glance.
  local amplitude_was_active = a.use_amplitude
  if amplitude_was_active then
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,        0x247A45FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x2F9858FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,  0x36AD65FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark,      0xFFFFFFFF)
  end
  if is_project_playrate(a) or is_sample_pitch(a) then
    a.use_amplitude = false
    ImGui.TextDisabled(ctx, "AMPLITUDE N/A")
    c = false
  else
    c, a.use_amplitude = ImGui.Checkbox(ctx, "USE AMPLITUDE", a.use_amplitude)
  end
  if amplitude_was_active then ImGui.PopStyleColor(ctx, 4) end
  if c then
    changed = true
    if a.use_amplitude then a.use_lfo = false end
    state.status = a.use_amplitude
      and ("Amplitude input enabled: " .. assignment_label(a))
      or ("Tablet input restored: " .. assignment_label(a))
  end

  ImGui.SameLine(ctx)
  local lfo_was_active = a.use_lfo
  if lfo_was_active then
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,        0x247A45FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x2F9858FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,  0x36AD65FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark,      0xFFFFFFFF)
  end
  c, a.use_lfo = ImGui.Checkbox(ctx, "USE LFO", a.use_lfo)
  if lfo_was_active then ImGui.PopStyleColor(ctx, 4) end
  if c then
    changed = true
    if a.use_lfo then a.use_amplitude = false end
    state.status = a.use_lfo
      and (string.format("LFO %d input enabled: %s", a.lfo_index or 1, assignment_label(a)))
      or ("Tablet input restored: " .. assignment_label(a))
  end

  ImGui.SameLine(ctx)
  local return_was_active = a.return_on_release
  if return_was_active then
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,        0x247A45FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x2F9858FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,  0x36AD65FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark,      0xFFFFFFFF)
  end
  c, a.return_on_release = ImGui.Checkbox(ctx, "RETURN TO RELEASE", a.return_on_release == true)
  if return_was_active then ImGui.PopStyleColor(ctx, 4) end
  if c then
    changed = true
    state.status = a.return_on_release
      and ("Return to release enabled: " .. assignment_label(a))
      or ("Return to release off — follows INPUT RESPONSE for " .. bus_name)
  end
  if ImGui.IsItemHovered(ctx) then
    local input_on = state.inputs[bus_name] and state.inputs[bus_name].return_enabled
    ImGui.SetTooltip(ctx,
      "Off (default): this lane follows INPUT RESPONSE.\n" ..
      "If RETURN ON RELEASE is on for " .. bus_name .. ", the lane returns with the bus.\n\n" ..
      "On: this lane returns when you lift the pen even if that input's\n" ..
      "return is off. Same RETURN TIME and default as INPUT RESPONSE.\n\n" ..
      (input_on and (bus_name .. " return is on — every lane returns.")
        or (bus_name .. " return is off — only checked lanes return.")))
  end

  ImGui.SameLine(ctx)
  if a.centered then
    ImGui.Text(ctx, min_text .. "  ←  " .. center_text .. "  →  " .. max_text)
  else
    ImGui.Text(ctx, min_text .. "  →  " .. max_text)
  end
  if not GR.is_neutral(state.global_range) then
    -- Say why the readout differs from the MIN / MAX sliders below it.
    ImGui.SameLine(ctx)
    ImGui.TextColored(ctx, 0x45D483FF, string.format("GLOBAL %d%%",
      math.floor(state.global_range.scale * 100 + 0.5)))
  end

  if a.use_lfo then
    ImGui.TextDisabled(ctx, "SOURCE")
    ImGui.SameLine(ctx)
    for lfo_i = 1, #state.lfos do
      if lfo_i > 1 then ImGui.SameLine(ctx) end
      local selected = (a.lfo_index == lfo_i)
      local label = string.format("LFO %d%s##route_lfo_%d", lfo_i, selected and " *" or "", lfo_i)
      -- v0.8.17: the LFO currently feeding this assignment is green.
      -- Unselected source buttons retain the normal Paint Pad blue styling.
      if selected then
        ImGui.PushStyleColor(ctx, ImGui.Col_Button,        0x247A45FF)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0x2F9858FF)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,  0x36AD65FF)
      end
      local pressed = ImGui.SmallButton(ctx, label)
      if selected then ImGui.PopStyleColor(ctx, 3) end
      if pressed then
        a.lfo_index = lfo_i
        changed = true
        state.status = string.format("Assignment source set to LFO %d: %s", lfo_i, assignment_label(a))
      end
    end
    ImGui.SameLine(ctx)
    local lfo = state.lfos[clamp(a.lfo_index or 1, 1, #state.lfos)]
    ImGui.TextDisabled(ctx, string.format("LIVE %.3f", lfo and (lfo.value or 0.5) or 0.5))
  end

  local threshold_active = false
  if a.use_amplitude then
    -- v0.8.12: keep the three amplitude controls together on their own
    -- compact row, leaving the right side of the assignment open for the
    -- meter. While THRESHOLD is held, the meter switches to the untouched
    -- host-track input (pre threshold / scale / follow).
    ImGui.SetNextItemWidth(ctx, 58)
    c, a.amplitude_threshold_db = ImGui.DragDouble(ctx, "THRESHOLD", a.amplitude_threshold_db or -40.0, 1.0, -80.0, 0.0, "%.0f dB")
    if c then changed = true end
    threshold_active = ImGui.IsItemActive(ctx)

    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 48)
    c, a.amplitude_scale = ImGui.DragDouble(ctx, "AMP SCALE", a.amplitude_scale or 3.0, 0.05, 0.0, 20.0, "%.2f")
    if c then changed = true end

    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 53)
    c, a.amplitude_follow_ms = ImGui.DragDouble(ctx, "FOLLOW MS", a.amplitude_follow_ms or 45.0, 5.0, 0.0, 5000.0, "%.0f ms")
    if c then changed = true end

    ImGui.SameLine(ctx)
    if threshold_active then
      local raw = math.max(assignment_input_peak(a), 0.0000001)
      local raw_db = 20.0 * (math.log(raw) / math.log(10.0))
      local meter_db = clamp(raw_db, -80.0, 0.0)
      local meter_pos = clamp((meter_db + 80.0) / 80.0, 0.0, 1.0)
      ImGui.ProgressBar(ctx, meter_pos, 285, 16, string.format("INPUT %.1f dB", raw_db))
      local mx1, my1 = ImGui.GetItemRectMin(ctx)
      local mx2, my2 = ImGui.GetItemRectMax(ctx)
      local threshold_db = clamp(tonumber(a.amplitude_threshold_db) or -40.0, -80.0, 0.0)
      local marker_x = mx1 + (mx2 - mx1) * ((threshold_db + 80.0) / 80.0)
      local dl = ImGui.GetWindowDrawList(ctx)
      ImGui.DrawList_AddLine(dl, marker_x, my1 - 2, marker_x, my2 + 2, 0xFFFFFFFF, 2.0)
    else
      local amp_output = clamp(a._amplitude_smoothed or 0.0, 0.0, 1.0)
      ImGui.ProgressBar(ctx, amp_output, 285, 16, string.format("OUTPUT %.3f", amp_output))
      local mx1, my1 = ImGui.GetItemRectMin(ctx)
      local mx2, my2 = ImGui.GetItemRectMax(ctx)
      local marker_x = mx1 + (mx2 - mx1) * assignment_threshold_meter_pos(a)
      local dl = ImGui.GetWindowDrawList(ctx)
      ImGui.DrawList_AddLine(dl, marker_x, my1 - 2, marker_x, my2 + 2, 0xFFFFFFFF, 2.0)
    end
  end

  -- v0.8.21: range/value controls are indented one more level beneath
  -- MAPPING/SOURCE so the adjustable value block reads as a distinct child
  -- section of the assignment, matching the visual hierarchy in the UI.
  ImGui.Indent(ctx, 40)
  local live_norm = assignment_current_normalized(a)
  local live_text = formatted_value_at_normalized(a, live_norm)
  ImGui.TextDisabled(ctx, "LIVE " .. live_text)

  if a.centered then
    ImGui.SetNextItemWidth(ctx, 185)
    c, a.center = ImGui.SliderDouble(ctx, "CENTER", a.center, 0.0, 1.0, "%.4f")
    if c then
      changed = true
      -- Audition the endpoint the pad will really reach under GLOBAL RANGE.
      local _, preview_center = GR.effective(a)
      hold_assignment_preview(a, preview_center)
      state.status = "Preview CENTER: " .. formatted_value_at_normalized(a, preview_center)
    end
    if ImGui.IsItemDeactivatedAfterEdit(ctx) then
      restore_assignment_to_input_default(a, bus_name)
    end
  end

  ImGui.SetNextItemWidth(ctx, 185)
  c, a.min = ImGui.SliderDouble(ctx, "MIN", a.min, 0.0, 1.0, "%.4f")
  if c then
    changed = true
    local preview_min = GR.effective(a)
    hold_assignment_preview(a, preview_min)
    state.status = "Preview MIN: " .. formatted_value_at_normalized(a, preview_min)
  end
  if ImGui.IsItemDeactivatedAfterEdit(ctx) then
    restore_assignment_to_input_default(a, bus_name)
  end

  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 185)
  c, a.max = ImGui.SliderDouble(ctx, "MAX", a.max, 0.0, 1.0, "%.4f")
  if c then
    changed = true
    local _, _, preview_max = GR.effective(a)
    hold_assignment_preview(a, preview_max)
    state.status = "Preview MAX: " .. formatted_value_at_normalized(a, preview_max)
  end
  if ImGui.IsItemDeactivatedAfterEdit(ctx) then
    restore_assignment_to_input_default(a, bus_name)
  end

  ImGui.SameLine(ctx)
  c, a.invert = ImGui.Checkbox(ctx, "INV", a.invert); changed = changed or c
  ImGui.Unindent(ctx, 40) -- range/value controls

  ImGui.Unindent(ctx, 36) -- assignment details
  if changed then save_state() end
  ImGui.Unindent(ctx, 24) -- assignment header
  ImGui.PopID(ctx)
  return remove
end

local function draw_bus(bus_name, display_name)
  local bus = state.buses[bus_name]
  ImGui.Separator(ctx)

  -- v1.0: fixed assignment-row grid.  Every bus uses the same X coordinates,
  -- regardless of whether the visible label is short (X BUS) or long (TILT Y BUS).
  -- No vertical divider lines: this is spacing/alignment only.
  local row_x = ImGui.GetCursorPosX(ctx)
  local col_label        = row_x
  local col_count        = row_x + 56
  local col_learn        = row_x + 140
  local col_sample_rate  = row_x + 205
  local col_sample_pitch = row_x + 310
  local col_track_pan    = row_x + 420
  local col_track_vol    = row_x + 505
  local col_clear        = row_x + 590

  ImGui.SetCursorPosX(ctx, col_label)
  ImGui.PushFont(ctx, input_heading_font, 18)
  ImGui.Text(ctx, display_name)
  ImGui.PopFont(ctx)

  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, col_count)
  ImGui.TextDisabled(ctx, tostring(#bus))

  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, col_learn)
  if ImGui.SmallButton(ctx, "+ LEARN##"..bus_name) then learn_into_bus(bus_name) end

  -- v0.9.3: SAMPLE RATE / SAMPLE PITCH insert ADFX Varispeed on the
  -- selected track and LEARN Rate or Pitch. One of each per plugin.
  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, col_sample_rate)
  if ImGui.SmallButton(ctx, "+ SAMPLE RATE##"..bus_name) then add_project_playrate_to_bus(bus_name) end

  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, col_sample_pitch)
  if ImGui.SmallButton(ctx, "+ SAMPLE PITCH##"..bus_name) then add_sample_pitch_to_bus(bus_name) end

  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, col_track_pan)
  if ImGui.SmallButton(ctx, "+ TRACK PAN##"..bus_name) then add_track_pan_to_bus(bus_name) end

  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, col_track_vol)
  if ImGui.SmallButton(ctx, "+ TRACK VOL##"..bus_name) then add_track_volume_to_bus(bus_name) end

  if #bus > 0 then
    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx, col_clear)
    if ImGui.SmallButton(ctx, "CLEAR ALL##"..bus_name) then
      state.buses[bus_name] = {}
      state.status = display_name .. " assignments cleared."
      save_state()
    end
  end

  local remove_index
  if #bus > 0 then
    -- v0.8.23: organize routes by stable plugin instance (track GUID + FX GUID).
    -- This keeps multiple parameters from the same FX visually together while
    -- separate instances of the same plugin remain distinct.
    local groups, group_order = {}, {}
    for i, a in ipairs(bus) do
      local key = plugin_instance_key(a, i)
      local g = groups[key]
      if not g then
        g = { key = key, first = a, entries = {} }
        groups[key] = g
        group_order[#group_order + 1] = g
      end
      g.entries[#g.entries + 1] = { index = i, assignment = a }
    end

    -- v0.8.41: use the same two-spacing visual buffer above the first
    -- plugin-instance frame as below the final frame, keeping each bus
    -- vertically balanced around its assignment boxes.
    if #group_order > 0 then
      ImGui.Spacing(ctx)
      ImGui.Spacing(ctx)
    end

    for gi, g in ipairs(group_order) do
      ImGui.PushID(ctx, bus_name .. "_plugin_group_" .. tostring(gi))
      ImGui.Indent(ctx, 38)
      ImGui.BeginGroup(ctx)

      ImGui.TextDisabled(ctx, is_native_control(g.first) and "NATIVE" or "PLUGIN")
      ImGui.SameLine(ctx)
      local group_fx_name, group_track_name = plugin_instance_parts(g.first)
      -- v0.8.24: plugin is the primary identifier; track is secondary context.
      ImGui.TextColored(ctx, 0x72B4EDFF, group_fx_name)
      ImGui.SameLine(ctx)
      ImGui.Text(ctx, "•  " .. group_track_name)
      ImGui.SameLine(ctx)
      local target_note = is_project_playrate(g.first) and "all loaded voices"
        or (is_sample_pitch(g.first) and "all loaded voices")
        or (is_track_playrate(g.first) and "loaded voices on assigned track")
        or (is_track_pan(g.first) and "native track pan")
        or (is_track_volume(g.first) and "native track volume")
        or string.format("%d parameter%s", #g.entries, #g.entries == 1 and "" or "s")
      ImGui.TextDisabled(ctx, target_note)

      for _, entry in ipairs(g.entries) do
        if draw_assignment_row(bus_name, entry.index, entry.assignment) then
          remove_index = entry.index
        end
      end

      ImGui.EndGroup(ctx)
      local gx1, gy1 = ImGui.GetItemRectMin(ctx)
      local gx2, gy2 = ImGui.GetItemRectMax(ctx)
      local dl = ImGui.GetWindowDrawList(ctx)
      ImGui.DrawList_AddRect(dl, gx1 - 8, gy1 - 5, gx2 + 8, gy2 + 5, 0x34404AFF, 4.0, 0, 1.0)
      ImGui.Unindent(ctx, 38)
      ImGui.PopID(ctx)
      if gi < #group_order then ImGui.Spacing(ctx); ImGui.Spacing(ctx) end
    end

    -- v0.8.41: keep the final plugin-instance frame from visually colliding
    -- with the separator/header of the next input bus. Match the same buffer
    -- used between plugin-instance boxes.
    if #group_order > 0 then
      ImGui.Spacing(ctx)
      ImGui.Spacing(ctx)
    end
  end

  if remove_index then
    table.remove(bus, remove_index)
    state.status = string.format("%s assignment %d removed.", display_name, remove_index)
    save_state()
  end
end

local INTERNAL_LFO_SHAPES = {"SINE", "TRI", "SQR", "UP", "DOWN"}

local function draw_lfo_waveform(lfo, width, height, id)
  width = math.max(90, width or 180)
  height = math.max(44, height or 58)

  ImGui.InvisibleButton(ctx, "##lfo_wave_"..tostring(id), width, height)
  local x1, y1 = ImGui.GetItemRectMin(ctx)
  local x2, y2 = ImGui.GetItemRectMax(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)

  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, 0x101418FF, 4.0)
  ImGui.DrawList_AddRect(dl, x1, y1, x2, y2, 0x35404AFF, 4.0, 0, 1.0)
  local mid_y = (y1 + y2) * 0.5
  ImGui.DrawList_AddLine(dl, x1 + 5, mid_y, x2 - 5, mid_y, 0x2B343CFF, 1.0)

  local points = 52
  local px, py
  for i = 0, points do
    local phase = i / points
    local v
    if lfo.shape == 1 then
      v = phase < 0.5 and phase * 2.0 or 2.0 - phase * 2.0
    elseif lfo.shape == 2 then
      v = phase < 0.5 and 1.0 or 0.0
    elseif lfo.shape == 3 then
      v = phase
    elseif lfo.shape == 4 then
      v = 1.0 - phase
    else
      v = 0.5 + 0.5 * math.sin((phase * math.pi * 2.0) - math.pi * 0.5)
    end
    local x = x1 + 6 + phase * math.max(1, (x2 - x1 - 12))
    local y = y2 - 6 - v * math.max(1, (y2 - y1 - 12))
    if px then ImGui.DrawList_AddLine(dl, px, py, x, y, lfo.active and 0x55D7B7FF or 0x607078FF, 1.6) end
    px, py = x, y
  end

  -- Live playhead/value dot.
  local live_x = x1 + 6 + (((r.time_precise() * clamp(lfo.rate_hz or 1, 0.01, 20)) % 1.0) * math.max(1, x2 - x1 - 12))
  local live_y = y2 - 6 - clamp(lfo.value or 0.5, 0, 1) * math.max(1, y2 - y1 - 12)
  ImGui.DrawList_AddCircleFilled(dl, live_x, live_y, 3.5, lfo.active and 0xFFFFFFFF or 0x89949CFF)
end

local function draw_lfo_card(index, lfo, width)
  ImGui.PushID(ctx, "internal_lfo_"..index)
  ImGui.BeginGroup(ctx)

  local changed = false
  ImGui.Text(ctx, string.format("LFO %02d", index))
  ImGui.SameLine(ctx)
  local c
  c, lfo.active = ImGui.Checkbox(ctx, "ACTIVE", lfo.active)
  if c then changed = true end
  ImGui.SameLine(ctx)
  ImGui.TextDisabled(ctx, string.format("%.3f", lfo.value or 0.5))

  draw_lfo_waveform(lfo, width, 62, index)

  ImGui.SetNextItemWidth(ctx, width)
  c, lfo.rate_hz = ImGui.SliderDouble(ctx, "##rate_hz", lfo.rate_hz or 1.0, 0.05, 10.0, "%.2f Hz")
  if c then changed = true end

  for shape_i, shape_name in ipairs(INTERNAL_LFO_SHAPES) do
    -- Compact labels allow all five shape controls to remain on one row.
    if shape_i > 1 then ImGui.SameLine(ctx) end
    local selected = (lfo.shape or 0) == (shape_i - 1)
    local label = selected and ("["..shape_name.."]") or shape_name
    if ImGui.SmallButton(ctx, label.."##shape"..shape_i) then
      lfo.shape = shape_i - 1
      changed = true
    end
  end

  if changed then save_state() end
  ImGui.EndGroup(ctx)
  ImGui.PopID(ctx)
end

local function draw_lfo_section()
  ImGui.Separator(ctx)
  ImGui.PushFont(ctx, input_heading_font, 18)
  ImGui.Text(ctx, "MODULATORS")
  ImGui.PopFont(ctx)

  -- Keep the three oscillator cards evenly distributed inside the config
  -- column with explicit padding on both outer edges.  Previously the cards
  -- consumed the entire available width, which left LFO 03 visually pressed
  -- against the Input Response/performance column.
  local avail = ImGui.GetContentRegionAvail(ctx)
  local side_pad = 18
  local gap = 8
  -- Reserve a little extra breathing room at the right edge.  All controls
  -- use hidden IDs, so nothing outside a card contributes to its layout width.
  local right_pad = 22
  local card_w = math.max(150, (avail - side_pad - right_pad - gap * 2) / 3)

  local row_x = ImGui.GetCursorPosX(ctx)
  ImGui.SetCursorPosX(ctx, row_x + side_pad)
  for i, lfo in ipairs(state.lfos) do
    if i > 1 then ImGui.SameLine(ctx, nil, gap) end
    draw_lfo_card(i, lfo, card_w)
  end
end

-- One row, drawn between the modulators and the input buses. Everything lives
-- on a single line so the section costs about as much height as the separator
-- above it: this is a restraint you reach for occasionally, not a panel to
-- live in.
function GR.draw_section()
  local g = state.global_range

  ImGui.Separator(ctx)

  -- Line the controls up with the modulator cards directly above.
  local side_pad = 18
  ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + side_pad)
  ImGui.BeginGroup(ctx)
  ImGui.PushID(ctx, "global_range")

  local changed, c = false, false

  -- An active GLOBAL RANGE uses the same green frame as the other live
  -- input-source toggles, so it is obvious that something is shaping the output.
  local was_enabled = g.enabled
  if was_enabled then
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,        0x247A45FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x2F9858FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,  0x36AD65FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark,      0xFFFFFFFF)
  end
  c, g.enabled = ImGui.Checkbox(ctx, "GLOBAL RANGE", g.enabled)
  if was_enabled then ImGui.PopStyleColor(ctx, 4) end
  if c then
    changed = true
    state.status = g.enabled
      and ("GLOBAL RANGE on  " .. GR.summary(g))
      or "GLOBAL RANGE off. Every route is back to its own MIN / MAX."
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      "Restrains every assignment at once, without touching its stored MIN / MAX.\n" ..
      "RANGE scales how much of each route's own sweep gets used.\n" ..
      "MIN / MAX are hard limits no route may cross.")
  end

  -- RANGE is the control this section exists for: one number that decides how
  -- much of each dialled-in range the pad is allowed to sweep.
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 150)
  local percent = (g.scale or 1.0) * 100.0
  c, percent = ImGui.SliderDouble(ctx, "RANGE", percent, 0.0, 200.0, "%.0f%%")
  if c then
    g.scale = percent / 100.0
    -- Reaching for RANGE is a clear statement of intent, so switch the section
    -- on rather than leaving the user wondering why nothing moved.
    if g.scale ~= 1.0 then g.enabled = true end
    changed = true
    state.status = "GLOBAL RANGE  " .. GR.summary(g)
  end

  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 110)
  c, g.floor = ImGui.SliderDouble(ctx, "MIN", g.floor or 0.0, 0.0, 1.0, "%.2f")
  if c then
    if g.floor > g.ceiling then g.ceiling = g.floor end
    if g.floor > 0.0 then g.enabled = true end
    changed = true
  end

  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 110)
  c, g.ceiling = ImGui.SliderDouble(ctx, "MAX", g.ceiling or 1.0, 0.0, 1.0, "%.2f")
  if c then
    if g.ceiling < g.floor then g.floor = g.ceiling end
    if g.ceiling < 1.0 then g.enabled = true end
    changed = true
  end

  ImGui.SameLine(ctx)
  if ImGui.SmallButton(ctx, "RESET") then
    state.global_range = GR.new()
    g = state.global_range
    changed = true
    state.status = "GLOBAL RANGE reset. Every route is back to its own MIN / MAX."
  end

  -- Only worth the width when something is actually being held back; an
  -- unchecked box already says "off" on its own.
  if not GR.is_neutral(g) then
    ImGui.SameLine(ctx)
    ImGui.TextDisabled(ctx, GR.summary(g))
  end

  ImGui.PopID(ctx)
  ImGui.EndGroup(ctx)

  if changed then
    state.global_range = GR.sanitize(g)
    -- Buses are normally only written when an input actually moves, so with
    -- the pen at rest a change here would not be heard until the pad was
    -- touched again. Push every bus now so the restraint is audible while the
    -- slider is still under the cursor.
    apply_input_outputs()
    save_state()
  end
end

function BR.draw_status()
  local b = state.bridge
  local now = r.time_precise()
  local launch_pending = now - (state.bridge_launch_requested_at or -1000.0) < 5.0
  local heartbeat_live = (b.heartbeat or -1) >= 0
    and (now - (b.last_heartbeat_change or -1000.0)) < 1.5

  ImGui.Separator(ctx)
  ImGui.Text(ctx, "WACOM")
  ImGui.SameLine(ctx)

  local label, color, hint
  if b.live then
    label, color, hint = "LIVE", 0x45D483FF, "Pressure + tilt active"
  elseif heartbeat_live then
    label, color, hint = "READY", 0xE0B84DFF, "Hover the pen over the pad"
  elseif launch_pending then
    label, color, hint = "STARTING", 0xE0B84DFF, "Starting..."
  elseif b.pen_present == false then
    label, color, hint = "OFFLINE", 0xE05252FF, "No pen tablet detected"
  else
    label, color, hint = "OFFLINE", 0xE05252FF, "Mouse + manual pressure"
  end

  ImGui.TextColored(ctx, color, label)
  ImGui.SameLine(ctx)

  if b.live or heartbeat_live or launch_pending then
    if ImGui.SmallButton(ctx, "STOP") then BR.stop() end
  else
    if ImGui.SmallButton(ctx, "START") then BR.start() end
  end

  if hint and hint ~= "" then
    ImGui.SameLine(ctx)
    ImGui.TextDisabled(ctx, hint)
  end
end

local function refresh_preset_list()
  state.preset_names = list_presets()
  if state.preset_index >= #state.preset_names then
    state.preset_index = math.max(0, #state.preset_names - 1)
  end
end

local function draw_preset_bar()
  local linked = state.linked_preset or ""
  ImGui.Text(ctx, "CONFIG")
  ImGui.SameLine(ctx)

  ImGui.SetNextItemWidth(ctx, 180)
  local changed
  changed, state.preset_name = ImGui.InputText(ctx, "##preset_name", state.preset_name)

  ImGui.SameLine(ctx)
  if ImGui.SmallButton(ctx, "SAVE PRESET") then
    if save_preset_to_disk(state.preset_name) then refresh_preset_list() end
  end

  ImGui.SameLine(ctx)
  if ImGui.SmallButton(ctx, "NEW EMPTY") then
    reset_state_to_empty()
    state.preset_name = "Untitled"
    set_project_linked_preset("")
    save_state()
    state.status = "New empty configuration. Project preset link cleared."
  end

  ImGui.SameLine(ctx)
  if ImGui.SmallButton(ctx, "REFRESH") then
    refresh_preset_list()
  end

  if #state.preset_names > 0 then
    ImGui.SetNextItemWidth(ctx, 220)
    local preview = state.preset_names[state.preset_index + 1] or state.preset_names[1]
    if ImGui.BeginCombo(ctx, "LOAD PRESET", preview) then
      for i, name in ipairs(state.preset_names) do
        local selected = (i - 1) == state.preset_index
        if ImGui.Selectable(ctx, name, selected) then
          state.preset_index = i - 1
          state.preset_name = name
        end
      end
      ImGui.EndCombo(ctx)
    end

    ImGui.SameLine(ctx)
    if ImGui.SmallButton(ctx, "LOAD") then
      local name = state.preset_names[state.preset_index + 1]
      if name then load_preset_from_disk(name) end
    end

    ImGui.SameLine(ctx)
    if ImGui.SmallButton(ctx, "DELETE PRESET") then
      local name = state.preset_names[state.preset_index + 1]
      if name and delete_preset_from_disk(name) then
        refresh_preset_list()
      end
    end
  else
    ImGui.TextDisabled(ctx, "No saved presets")
  end

  linked = state.linked_preset or ""
  if linked ~= "" then
    ImGui.TextDisabled(ctx, "PROJECT LINK: " .. linked)
    ImGui.SameLine(ctx)
    if ImGui.SmallButton(ctx, "UNLINK") then
      set_project_linked_preset("")
      state.status = "Project preset link cleared."
    end
  else
    ImGui.TextDisabled(ctx, "PROJECT LINK: none")
  end

  ImGui.Separator(ctx)
end

local function draw_mode_bar()
  -- v0.8.15: internal LFOs are autonomous assignment sources, so the old MOD
  -- performance mode is no longer needed. Keep the pad in direct mode.
  state.mode = 0
  ImGui.Text(ctx, "DIRECT")
  ImGui.SameLine(ctx, 180)
  _, state.armed = ImGui.Checkbox(ctx, "ARM", state.armed)
end

local function process_values(x, y, p, tx, ty, pen_down)
  -- Tilt Y inversion is global and happens before Pickup Glide / Multiplier /
  -- Return processing, so the monitor, trail and every TY assignment all share
  -- one consistent polarity.
  local normalized_ty = clamp(ty, 0, 1)
  if state.invert_tilt_y then normalized_ty = 1.0 - normalized_ty end

  local targets = {
    X = clamp(x, 0, 1),
    Y = clamp(y, 0, 1),
    Z = clamp(p, 0, 1),
    TX = clamp(tx, 0, 1),
    TY = normalized_ty,
  }
  update_input_response(pen_down, targets, r.time_precise())
end

local function draw_input_response_controls()
  ImGui.Separator(ctx)
  ImGui.Text(ctx, "INPUT RESPONSE")

  -- Fixed grid shared by every input row.  Nothing is allowed to drift based on
  -- label width; the two dividers sit in equal 20 px gaps (10 px per side).
  local grid_x = ImGui.GetCursorPosX(ctx)
  local col_input   = grid_x
  local col_attack  = grid_x + 76
  local divider_1  = grid_x + 248
  local col_release = grid_x + 258
  local divider_2  = grid_x + 413
  local col_return = grid_x + 423
  local attack_w, release_w, return_w = 87, 87, 81

  local section_top_x, section_top_y = ImGui.GetCursorScreenPos(ctx)

  for input_index, name in ipairs(INPUT_NAMES) do
    local cfg = state.inputs[name]
    ImGui.PushID(ctx, "response_" .. name)

    local label = name
    if name == "Z" then label = "PRESS / Z"
    elseif name == "TX" then label = "TILT X"
    elseif name == "TY" then label = "TILT Y"
    end

    local changed = false
    local c

    -- ROW 1: input label | ATTACK | RELEASE | optional INVERT.
    ImGui.SetCursorPosX(ctx, col_input)
    ImGui.Text(ctx, label)

    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx, col_attack)
    ImGui.SetNextItemWidth(ctx, attack_w)
    c, cfg.pickup_attack_time = ImGui.SliderDouble(
      ctx, "ATTACK", cfg.pickup_attack_time, 0.0, 3.0, "%.2f s"
    )
    changed = changed or c

    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx, col_release)
    ImGui.SetNextItemWidth(ctx, release_w)
    c, cfg.pickup_release_time = ImGui.SliderDouble(
      ctx, "RELEASE", cfg.pickup_release_time, 0.0, 3.0, "%.2f s"
    )
    changed = changed or c

    -- Tilt Y has one global polarity switch rather than per-assignment inversion.
    if name == "TY" then
      ImGui.SameLine(ctx)
      ImGui.SetCursorPosX(ctx, col_return)
      c, state.invert_tilt_y = ImGui.Checkbox(ctx, "INVERT", state.invert_tilt_y)
      changed = changed or c
    end

    -- ROW 2: MULTIPLIER | RETURN ON RELEASE | RETURN TIME.
    ImGui.SetCursorPosX(ctx, col_attack)
    ImGui.SetNextItemWidth(ctx, attack_w)
    c, cfg.multiplier = ImGui.SliderDouble(
      ctx, "MULTIPLIER", cfg.multiplier or 2.0, 0.10, 4.00, "%.2fx"
    )
    changed = changed or c

    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx, col_release)
    c, cfg.return_enabled = ImGui.Checkbox(
      ctx, "RETURN ON RELEASE", cfg.return_enabled
    )
    changed = changed or c

    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx, col_return)
    ImGui.SetNextItemWidth(ctx, return_w)
    c, cfg.return_time = ImGui.SliderDouble(
      ctx, "RETURN TIME", cfg.return_time, 0.0, 5.0, "%.2f s"
    )
    changed = changed or c

    if changed then save_state() end
    ImGui.PopID(ctx)

    -- Visually group each two-row input response block.
    if input_index < #INPUT_NAMES then
      ImGui.Separator(ctx)
    end
  end

  -- Draw the vertical grid after all widgets so it spans the complete section.
  -- Both lines use the same 10 px clearance to the adjacent fixed columns.
  local _, section_bottom_y = ImGui.GetCursorScreenPos(ctx)
  if ImGui.GetWindowDrawList and ImGui.DrawList_AddLine then
    local dl = ImGui.GetWindowDrawList(ctx)
    local win_x, _ = ImGui.GetWindowPos(ctx)
    local cursor_x = ImGui.GetCursorPosX(ctx)
    local content_screen_x = section_top_x - grid_x
    local x1 = content_screen_x + divider_1
    local x2 = content_screen_x + divider_2
    local col = 0x3A3D42FF
    ImGui.DrawList_AddLine(dl, x1, section_top_y + 2, x1, section_bottom_y - 2, col, 1.0)
    ImGui.DrawList_AddLine(dl, x2, section_top_y + 2, x2, section_bottom_y - 2, col, 1.0)
  end
end

-- v0.9.1 SAMPLE ENGINE.
-- Selected items are decoded into a section WAV and played by the ADFX
-- Varispeed JSFX on that item's track. Rate and pitch are sliders on an
-- interpolated, slewed read head — not CF_Preview D_PLAYRATE, and not
-- the arrange. Namespaced as a table for the same 200-locals reason
-- as GR / RC / TR.
SE.JSFX_NAME = "ADFX Varispeed"
SE.JSFX_FILENAME = "ADFX_Varispeed.jsfx"
SE.MAX_FRAMES = 3000000
SE.P_PLAY = 0
SE.P_RATE = 1
SE.P_PITCH = 2
SE.P_LOOP = 3
SE.P_SMOOTH = 4
SE.P_GAIN = 5
SE.P_LOAD = 6
SE.P_GMEM_SLOT = 10
SE.GMEM_NAME = "ADFXVarispeed"
SE.GMEM_MAGIC = 0x41444658
SE.GMEM_SLOTS = 32

function SE.gmem_ok()
  if SE._gmem then return true end
  if not r.gmem_attach or not r.gmem_write then return false end
  r.gmem_attach(SE.GMEM_NAME)
  SE._gmem = true
  return true
end

function SE.gmem_clear()
  if not SE.gmem_ok() then return end
  r.gmem_write(0, 0)
end

function SE.read_slot(track, fx)
  local v = math.floor(tonumber(SE.get_param(track, fx, SE.P_GMEM_SLOT)) or 0)
  if v < 0 then v = 0 end
  if v > (SE.GMEM_SLOTS - 1) then v = SE.GMEM_SLOTS - 1 end
  return v
end

function SE.assign_slot(track, fx)
  if not track or fx == nil then return 0 end
  local guid = fx_guid(track, fx)
  if guid and SE._slots and SE._slots[guid] ~= nil then
    return SE._slots[guid]
  end
  local cur = SE.read_slot(track, fx)
  local used = {}
  SE.each_project_track(function(tr)
    if not tr then return end
    for i = 0, r.TrackFX_GetCount(tr) - 1 do
      if SE.fx_is_ours(tr, i) and not (tr == track and i == fx) then
        used[SE.read_slot(tr, i)] = true
      end
    end
  end)
  local slot = cur
  if used[slot] then
    slot = 0
    for s = 0, SE.GMEM_SLOTS - 1 do
      if not used[s] then
        slot = s
        break
      end
    end
    SE.set_param(track, fx, SE.P_GMEM_SLOT, slot)
  elseif cur ~= slot then
    SE.set_param(track, fx, SE.P_GMEM_SLOT, slot)
  else
    -- Persist the default slot so a later instance does not also sit on 0.
    SE.set_param(track, fx, SE.P_GMEM_SLOT, slot)
  end
  SE._slots = SE._slots or {}
  if guid then SE._slots[guid] = slot end
  return slot
end

function SE.gmem_write_native(track, fx, rate, pitch)
  if not track or fx == nil or not SE.gmem_ok() then return end
  if not SE.fx_is_ours(track, fx) then return end
  local slot = SE.assign_slot(track, fx)
  local base = 8 + slot * 4
  local prev = math.floor(tonumber(r.gmem_read(base + 3)) or 0)
  local flags = prev
  if rate ~= nil then
    r.gmem_write(base + 1, rate)
    if flags % 2 < 1 then flags = flags + 1 end
  end
  if pitch ~= nil then
    r.gmem_write(base + 2, pitch)
    if math.floor(flags / 2) % 2 < 1 then flags = flags + 2 end
  end
  SE._gmem_seq = (SE._gmem_seq or 0) + 1
  r.gmem_write(0, SE.GMEM_MAGIC)
  r.gmem_write(1, SE._gmem_seq)
  r.gmem_write(base, SE._gmem_seq)
  r.gmem_write(base + 3, flags)
end

function SE.gmem_write_mapped(track, fx, param, norm)
  if param == SE.P_RATE then
    SE.gmem_write_native(track, fx, MATH.normalized_to_playrate(norm), nil)
  elseif param == SE.P_PITCH then
    SE.gmem_write_native(track, fx, nil, MATH.normalized_to_pitch(norm))
  end
end

function SE.apply_follow(ms)
  ms = tonumber(ms)
  if ms == nil then ms = state.follow_ms or 8 end
  if ms < 0 then ms = 0 end
  if ms > 40 then ms = 40 end
  state.follow_ms = ms
  for _, bus in pairs(state.buses or {}) do
    for _, a in ipairs(bus) do
      if a and not is_native_control(a) then
        resolve_assignment(a)
        local tr = track_from_index(a.track_idx)
        if tr and a.fx ~= nil and SE.fx_is_ours(tr, a.fx) then
          SE.set_param(tr, a.fx, SE.P_SMOOTH, ms)
        end
      end
    end
  end
  for _, voice in ipairs(SE.voices or {}) do
    local tr, fx = SE.resolve_voice(voice)
    if tr and fx ~= nil then
      SE.set_param(tr, fx, SE.P_SMOOTH, ms)
    end
  end
end

function SE.has_api()
  return r.TrackFX_AddByName ~= nil
    and r.CreateTakeAudioAccessor ~= nil
    and r.new_array ~= nil
end

function SE.rate_for(track_guid_value)
  local track_rate = 1.0
  if track_guid_value and SE.track_rates[track_guid_value] then
    track_rate = SE.track_rates[track_guid_value]
  end
  return MATH.combine_playrate(SE.project_rate, track_rate)
end

function SE.root_source(src)
  local guard = 0
  while src and guard < 8 do
    local parent = r.GetMediaSourceParent and r.GetMediaSourceParent(src) or nil
    if not parent then break end
    src = parent
    guard = guard + 1
  end
  return src
end

function SE.source_filename(src)
  src = SE.root_source(src)
  if not src or not r.GetMediaSourceFileName then return "" end
  local ok, filename = r.GetMediaSourceFileName(src, "")
  if type(ok) == "string" and ok ~= "" then return ok end
  if type(filename) == "string" then return filename end
  return ""
end

function SE.take_is_midi(take)
  if not take then return true end
  if r.TakeIsMIDI then return r.TakeIsMIDI(take) and true or false end
  local src = r.GetMediaItemTake_Source(take)
  if not src or not r.GetMediaSourceType then return false end
  local typ = r.GetMediaSourceType(src, "")
  if type(typ) ~= "string" then
    local _, typed = r.GetMediaSourceType(src, "")
    typ = typed or ""
  end
  return typ == "MIDI" or typ == "MIDIPOOL"
end

function SE.collect_selected()
  local out = {}
  local count = r.CountSelectedMediaItems(0)
  for i = 0, count - 1 do
    local item = r.GetSelectedMediaItem(0, i)
    local take = item and r.GetActiveTake(item) or nil
    if item and take and not SE.take_is_midi(take) then
      local track = r.GetMediaItem_Track(item)
      local src = r.GetMediaItemTake_Source(take)
      local item_len = tonumber(r.GetMediaItemInfo_Value(item, "D_LENGTH")) or 0
      local take_rate = tonumber(r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")) or 1
      local startoffs = tonumber(r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")) or 0
      local source_len = MATH.section_source_length(item_len, take_rate)
      local name = ""
      if r.GetTakeName then
        name = r.GetTakeName(take) or ""
      end
      if name == "" then
        name = SE.source_filename(src)
        name = name:match("([^\\/]+)$") or name
      end
      out[#out + 1] = {
        item = item,
        take = take,
        track = track,
        track_guid = track_guid(track),
        name = name ~= "" and name or ("item " .. tostring(i + 1)),
        item_pos = tonumber(r.GetMediaItemInfo_Value(item, "D_POSITION")) or 0,
        startoffs = startoffs,
        source_len = source_len,
        item_vol = tonumber(r.GetMediaItemInfo_Value(item, "D_VOL")) or 1,
        take_vol = tonumber(r.GetMediaItemTakeInfo_Value(take, "D_VOL")) or 1,
        take_pan = tonumber(r.GetMediaItemTakeInfo_Value(take, "D_PAN")) or 0,
      }
    end
  end
  return out
end

function SE.fx_name(track, fx)
  if not track or fx == nil then return "" end
  local ok, name = r.TrackFX_GetFXName(track, fx, "")
  if type(ok) == "string" and ok ~= "" then return ok end
  return name or ""
end

function SE.fx_is_ours(track, fx)
  return SE.fx_name(track, fx):find("ADFX Varispeed", 1, true) ~= nil
end

function SE.nth_jsfx(track, n)
  local seen = 0
  for i = 0, r.TrackFX_GetCount(track) - 1 do
    if SE.fx_is_ours(track, i) then
      if seen == n then return i end
      seen = seen + 1
    end
  end
  return nil
end

function SE.installed_jsfx()
  return r.GetResourcePath() .. SEP .. "Effects" .. SEP .. "ADFX" .. SEP .. SE.JSFX_FILENAME
end

-- The JSFX can sit in effects/, next to the Lua file (common install),
-- or already in REAPER's Effects/ADFX folder.
function SE.source_jsfx()
  -- Only the copies next to the pad script. Never treat Effects/ADFX as
  -- the source, or a stale installed file can hide the one you just replaced.
  local candidates = {
    SCRIPT_DIR .. "effects" .. SEP .. SE.JSFX_FILENAME,
    SCRIPT_DIR .. SE.JSFX_FILENAME,
  }
  for i = 1, #candidates do
    if candidates[i] ~= "" and r.file_exists(candidates[i]) then
      return candidates[i]
    end
  end
  return nil
end

function SE.bundled_jsfx()
  return SE.source_jsfx() or (SCRIPT_DIR .. "effects" .. SEP .. SE.JSFX_FILENAME)
end

function SE.copy_file(src, dst)
  local inf = io.open(src, "rb")
  if not inf then return false end
  local data = inf:read("*a")
  inf:close()
  if not data or data == "" then return false end
  local dir = dst:match("^(.*[\\/])")
  if dir and r.RecursiveCreateDirectory then
    r.RecursiveCreateDirectory(dir, 0)
  end
  local outf = io.open(dst, "wb")
  if not outf then return false end
  outf:write(data)
  outf:close()
  return true
end

-- REAPER compiles each JSFX instance and keeps that compile. Restarting the
-- computer does not replace an instance already on a track, and there is no
-- VST-style "rescan". The live file is Effects/ADFX/ADFX_Varispeed.jsfx.
-- To pick up a new copy: Edit → Ctrl+S, or remove and re-add the FX.
function SE.read_text(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local data = f:read("*a")
  f:close()
  if not data then return nil end
  return data:gsub("\r\n", "\n"):gsub("\r", "\n")
end

function SE.named_parm(track, fx, key)
  if not track or fx == nil or not r.TrackFX_GetNamedConfigParm then return "" end
  local a, b = r.TrackFX_GetNamedConfigParm(track, fx, key)
  if type(a) == "string" and a ~= "" then return a end
  if a and type(b) == "string" then return b end
  return ""
end

function SE.snapshot_instance(track, fx)
  local snap = {
    file0 = SE.named_parm(track, fx, "FILE0"),
    enabled = r.TrackFX_GetEnabled(track, fx),
    params = {},
  }
  if r.TrackFX_GetOffline then
    snap.offline = r.TrackFX_GetOffline(track, fx)
  end
  local n = r.TrackFX_GetNumParams(track, fx) or 0
  if n > 16 then n = 16 end
  for i = 0, n - 1 do
    snap.params[i] = SE.get_param(track, fx, i)
  end
  return snap
end

function SE.restore_instance(track, fx, snap)
  if not snap then return end
  if snap.file0 and snap.file0 ~= "" then
    SE.set_file(track, fx, snap.file0)
  end
  for i, value in pairs(snap.params) do
    SE.set_param(track, fx, i, value)
  end
  if snap.enabled ~= nil then
    r.TrackFX_SetEnabled(track, fx, snap.enabled)
  end
  if snap.offline ~= nil and r.TrackFX_SetOffline then
    r.TrackFX_SetOffline(track, fx, snap.offline)
  end
end

function SE.retarget_instance(old_guid, new_guid, new_fx)
  if not old_guid or not new_guid or old_guid == new_guid then
    return
  end
  for _, bus in pairs(state.buses or {}) do
    for _, a in ipairs(bus) do
      if a and a.fx_guid == old_guid then
        a.fx_guid = new_guid
        a.fx = new_fx
      end
    end
  end
  for _, voice in ipairs(SE.voices or {}) do
    if voice.fx_guid == old_guid then
      voice.fx_guid = new_guid
      voice.fx = new_fx
    end
  end
end

function SE.add_one(track)
  local fx = r.TrackFX_AddByName(track, SE.JSFX_NAME, false, -1)
  if fx == nil or fx < 0 then
    local path = SE.installed_jsfx()
    if r.file_exists(path) then
      fx = r.TrackFX_AddByName(track, path, false, -1)
    end
  end
  if fx == nil or fx < 0 then
    local src = SE.source_jsfx()
    if src then
      fx = r.TrackFX_AddByName(track, src, false, -1)
    end
  end
  if fx == nil or fx < 0 then return nil end
  return fx
end

-- Add a fresh compile, copy the old settings, then remove the stale instance
-- so a failed add cannot leave the track without Varispeed.
function SE.reinsert_instance(track, fx)
  local old_guid = fx_guid(track, fx)
  local snap = SE.snapshot_instance(track, fx)
  local newfx = SE.add_one(track)
  if newfx == nil then return nil end
  SE.restore_instance(track, newfx, snap)
  r.TrackFX_Delete(track, fx)
  if newfx > fx then newfx = newfx - 1 end
  if newfx ~= fx and r.TrackFX_CopyToTrack then
    r.TrackFX_CopyToTrack(track, newfx, track, fx, true)
    newfx = fx
  end
  SE.retarget_instance(old_guid, fx_guid(track, newfx), newfx)
  return newfx
end

function SE.each_project_track(fn)
  for i = 0, r.CountTracks(0) - 1 do
    fn(r.GetTrack(0, i))
  end
  if r.GetMasterTrack then
    fn(r.GetMasterTrack(0))
  end
end

function SE.reinsert_all()
  local n = 0
  r.PreventUIRefresh(1)
  r.Undo_BeginBlock2(0)
  SE.each_project_track(function(track)
    if not track then return end
    local idxs = {}
    for i = 0, r.TrackFX_GetCount(track) - 1 do
      if SE.fx_is_ours(track, i) then
        idxs[#idxs + 1] = i
      end
    end
    for k = 1, #idxs do
      if SE.reinsert_instance(track, idxs[k]) ~= nil then
        n = n + 1
      end
    end
  end)
  r.Undo_EndBlock2(0, "ADFX: reload Varispeed JSFX", -1)
  r.PreventUIRefresh(-1)
  if n > 0 then
    save_state()
  end
  return n
end

function SE.reload_from_script()
  local src = SE.source_jsfx()
  if not src then
    return 0, "put ADFX_Varispeed.jsfx next to this script, or in an effects subfolder"
  end
  if not SE.copy_file(src, SE.installed_jsfx()) then
    return 0, "could not write Effects/ADFX/ADFX_Varispeed.jsfx"
  end
  local n = SE.reinsert_all()
  return n
end

-- Never overwrite an Effects/ADFX file the user already has. That was
-- putting the 10-slider copy back every time the pad opened. Only install
-- when REAPER has no file yet. RELOAD JSFX is the explicit overwrite.
function SE.ensure_installed()
  local dst = SE.installed_jsfx()
  if r.file_exists(dst) then return true end
  local src = SE.source_jsfx()
  if src and src ~= dst then
    SE.copy_file(src, dst)
  end
  if r.file_exists(dst) then return true end
  return src ~= nil
end

function SE.temp_dir()
  local t = os.getenv("TEMP") or os.getenv("TMP") or os.getenv("TMPDIR") or "."
  local dir = t .. SEP .. "ADFX_Varispeed"
  if r.RecursiveCreateDirectory then r.RecursiveCreateDirectory(dir, 0) end
  return dir
end

function SE.extract_take_wav(entry, path)
  local take = entry.take
  if not take then return nil end
  local src = r.GetMediaItemTake_Source(take)
  local srate = src and tonumber(r.GetMediaSourceSampleRate(src)) or 0
  if not srate or srate < 1 then
    srate = tonumber(r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)) or 44100
  end
  local nch = src and tonumber(r.GetMediaSourceNumChannels(src)) or 2
  if not nch or nch < 1 then nch = 1 end
  if nch > 2 then nch = 2 end

  local start = tonumber(entry.startoffs) or 0
  local len = tonumber(entry.source_len) or 0
  if len <= 0 then return nil end
  local frames = math.floor(len * srate + 0.5)
  if frames < 2 then return nil end
  if frames > SE.MAX_FRAMES then frames = SE.MAX_FRAMES end

  local aa = r.CreateTakeAudioAccessor(take)
  if not aa then return nil end

  local f = io.open(path, "wb")
  if not f then
    r.DestroyAudioAccessor(aa)
    return nil
  end

  -- 16-bit PCM: JSFX file_riff is reliable with integer WAV, less so with
  -- IEEE float on some builds.
  local sr = math.floor(srate + 0.5)
  local data_bytes = frames * nch * 2
  f:write("RIFF")
  f:write(string.pack("<I4", 36 + data_bytes))
  f:write("WAVEfmt ")
  f:write(string.pack("<I4I2I2I4I4I2I2", 16, 1, nch, sr, sr * nch * 2, nch * 2, 16))
  f:write("data")
  f:write(string.pack("<I4", data_bytes))

  local chunk = 8192
  local arr = r.new_array(chunk * nch)
  local done = 0
  while done < frames do
    local n = math.min(chunk, frames - done)
    if arr.clear then arr.clear() end
    local ok = r.GetAudioAccessorSamples(aa, srate, nch, start + done / srate, n, arr)
    for i = 1, n * nch do
      local v = (ok and ok ~= 0) and (arr[i] or 0) or 0
      if v ~= v then v = 0 end
      if v > 1 then v = 1 elseif v < -1 then v = -1 end
      f:write(string.pack("<i2", math.floor(v * 32767 + 0.5)))
    end
    done = done + n
  end
  f:close()
  r.DestroyAudioAccessor(aa)
  return path
end

function SE.set_file(track, fx, path)
  if not track or fx == nil or not path or not r.TrackFX_SetNamedConfigParm then
    return false
  end
  local keys = {"FILE0", "FILE", "filename.0", "jsfx_file0"}
  for i = 1, #keys do
    if r.TrackFX_SetNamedConfigParm(track, fx, keys[i], path) then return true end
  end
  return false
end

function SE.set_param(track, fx, param, value)
  if not track or fx == nil then return end
  r.TrackFX_SetParam(track, fx, param, value)
end

function SE.get_param(track, fx, param)
  if not track or fx == nil then return 0 end
  local value = r.TrackFX_GetParam(track, fx, param)
  return tonumber(value) or 0
end

function SE.resolve_voice(voice)
  if not voice then return nil, nil end
  local tr = nil
  if voice.track_guid then
    tr = find_track_by_guid(voice.track_guid)
  end
  if not tr then return nil, nil end
  if voice.fx_guid then
    local fx = find_fx_by_guid(tr, voice.fx_guid)
    if fx ~= nil then return tr, fx end
  end
  if voice.fx ~= nil and SE.fx_is_ours(tr, voice.fx) then
    return tr, voice.fx
  end
  local fx = SE.nth_jsfx(tr, voice.nth or 0)
  return tr, fx
end

function SE.place_jsfx(track, fx)
  local dest = 0
  for i = 0, fx - 1 do
    if SE.fx_is_ours(track, i) then dest = dest + 1 end
  end
  if fx ~= dest and r.TrackFX_CopyToTrack then
    r.TrackFX_CopyToTrack(track, fx, track, dest, true)
    fx = dest
  end
  return fx
end

function SE.ensure_jsfx(track, nth)
  local fx = SE.nth_jsfx(track, nth)
  if fx ~= nil then
    SE.assign_slot(track, fx)
    return fx
  end
  fx = r.TrackFX_AddByName(track, SE.JSFX_NAME, false, 1)
  if fx == nil or fx < 0 then
    local path = SE.installed_jsfx()
    if r.file_exists(path) then
      fx = r.TrackFX_AddByName(track, path, false, 1)
    end
  end
  if fx == nil or fx < 0 then
    local src = SE.source_jsfx()
    if src then
      fx = r.TrackFX_AddByName(track, src, false, 1)
    end
  end
  if fx == nil or fx < 0 then return nil end
  fx = SE.place_jsfx(track, fx)
  SE.assign_slot(track, fx)
  SE.set_param(track, fx, SE.P_SMOOTH, state.follow_ms or 8)
  return fx
end

function SE.apply_voice_params(voice)
  local tr, fx = SE.resolve_voice(voice)
  if not tr or fx == nil then return end
  SE.set_param(tr, fx, SE.P_RATE, SE.rate_for(voice.track_guid))
  SE.set_param(tr, fx, SE.P_PITCH, SE.project_pitch or 0)
  SE.set_param(tr, fx, SE.P_LOOP, state.transport.loop_selected_on_play and 1 or 0)
  SE.gmem_write_native(tr, fx, SE.rate_for(voice.track_guid), SE.project_pitch or 0)
end

function SE.apply_rates()
  for _, voice in ipairs(SE.voices) do
    local tr, fx = SE.resolve_voice(voice)
    if tr and fx ~= nil then
      SE.set_param(tr, fx, SE.P_RATE, SE.rate_for(voice.track_guid))
      SE.set_param(tr, fx, SE.P_PITCH, SE.project_pitch or 0)
      SE.gmem_write_native(tr, fx, SE.rate_for(voice.track_guid), SE.project_pitch or 0)
    end
  end
end

function SE.apply_loop()
  local loop = state.transport.loop_selected_on_play and 1 or 0
  for _, voice in ipairs(SE.voices) do
    local tr, fx = SE.resolve_voice(voice)
    if tr and fx ~= nil then
      SE.set_param(tr, fx, SE.P_LOOP, loop)
    end
  end
end

function SE.stop_voices()
  for _, voice in ipairs(SE.voices) do
    local tr, fx = SE.resolve_voice(voice)
    if tr and fx ~= nil then
      SE.set_param(tr, fx, SE.P_PLAY, 0)
    end
  end
  SE.playing = false
end

function SE.play()
  if not SE.has_api() then
    state.status = "Sample engine needs TrackFX and AudioAccessor (REAPER 6+)."
    return
  end
  if not SE.ensure_installed() then
    state.status = "Could not find ADFX_Varispeed.jsfx. Put it next to this script, or in an effects subfolder."
    return
  end

  SE.stop_voices()
  SE.voices = {}

  local entries = SE.collect_selected()
  if #entries == 0 then
    state.status = "Select audio items, then press PLAY to load them into ADFX Varispeed."
    return
  end

  local per_track = {}
  local loaded, failed = 0, 0
  r.PreventUIRefresh(1)
  r.Undo_BeginBlock2(0)

  for _, entry in ipairs(entries) do
    if entry.track then
      local guid = entry.track_guid or track_guid(entry.track) or "_"
      per_track[guid] = (per_track[guid] or 0)
      local wav = SE.temp_dir() .. SEP .. string.format("voice_%s_%d.wav",
        guid:gsub("[^%w]", ""):sub(1, 12), per_track[guid])
      local path = SE.extract_take_wav(entry, wav)
      local fx = path and SE.ensure_jsfx(entry.track, per_track[guid]) or nil
      if path and fx ~= nil then
        SE.set_file(entry.track, fx, path)
        SE.load_serial = (SE.load_serial or 0) + 1
        SE.set_param(entry.track, fx, SE.P_LOAD, SE.load_serial)
        local voice = {
          track_guid = guid,
          fx = fx,
          fx_guid = fx_guid(entry.track, fx),
          nth = per_track[guid],
          name = entry.name,
          item_pos = entry.item_pos,
          source_len = entry.source_len,
          wav_path = path,
        }
        SE.set_param(entry.track, fx, SE.P_PLAY, 0)
        SE.set_param(entry.track, fx, SE.P_RATE, SE.rate_for(guid))
        SE.set_param(entry.track, fx, SE.P_PITCH, SE.project_pitch or 0)
        SE.set_param(entry.track, fx, SE.P_LOOP, state.transport.loop_selected_on_play and 1 or 0)
        SE.set_param(entry.track, fx, SE.P_SMOOTH, state.follow_ms or 8)
        SE.set_param(entry.track, fx, SE.P_GAIN,
          MATH.gain_to_jsfx(MATH.preview_volume(entry.item_vol, entry.take_vol)))
        SE.set_param(entry.track, fx, SE.P_PLAY, 1)
        SE.gmem_write_native(entry.track, fx, SE.rate_for(guid), SE.project_pitch or 0)
        SE.voices[#SE.voices + 1] = voice
        loaded = loaded + 1
        per_track[guid] = per_track[guid] + 1
      else
        failed = failed + 1
      end
    else
      failed = failed + 1
    end
  end

  r.Undo_EndBlock2(0, "ADFX: load varispeed voices", -1)
  r.PreventUIRefresh(-1)
  r.TrackList_AdjustWindows(false)

  SE.playing = loaded > 0
  SE.started_wall = r.time_precise()
  if loaded == 0 then
    state.status = "Could not load the selected items into ADFX Varispeed."
  else
    state.status = string.format(
      "Varispeed playing %d voice%s%s  •  interpolated + slewed",
      loaded, loaded == 1 and "" or "s",
      failed > 0 and string.format(", %d skipped", failed) or "")
  end
end

function SE.stop()
  local had = #SE.voices
  SE.stop_voices()
  state.status = had > 0 and "Varispeed stopped." or "Sample engine idle."
end

function SE.is_playing()
  return SE.playing and true or false
end

function SE.poll()
  if not SE.playing then return end
  local alive = 0
  for _, voice in ipairs(SE.voices) do
    local tr, fx = SE.resolve_voice(voice)
    if tr and fx ~= nil and SE.get_param(tr, fx, SE.P_PLAY) > 0.5 then
      alive = alive + 1
    end
  end
  if alive == 0 then
    SE.playing = false
    if type(state.status) == "string" and state.status:find("^Varispeed playing") then
      state.status = "Varispeed finished."
    end
  end
end

function SE.rec_time()
  local voice = SE.voices[1]
  if voice then
    local elapsed = r.time_precise() - (SE.started_wall or r.time_precise())
    local rate = SE.rate_for(voice.track_guid)
    if rate < 0.01 then rate = 0.01 end
    return MATH.rec_time(voice.item_pos, elapsed * rate, voice.source_len)
  end
  return r.GetCursorPosition()
end

function SE.voice_summary()
  local n = #SE.voices
  if n == 0 then return "no voices loaded" end
  if n == 1 then return SE.voices[1].name or "1 voice" end
  return string.format("%d voices", n)
end

-- v0.8.56 TRANSPORT, rewritten in v0.9.0 to drive the sample engine
-- instead of Main_OnCommand PLAY / STOP. LOOP still means "loop the
-- selected items", but that flag is now B_LOOP on each preview voice.
local TR = {}

TR.tab_nav = (function()
  local names = {
    "ADFX_Tab to Transient.lua",
    "ADFX_Tab to Previous Transient.lua",
  }
  for i = 1, #names do
    local path = SCRIPT_DIR .. names[i]
    if path ~= "" and r.file_exists(path) then
      local ok, mod = pcall(dofile, path)
      if ok and type(mod) == "table" and mod.next and mod.prev then
        return mod
      end
    end
  end
  return nil
end)()

TR.NO_NAV = (function()
  local flags = 0
  local names = {
    "WindowFlags_NoNav",
    "WindowFlags_NoNavInputs",
    "WindowFlags_NoNavFocus",
  }
  for i = 1, #names do
    local ok, flag = pcall(function() return ImGui[names[i]] end)
    if ok and flag then
      if type(flag) == "function" then flag = flag() end
      if type(flag) == "number" then flags = flags | flag end
    end
  end
  return flags
end)()

-- Shift+Tab is ImGui's reverse tab-stop, which still walks INPUT RESPONSE
-- sliders even when keyboard nav is off. Mark every widget as not tabbable
-- and take ownership of Key_Tab for the frame.
function TR.claim_tab_keys()
  pcall(function()
    if type(ImGui.SetKeyOwner) == "function" and ImGui.Key_Tab then
      ImGui.SetKeyOwner(ctx, ImGui.Key_Tab, ImGui.GetID(ctx, "adfx_consume_tab"))
    end
  end)
end

function TR.push_no_tab_stop()
  TR._no_tab_pushed = false
  pcall(function()
    local flags = 0
    local names = { "ItemFlags_NoTabStop", "ItemFlags_NoNav" }
    for i = 1, #names do
      local ok, flag = pcall(function() return ImGui[names[i]] end)
      if ok and flag then
        if type(flag) == "function" then flag = flag() end
        if type(flag) == "number" then flags = flags | flag end
      end
    end
    if flags ~= 0 and type(ImGui.PushItemFlag) == "function" then
      ImGui.PushItemFlag(ctx, flags, true)
      TR._no_tab_pushed = true
    end
  end)
end

function TR.pop_no_tab_stop()
  if TR._no_tab_pushed then
    pcall(ImGui.PopItemFlag, ctx)
    TR._no_tab_pushed = false
  end
end

TR.CMD_REMOVE_TIME_SELECTION = 40635

-- Earliest start and latest end across the current item selection.
function TR.selection_bounds()
  local count = r.CountSelectedMediaItems(0)
  if count == 0 then return nil, nil, 0 end

  local start_pos, end_pos
  for i = 0, count - 1 do
    local item = r.GetSelectedMediaItem(0, i)
    if item then
      local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
      local len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
      if start_pos == nil or pos < start_pos then start_pos = pos end
      if end_pos == nil or pos + len > end_pos then end_pos = pos + len end
    end
  end

  return start_pos, end_pos, count
end

-- Loop the current item selection: one item gives its own bounds, several give
-- the span from the first start to the last end.
--
-- Unlike the standalone action this does not hand focus back to the arrange
-- view. That step existed so the spacebar still worked after running the action
-- from a toolbar; here PLAY is right next to the pad, and stealing focus
-- mid-performance would pull the pen surface out from under the user.
function TR.set_loop_from_selection()
  local start_pos, end_pos, count = TR.selection_bounds()
  if not start_pos or end_pos <= start_pos then return nil, nil, count end

  r.Main_OnCommand(TR.CMD_REMOVE_TIME_SELECTION, 0)
  r.GetSet_LoopTimeRange(true, false, start_pos, end_pos, false) -- time selection
  r.GetSet_LoopTimeRange(true, true, start_pos, end_pos, false)  -- loop points

  -- Leave an already-enabled repeat alone so this cannot toggle it off.
  if r.GetSetRepeat(-1) == 0 then r.GetSetRepeat(1) end

  r.SetEditCurPos(start_pos, false, false)
  return start_pos, end_pos, count
end

TR.CMD_PLAY = 1007
TR.CMD_STOP = 1016

function TR.play()
  if state.transport.loop_selected_on_play then
    local start_pos, end_pos, count = TR.set_loop_from_selection()
    if start_pos then
      state.status = string.format(
        "Loop set to %d selected item%s  %.3f - %.3f",
        count, count == 1 and "" or "s", start_pos, end_pos)
    elseif count and count > 0 then
      state.status = "Selected items have no length. Playing without changing the loop."
    else
      state.status = "No items selected. Playing without changing the loop."
    end
  end
  r.Main_OnCommand(TR.CMD_PLAY, 0)
end

function TR.stop()
  r.Main_OnCommand(TR.CMD_STOP, 0)
  state.status = "Transport stopped."
end

function TR.is_playing()
  return (r.GetPlayState() & 1) == 1
end

function TR.toggle_play()
  if TR.is_playing() then TR.stop() else TR.play() end
end

-- v0.8.57: while a ReaImGui window holds focus the host never sees the
-- spacebar, so clicking the pad used to kill transport control until you
-- clicked back into REAPER. Handle the key here instead and mirror the PLAY /
-- STOP buttons exactly, including the loop-the-selection option.
--
-- Skipped while any widget is active so a space still types normally in the
-- preset name field and does not interrupt a slider drag.
function TR.handle_keyboard()
  -- Skip Space while a text field or slider is active. Tab still works
  -- while the pen is down on the XY surface — that hold used to look
  -- like AnyItemActive and ate the jump.
  -- ReaImGui errors on unknown Key_* fields, so only use known keys.
  local typing = false
  pcall(function()
    if type(ImGui.GetWantTextInput) == "function" then
      typing = ImGui.GetWantTextInput(ctx) and true or false
    end
  end)
  if typing then return end

  if ImGui.IsKeyPressed(ctx, ImGui.Key_Space, false) then
    if ImGui.IsAnyItemActive(ctx) then return end
    if RC.consume_space and RC.consume_space() then return end
    TR.toggle_play()
  end

  if ImGui.IsAnyItemActive(ctx) and not TR.pen_in_use then return end

  local tab = TR.tab_nav
  local ok_tab, key_tab = pcall(function() return ImGui.Key_Tab end)
  if not (tab and ok_tab and key_tab and ImGui.IsKeyPressed(ctx, key_tab, false)) then
    return
  end

  local shift = false
  local ok_mod, mod_shift = pcall(function() return ImGui.Mod_Shift end)
  if ok_mod and mod_shift then
    shift = ImGui.IsKeyDown(ctx, mod_shift)
  else
    local ok_l, left = pcall(function() return ImGui.Key_LeftShift end)
    local ok_r, right = pcall(function() return ImGui.Key_RightShift end)
    if ok_l and left then shift = shift or ImGui.IsKeyDown(ctx, left) end
    if ok_r and right then shift = shift or ImGui.IsKeyDown(ctx, right) end
  end

  local start_pos, end_pos, count
  local opts = {
    set_loop = true,
    enable_repeat = state.transport.loop_selected_on_play,
  }
  if shift then
    start_pos, end_pos, count = tab.prev(r, opts)
  else
    start_pos, end_pos, count = tab.next(r, opts)
  end
  if start_pos then
    state.status = string.format(
      "%s item  loop %.3f - %.3f  (%d selected)",
      shift and "Previous" or "Next", start_pos, end_pos, count or 1)
  else
    state.status = shift
      and "No previous item to select."
      or "No next item to select."
  end
end

-- One button row plus the separator above it.
TR.SECTION_H = 32

-- The REC toggle, pinned to the right-hand end of the footer. Red only while
-- it is armed, so a glance at the corner tells you whether the next playback
-- is going to write anything.
RC.BUTTON_W = 68

function RC.draw_button()
  local rec = state.rec
  if rec.armed then
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,        0xC02A2AFF)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0xD94040FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,  0xE85555FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text,          0xFFFFFFFF)
  end
  local pressed = ImGui.Button(ctx, rec.armed and "REC" or "NO ARM",
    RC.BUTTON_W, 24)
  if rec.armed then ImGui.PopStyleColor(ctx, 4) end

  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      "Armed: the next playback writes everything the pad sends into each\n" ..
      "plugin parameter's automation lane. The points are committed when\n" ..
      "the transport stops, as one undo step.\n\n" ..
      "Times follow the arrange playhead.\n\n" ..
      "Only FX parameters are recorded. Track volume, pan, sample rate\n" ..
      "and sample pitch routes have no FX lane and are skipped.\n\n" ..
      "The pad must also be ARMED, or it is not sending anything to record.")
  end

  if pressed then
    rec.armed = not rec.armed
    if rec.armed then
      state.status = state.armed
        and "REC armed. The next engine playback writes automation for every assigned FX parameter."
        or "REC armed, but the pad is not ARMED, so there is nothing to record yet."
    elseif rec.active then
      -- Disarming mid-pass commits what has been captured so far rather than
      -- throwing it away; RC.update() picks this up on the next frame.
      state.status = "REC disarmed. Writing what was captured."
    else
      state.status = "REC off. Playback will not write automation."
    end
  end
end

function TR.draw_section()
  ImGui.Separator(ctx)
  ImGui.PushID(ctx, "transport")

  local play_state = r.GetPlayState()
  local playing = (play_state & 1) == 1
  local paused = (play_state & 2) == 2
  local footer_w = ImGui.GetContentRegionAvail(ctx)

  ImGui.Text(ctx, "TRANSPORT")
  ImGui.SameLine(ctx)
  if playing then
    ImGui.TextColored(ctx, 0x45D483FF, paused and "PAUSED" or "PLAYING")
  else
    ImGui.TextDisabled(ctx, "STOPPED")
  end
  ImGui.SameLine(ctx)

  local toggle_label = "LOOP SELECTED ITEMS ON PLAY"
  local avail_w = ImGui.GetContentRegionAvail(ctx)
  local toggle_w = ImGui.CalcTextSize(ctx, toggle_label) + 30
  if state.transport.loop_selected_on_play then
    toggle_w = toggle_w + ImGui.CalcTextSize(ctx, "999 selected") + 16
  end
  local reload_w = ImGui.CalcTextSize(ctx, "RELOAD JSFX") + 16
  local button_w = clamp(
    (avail_w - toggle_w - reload_w - RC.BUTTON_W - 32) / 2, 46, 96)

  if playing then
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,        0x247A45FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0x2F9858FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,  0x36AD65FF)
  end
  if ImGui.Button(ctx, "PLAY", button_w, 24) then TR.play() end
  if playing then ImGui.PopStyleColor(ctx, 3) end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      "Start the arrange. Space does the same while this window is focused.\n" ..
      "Tab / Shift+Tab jump to the next or previous item and set the loop.\n" ..
      "Put ADFX Varispeed on the track (+ SAMPLE RATE / + SAMPLE PITCH)\n" ..
      "so the pad drives Rate and Pitch while the items play.")
  end

  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, "STOP", button_w, 24) then TR.stop() end

  ImGui.SameLine(ctx)
  local changed
  changed, state.transport.loop_selected_on_play = ImGui.Checkbox(
    ctx, toggle_label, state.transport.loop_selected_on_play)
  if changed then
    state.status = state.transport.loop_selected_on_play
      and "PLAY and Tab will loop the selected items (Repeat on)."
      or "PLAY will leave Repeat alone. Tab still sets loop points."
    save_state()
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      "PLAY sets loop points from the selected items and turns Repeat on.\n" ..
      "Tab / Shift+Tab always set those loop points to the item you land on.\n" ..
      "With this checked, Tab also turns Repeat on.")
  end

  if state.transport.loop_selected_on_play then
    ImGui.SameLine(ctx)
    local _, _, count = TR.selection_bounds()
    ImGui.TextDisabled(ctx, string.format("%d selected", count))
  end

  ImGui.SameLine(ctx)
  if ImGui.SmallButton(ctx, "RELOAD JSFX") then
    local n, err = SE.reload_from_script()
    if err then
      state.status = "Could not reload ADFX Varispeed: " .. err
    else
      state.status = string.format(
        "Reloaded ADFX Varispeed on %d instance%s. Restarting does not replace a compiled JSFX; this does.",
        n, n == 1 and "" or "s")
    end
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      "Optional. The pad no longer overwrites Effects/ADFX on its own.\n" ..
      "Use this only when you want the script-folder ADFX_Varispeed.jsfx\n" ..
      "copied into Effects/ADFX and every track instance replaced.\n" ..
      "Needed once after a JSFX update (v1.4: FOLLOW + gmem).\n" ..
      "Or: FX window → Edit → Ctrl+S.")
  end

  ImGui.SameLine(ctx, math.max(0, footer_w - RC.BUTTON_W))
  RC.draw_button()

  ImGui.PopID(ctx)
end

local function draw_live_input_monitor()
  ImGui.Separator(ctx)
  ImGui.Text(ctx, "LIVE INPUT VALUES")

  local values = {
    {"X", apply_input_multiplier("X", state.inputs.X.value), state.bridge.connected and state.bridge.x or nil, #state.buses.X},
    {"Y", apply_input_multiplier("Y", state.inputs.Y.value), state.bridge.connected and (1.0 - state.bridge.y) or nil, #state.buses.Y},
    {"PRESS / Z", apply_input_multiplier("Z", state.inputs.Z.value), state.bridge.connected and shape_pressure(state.bridge.pressure) or state.pressure, #state.buses.Z},
    {"TILT X", apply_input_multiplier("TX", state.inputs.TX.value), state.bridge.connected and ((state.bridge.tilt_x + 1.0) * 0.5) or nil, #state.buses.TX},
    {"TILT Y", apply_input_multiplier("TY", state.inputs.TY.value), state.bridge.connected and (state.invert_tilt_y and (1.0 - ((state.bridge.tilt_y + 1.0) * 0.5)) or ((state.bridge.tilt_y + 1.0) * 0.5)) or nil, #state.buses.TY},
  }

  local avail = ImGui.GetContentRegionAvail(ctx)
  local total_w = math.max(300, avail)
  local gap = 8
  local cell_w = math.max(110, (total_w - gap * 4) / 5)

  for i, item in ipairs(values) do
    if i > 1 then ImGui.SameLine(ctx, nil, gap) end

    ImGui.BeginGroup(ctx)
    ImGui.TextDisabled(ctx, item[1])

    local v = clamp(item[2] or 0, 0, 1)
    ImGui.Text(ctx, string.format("%.3f", v))

    ImGui.SetNextItemWidth(ctx, cell_w)
    ImGui.ProgressBar(ctx, v, cell_w, 10, "")

    if item[3] ~= nil then
      ImGui.TextDisabled(ctx, string.format("RAW %.3f  •  %d route%s",
        clamp(item[3], 0, 1), item[4], item[4] == 1 and "" or "s"))
    else
      ImGui.TextDisabled(ctx, string.format("RAW --  •  %d route%s",
        item[4], item[4] == 1 and "" or "s"))
    end

    ImGui.EndGroup(ctx)
  end
end

local xy_popout_open = false

-- Short-lived normalized XY history used by both the embedded and pop-out
-- surfaces. Keeping the points normalized means the same trail scales cleanly
-- when the performance pad is resized. The trail is intentionally sparse and
-- capped so the visual stays lightweight even at high frame rates.
local xy_trail = {}
local xy_trail_last_sample = -1000.0
local XY_TRAIL_LIFETIME = 1.0
local XY_TRAIL_MAX_POINTS = 72
local XY_TRAIL_SAMPLE_INTERVAL = 1.0 / 60.0
local XY_TRAIL_MIN_DIST = 0.0015

local function trail_color(r, g, b, a)
  a = math.floor(clamp(a, 0, 255) + 0.5)
  return r * 0x1000000 + g * 0x10000 + b * 0x100 + a
end

local function update_xy_trail(owns_input)
  local now = r.time_precise()

  -- Expire old ghosts whether or not this surface currently owns input.
  while #xy_trail > 0 and now - xy_trail[1].t > XY_TRAIL_LIFETIME do
    table.remove(xy_trail, 1)
  end

  if not owns_input then return now end

  local x, y = state.last_x, state.last_y
  local last = xy_trail[#xy_trail]
  local moved = not last
  if last then
    local dx, dy = x - last.x, y - last.y
    moved = (dx * dx + dy * dy) >= (XY_TRAIL_MIN_DIST * XY_TRAIL_MIN_DIST)
  end

  if moved and now - xy_trail_last_sample >= XY_TRAIL_SAMPLE_INTERVAL then
    xy_trail[#xy_trail + 1] = {x = x, y = y, p = state.last_p or 0, tx = state.last_tx or 0.5, ty = state.last_ty or 0.5, t = now}
    xy_trail_last_sample = now
    if #xy_trail > XY_TRAIL_MAX_POINTS then
      table.remove(xy_trail, 1)
    end
  end

  return now
end

local function draw_xy_trail(dl, sx, sy, pad_w, pad_h, now)
  local count = #xy_trail
  if count == 0 then return end

  for i = 1, count do
    local pt = xy_trail[i]
    local life = clamp(1.0 - ((now - pt.t) / XY_TRAIL_LIFETIME), 0, 1)
    if life > 0 then
      -- Ease the fade so the head stays luminous while the tail disappears
      -- quickly. Shift from cool blue in the tail toward mint/cyan near the dot.
      local glow = life * life
      local rr = math.floor(72  + (86  - 72)  * life)
      local gg = math.floor(142 + (230 - 142) * life)
      local bb = math.floor(235 + (199 - 235) * life)
      local x = sx + pt.x * pad_w
      local y = sy + (1.0 - pt.y) * pad_h
      local pressure_boost = clamp(pt.p or 0, 0, 1) * 2.0

      -- Two translucent particles create a soft ghost/glow without requiring
      -- a continuous solid polyline. Alternating particle sizes give the trail
      -- a slightly energetic, irregular look while remaining cheap to draw.
      local pulse = (i % 3 == 0) and 1.8 or 0.0
      local outer_r = 5.0 + 7.0 * glow + pressure_boost + pulse
      local inner_r = 1.8 + 3.2 * glow + pressure_boost * 0.35
      ImGui.DrawList_AddCircleFilled(dl, x, y, outer_r, trail_color(rr, gg, bb, 18 + 38 * glow))
      ImGui.DrawList_AddCircleFilled(dl, x, y, inner_r, trail_color(rr, gg, bb, 28 + 105 * glow))

      -- Add occasional faint dashes between neighboring ghosts. This hints at
      -- motion direction but deliberately leaves gaps instead of a solid line.
      if i > 1 and i % 3 == 0 then
        local prev = xy_trail[i - 1]
        local px = sx + prev.x * pad_w
        local py = sy + (1.0 - prev.y) * pad_h
        ImGui.DrawList_AddLine(dl, px, py, x, y, trail_color(rr, gg, bb, 10 + 42 * glow), 1.0 + 1.4 * glow)
      end
    end
  end
end


-- Tilt ghosts share the same compact history as the XY trail, so there is no
-- extra sampling cost. Yellow visualizes Tilt X as a horizontal echo from the
-- XY path; orange visualizes Tilt Y as a vertical echo. At neutral tilt the
-- echoes collapse back onto the XY path, while stronger tilt fans them outward.
-- This keeps the 5D motion readable without adding meters or dense geometry.
local TILT_TRAIL_OFFSET_SCALE = 0.18

local function draw_tilt_trails(dl, sx, sy, pad_w, pad_h, now)
  local count = #xy_trail
  if count == 0 then return end

  for i = 1, count do
    local pt = xy_trail[i]
    local life = clamp(1.0 - ((now - pt.t) / XY_TRAIL_LIFETIME), 0, 1)
    if life > 0 then
      local glow = life * life
      local base_x = sx + pt.x * pad_w
      local base_y = sy + (1.0 - pt.y) * pad_h
      local tx = clamp(pt.tx or 0.5, 0, 1)
      local ty = clamp(pt.ty or 0.5, 0, 1)

      -- Bipolar tilt is stored normalized around 0.5. Map the deviation to an
      -- offset from the XY gesture rather than drawing two overlapping paths.
      local tx_x = base_x + (tx - 0.5) * 2.0 * (pad_w * TILT_TRAIL_OFFSET_SCALE)
      local tx_y = base_y
      local ty_x = base_x
      local ty_y = base_y - (ty - 0.5) * 2.0 * (pad_h * TILT_TRAIL_OFFSET_SCALE)

      -- Keep the ghosts inside the pad, including a little radius padding.
      tx_x = clamp(tx_x, sx + 3, sx + pad_w - 3)
      ty_x = clamp(ty_x, sx + 3, sx + pad_w - 3)
      ty_y = clamp(ty_y, sy + 3, sy + pad_h - 3)

      local pulse = (i % 4 == 0) and 1.2 or 0.0
      local outer_r = 3.8 + 4.2 * glow + pulse
      local inner_r = 1.4 + 2.2 * glow

      -- Tilt X: electric yellow / gold.
      ImGui.DrawList_AddCircleFilled(dl, tx_x, tx_y, outer_r,
        trail_color(255, 220, 72, 10 + 34 * glow))
      ImGui.DrawList_AddCircleFilled(dl, tx_x, tx_y, inner_r,
        trail_color(255, 235, 105, 24 + 112 * glow))

      -- Tilt Y: warm orange / amber.
      ImGui.DrawList_AddCircleFilled(dl, ty_x, ty_y, outer_r,
        trail_color(255, 133, 48, 10 + 34 * glow))
      ImGui.DrawList_AddCircleFilled(dl, ty_x, ty_y, inner_r,
        trail_color(255, 166, 72, 24 + 112 * glow))

      -- Sparse dashes preserve the ghosty broken-trail look and make direction
      -- easier to read without turning either tilt trace into a solid line.
      if i > 1 and i % 4 == 0 then
        local prev = xy_trail[i - 1]
        local ptx = clamp(prev.tx or 0.5, 0, 1)
        local pty = clamp(prev.ty or 0.5, 0, 1)
        local pbx = sx + prev.x * pad_w
        local pby = sy + (1.0 - prev.y) * pad_h
        local ptx_x = clamp(pbx + (ptx - 0.5) * 2.0 * (pad_w * TILT_TRAIL_OFFSET_SCALE), sx + 3, sx + pad_w - 3)
        local pty_x = clamp(pbx, sx + 3, sx + pad_w - 3)
        local pty_y = clamp(pby - (pty - 0.5) * 2.0 * (pad_h * TILT_TRAIL_OFFSET_SCALE), sy + 3, sy + pad_h - 3)

        ImGui.DrawList_AddLine(dl, ptx_x, pby, tx_x, tx_y,
          trail_color(255, 225, 76, 8 + 38 * glow), 1.0 + 0.8 * glow)
        ImGui.DrawList_AddLine(dl, pty_x, pty_y, ty_x, ty_y,
          trail_color(255, 145, 52, 8 + 38 * glow), 1.0 + 0.8 * glow)
      end
    end
  end
end

local function draw_xy_surface(pad_id, pad_w, pad_h, owns_input)
  local sx, sy = ImGui.GetCursorScreenPos(ctx)
  ImGui.InvisibleButton(ctx, pad_id, pad_w, pad_h)
  if ImGui.IsItemActive(ctx) then TR.pen_in_use = true end

  -- Only one XY surface may own tablet/mouse input at a time. In v0.8.25
  -- both surfaces called write_bridge_rect(), and the global 30 ms write
  -- throttle meant the embedded pad usually won because it rendered first.
  -- That kept the Wacom coordinate mapping constrained to the small pad even
  -- while the large pop-out was open.
  owns_input = owns_input ~= false
  if owns_input then
    BR.write_rect(sx, sy, pad_w, pad_h)
    BR.poll()
  end

  local hovered = ImGui.IsItemHovered(ctx)
  local active = ImGui.IsItemActive(ctx)
  local mx, my = ImGui.GetMousePos(ctx)

  if owns_input and state.bridge.live then
    local b = state.bridge
  
    -- Bridge tilt is bipolar (-1..1). Convert to normalized buses.
    local ntx = (b.tilt_x + 1.0) * 0.5
    local nty = (b.tilt_y + 1.0) * 0.5
    local pressure = shape_pressure(b.pressure)
  
    -- Barrel buttons act as axis freezes while tip is down.
    local x = b.button1 and state.last_x or b.x
    local y = b.button2 and state.last_y or (1.0 - b.y)
  
    -- Stabilize contact before feeding the response engine. Some tablet/
    -- Windows configurations briefly flicker TIP up/down while the pen is
    -- still physically touching. That used to restart Pickup Glide and pull
    -- values back toward their retained/default position.
    local now = r.time_precise()
    local raw_contact = b.tip or b.pressure > 0.001
  
    if raw_contact then
      b.contact_hold_until = now + 0.080
    end
  
    local stable_contact = raw_contact or now < (b.contact_hold_until or -1000.0)
    if stable_contact then TR.pen_in_use = true end

    process_values(x, y, pressure, ntx, nty, stable_contact)
  elseif owns_input and state.bridge.running then
    -- Overlay is covering the pad, so mouse clicks never reach ImGui.
    -- Hold last values until the pen comes back or the user hits STOP.
    process_values(state.last_x, state.last_y, state.last_p, state.last_tx, state.last_ty, false)
  elseif owns_input then
    state.freeze_x = hovered and ImGui.IsMouseDown(ctx, 1)
    state.freeze_y = hovered and ImGui.IsMouseDown(ctx, 2)
  
    if active then
      local x = clamp((mx - sx) / pad_w, 0, 1)
      local y = 1 - clamp((my - sy) / pad_h, 0, 1)
      local p = shape_pressure(state.pressure)
      if state.freeze_x then x = state.last_x end
      if state.freeze_y then y = state.last_y end
      process_values(x, y, p, 0.5, 0.5, true)
    else
      process_values(state.last_x, state.last_y, state.last_p, state.last_tx, state.last_ty, false)
    end
  end
  
  local dl = ImGui.GetWindowDrawList(ctx)
  local bg, accent, grid, white = 0x171A1FFF, 0x72B4EDFF, 0x28313BFF, 0xE7EBEFFF
  local border = state.bridge.live and 0x56C57AFF
    or (state.bridge.running and 0xC9A227FF)
    or (hovered and 0x6FA6D9FF or 0x45505DFF)
  
  ImGui.DrawList_AddRectFilled(dl, sx, sy, sx + pad_w, sy + pad_h, bg, 5)
  ImGui.DrawList_AddRect(dl, sx, sy, sx + pad_w, sy + pad_h, border, 5, 0, 1.5)
  for i = 1, 3 do
    local gx, gy = sx + pad_w * (i/4), sy + pad_h * (i/4)
    ImGui.DrawList_AddLine(dl, gx, sy, gx, sy + pad_h, grid)
    ImGui.DrawList_AddLine(dl, sx, gy, sx + pad_w, gy, grid)
  end
  
  local now = update_xy_trail(owns_input)
  draw_tilt_trails(dl, sx, sy, pad_w, pad_h, now)
  draw_xy_trail(dl, sx, sy, pad_w, pad_h, now)

  local px = sx + state.last_x * pad_w
  local py = sy + (1 - state.last_y) * pad_h
  local radius = 7 + state.last_p * 24
  ImGui.DrawList_AddCircleFilled(dl, px, py, radius, accent)
  ImGui.DrawList_AddCircle(dl, px, py, radius + 4, white, 0, 1.5)
  
  local mode_text = "DIRECT / WACOM 5D"
  ImGui.DrawList_AddText(dl, sx + 12, sy + 10, white, mode_text)
  ImGui.DrawList_AddText(dl, sx + 12, sy + 30, 0xAEB8C2FF,
    string.format("OUT  X %.3f   Y %.3f   Z %.3f   TX %.3f   TY %.3f",
      apply_input_multiplier("X", state.inputs.X.value),
      apply_input_multiplier("Y", state.inputs.Y.value),
      apply_input_multiplier("Z", state.inputs.Z.value),
      apply_input_multiplier("TX", state.inputs.TX.value),
      apply_input_multiplier("TY", state.inputs.TY.value)))
  
  ImGui.DrawList_AddText(dl, sx + 12, sy + pad_h - 24, 0x84909BFF,
    state.bridge.live
      and "Native pen: pressure + tilt active   B1=freeze X   B2=freeze Y"
      or (state.bridge.running
        and "Bridge ready: hover the pen over the pad"
        or "Bridge offline: mouse + manual pressure fallback"))
end

local function draw_pad()
  ImGui.Separator(ctx)

  if ImGui.Button(ctx, "POP OUT XY PAD") then
    xy_popout_open = true
  end

  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 140)
  local follow_changed
  follow_changed, state.follow_ms = ImGui.SliderDouble(
    ctx, "FOLLOW (ms)", state.follow_ms or 8, 0.0, 40.0, "%.2f")
  if follow_changed then
    SE.apply_follow(state.follow_ms)
    save_state()
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      "How tightly ADFX Varispeed follows Rate/Pitch.\n" ..
      "0 = apply on the next audio sample (48 kHz at 48 k project rate).\n" ..
      "8 = the previous default. This does not create extra XY samples;\n" ..
      "the pad still writes new gestures once per frame, then the JSFX\n" ..
      "reads them every sample through gmem.")
  end

  -- v0.8.57: two even columns instead of four full-width rows. Sliders share
  -- one width and the second column starts at a fixed offset, so no label can
  -- be pushed off the edge of the performance column the way PRESSURE GAIN was.
  --
  -- The old SMOOTH slider is gone: nothing ever read state.smoothing, its
  -- smoothing was superseded by the per-input PICKUP GLIDE controls under
  -- INPUT RESPONSE. The state field itself is kept so old sessions still load.
  -- v0.8.59: all three on one line. The sliders share whatever is left after
  -- their own labels, measured rather than guessed, so the widest label cannot
  -- push the last control off the edge of the column.
  local show_fallback = not state.bridge.running and not state.bridge.live
  local labels = { "PRESS GAIN", "PRESS CURVE" }
  if show_fallback then labels[#labels + 1] = "PRESS FALLBACK" end

  local labels_w = 0
  for _, label in ipairs(labels) do
    labels_w = labels_w + ImGui.CalcTextSize(ctx, label)
  end
  -- Per control: the gap between slider and label, plus the gap to the next.
  local per_item_gap = 14
  local slider_w = clamp(
    (ImGui.GetContentRegionAvail(ctx) - labels_w - per_item_gap * #labels) / #labels,
    52, 150)

  local changed
  ImGui.SetNextItemWidth(ctx, slider_w)
  changed, state.pressure_gain = ImGui.SliderDouble(ctx, "PRESS GAIN", state.pressure_gain, 0.1, 4.0, "%.2f")
  if changed then save_state() end

  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, slider_w)
  changed, state.pressure_curve = ImGui.SliderDouble(ctx, "PRESS CURVE", state.pressure_curve, 0.25, 5.0, "%.2f")
  if changed then save_state() end

  -- With a pen connected the tablet supplies pressure, so the manual stand-in
  -- has nothing to do. The pad surface itself already says which is in use.
  if show_fallback then
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, slider_w)
    changed, state.pressure = ImGui.SliderDouble(ctx, "PRESS FALLBACK", state.pressure, 0.0, 1.0, "%.3f")
    if changed then save_state() end
  end

  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local pad_w = math.max(420, avail_w)

  -- Keep the XY pad prominent while reserving vertical space for
  -- the Input Response controls directly beneath it.
  local pad_h = math.max(300, math.min(430, avail_h * 0.52))

  draw_xy_surface("##paintpad", pad_w, pad_h, not xy_popout_open)
end

local function draw_xy_popout_window()
  if not xy_popout_open then return end

  ImGui.SetNextWindowSize(ctx, 1000, 800, ImGui.Cond_FirstUseEver)
  local visible, still_open = ImGui.Begin(ctx, "ADFXSound Sound Design Pad - XY Performance Pad", xy_popout_open, TR.NO_NAV or 0)
  xy_popout_open = still_open

  if visible then
    TR.claim_tab_keys()
    TR.push_no_tab_stop()
    ImGui.TextDisabled(ctx, "Resizable performance surface - close this window to return to the embedded pad")
    local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
    local pad_w = math.max(300, avail_w)
    local pad_h = math.max(260, avail_h)
    draw_xy_surface("##paintpad_popout", pad_w, pad_h, true)
    TR.pop_no_tab_stop()
  end

  ImGui.End(ctx)
end

load_state()
refresh_preset_list()

if state.pending_linked_preset and state.pending_linked_preset ~= "" then
  local linked_name = state.pending_linked_preset
  state.pending_linked_preset = nil
  if not load_preset_from_disk(linked_name) then
    -- Missing/moved preset: keep project link visible but start empty.
    reset_state_to_empty()
    state.linked_preset = linked_name
    state.status = "Linked preset missing: " .. linked_name
  end
end

-- Initialize live control values from their configured defaults.
-- X/Y/Tilt default to midpoint; Pressure defaults to zero.
for _, name in ipairs(INPUT_NAMES) do
  state.inputs[name].value = clamp(state.inputs[name].default_value, 0, 1)
end
sync_last_fields_from_inputs()

if not SE.has_api() then
  state.status = "Sample engine needs REAPER 6+ (TrackFX + AudioAccessor)."
elseif not SE.ensure_installed() then
  state.status = "Could not find ADFX_Varispeed.jsfx. Put it next to this script, or in an effects subfolder."
else
  SE.gmem_ok()
  SE.apply_follow(state.follow_ms)
end

RC.prime_outputs = apply_input_outputs

-- Shared ADFX output recorder, optional. The pad used to hard-require
-- Scripts/ADFX/Modules/ADFX_Recorder.lua; that file is not part of this
-- standalone sample-engine slice, so a missing module becomes a no-op strip.
local RECORDER_STRIP_H = 64
local recorder
do
  local recorder_path = RECORDER_PATH
  local recorder_missing = RECORDER_MISSING
  local ok, Recorder = false, nil
  if not recorder_missing then
    ok, Recorder = pcall(dofile, recorder_path)
  end
  if ok and type(Recorder) == "table" and Recorder.new then
    local built
    ok, built = pcall(Recorder.new, {
      id          = "adfx_sound_design_pad",
      name_prefix = "ADFX_SDPad",
      label       = "RECORDER",
      height      = RECORDER_STRIP_H,
      capture     = "master",
      -- S-Layer and the standalone demo both record through the capture
      -- JSFX. Record only marks a slice of that buffer; the arrange is
      -- never rolled. The pad used to pass transport = "none", which the
      -- engine treats as timeline recording: ACTION_RECORD from the edit
      -- cursor, through the pad's loop points and time selection. Live
      -- meters still looked right; the take those peaks were rebuilt from
      -- after Stop did not match the file you drag out.
      backend     = "buffer",
      transport   = "isolated",
      imgui       = ImGui,
    })
    if ok and type(built) == "table" then
      recorder = built
      local engine = recorder.engine
      if engine then
        -- Peak extraction uses CreateTakeAudioAccessor + the accessor's
        -- start/end times. Those follow the item's project position, and
        -- this pad's edit cursor is usually sitting on the looped items,
        -- not 0. S-Layer and the demo typically scan a take at time 0, so
        -- their preview matches the file; ours did not. Park the take at
        -- 0 / playrate 1 for the scan, then put it back.
        local orig_peaks = engine._peaks_from_samples
        if type(orig_peaks) == "function" then
          function engine:_peaks_from_samples(take, length)
            local item = take and r.GetMediaItemTake_Item(take)
            local saved_pos, saved_rate
            if item and r.ValidatePtr2(0, item, "MediaItem*") then
              saved_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
              saved_rate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
              if saved_pos and saved_pos ~= 0 then
                r.SetMediaItemPosition(item, 0, false)
              end
              if saved_rate and saved_rate ~= 1 then
                r.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", 1)
              end
            end
            local peaks = orig_peaks(self, take, length)
            if item and saved_pos and saved_pos ~= 0 then
              r.SetMediaItemPosition(item, saved_pos, false)
            end
            if take and saved_rate and saved_rate ~= 1 then
              r.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", saved_rate)
            end
            return peaks
          end
        end
        -- Second pass from the bounced file on a clean take, matching
        -- what drag-out inserts. Covers the transport fallback.
        if type(engine.tick) == "function"
          and type(engine.rebuild_peaks) == "function" then
          local orig_tick = engine.tick
          local rebuilt_for = nil
          function engine:tick(...)
            orig_tick(self, ...)
            local cur = self.current
            if self.state == "ready" and cur and cur.path and cur ~= rebuilt_for then
              rebuilt_for = cur
              self:rebuild_peaks()
            end
          end
        end
      end
    end
  end
  if not recorder then
    -- Missing-module notification already ran before ImGui.CreateContext. Do not
    -- open modal dialogs here: the ReaImGui context is live at this point.
    if not recorder_missing then
      state.status = "ADFX_Recorder.lua was found but could not be loaded or initialized. Reinstall/update the Recorder module; the pad will continue without it."
    end
    recorder = {
      reserved_height = function() return 0 end,
      draw = function() end,
      shutdown = function() end,
      consume_space = function() return false end,
    }
  end
end

-- Reached from TR.handle_keyboard, which runs before this point in the file.
function RC.consume_space()
  return recorder:consume_space()
end

local open = true
local function loop()
  -- Capture a genuine plugin touch before Paint Pad performs any of its own
  -- parameter writes for this frame.
  sample_external_last_touched()
  BR.poll()

  TR.pen_in_use = false
  pcall(function()
    local flags = ImGui.GetConfigFlags(ctx)
    local nav = ImGui.ConfigFlags_NavEnableKeyboard
    if type(nav) == "function" then nav = nav() end
    if flags and nav then ImGui.SetConfigFlags(ctx, flags & ~nav) end
  end)

  -- Drop finished voices before REC looks at engine playing-state.
  SE.poll()

  -- Before any writes, so a pass that starts this frame captures this frame.
  RC.update()

  update_modulator_assignments()
  update_amplitude_assignments()

  -- Wider default layout: configuration scrolls on the left while the
  -- performance pad remains permanently visible on the right.
  ImGui.SetNextWindowSize(ctx, 1480, 960, ImGui.Cond_FirstUseEver)

  local visible
  visible, open = ImGui.Begin(ctx, "ADFXHelper; sound design pad v1.0.3", open, TR.NO_NAV or 0)
  if visible then
    pcall(function()
      if ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows) then
        ImGui.SetNextFrameWantCaptureKeyboard(ctx, true)
      end
    end)
    TR.claim_tab_keys()
    TR.push_no_tab_stop()
    local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
    local gap = 8

    -- The recorder is a full-width footer under both columns, so take its
    -- height out of the space the columns share before laying them out.
    local recorder_h = recorder:reserved_height(ctx)
    local column_h = math.max(avail_h - recorder_h, 240)

    local performance_w = math.max(500, math.min(650, avail_w * 0.42))
    local config_w = avail_w - performance_w - gap

    if config_w < 520 then
      config_w = math.max(360, avail_w * 0.52)
      performance_w = math.max(360, avail_w - config_w - gap)
    end

    -- LEFT: independently scrolling configuration/routing column.
    local config_visible = ImGui.BeginChild(
      ctx, "##sdpp_config_column", config_w, column_h, 0, TR.NO_NAV or 0
    )

    if config_visible then
      -- v0.8.36: reduce the ADFX SOUND logo by ~5% and center it within
      -- the open header area to the right of the preset controls. This keeps
      -- visually equal breathing room on the left and right while retaining
      -- safe clearance from the config-pane scrollbar/separator.
      if logo_image then
        local logo_w = math.min(304, math.max(190, config_w * 0.361))
        local logo_h = logo_w * (204 / 1357)
        local save_x, save_y = ImGui.GetCursorPos(ctx)
        local logo_area_left = math.min(480, config_w * 0.56)
        local logo_area_right = config_w - 18
        local logo_area_w = math.max(logo_w, logo_area_right - logo_area_left)
        local logo_x = logo_area_left + (logo_area_w - logo_w) * 0.5
        ImGui.SetCursorPos(ctx, logo_x, save_y)
        ImGui.Image(ctx, logo_image, logo_w, logo_h)
        ImGui.SetCursorPos(ctx, save_x, save_y)
      end

      draw_preset_bar()
      draw_mode_bar()

      if state.touch_cache.valid then
        local tr = track_from_index(state.touch_cache.track_idx)
        -- v0.8.33: keep touch-cache timing internally, but do not expose its age in the UI.
        ImGui.TextDisabled(ctx,
          "LEARN SOURCE: " ..
          fx_name(tr, state.touch_cache.fx) ..
          "  •  " ..
          param_name(tr, state.touch_cache.fx, state.touch_cache.param))
      else
        ImGui.TextDisabled(ctx, "LEARN SOURCE: touch a plugin parameter")
      end


      -- v0.8.23: keep global modulation sources directly below DIRECT /
      -- LEARN SOURCE and immediately above the input assignment buses.
      draw_lfo_section()

      -- v0.8.55: global restraint sits between the modulation sources and the
      -- buses it acts on, which is where it reads in signal order.
      GR.draw_section()

      draw_bus("X", "X BUS")
      draw_bus("Y", "Y BUS")
      draw_bus("Z", "PRESS")
      draw_bus("TX", "TILT X")
      draw_bus("TY", "TILT Y")

      ImGui.Separator(ctx)
      ImGui.TextDisabled(ctx, state.status)

      if state.range_preview.active then
        ImGui.Text(ctx, "RANGE PREVIEW — release slider to return to input default")
      end
    end

    ImGui.EndChild(ctx)

    ImGui.SameLine(ctx, nil, gap)

    -- RIGHT: fixed performance column.
    local performance_visible = ImGui.BeginChild(
      ctx, "##sdpp_performance_column", performance_w, column_h, 0, TR.NO_NAV or 0
    )

    if performance_visible then
      -- TRANSPORT is a fixed footer, not the last thing in the scroll region.
      -- Everything above it shares what is left, so shrinking the window
      -- squeezes the pad instead of cropping the transport controls off the
      -- bottom edge where they cannot be reached.
      if ImGui.BeginChild(ctx, "##sdpp_performance_scroll", 0, -TR.SECTION_H, 0, 0) then
        BR.draw_status()
        draw_live_input_monitor()
        draw_pad()
        draw_input_response_controls()
      end
      ImGui.EndChild(ctx)

      TR.draw_section()
    end

    ImGui.EndChild(ctx)

    -- Full-width recorder footer, under both columns.
    recorder:draw(ctx)

    TR.pop_no_tab_stop()
    ImGui.End(ctx)
  end

  -- Render the optional large XY pad as an independent ReaImGui window.
  -- It shares the same live control state as the embedded performance pad.
  draw_xy_popout_window()

  -- After every window, so the spacebar works whichever of them has focus.
  TR.handle_keyboard()

  if open then
    r.defer(loop)
  else
    BR.deactivate_overlay()
    save_state()
    SE.stop_voices()
    recorder:shutdown()
  end
end

r.atexit(function()
  BR.deactivate_overlay()
  SE.stop_voices()
  if SE.gmem_clear then SE.gmem_clear() end
  recorder:shutdown()
end)

r.defer(loop)
