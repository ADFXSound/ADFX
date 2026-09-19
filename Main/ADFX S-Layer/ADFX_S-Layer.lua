-- @description ADFX_S-Layer
-- @version 2.0.0
-- @author ADFXSound

--[[
  ADFX S-Layer v0.2.66
  REAPER / ReaImGui prototype inspired by the workflow of Twisted Tools S-LAYER

  This is an original implementation. It does not contain or redistribute S-LAYER code,
  samples, artwork, or proprietary resources.

  Architecture:
    * ReaImGui controller + project state
    * 16 managed REAPER child tracks
    * REAPER source tracks are scanned as sample pools
    * hidden ADFX Trigger Bridge JSFX -> ReaSamplOmatic5000 -> Duck JSFX playback engines
    * 8 scenes
    * one row per layer: every per-layer control is on it
    * per-trigger global randomization of pitch, volume, pan, start, reverse, FX and side-chain duck
    * CHOKE decides whether a new trigger interrupts the previous shot
    * right-drag down a column to paint a value into every lane it crosses
    * RESET restores one column, or all of them, to a fresh layer's values
    * ASSIGN SELECTED lays a track selection into the free lanes in one press
    * ASSIGN + FX prints each source track's FX chain onto its items first,
      then assigns; tracks with no enabled FX use the normal assign path.
      Each item keeps its original take plus one replaceable FX take.
      Unchanged FX chains are skipped; already-assigned tracks still reprint
      when the chain changed. Per-lane FX toggles wet / dry on that source.
    * right click a recorded sound to restore the rack that made it, in its
      own scene




  v0.2.83:
    * SIDECHAIN Shuffle pairs all 16 lanes into 8 random mates each
      TRIGGER (same idea as Pair, but the matching is re-rolled)

  v0.2.82:
    * SIDECHAIN Shuffle mode: each TRIGGER picks a new directed pair
      (any lane -> any other lane) and walks every permutation before
      reshuffling, instead of Pair's fixed L1↔L9 mates

  v0.2.81:
    * key lanes show a horizontal green line on the waveform that rides the
      side-chain envelope so you can see what is doing the ducking

  v0.2.80:
    * SIDECHAIN now rides the key lane's audio against a Threshold instead of
      firing a one-shot envelope on TRIGGER. Loud / quiet / loud on the key
      ducks a lot / a little / a lot. Amount is max depth above threshold.

  v0.2.79:
    * ducked lanes show a horizontal red line on the waveform that drops
      with the side-chain envelope so the duck is visible next to the
      green playhead

  v0.2.78:
    * each playback lane owns FX3 ADFX S-Layer Duck after RS5K; user FX stay
      after it and still hear the ducked dry hit
    * GLOBAL TRIGGER RANDOM SIDECHAIN: Mode, RND, RND MODE, Amount / Attack /
      Release min-max. Mode Off writes no duck. RND MODE never picks Off.
    * each TRIGGER latches mode+values into gmem; LAST TRIGGER replays the
      last shot's duck; CHOKE does not cancel an in-progress envelope

  v0.2.77:
    * REC LAST now actually gates capture: off pauses an open Signal Session
      (and closes an open Auto take) before LAST TRIGGER plays, so the replay
      is not appended to the current recording

  v0.2.76:
    * LAST TRIGGER can follow Auto / Signal Session the same way TRIGGER does.
      REC LAST next to the button turns that off when a replay should stay
      diagnostic-only

  v0.2.75:
    * ASSIGN + FX keeps printing when another program is in front instead of
      pausing; STOP ALL stays clickable because one item is printed per frame
    * media-offline-on-inactive is still held off during the print so items
      do not stay offline after a focus change

  v0.2.74:
    * TAKE 1 and +2 SEC run the ADFX item helpers on the current selection
      without leaving S-Layer
    * ASSIGN and ASSIGN + FX run as a cancellable pipeline; STOP ALL aborts
      the import as well as sounding voices
    * ASSIGN + FX no longer leaves printed items offline when REAPER loses
      focus: media-offline-on-inactive is held off during the print, printing
      pauses while another program is in front, and new FX takes are forced
      online with peaks rebuilt

  v0.2.73:
    * GLOBAL TRIGGER RANDOM FX checkbox independently turns each source's
      printed FX take on or off per TRIGGER; ignored when no FX take exists
    * the lane item-count column is fixed-width so 10+ variations no longer
      shift RND and the sliders off the grid

  v0.2.72:
    * per-lane FX next to USE SELECTED toggles that source between the
      original take and the printed ADFX FX take (prints on first use)
    * ASSIGN + FX hashes the track FX chain and reprints only tracks that
      changed, including tracks that are already assigned

  v0.2.71:
    * Loop / Rev / Mute / Solo are unlabeled boxes under a single header row
      so each box sits in its column instead of between two names.

  v0.2.70:
    * ASSIGN + FX keeps one original take and one FX take per item. Using the
      button again replaces that FX take with the latest chain instead of
      stacking another take.

  v0.2.69:
    * ASSIGN + FX prints each selected track's enabled FX chain onto its
      items as new takes, then fills free lanes the same way as ASSIGN SELECTED.
      Tracks with no enabled FX, or no audio items, skip the print and assign
      with the original files.

  v0.2.68:
    * Recorder Signal Session now defaults ON when S-Layer opens.

  v0.2.64:
    * CHOKE now stops every currently sounding S-Layer sampler voice before a new
      shot is fired, including lanes that do not participate in the new shot
    * added STOP ALL beside the trigger controls for immediately killing long sounds
    * CLEAR LANES now performs STOP ALL first, so unassigned long sounds cannot keep ringing
    * STOP ALL also aborts ASSIGN / ASSIGN + FX while either is still importing

  v0.2.61:
    * recorder module is now an optional dependency: if ADFX_Recorder.lua is not
      installed, S-Layer opens normally and shows a clear install message instead
      of exposing Lua's raw "cannot open ... No such file or directory" error

  v0.2.62:
    * recorder dependency preflight now runs before the ReaImGui context is created
    * missing ADFX_Recorder.lua shows a clean install message without invalidating S-Layer
    * recorder load/init failures are reported in S-Layer status instead of modal dialogs

  v0.2.60:
    * fixed the ADFX logo becoming an invalid ImGui_Image after collapsing/restoring
      the window by explicitly attaching the image resource to the ImGui context
    * logo drawing now fails safely and recreates/re-attaches the image if ReaImGui
      invalidates it during a window/context transition

  v0.2.59:
    * fixed an ImGui child-window assertion when collapsing S-Layer by only calling
      EndChild after BeginChild actually opens the body child for that frame

  v0.2.58:
    * corrected GLOBAL TRIGGER RANDOM section spacing: restored the Start/Reverse
      divider to the center of its gap and moved the Narrow Current section right
      so both divider gaps use the same 32 px section spacing

  v0.2.57:
    * made the two GLOBAL TRIGGER RANDOM vertical dividers use matching horizontal
      padding so both section gaps read with the same visual spacing

  v0.2.56:
    * guards sample loading against stale REAPER MediaTrack pointers
    * if an engine lane reference becomes stale, refreshes the engine references
      before writing the RS5K FILE0/DONE named config parameters

  v0.2.55:
    * fixed the 16-lane assignment grid so L1-L9 and L10-L16 use the same
      fixed column positions; two-digit lane numbers no longer push the row controls right

  v0.2.54:
    * added subtle vertical divider lines between the Pitch/Volume/Pan,
      Start/Reverse, and Narrow Current sections

  v0.2.53:
    * moved NARROW CURRENT + Range x onto the Pitch / Start row
    * Reverse Odds slider now matches the 92 px width used by the Start range controls

  v0.2.52:
    * when NARROW CURRENT is turned OFF during recorder-restore isolation, return
      to the original isolated restore state instead of releasing it: all lane RND
      checkboxes OFF and Pitch/Volume/Pan/Start/Reverse Global Random disabled
    * RESTORE remains the explicit exit from recorder-restore isolation and still
      reinstates the pre-restore Global Random + per-lane RND setup

  v0.2.48:
    * RESTORE keeps flashing by color only; removed the alternating asterisk label
    * tuned first-open window size to 1380x880 for a better fit on 2K displays while keeping lane controls visible

  v0.2.47:
    * RESTORE now flashes while recorder-restore isolation is active, making the
      temporary exact-shot state visually obvious until it is released

  v0.2.46:
    * pressing NARROW CURRENT after a recorder restore reinstates every lane's
      saved RND checkbox state before capturing the narrow sweet spot
    * the temporary RESTORE button remains responsible for restoring the broad
      Global Trigger Random setup; lane RND is no longer dependent on pressing it

  v0.2.45:
    * recorder-restore isolation button renamed from ISO SETTINGS to RESTORE
    * RESTORE also reinstates every lane's pre-restore RND/sample-random checkbox state

  v0.2.44:
    * recorder restore now snapshots the complete GLOBAL TRIGGER RANDOM setup before
      isolating the restored shot. A temporary RESTORE button appears beside
      NARROW CURRENT; clicking it restores Pitch/Volume/Pan/Start/Reverse enable
      states, ranges and Reverse odds exactly as they were, then the button disappears

  v0.2.43:
    * recorder restore reliably forces Auto Record OFF across older shared recorder layouts

  v0.2.42:
    * recorder restore requests Auto Record OFF before loading the diagnostic shot

  v0.2.41:
    * removed Repair Engine and Refresh Pools from the persistent header; Repair Engine remains under File
    * compact top layout: status first, then Trigger controls, then Scenes on the next row

  v0.2.40:
    * NARROW CURRENT always initializes OFF when S-Layer is opened or a project
      is reloaded. Captured centers and the Range multiplier are still restored,
      but Narrow must be deliberately enabled for the current session.

  v0.2.39:
    * Narrow Range multiplier defaults to 2.00x for new/reset scenes
    * NARROW CURRENT is a true mode toggle and no longer rewrites the normal
      GLOBAL TRIGGER RANDOM enable states or broad ranges
    * Narrow OFF makes TRIGGER use the normal Global settings exactly as configured
    * NARROW CURRENT is green while active and red while inactive

  v0.2.38:
    * restoring recorder settings now becomes the source for LAST TRIGGER, so T
      replays the restored rack instead of an older journal entry
    * lane RND checkboxes support the same right-drag paint gesture as Loop/Rev/M/S
    * NARROW CURRENT has a per-scene Range multiplier for fine-tuning sweet-spot spread
    * NARROW CURRENT and its Range control now live on the third global-random row

  v0.2.37:
    * NARROW CURRENT captures every lane's current Pitch, Volume, Pan and Start
      as a per-lane sweet spot, then future triggers vary only slightly around
      those centers instead of using the broad global ranges
    * narrow spreads are +/-1 semitone, +/-1 dB, +/-0.05 pan and +/-0.025 Start
    * Reverse, Loop, Mute and Solo are left exactly as-is while narrow mode runs

  v0.2.36:
    * startup-safe trigger bridge: loading an existing session no longer emits
      a phantom trigger from the previous gmem counter
    * bridge instances are recreated once when this bridge revision is installed
    * removed the redundant main-row Refresh Pools button; the header copy remains
    * GLOBAL TRIGGER RANDOM uses three compact rows: Pitch + Start, Volume + Reverse,
      then Pan, on a fixed column grid so Min / Max / Odds controls align perfectly
    * global numeric sliders show a live value tooltip while click-dragging, matching
      the immediate value feedback used by the per-lane paint workflow
    * click-drag across the five GLOBAL TRIGGER RANDOM enable checkboxes paints the
      starting checkbox state through every checkbox the pointer crosses
    * CLEAR ALL SCENES beside Copy Scene resets all eight scenes at once

  v0.2.35:
    * recorder timeline selection now owns Space before S-Layer auditioning
    * recorder UI is resolved before keyboard routing so a selected range plays
      instead of accidentally firing a new S-Layer trigger

  v0.2.33:
    * CLEAR LANES now clears the lane waveform preview and playhead/activity state
      immediately, so no stale waveform remains after a source is unassigned
    * upgraded the managed trigger bridge from 8 addressable lanes to all 16;
      this fixes Solo/triggering on L9-L16 while preserving Mute behavior
    * old bridge instances are automatically reassigned/rebuilt once when needed

  v0.2.32:
    * fixed first-open lane layout: empty/uninitialized waveforms can no longer
      leave ImGui in SameLine mode and make following lanes appear missing
    * waveform previews initialize from the lane pool before the first trigger
    * moved each lane waveform directly after USE SELECTED

  v0.2.31:
    * lane waveforms now live on the same horizontal row as the layer controls,
      using the remaining row width instead of creating a second strip underneath
    * waveform height matches the control row for a cleaner single-lane layout

  v0.2.30:
    * every layer has a compact cached waveform strip. The waveform is analyzed only
      when a new pool item is first shown, then reused; normal UI frames only draw it
    * fired layers get a moving playhead so the currently sounding region is visible
      without polling or re-analyzing the audio on every frame

  v0.2.29:
    * LAST TRIGGER keeps the current Mute/Solo state live, so individual layers can
      be isolated while the exact previous randomized sound remains frozen

  v0.2.28:
    * LAST TRIGGER replays the exact previous shot without running any randomizer:
      the same pool items and the same pitch, volume, pan, start and reverse values
      are restored, making a suspicious sound repeatable for diagnosis
    * T invokes LAST TRIGGER whenever the S-Layer window is focused, taking the key
      for S-Layer instead of allowing the normal REAPER shortcut to run

  v0.2.27:
    * every trigger is written down with the moment it fired. Right click a
      point in the recorded waveform and "Restore S-Layer settings from here"
      rebuilds that shot -- sources, chosen items, pitch, start, volume, pan,
      loop, reverse, mute, solo -- in a spare scene and switches to it, so the
      scene being worked in is untouched and the two can be compared
    * restoring pins the exact item each lane used and turns off any global
      randomizer that was running, so the next trigger plays what was heard

  v0.2.26:
    * 16 layers instead of 8
    * a trigger no longer rescans the project or reloads files it already has:
      the engine and the item pools are remembered between shots, a sampler is
      only handed a file when the file is different, and the wait before the
      note is only as long as the loads actually issued
    * if the installed trigger JSFX cannot address a layer index, the strip
      says which layers will not sound instead of failing silently

  v0.2.25:
    * CHOKE starts on and the recorder's Auto starts off
    * double-click the recorded waveform to play from that point. While it
      plays, Space stops the playback and nothing else; the press after that
      auditions again

  v0.2.24:
    * onboarding is one press: select the source tracks in REAPER and ASSIGN
      SELECTED fills the free lanes with them, in project order. CLEAR LANES
      empties the assignments again
    * the painting tip moved below the lane rows it describes

  v0.2.23:
    * painting covers the checkboxes: a right-drag through Loop, Rev, M or S
      writes one state into every lane it crosses
    * RESET buttons for Pitch, Start, Vol, Pan, Loop, Rev, Mute and Solo
    * the ISO checkbox is gone. It only shielded a layer from randomization,
      which mute already covers in practice, so randomization now reaches
      every layer

  v0.2.22:
    * value painting: right-drag a line through Pitch, Start, Vol or Pan and
      each lane takes the value where the line crossed it

  v0.2.21:
    * CHOKE toggle: a new trigger either interrupts the sounds still playing
      or lets them overlap

  v0.2.20:
    * Reverse actually plays backwards. RS5K has no reverse control, so the
      old write went nowhere; the item's own audio is now rendered backwards
      to a cached file and the sampler is pointed at that

  v0.2.19:
    * the recorder follows TRIGGER: a take opens with the sound and closes
      itself a second after it decays, so the strip needs no babysitting

  v0.2.18:
    * global trigger random covers Reverse, by odds rather than by range

  v0.2.17:
    * single page: the MAIN / ENV / MOD tabs are gone
    * the modulation sequencers and wrapper macros are removed outright
    * Loop and Reverse moved from the envelope page onto the layer row
    * Start joins the global trigger randomization; the Random Pitch / Mix /
      Start buttons go, since that section covers them with a range

  v0.2.16:
    * the Cells / precision editing block is gone; Start and ISO moved onto the
      layer row, which is the only place a layer is edited now

  v0.2.15 performance pass:
    * dirty-layer runtime updates instead of full-engine writes every UI frame
    * debounced project-state writes while dragging controls
    * Space triggers audition while the S-Layer window is focused

  v0.2.0 intentionally does NOT attempt granular time-stretching. That belongs in a
  dedicated DSP stage rather than Lua.
]]

local r = reaper
local VERSION = "0.2.83"
local TITLE = "ADFX S-Layer v" .. VERSION
local EXT_SECTION = "ADFX_SLAYER_V020"
local OLD_EXT_SECTION = "ADFX_SLAYER_V010"
local GMEM_NAME = "ADFX_SLayer_v020"
-- The trigger protocol puts a layer's trigger in gmem slot 9+li and its
-- acknowledgement in 29+li, so the slots collide past 20 layers. The installed
-- trigger JSFX also has to address the index; configure_engine_track checks
-- that it can and says so if it cannot.
-- Side-chain duck (high reserved): 80 mode, 81 amount, 82 attack ms, 83 release ms,
-- 84 threshold. Per-lane input envelopes live at 100+layer.
-- Shuffle key index for each bed lives at 120+layer (-1 = this lane is not a bed).
local NUM_LAYERS = 16
local NUM_SCENES = 8
local ROOT_NAME = "ADFX S-LAYER"
local TRIGGER_FX_NAMES = {
  -- TrackFX_AddByName() is most reliable for JSFX when addressed by its
  -- filename/basename. Keep the friendly desc forms as fallbacks.
  "JS: ADFX_SLayer_Trigger",
  "ADFX_SLayer_Trigger",
  "JS: ADFX S-Layer Trigger Bridge v0.2.6",
  "ADFX S-Layer Trigger Bridge v0.2.6",
  "JS: ADFX S-Layer Trigger Bridge v0.2.5",
  "ADFX S-Layer Trigger Bridge v0.2.5"
}
local RS5K_NAMES = {
  "VSTi: ReaSamplOmatic5000 (Cockos)",
  "ReaSamplOmatic5000 (Cockos)",
  "VST: ReaSamplOmatic5000 (Cockos)",
  "ReaSamplOmatic5000"
}
if not r.ImGui_CreateContext then
  r.MB("ADFX S-Layer requires ReaImGui. Install ReaImGui through ReaPack, then restart REAPER.", TITLE, 0)
  return
end

-- Check the optional shared recorder BEFORE creating the ReaImGui context. A native
-- REAPER message box blocks this script; showing it after CreateContext but before
-- the first ImGui frame can leave older ReaImGui builds holding an invalid context.
local ADFX_SEP = package.config:sub(1,1)
local RECORDER_MODULE_PATH = r.GetResourcePath() .. ADFX_SEP .. "Scripts" .. ADFX_SEP ..
  "ADFX" .. ADFX_SEP .. "Modules" .. ADFX_SEP .. "ADFX_Recorder.lua"
local RECORDER_MODULE_MISSING = not r.file_exists(RECORDER_MODULE_PATH)
if RECORDER_MODULE_MISSING then
  r.MB(
    "ADFX Recorder is not installed.\n\n" ..
    "Install ADFX_Recorder.lua in:\n" ..
    r.GetResourcePath() .. ADFX_SEP .. "Scripts" .. ADFX_SEP .. "ADFX" .. ADFX_SEP .. "Modules" ..
    "\n\nS-Layer will continue without the Recorder.",
    "ADFX Recorder Required", 0)
end

math.randomseed(os.time() + math.floor((r.time_precise() % 1) * 1000000))
r.gmem_attach(GMEM_NAME)

local ctx = r.ImGui_CreateContext(TITLE)

-- ADFX logo lives beside this script. Keep it as a separate PNG so ReaImGui can
-- load the original transparent artwork without baking image data into Lua.
local script_path = ({r.get_action_context()})[2] or ""
local script_dir = script_path:match("^(.*[\\/])") or ""
local logo_path = script_dir .. "ADFX_LOGO_BG_BANNER_CLEAR.png"
local adfx_logo = nil

local function create_adfx_logo()
  if not r.ImGui_CreateImage then return nil end
  local ok,img = pcall(r.ImGui_CreateImage,logo_path)
  if not ok or not img then return nil end

  -- ReaImGui resources that are only referenced from Lua can be invalidated after
  -- several frames where they are not submitted (for example while the parent
  -- window is collapsed). Attach the image to this context so its lifetime is
  -- tied to the S-Layer context rather than to whether it happened to be drawn.
  if r.ImGui_Attach then
    local attached = pcall(r.ImGui_Attach,ctx,img)
    if not attached then return nil end
  end
  return img
end

adfx_logo = create_adfx_logo()
local open = true
local selected_scene = 1
local last_apply = 0
local runtime_dirty_all = true
local runtime_dirty_layers = {}
local state_dirty = false
local last_state_change = 0
-- Built near the bottom, once the functions it is handed exist. Declared here
-- so the trigger path can tell it a sound is about to play.
local recorder

local function mark_layer_dirty(li)
  runtime_dirty_layers[li] = true
end

local function mark_all_dirty()
  runtime_dirty_all = true
end

local function mark_state_dirty()
  state_dirty = true
  last_state_change = r.time_precise()
end
local trigger_counter = 0
local pending_trigger = nil
local pending_ack = nil
local status = "Ready"
-- Kept apart from status because the trigger path rewrites status a few times
-- per shot and a reverse that could not be rendered must not scroll past.
local reverse_note = ""
local tracks = {}
-- Set when the installed trigger bridge refuses a layer index, which means the
-- JSFX in REAPER/Effects predates this lane count.
local bridge_layer_limit = nil
-- CHOKE on: a new trigger cuts whatever the layer is still playing.
-- CHOKE off: shots pile up and ring out over each other.
local choke = true
-- When on, LAST TRIGGER / T is treated like TRIGGER for Auto and Signal Session.
-- Off keeps LAST TRIGGER diagnostic-only so a replay does not open a new take.
local last_trigger_follow = true
local CHOKE_VOICES = 1
local OVERLAP_VOICES = 16
-- How long a trigger waits for RS5K to have its files ready. Nothing to load
-- means almost no wait; otherwise it grows with the number of loads issued, so
-- a full rack is still ready before the note arrives.
local PRE_ROLL = {NONE=0.010, BASE=0.060, PER_SWAP=0.010, MAX=0.300}
-- Screen rects of the painted controls, refreshed as the rows are drawn. They
-- cannot be computed ahead of time: a lane showing its Item slider pushes
-- everything after it to the right, so the rows are not a uniform grid.
local paint_rects = {}
local paint = nil

local function clamp(v, a, b) if v < a then return a elseif v > b then return b else return v end end
local function db_to_amp(db) return 10^(db/20) end
local function basename(p) return (p and p ~= "" and p:match("([^/\\]+)$")) or "(no sample)" end
local function pct_encode(s)
  s = tostring(s or "")
  return (s:gsub("([^%w%-%._~])", function(c) return string.format("%%%02X", string.byte(c)) end))
end
local function pct_decode(s)
  return (tostring(s or ""):gsub("%%(%x%x)", function(h) return string.char(tonumber(h,16)) end))
end

local function default_layer(i)
  return {
    sample="", source_guid="", source_name="", sample_index=1, random_sample=true, pool_count=0,
    pitch=0.0, start=0.0, volume_db=0.0, pan=0.0,
    attack=0.0, hold=0.0, decay=0.15, sustain=1.0, release=0.10,
    reverse=false, loop=false, mute=false, solo=false,
    grain=0.0, stretch=1.0, cutoff=1.0, resonance=0.0,
    send1=0.0, send2=0.0
  }
end

local function default_scene()
  local s = {layers={}}
  for i=1,NUM_LAYERS do s.layers[i] = default_layer(i) end
  return s
end

local scenes = {}
for i=1,NUM_SCENES do scenes[i] = default_scene() end

-- Project-global randomization applied immediately before every trigger.
-- Each enabled parameter generates an independent value for every layer.
local global_trigger_random = {
  Pitch  = {enabled=false, min=-12.0, max=12.0},
  Volume = {enabled=false, min=-6.0,  max=0.0},
  Pan    = {enabled=false, min=-1.0,  max=1.0},
  Start  = {enabled=false, min=0.0,   max=0.25},
  -- Reverse is a switch rather than a range, so it randomizes by chance:
  -- 0 leaves every layer forward, 1 reverses all of them.
  Reverse = {enabled=false, min=0.0, max=0.0, chance=0.5},
  -- Per-lane wet/dry. Only sources that already have an ADFX FX take are touched.
  FX = {enabled=false, min=0.0, max=0.0, chance=0.5}
}
local GLOBAL_RANDOM_ORDER = {"Pitch","Volume","Pan","Start","Reverse","FX"}

-- Per-shot side-chain duck. Mode 0 Off / 1 Bank (1-8→9-16) / 2 Invert (9-16→1-8) / 3 Pair.
-- RND rolls Amount/Threshold/Attack/Release. RND MODE picks 1/2/3 only — never Off.
-- When Mode is Off both randomizers are ignored and nothing ducks.
-- The JSFX rides key-lane audio against Threshold; Amount is max depth.
-- Helpers live on this table so they do not burn REAPER's 200-local chunk limit.
local sidechain = {
  mode=0, rnd=false, rnd_mode=false,
  amount_min=0.35, amount_max=0.70,
  thresh_min=0.12, thresh_max=0.35,
  attack_min=2.0, attack_max=15.0,
  release_min=80.0, release_max=320.0,
  restore_snapshot=nil,
  file_upgraded=false,
  file_ready=false,
  GMEM_MODE=80, GMEM_AMOUNT=81, GMEM_ATTACK=82, GMEM_RELEASE=83, GMEM_THRESH=84,
  GMEM_SHUFFLE=120,
  MODE_LABELS={"Off", "1-8→9-16", "9-16→1-8", "Pair", "Shuffle"},
  FX_NAMES={
    "JS: ADFX_SLayer_Duck",
    "ADFX_SLayer_Duck",
    "JS: ADFX S-Layer Duck",
    "ADFX S-Layer Duck"
  },
  SCHEMA_TAG="// ADFX_SLAYER_DUCK=3",
}

-- A recorder restore temporarily isolates the exact shot by turning off the global
-- randomizers that produced it. Keep the user's complete pre-restore global setup
-- here so one click can return to normal exploration. This is intentionally
-- session-only: it describes a temporary diagnostic mode, not project state.
local restore_global_random_snapshot = nil
-- Lane RND/sample-random states are part of the exploration setup too. A recorder
-- restore pins its exact source items by turning RND off, so remember the prior
-- per-lane states and put them back when the temporary RESTORE lock is released.
local restore_lane_random_snapshot = nil

-- A successful randomized combination can be treated as a per-lane sweet spot.
-- Unlike GLOBAL TRIGGER RANDOM, these are offsets around EACH lane's captured
-- value, so a rack whose layers landed at very different pitches/levels keeps
-- that relationship while still breathing a little on every trigger.
local NARROW_RANDOM_SPREAD = {Pitch=1.0, Volume=1.0, Pan=0.05, Start=0.025}
local NARROW_MULTIPLIER_MIN = 0.0
local NARROW_MULTIPLIER_MAX = 4.0
local narrow_random = {}
for si=1,NUM_SCENES do narrow_random[si]={active=false,multiplier=2.0,layers={}} end

local function copy_table(t)
  if type(t) ~= "table" then return t end
  local n = {}
  for k,v in pairs(t) do n[k] = copy_table(v) end
  return n
end

local function serialize_state()
  local out = {"version="..VERSION, "scene="..selected_scene}
  out[#out+1]=table.concat({"O","choke",choke and 1 or 0},"|")
  out[#out+1]=table.concat({"O","last_follow",last_trigger_follow and 1 or 0},"|")
  -- RESTORE lock is a temporary diagnostic state. If the project is saved while
  -- it is active, persist the user's pre-restore broad random setup rather than
  -- the temporarily-disabled runtime toggles. That way closing S-Layer while
  -- isolated cannot accidentally make the lock permanent.
  local global_to_save=restore_global_random_snapshot or global_trigger_random
  for _,name in ipairs(GLOBAL_RANDOM_ORDER) do
    local g=global_to_save[name]
    out[#out+1]=table.concat({"G",name,g.enabled and 1 or 0,g.min,g.max,g.chance or 0},"|")
  end
  local sc_to_save=sidechain.restore_snapshot or sidechain
  out[#out+1]=table.concat({"O","sc_mode",sc_to_save.mode or 0},"|")
  out[#out+1]=table.concat({"O","sc_rnd",sc_to_save.rnd and 1 or 0},"|")
  out[#out+1]=table.concat({"O","sc_rnd_mode",sc_to_save.rnd_mode and 1 or 0},"|")
  out[#out+1]=table.concat({"G","SC",0,
    sc_to_save.amount_min,sc_to_save.amount_max,
    sc_to_save.attack_min,sc_to_save.attack_max,
    sc_to_save.release_min,sc_to_save.release_max,
    sc_to_save.thresh_min,sc_to_save.thresh_max},"|")
  for si=1,NUM_SCENES do
    local nr=narrow_random[si]
    out[#out+1]=table.concat({"N",si,nr.active and 1 or 0,nr.multiplier or 2.0},"|")
    for li=1,NUM_LAYERS do
      local c=nr.layers[li]
      if c then
        out[#out+1]=table.concat({"C",si,li,c.pitch,c.volume_db,c.pan,c.start},"|")
      end
    end
  end
  -- Field 18 of an L line was the isolate flag. It is written as 0 rather than
  -- dropped, because an L line is positional and a build that still reads
  -- isolate would otherwise read the field after it.
  for si=1,NUM_SCENES do
    local s=scenes[si]
    for li=1,NUM_LAYERS do
      local L=s.layers[li]
      out[#out+1]=table.concat({"L",si,li,pct_encode(L.sample),L.pitch,L.start,L.volume_db,L.pan,L.attack,L.hold,L.decay,L.sustain,L.release,L.reverse and 1 or 0,L.loop and 1 or 0,L.mute and 1 or 0,L.solo and 1 or 0,0,L.grain,L.stretch,L.cutoff,L.resonance,L.send1,L.send2,pct_encode(L.source_guid),pct_encode(L.source_name),L.sample_index,L.random_sample and 1 or 0},"|")
    end
  end
  return table.concat(out,"\n")
end

local function save_state()
  r.SetProjExtState(0, EXT_SECTION, "state", serialize_state())
end

local function split(s, sep)
  local t, start = {}, 1
  while true do
    local a,b = string.find(s, sep, start, true)
    if not a then t[#t+1] = string.sub(s, start); break end
    t[#t+1] = string.sub(s, start, a-1)
    start = b + 1
  end
  return t
end

local function load_state()
  local ok, data = r.GetProjExtState(0, EXT_SECTION, "state")
  if ok == 0 or data == "" then
    ok, data = r.GetProjExtState(0, OLD_EXT_SECTION, "state")
  end
  if ok == 0 or data == "" then return end
  for line in data:gmatch("[^\r\n]+") do
    if line:match("^scene=") then selected_scene=clamp(tonumber(line:match("=(%d+)")) or 1,1,NUM_SCENES) end
    if line:sub(1,2)=="O|" then
      local p=split(line,"|")
      if p[2]=="choke" then choke=p[3]=="1" end
      if p[2]=="last_follow" then last_trigger_follow=p[3]=="1" end
      if p[2]=="sc_mode" then sidechain.mode=clamp(tonumber(p[3]) or 0,0,4) end
      if p[2]=="sc_rnd" then sidechain.rnd=p[3]=="1" end
      if p[2]=="sc_rnd_mode" then sidechain.rnd_mode=p[3]=="1" end
    elseif line:sub(1,2)=="G|" then
      local p=split(line,"|")
      if p[2]=="SC" then
        sidechain.amount_min=clamp(tonumber(p[4]) or sidechain.amount_min,0,1)
        sidechain.amount_max=clamp(tonumber(p[5]) or sidechain.amount_max,0,1)
        sidechain.attack_min=clamp(tonumber(p[6]) or sidechain.attack_min,0,50)
        sidechain.attack_max=clamp(tonumber(p[7]) or sidechain.attack_max,0,50)
        sidechain.release_min=clamp(tonumber(p[8]) or sidechain.release_min,0,800)
        sidechain.release_max=clamp(tonumber(p[9]) or sidechain.release_max,0,800)
        sidechain.thresh_min=clamp(tonumber(p[10]) or sidechain.thresh_min,0,1)
        sidechain.thresh_max=clamp(tonumber(p[11]) or sidechain.thresh_max,0,1)
        if sidechain.amount_min>sidechain.amount_max then
          sidechain.amount_min,sidechain.amount_max=sidechain.amount_max,sidechain.amount_min
        end
        if sidechain.attack_min>sidechain.attack_max then
          sidechain.attack_min,sidechain.attack_max=sidechain.attack_max,sidechain.attack_min
        end
        if sidechain.release_min>sidechain.release_max then
          sidechain.release_min,sidechain.release_max=sidechain.release_max,sidechain.release_min
        end
        if sidechain.thresh_min>sidechain.thresh_max then
          sidechain.thresh_min,sidechain.thresh_max=sidechain.thresh_max,sidechain.thresh_min
        end
      else
        local g=global_trigger_random[p[2]]
        if g then
          g.enabled=p[3]=="1"
          g.min=tonumber(p[4]) or g.min
          g.max=tonumber(p[5]) or g.max
          if g.chance then g.chance=tonumber(p[6]) or g.chance end
        end
      end
    elseif line:sub(1,2)=="N|" then
      local p=split(line,"|")
      local si=tonumber(p[2])
      if narrow_random[si] then
        -- Narrow is intentionally session-safe: never resume an active Narrow
        -- mode just because the project was saved while it was on. Keep the
        -- captured sweet spot/range data below, but require an explicit click
        -- each time S-Layer is opened.
        narrow_random[si].active=false
        narrow_random[si].multiplier=math.max(NARROW_MULTIPLIER_MIN,tonumber(p[4]) or 2.0)
      end
    elseif line:sub(1,2)=="C|" then
      local p=split(line,"|")
      local si,li=tonumber(p[2]),tonumber(p[3])
      if narrow_random[si] and li then
        narrow_random[si].layers[li]={
          pitch=tonumber(p[4]) or 0,
          volume_db=tonumber(p[5]) or 0,
          pan=tonumber(p[6]) or 0,
          start=tonumber(p[7]) or 0,
        }
      end
    elseif line:sub(1,2)=="L|" then
      local p=split(line,"|")
      local si,li=tonumber(p[2]),tonumber(p[3])
      if scenes[si] and scenes[si].layers[li] then
        local L=scenes[si].layers[li]
        L.sample=pct_decode(p[4]); L.pitch=tonumber(p[5]) or 0; L.start=tonumber(p[6]) or 0
        L.volume_db=tonumber(p[7]) or 0; L.pan=tonumber(p[8]) or 0; L.attack=tonumber(p[9]) or 0
        L.hold=tonumber(p[10]) or 0; L.decay=tonumber(p[11]) or .15; L.sustain=tonumber(p[12]) or 1; L.release=tonumber(p[13]) or .1
        L.reverse=p[14]=="1"; L.loop=p[15]=="1"; L.mute=p[16]=="1"; L.solo=p[17]=="1"
        L.grain=tonumber(p[19]) or 0; L.stretch=tonumber(p[20]) or 1; L.cutoff=tonumber(p[21]) or 1; L.resonance=tonumber(p[22]) or 0
        L.send1=tonumber(p[23]) or 0; L.send2=tonumber(p[24]) or 0
        L.source_guid=pct_decode(p[25] or ""); L.source_name=pct_decode(p[26] or "")
        L.sample_index=tonumber(p[27]) or 1; L.random_sample=(p[28] == nil) and true or p[28]=="1"
      end
    end
    -- M| and W| lines are modulation and wrapper state from before v0.2.17.
    -- They are simply skipped; a project saved by an older build still loads.
  end
end
load_state()

local BRIDGE_SCHEMA_TAG = "// ADFX_SLAYER_BRIDGE_BOOTSAFE=1"
local BRIDGE_SOURCE = [[
desc:ADFX S-Layer Trigger Bridge v0.2.7
// ADFX_SLAYER_BRIDGE_LAYERS=16
// ADFX_SLAYER_BRIDGE_BOOTSAFE=1
// Managed by ADFX S-Layer. One instance lives on each playback lane.
// slider2 is zero-based: 0=L1 ... 15=L16.

options:gmem=ADFX_SLayer_v020

slider1:60<0,127,1>Trigger note
slider2:0<0,15,1>Layer index

@init
// Never interpret the pre-existing shared-memory value as a new trigger when
// REAPER restores this FX from a saved project. The first audio block simply
// adopts whatever counter is already present, then subsequent changes fire.
armed = 0;
note = floor(slider1 + 0.5);
layer = floor(slider2 + 0.5);
last_counter = 0;

@slider
note = floor(slider1 + 0.5);
new_layer = floor(slider2 + 0.5);
// Changing/restoring the lane index also re-arms from that lane's current
// counter so moving the managed bridge can never create a phantom note.
new_layer != layer ? (
  layer = new_layer;
  armed = 0;
) : (
  layer = new_layer;
);

@block
counter = floor(gmem[10 + layer] + 0.5);
velocity = floor(gmem[1] + 0.5);
velocity < 1 ? velocity = 1;
velocity > 127 ? velocity = 127;

!armed ? (
  last_counter = counter;
  gmem[30 + layer] = counter;
  armed = 1;
) : counter != last_counter ? (
  midisend(0, $x90, note, velocity);
  midisend(max(0, samplesblock-1), $x80, note, 0);
  gmem[30 + layer] = counter;
  last_counter = counter;
);
]]

local bridge_file_upgraded = false
local function install_bridge_if_missing()
  local resource = r.GetResourcePath()
  local effects_dir = resource .. "/Effects/ADFX"

  -- Keep all ADFX-managed JSFX together under REAPER/Effects/ADFX.
  -- Create the folder on first run so a clean installation can write the bridge.
  r.RecursiveCreateDirectory(effects_dir, 0)

  local target = effects_dir .. "/ADFX_SLayer_Trigger.jsfx"

  local current = nil
  local f=io.open(target,"rb")
  if f then current=f:read("*a"); f:close() end
  if current and current:find(BRIDGE_SCHEMA_TAG,1,true) then return true end

  -- This bridge is owned by S-Layer. Older builds only exposed layer indices
  -- 0..7, which makes L9-L16 look like Solo is broken even though Mute still
  -- works (Mute is applied directly to the REAPER playback tracks).
  local wf,why=io.open(target,"wb")
  if not wf then
    status = "Could not update ADFX_SLayer_Trigger.jsfx: "..tostring(why)
    return false
  end
  wf:write(BRIDGE_SOURCE)
  wf:close()
  bridge_file_upgraded = true
  return true
end

sidechain.SOURCE = [[
desc:ADFX S-Layer Duck
author: ADFXSound
version: 1.2
// ADFX_SLAYER_DUCK=3
// Managed by ADFX S-Layer. One instance lives on each playback lane after RS5K.
// slider1 is zero-based: 0=L1 ... 15=L16.
// Modes: 0 Off, 1 Bank, 2 Invert, 3 Pair (L<->L+8), 4 Shuffle (gmem 120+layer = key).
// Each instance publishes its input envelope to gmem[100+layer]. Beds ride the
// key envelope against a threshold so GR follows loud / quiet / loud.
// Shuffle: Lua writes one directed pair per TRIGGER into gmem[120+layer].

options:gmem=ADFX_SLayer_v020

slider1:0<0,15,1>Layer index
slider2:0<0,4,1{Off,Bank,Invert,Pair,Shuffle}>Mode
slider3:0<0,1,0.001>Amount
slider4:0<0,50,0.1>Attack ms
slider5:20<0,800,0.1>Release ms
slider6:1<0,1,0.001>Gain
slider7:0.15<0,1,0.001>Threshold

@init
layer = floor(slider1 + 0.5);
gain = 1;
det = 0;
latched_mode = 0;
latched_amount = 0;
latched_threshold = 0.15;
latched_attack_ms = 0;
latched_release_ms = 20;
att_coeff = 1;
rel_coeff = 1;
det_rel_coeff = 1;

@slider
new_layer = floor(slider1 + 0.5);
new_layer != layer ? layer = new_layer : layer = new_layer;

@block
latched_mode = floor(gmem[80] + 0.5);
latched_mode < 0 ? latched_mode = 0;
latched_mode > 4 ? latched_mode = 4;
latched_amount = gmem[81];
latched_amount < 0 ? latched_amount = 0;
latched_amount > 1 ? latched_amount = 1;
latched_attack_ms = gmem[82];
latched_attack_ms < 0 ? latched_attack_ms = 0;
latched_release_ms = gmem[83];
latched_release_ms < 0 ? latched_release_ms = 0;
latched_threshold = gmem[84];
latched_threshold < 0 ? latched_threshold = 0;
latched_threshold > 1 ? latched_threshold = 1;
slider2 = latched_mode;
slider3 = latched_amount;
slider4 = latched_attack_ms;
slider5 = latched_release_ms;
slider7 = latched_threshold;

latched_attack_ms <= 0 ? att_coeff = 1 : att_coeff = 1 - exp(-2.2 / (latched_attack_ms * 0.001 * srate));
latched_release_ms <= 0 ? rel_coeff = 1 : rel_coeff = 1 - exp(-2.2 / (latched_release_ms * 0.001 * srate));
det_rel_coeff = 1 - exp(-2.2 / max(1, 0.008 * srate));
mate = layer < 8 ? layer + 8 : layer - 8;
shuffle_key = floor(gmem[120 + layer] + 0.5);

@sample
pk = abs(spl0);
abs(spl1) > pk ? pk = abs(spl1);
pk > det ? det = pk : det += (pk - det) * det_rel_coeff;
gmem[100 + layer] = det;

key = 0;
latched_mode == 1 && layer >= 8 ? (
  i = 0;
  loop(8,
    gmem[100 + i] > key ? key = gmem[100 + i];
    i += 1;
  );
);
latched_mode == 2 && layer < 8 ? (
  i = 8;
  loop(8,
    gmem[100 + i] > key ? key = gmem[100 + i];
    i += 1;
  );
);
latched_mode == 3 ? key = gmem[100 + mate];
latched_mode == 4 && shuffle_key >= 0 && shuffle_key <= 15 && shuffle_key != layer ? (
  key = gmem[100 + shuffle_key];
);

target = 1;
latched_mode > 0 && key > latched_threshold ? (
  span = 1 - latched_threshold;
  span < 0.0001 ? span = 0.0001;
  over = (key - latched_threshold) / span;
  over > 1 ? over = 1;
  target = 1 - latched_amount * over;
);

target < gain ? (
  gain += (target - gain) * att_coeff;
) : (
  gain += (target - gain) * rel_coeff;
);

spl0 *= gain;
spl1 *= gain;
slider6 = gain;
]]

function sidechain.install_if_missing()
  local resource = r.GetResourcePath()
  local effects_dir = resource .. "/Effects/ADFX"
  r.RecursiveCreateDirectory(effects_dir, 0)
  local target = effects_dir .. "/ADFX_SLayer_Duck.jsfx"

  local current = nil
  local f=io.open(target,"rb")
  if f then current=f:read("*a"); f:close() end
  if current and current:find(sidechain.SCHEMA_TAG,1,true) then return true end

  local wf,why=io.open(target,"wb")
  if not wf then
    status = "Could not update ADFX_SLayer_Duck.jsfx: "..tostring(why)
    return false
  end
  wf:write(sidechain.SOURCE)
  wf:close()
  sidechain.file_upgraded = true
  return true
end

local function track_by_guid(guid)
  if not guid then return nil end
  for i=0,r.CountTracks(0)-1 do local tr=r.GetTrack(0,i); if r.GetTrackGUID(tr)==guid then return tr end end
end

local function find_root_track()
  for i=0,r.CountTracks(0)-1 do
    local tr=r.GetTrack(0,i); local _,name=r.GetTrackName(tr)
    if name==ROOT_NAME then return tr,i end
  end
end

local function add_fx_any(track, names)
  for _,name in ipairs(names) do
    local fx=r.TrackFX_AddByName(track,name,false,-1)
    if fx>=0 then return fx end
  end
  return -1
end

local function add_trigger_fx(track)
  return add_fx_any(track, TRIGGER_FX_NAMES)
end

function sidechain.add_fx(track)
  return add_fx_any(track, sidechain.FX_NAMES)
end

function sidechain.is_name(name)
  local low=(name or ""):lower()
  return low:find("adfx s-layer duck",1,true) ~= nil
      or low:find("adfx_slayer_duck",1,true) ~= nil
end

function sidechain.find(track)
  for fx=0,r.TrackFX_GetCount(track)-1 do
    local _,name=r.TrackFX_GetFXName(track,fx,"")
    if sidechain.is_name(name) then return fx end
  end
  return -1
end

local function find_fx_by_name(track, needle)
  for fx=0,r.TrackFX_GetCount(track)-1 do
    local _,name=r.TrackFX_GetFXName(track,fx,"")
    if name:lower():find(needle:lower(),1,true) then return fx end
  end
  return -1
end

local function is_rs5k_name(name)
  local low=(name or ""):lower()
  -- Important: once a sample is loaded REAPER commonly displays RS5K as
  -- "SampleName.wav (RS5K)" rather than "ReaSamplOmatic5000".
  return low:find("reasamplomatic",1,true) ~= nil
      or low:find("samplomatic",1,true) ~= nil
      or low:find("(rs5k)",1,true) ~= nil
      or low:find("rs5k",1,true) ~= nil
end

local function find_all_rs5k(track)
  local out={}
  for fx=0,r.TrackFX_GetCount(track)-1 do
    local _,nm=r.TrackFX_GetFXName(track,fx,"")
    if is_rs5k_name(nm) then out[#out+1]=fx end
  end
  return out
end

local function find_rs5k(track)
  local all=find_all_rs5k(track)
  if #all>0 then return all[1] end
  if r.TrackFX_GetInstrument then
    local inst=r.TrackFX_GetInstrument(track)
    if inst and inst>=0 then
      local _,nm=r.TrackFX_GetFXName(track,inst,"")
      if is_rs5k_name(nm) then return inst end
    end
  end
  return -1
end

local function ensure_rs5k(track)
  local fx=find_rs5k(track)
  if fx>=0 then return fx end

  -- TrackFX_GetByName(..., true) is a very reliable path for Cockos instruments.
  if r.TrackFX_GetByName then
    for _,name in ipairs(RS5K_NAMES) do
      local idx=r.TrackFX_GetByName(track,name,true)
      if idx and idx>=0 then
        fx=find_rs5k(track)
        if fx>=0 then return fx end
        -- Some REAPER builds return the index before the friendly name refreshes.
        return idx
      end
    end
  end

  -- Final fallback: force-create by name and then rediscover.
  for _,name in ipairs(RS5K_NAMES) do
    local idx=r.TrackFX_AddByName(track,name,false,-1)
    if idx and idx>=0 then
      fx=find_rs5k(track)
      if fx>=0 then return fx end
      return idx
    end
  end
  return -1
end

local function find_param(track, fx, needles)
  if not track or fx<0 then return -1 end
  local n=r.TrackFX_GetNumParams(track,fx)
  for p=0,n-1 do
    local _,name=r.TrackFX_GetParamName(track,fx,p,"")
    local low=name:lower()
    for _,needle in ipairs(needles) do if low:find(needle:lower(),1,true) then return p end end
  end
  return -1
end

local function set_param_raw(track,fx,needles,value)
  local p=find_param(track,fx,needles); if p<0 then return false end
  local _,mn,mx = r.TrackFX_GetParamEx(track,fx,p)
  r.TrackFX_SetParam(track,fx,p,clamp(value,mn,mx)); return true
end

local function set_param_norm(track,fx,needles,norm)
  local p=find_param(track,fx,needles); if p<0 then return false end
  r.TrackFX_SetParamNormalized(track,fx,p,clamp(norm,0,1)); return true
end

local function valid_media_track(track)
  if not track then return false end
  if r.ValidatePtr2 then
    return r.ValidatePtr2(0,track,"MediaTrack*") and true or false
  end
  return true
end

local function set_sample(track,fx,path)
  -- A lane track can be recreated/re-resolved by REAPER while the UI is still
  -- holding the previous userdata. Never pass a stale pointer into
  -- TrackFX_SetNamedConfigParm: Lua raises "MediaTrack expected" before REAPER
  -- can simply return false.
  if not valid_media_track(track) or not fx or fx<0 or not path or path=="" then
    return false
  end
  local ok1,rv1=pcall(r.TrackFX_SetNamedConfigParm,track,fx,"FILE0",path)
  if not ok1 or rv1==false then return false end
  local ok2,rv2=pcall(r.TrackFX_SetNamedConfigParm,track,fx,"DONE","")
  return ok2 and rv2~=false
end

local function hide_managed_fx_windows(tr, bridge, rs, duck)
  -- showFlag 2 hides an FX floating window without changing processing.
  -- This keeps the managed Trigger Bridge / RS5K / Duck running silently in the
  -- background while leaving the track and user FX fully accessible.
  if r.TrackFX_Show then
    if bridge and bridge>=0 then r.TrackFX_Show(tr,bridge,2) end
    if rs and rs>=0 then r.TrackFX_Show(tr,rs,2) end
    if duck and duck>=0 then r.TrackFX_Show(tr,duck,2) end
  end
end

function sidechain.needs_recreate(tr, duck)
  -- v1 was a one-shot trigger envelope (6 sliders). v2 adds Threshold.
  -- v3 adds Shuffle (mode slider max 4). Rebuild stale instances.
  if duck<0 then return true end
  local n=r.TrackFX_GetNumParams(tr,duck) or 0
  if n<7 then return true end
  local _,nm=r.TrackFX_GetParamName(tr,duck,6,"")
  if not (nm and tostring(nm):lower():find("threshold",1,true)) then return true end
  if r.TrackFX_GetParamEx then
    local _,mn,mx=r.TrackFX_GetParamEx(tr,duck,1)
    if type(mx)=="number" and mx<3.5 then return true end
  end
  return false
end

function sidechain.place_on_track(tr, li, force_recreate)
  local existing=sidechain.find(tr)
  if not force_recreate and sidechain.needs_recreate(tr,existing) then
    force_recreate=true
  end
  if force_recreate then
    for fx=r.TrackFX_GetCount(tr)-1,0,-1 do
      local _,nm=r.TrackFX_GetFXName(tr,fx,"")
      if sidechain.is_name(nm) then r.TrackFX_Delete(tr,fx) end
    end
  end

  local duck=sidechain.find(tr)
  if duck<0 then duck=sidechain.add_fx(tr) end
  if duck<0 then return -1 end

  if duck~=2 then
    r.TrackFX_CopyToTrack(tr,duck,tr,2,true)
    duck=sidechain.find(tr)
  end
  if duck<0 then return -1 end

  -- Only one managed duck. Extra copies of our JSFX are not user FX.
  for fx=r.TrackFX_GetCount(tr)-1,0,-1 do
    if fx~=duck then
      local _,nm=r.TrackFX_GetFXName(tr,fx,"")
      if sidechain.is_name(nm) then r.TrackFX_Delete(tr,fx) end
    end
  end
  duck=sidechain.find(tr)
  if duck<0 then return -1 end
  if duck~=2 then
    r.TrackFX_CopyToTrack(tr,duck,tr,2,true)
    duck=sidechain.find(tr)
  end
  if duck<0 then return -1 end

  r.TrackFX_SetEnabled(tr,duck,true)
  r.TrackFX_SetOffline(tr,duck,false)
  r.TrackFX_SetParam(tr,duck,0,li-1)
  hide_managed_fx_windows(tr,nil,nil,duck)
  return duck
end

local function configure_engine_track(tr, li)
  -- v0.2.78: playback tracks are user-facing, but managed FX GUIs stay hidden.
  -- The first three FX positions are managed by ADFX S-Layer:
  --   FX 1 = Trigger Bridge
  --   FX 2 = managed RS5K sampler
  --   FX 3 = Duck
  -- Every FX after those three slots belongs to the user and MUST be preserved.

  -- Remove old ADFX bridge instances only. Never delete arbitrary user FX.
  for fx=r.TrackFX_GetCount(tr)-1,0,-1 do
    local _,nm=r.TrackFX_GetFXName(tr,fx,"")
    if nm:lower():find("adfx s%-layer trigger bridge") then
      r.TrackFX_Delete(tr,fx)
    end
  end

  -- Reuse the first RS5K already present as the managed sampler. Do NOT
  -- delete additional RS5K instances because they may have been intentionally
  -- inserted by the user as part of the processing chain.
  local rs=find_rs5k(tr)
  if rs<0 then rs=ensure_rs5k(tr) end

  local bridge=add_trigger_fx(tr)

  -- Put the bridge first.
  if bridge>=0 and bridge~=0 then
    r.TrackFX_CopyToTrack(tr,bridge,tr,0,true)
  end
  bridge=find_fx_by_name(tr,"ADFX S-Layer Trigger Bridge")

  -- Re-find the sampler after moving the bridge, then force the managed RS5K
  -- into slot 2 (zero-based index 1). Everything that was after it shifts
  -- naturally and remains untouched.
  rs=find_rs5k(tr)
  if rs>=0 and rs~=1 then
    r.TrackFX_CopyToTrack(tr,rs,tr,1,true)
  end
  bridge=find_fx_by_name(tr,"ADFX S-Layer Trigger Bridge")
  rs=find_rs5k(tr)

  -- Visible, normal REAPER playback tracks. Users can insert plugins after
  -- RS5K and those plugins process the triggered S-Layer audio normally.
  r.SetMediaTrackInfo_Value(tr,"B_SHOWINTCP",1)
  r.SetMediaTrackInfo_Value(tr,"B_SHOWINMIXER",1)
  r.SetMediaTrackInfo_Value(tr,"B_MUTE",0)
  r.SetMediaTrackInfo_Value(tr,"B_MAINSEND",1)
  r.SetMediaTrackInfo_Value(tr,"I_RECARM",1)
  r.SetMediaTrackInfo_Value(tr,"I_RECMON",1)
  r.SetMediaTrackInfo_Value(tr,"I_RECMODE",2)
  r.SetMediaTrackInfo_Value(tr,"I_RECINPUT",-1)

  if bridge>=0 then
    r.TrackFX_SetEnabled(tr,bridge,true)
    r.TrackFX_SetOffline(tr,bridge,false)
    r.TrackFX_SetParam(tr,bridge,0,60)
    -- Which trigger slot this bridge listens to. REAPER clamps a parameter to
    -- the range the JSFX declares, so an installed bridge built for fewer
    -- layers silently lands two tracks on the same slot: read it back and say
    -- so instead, because the symptom is a lane that never sounds.
    r.TrackFX_SetParam(tr,bridge,1,li-1)
    local wrote=r.TrackFX_GetParam(tr,bridge,1)
    if type(wrote)=="number" and math.abs(wrote-(li-1))>0.01 then
      bridge_layer_limit=math.min(bridge_layer_limit or NUM_LAYERS,math.floor(wrote+1.5))
    end
  end
  if rs>=0 then
    r.TrackFX_SetEnabled(tr,rs,true)
    r.TrackFX_SetOffline(tr,rs,false)
  end

  -- Duck sits after RS5K and before any user FX so verbs still hear the ducked hit.
  local duck=sidechain.place_on_track(tr,li,sidechain.file_upgraded)

  -- Never leave the managed FX floating after engine creation/repair.
  hide_managed_fx_windows(tr,bridge,rs,duck)
  return bridge,rs,duck
end

local function rebuild_tracks()
  r.Undo_BeginBlock()
  local root,idx=find_root_track()
  if not root then
    idx=r.CountTracks(0); r.InsertTrackAtIndex(idx,true); root=r.GetTrack(0,idx); r.GetSetMediaTrackInfo_String(root,"P_NAME",ROOT_NAME,true)
  end
  tracks.root=root; tracks.layers={}
  r.SetMediaTrackInfo_Value(root,"B_SHOWINTCP",1)
  r.SetMediaTrackInfo_Value(root,"B_SHOWINMIXER",1)
  r.SetMediaTrackInfo_Value(root,"B_MUTE",0)
  r.SetMediaTrackInfo_Value(root,"B_MAINSEND",1)
  r.SetMediaTrackInfo_Value(root,"I_FOLDERDEPTH",1)
  for li=1,NUM_LAYERS do
    local wanted=ROOT_NAME.." - Layer "..li
    local tr=nil
    for i=0,r.CountTracks(0)-1 do local t=r.GetTrack(0,i); local _,nm=r.GetTrackName(t); if nm==wanted then tr=t break end end
    if not tr then
      r.InsertTrackAtIndex(idx+li,true); tr=r.GetTrack(0,idx+li); r.GetSetMediaTrackInfo_String(tr,"P_NAME",wanted,true)
    end
    local bridge,rs,duck=configure_engine_track(tr,li)
    tracks.layers[li]={track=tr,bridge=bridge,rs5k=rs,duck=duck}
    r.SetMediaTrackInfo_Value(tr,"I_FOLDERDEPTH",li==NUM_LAYERS and -1 or 0)
  end
  r.Undo_EndBlock("Build/repair ADFX S-Layer engine",-1)
  if bridge_layer_limit then
    status=string.format(
      "Installed ADFX_SLayer_Trigger.jsfx only addresses %d layers, so L%d and up cannot be triggered. Update the JSFX in REAPER/Effects.",
      bridge_layer_limit,bridge_layer_limit+1)
  else
    status="Engine ready: "..NUM_LAYERS.." visible playback tracks"
  end
end

--[[
  Cheap confirmation that the engine resolved earlier is still the engine.

  The full scan below reads every track name in the project once per layer,
  which a trigger cannot afford to do on the way to making a sound. This looks
  only at what it already holds: the track pointer is still a track, and the
  first two managed slots still hold the bridge and the sampler. A missing
  duck is not a failure; Repair Engine / launch put FX3 back.
]]
local function engine_still_valid()
  if not tracks.layers or #tracks.layers<NUM_LAYERS then return false end
  for li=1,NUM_LAYERS do
    local E=tracks.layers[li]
    if not (E and E.track) then return false end
    if r.ValidatePtr2 and not r.ValidatePtr2(0,E.track,"MediaTrack*") then return false end
    local _,bridge_name=r.TrackFX_GetFXName(E.track,0,"")
    if not (bridge_name and bridge_name:lower():find("adfx s-layer trigger bridge",1,true)) then
      return false
    end
    local _,rs_name=r.TrackFX_GetFXName(E.track,1,"")
    if not is_rs5k_name(rs_name) then return false end
  end
  return true
end

local function scan_tracks(force)
  if not force and engine_still_valid() then return true,"ok" end
  local root=find_root_track()
  if not root then
    tracks={}
    return false,"missing engine root track"
  end
  -- A full scan means something about the engine changed, so nothing is assumed
  -- about what the samplers hold: every layer reloads its file once.
  tracks.root=root; tracks.layers={}
  for li=1,NUM_LAYERS do
    local wanted=ROOT_NAME.." - Layer "..li
    local found=nil
    for i=0,r.CountTracks(0)-1 do
      local tr=r.GetTrack(0,i); local _,nm=r.GetTrackName(tr)
      if nm==wanted then found=tr break end
    end
    if not found then return false,"missing playback layer "..li end

    local bridge=find_fx_by_name(found,"ADFX S-Layer Trigger Bridge")
    local rs=find_rs5k(found)
    if bridge<0 then return false,"trigger JSFX missing on layer "..li end
    if rs<0 then
      local names={}
      for fx=0,r.TrackFX_GetCount(found)-1 do
        local _,nm=r.TrackFX_GetFXName(found,fx,"")
        names[#names+1]=nm or ("FX "..fx)
      end
      local shown={}
      for i=1,math.min(#names,6) do shown[#shown+1]=names[i] end
      local extra=#names>6 and (" -> +"..(#names-6).." more") or ""
      return false,"RS5K missing on layer "..li.." [chain: "..table.concat(shown," -> ")..extra.."]"
    end
    if bridge~=0 or rs~=1 then return false,"managed FX order invalid on layer "..li.." (FX 1 must be bridge, FX 2 must be RS5K)" end

    -- Duck is owned by Repair Engine but missing FX3 must not fail old projects.
    local duck=sidechain.find(found)
    tracks.layers[li]={track=found,bridge=bridge,rs5k=rs,duck=duck}
    -- Close managed floating windows left open by older builds, including
    -- projects upgraded directly from v0.2.13.
    hide_managed_fx_windows(found,bridge,rs,duck>=0 and duck or nil)
  end
  return #tracks.layers==NUM_LAYERS, (#tracks.layers==NUM_LAYERS and "ok" or "incomplete engine")
end

-- Engine management is automatic. Existing v0.2.x projects are repaired on
-- launch when an old bridge, missing sampler, or wrong FX order is detected.
-- A missing duck is accepted so old projects still scan; we put FX3 back below.
local bridge_file_ready=install_bridge_if_missing()
sidechain.file_ready=sidechain.install_if_missing()
local engine_ok,engine_reason=scan_tracks()
if not engine_ok then
  if bridge_file_ready then
    rebuild_tracks()
    engine_ok,engine_reason=scan_tracks()
    if engine_ok then status="Engine ready" else status="Engine repair failed: "..tostring(engine_reason) end
  end
else
  for li=1,NUM_LAYERS do
    local E=tracks.layers[li]
    if E and E.track then
      r.SetMediaTrackInfo_Value(E.track,"B_MUTE",0)
      r.SetMediaTrackInfo_Value(E.track,"B_MAINSEND",1)
      r.SetMediaTrackInfo_Value(E.track,"I_RECARM",1)
      r.SetMediaTrackInfo_Value(E.track,"I_RECMON",1)
      r.SetMediaTrackInfo_Value(E.track,"I_RECMODE",2)
      r.SetMediaTrackInfo_Value(E.track,"I_RECINPUT",-1)
      if E.bridge and E.bridge>=0 then
        r.TrackFX_SetEnabled(E.track,E.bridge,true); r.TrackFX_SetOffline(E.track,E.bridge,false)
        -- Re-assert the lane index every launch. This repairs projects that were
        -- created with the old 8-lane bridge, where L9-L16 had all been clamped
        -- to the highest available index.
        r.TrackFX_SetParam(E.track,E.bridge,0,60)
        r.TrackFX_SetParam(E.track,E.bridge,1,li-1)
        local wrote=r.TrackFX_GetParam(E.track,E.bridge,1)
        if type(wrote)=="number" and math.abs(wrote-(li-1))>0.01 then
          bridge_layer_limit=math.min(bridge_layer_limit or NUM_LAYERS,math.floor(wrote+1.5))
        end
      end
      if E.rs5k and E.rs5k>=0 then r.TrackFX_SetEnabled(E.track,E.rs5k,true); r.TrackFX_SetOffline(E.track,E.rs5k,false) end
      if sidechain.file_ready then
        E.duck=sidechain.place_on_track(E.track,li,sidechain.file_upgraded)
      end
    end
  end
  if bridge_file_upgraded then
    -- REAPER can keep an already-instantiated JSFX compiled from the previous
    -- file contents until the instance is recreated. Rebuild the managed bridge
    -- once whenever its on-disk revision changes. The boot-safe bridge adopts
    -- the current gmem counters first, so this rebuild cannot fire a note.
    bridge_layer_limit=nil
    rebuild_tracks()
    engine_ok,engine_reason=scan_tracks(true)
    if engine_ok then status="Engine ready - trigger bridge upgraded (startup-safe)" end
  elseif bridge_layer_limit then
    status=string.format("Trigger bridge only addresses %d layers - press Repair Engine",bridge_layer_limit)
  else
    status="Engine ready"
  end
end

local function solo_logic(scene)
  for i=1,NUM_LAYERS do if scene.layers[i].solo then return true end end
  return false
end

local function apply_runtime(force)
  local now=r.time_precise()
  if not tracks.layers or #tracks.layers<NUM_LAYERS then return end
  local scene=scenes[selected_scene]
  if not force and not runtime_dirty_all and next(runtime_dirty_layers)==nil then return end
  last_apply=now
  local anysolo=solo_logic(scene)
  for li=1,NUM_LAYERS do
    local process_layer = force or runtime_dirty_all or runtime_dirty_layers[li]
    local L=scene.layers[li]; local E=tracks.layers[li]
    if process_layer and E and E.track then
      local muted=L.mute or (anysolo and not L.solo)
      r.SetMediaTrackInfo_Value(E.track,"B_MUTE",muted and 1 or 0)
      local vol_db=clamp(L.volume_db,-60,12)
      local pan=clamp(L.pan,-1,1)
      r.SetMediaTrackInfo_Value(E.track,"D_VOL",db_to_amp(vol_db)); r.SetMediaTrackInfo_Value(E.track,"D_PAN",pan)
      if E.rs5k and E.rs5k>=0 then
        local pitch=clamp(L.pitch,-48,48)
        -- RS5K Pitch Offset is parameter index 15. Do not resolve this by
        -- parameter-name substring: recent REAPER builds expose several
        -- pitch-related names and a generic "pitch" search can target the
        -- wrong control. RS5K maps +/-80 semitones across normalized 0..1.
        local pitch_norm = clamp(0.5 + pitch/160.0, 0, 1)
        if r.TrackFX_GetNumParams(E.track,E.rs5k) > 15 then
          r.TrackFX_SetParamNormalized(E.track,E.rs5k,15,pitch_norm)
        end
        local st=clamp(L.start,0,1)
        set_param_norm(E.track,E.rs5k,{"start offset","start pos","start"},st)
        set_param_norm(E.track,E.rs5k,{"attack"},clamp(L.attack,0,1))
        set_param_norm(E.track,E.rs5k,{"release"},clamp(L.release,0,1))
        -- Reverse is not written here: RS5K has no such parameter. It is done
        -- by handing the sampler an already reversed file, in load_pool_item.
        set_param_norm(E.track,E.rs5k,{"loop"},L.loop and 1 or 0)
        -- RS5K's Max voices is how many shots may sound at once before a new
        -- one steals a voice, so 1 is the choke and a higher count overlaps.
        set_param_raw(E.track,E.rs5k,{"max voices"},choke and CHOKE_VOICES or OVERLAP_VOICES)
      end
    end
  end
  runtime_dirty_all=false
  runtime_dirty_layers={}
end

local function is_engine_track(tr)
  if not tr then return false end
  local _,name=r.GetTrackName(tr)
  return name==ROOT_NAME or name:sub(1,#ROOT_NAME+8)==ROOT_NAME.." - Layer"
end

local function collect_pool(tr)
  local pool={}
  if not tr then return pool end
  for i=0,r.CountTrackMediaItems(tr)-1 do
    local item=r.GetTrackMediaItem(tr,i)
    local take=item and r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then
      local src=r.GetMediaItemTake_Source(take)
      if src then
        local path=r.GetMediaSourceFileName(src,"")
        if path and path~="" then
          local src_len=r.GetMediaSourceLength(src)
          if not src_len or src_len<=0 then src_len=0 end
          local item_len=r.GetMediaItemInfo_Value(item,"D_LENGTH") or 0
          local offs=r.GetMediaItemTakeInfo_Value(take,"D_STARTOFFS") or 0
          local rate=r.GetMediaItemTakeInfo_Value(take,"D_PLAYRATE") or 1
          local _,take_name=r.GetSetMediaItemTakeInfo_String(take,"P_NAME","",false)
          pool[#pool+1]={item=item,take=take,path=path,name=(take_name~="" and take_name or basename(path)),offset=offs,length=item_len,rate=rate,source_len=src_len}
        end
      end
    end
  end
  return pool
end

local function source_track_for_layer(L)
  if not L.source_guid or L.source_guid=="" then return nil end
  return track_by_guid(L.source_guid)
end

--[[
  Pools, remembered between triggers.

  collect_pool asks REAPER about every item on the source track, so scanning
  every layer on every shot is the most expensive thing a trigger does. The
  cache is checked against the item count, which is one call and catches items
  being added or removed. An item that was edited in place -- moved, trimmed,
  renamed -- looks the same by count, and Refresh Pools is what re-reads those.
]]
local pool_cache = {}

local function invalidate_pools(li)
  if li then pool_cache[li]=nil else pool_cache={} end
end

local function refresh_layer_pool(li,force)
  local L=scenes[selected_scene].layers[li]
  local tr=source_track_for_layer(L)
  if not tr then
    L.pool_count=0
    pool_cache[li]=nil
    return {}
  end

  local items=r.CountTrackMediaItems(tr)
  local hit=pool_cache[li]
  local pool
  if not force and hit and hit.track==tr and hit.guid==L.source_guid
     and hit.scene==selected_scene and hit.items==items then
    pool=hit.pool
  else
    local _,nm=r.GetTrackName(tr); L.source_name=nm
    pool=collect_pool(tr)
    pool_cache[li]={track=tr,guid=L.source_guid,scene=selected_scene,items=items,pool=pool}
  end

  L.pool_count=#pool
  if L.sample_index<1 then L.sample_index=1 end
  if #pool>0 and L.sample_index>#pool then L.sample_index=#pool end
  return pool
end

--[[
  Lane waveform cache
  -----------------------------------------------------------------------------
  This is deliberately NOT a realtime oscilloscope. A tiny amplitude overview is
  sampled from the take only once per distinct item region and kept in memory.
  Drawing the strip later is just a few dozen ImGui lines plus one playhead.
]]
local WAVEFORM_BINS = 72
local WAVEFORM_HEIGHT = 22
local WAVEFORM_WIDTH = 230
-- Wide enough for "999 items" so a 10th variation cannot shove RND sideways.
local ITEMS_COL_W = 80
local waveform_cache = {}
local waveform_queue = {}
local waveform_queued = {}
local lane_waveform_entry = {}
local lane_activity = {}

local function waveform_key(entry)
  if not entry then return "" end
  return string.format("%s|%.6f|%.6f|%.6f",entry.path or "",entry.offset or 0,entry.length or 0,entry.rate or 1)
end

local function build_waveform_now(entry)
  if not entry then return nil end
  local key=waveform_key(entry)
  if not entry.take or not (r.CreateTakeAudioAccessor and r.GetAudioAccessorSamples and r.new_array) then
    waveform_queued[key]=nil
    return nil
  end
  local hit=waveform_cache[key]
  if hit then return hit end

  local ok,acc=pcall(r.CreateTakeAudioAccessor,entry.take)
  if not ok or not acc then
    waveform_cache[key]={amps={},duration=entry.length or 0}; waveform_queued[key]=nil
    return waveform_cache[key]
  end
  local a=r.GetAudioAccessorStartTime(acc) or 0
  local b=r.GetAudioAccessorEndTime(acc) or a
  local span=math.max(0,b-a)
  if entry.length and entry.length>0 then span=math.min(span,entry.length) end
  if span<=0 then
    r.DestroyAudioAccessor(acc); waveform_cache[key]={amps={},duration=0}; waveform_queued[key]=nil
    return waveform_cache[key]
  end

  local src=r.GetMediaItemTake_Source(entry.take)
  local chans=src and math.floor((r.GetMediaSourceNumChannels and r.GetMediaSourceNumChannels(src)) or 0) or 0
  chans=clamp(chans>0 and chans or 2,1,8)
  -- Roughly 48 source points per visual bin. Even long files stay cheap because
  -- the accessor resamples down before Lua sees the data.
  local read_rate=clamp(math.floor((WAVEFORM_BINS*48)/span+0.5),200,4000)
  local frames=math.max(WAVEFORM_BINS,math.floor(span*read_rate+0.5))
  local buf=r.new_array(frames*chans)
  if buf.clear then buf.clear() end
  local read_ok,rv=pcall(r.GetAudioAccessorSamples,acc,read_rate,chans,a,frames,buf)
  r.DestroyAudioAccessor(acc)
  if not read_ok or (type(rv)=="number" and rv<0) then
    waveform_cache[key]={amps={},duration=span}; waveform_queued[key]=nil
    return waveform_cache[key]
  end
  local data=(rv~=0) and buf.table(1,frames*chans) or nil
  local amps={}
  for bi=1,WAVEFORM_BINS do
    local f0=math.floor((bi-1)*frames/WAVEFORM_BINS)
    local f1=math.max(f0,math.floor(bi*frames/WAVEFORM_BINS)-1)
    local peak=0
    for f=f0,f1 do
      for c=1,chans do
        local v=data and math.abs(data[f*chans+c] or 0) or 0
        if v>peak then peak=v end
      end
    end
    amps[bi]=clamp(peak,0,1)
  end
  waveform_cache[key]={amps=amps,duration=span}
  waveform_queued[key]=nil
  return waveform_cache[key]
end

local function request_waveform(entry)
  if not entry then return nil end
  local key=waveform_key(entry)
  local hit=waveform_cache[key]
  if hit then return hit end
  if not waveform_queued[key] then
    waveform_queued[key]=true
    waveform_queue[#waveform_queue+1]=entry
  end
  return nil
end

local function process_waveform_queue()
  -- Analyze at most one previously unseen sample per defer cycle. This keeps a
  -- 16-lane scene change or a large randomized shot from bunching all waveform
  -- work into one UI frame.
  local entry=table.remove(waveform_queue,1)
  if entry then build_waveform_now(entry) end
end

local function note_lane_trigger(li, visual)
  if not visual or not visual.entry then return end
  local wf=request_waveform(visual.entry)
  local start=clamp(visual.start or 0,0,1)
  local pitch=visual.pitch or 0
  local base=(wf and wf.duration and wf.duration>0) and wf.duration or (visual.entry.length or 0)
  -- RS5K pitch changes playback speed, so this gets the visual playhead close to
  -- the audible traversal without doing any realtime sampler interrogation.
  local speed=2^(pitch/12)
  local remain=math.max(0,base*(1-start))
  local dur=(speed>0) and (remain/speed) or remain
  lane_activity[li]={
    started=r.time_precise(), duration=dur, start=start,
    reverse=visual.reverse and true or false, loop=visual.loop and true or false,
    key=waveform_key(visual.entry), waveform=wf
  }
end

local function draw_lane_waveform(li,L)
  -- Always submit an ImGui item for the waveform slot. In v0.2.31 this could
  -- return after SameLine() had already been called, causing the following lane
  -- to continue on the same row and look missing until a trigger populated it.
  if not (r.ImGui_GetCursorScreenPos and r.ImGui_Dummy and r.ImGui_GetWindowDrawList and
          r.ImGui_DrawList_AddRectFilled and r.ImGui_DrawList_AddRect and r.ImGui_DrawList_AddLine) then
    if r.ImGui_Dummy then r.ImGui_Dummy(ctx,WAVEFORM_WIDTH,WAVEFORM_HEIGHT) end
    return
  end

  -- Prime the preview from the current lane pool before the first trigger. This
  -- does not fire or randomize the lane; it only gives the visualizer the same
  -- current item the lane already points at. refresh_layer_pool() is cached.
  local entry=lane_waveform_entry[li]
  if (not entry) and L.source_guid and L.source_guid~="" then
    local pool=refresh_layer_pool(li)
    if #pool>0 then
      entry=pool[clamp(L.sample_index or 1,1,#pool)]
      lane_waveform_entry[li]=entry
    end
  end
  local wf=entry and request_waveform(entry) or nil

  local x,y=r.ImGui_GetCursorScreenPos(ctx)
  local w=WAVEFORM_WIDTH
  local h=WAVEFORM_HEIGHT
  r.ImGui_Dummy(ctx,w,h)
  local dl=r.ImGui_GetWindowDrawList(ctx)
  r.ImGui_DrawList_AddRectFilled(dl,x,y,x+w,y+h,0x15171CFF,2)
  r.ImGui_DrawList_AddRect(dl,x,y,x+w,y+h,0x3A3D44FF,2)
  local mid=y+h*0.5
  r.ImGui_DrawList_AddLine(dl,x+2,mid,x+w-2,mid,0x31343AFF,1)

  local amps=(wf and wf.amps) or {}
  local n=#amps
  if n>0 then
    for bi=1,n do
      local idx=L.reverse and (n-bi+1) or bi
      local a=amps[idx] or 0
      local px=x+2+(bi-1)*(w-4)/math.max(1,n-1)
      local hh=a*(h*0.42)
      r.ImGui_DrawList_AddLine(dl,px,mid-hh,px,mid+hh,0x8492A6FF,1)
    end
  end

  local act=lane_activity[li]
  if entry and act and act.key==waveform_key(entry) then
    local elapsed=r.time_precise()-act.started
    local dur=act.duration or 0
    local p
    if dur>0 then
      if act.loop then p=(elapsed%dur)/dur elseif elapsed<=dur then p=elapsed/dur end
    end
    if p then
      local q=act.start + p*(1-act.start)
      local px=x+2+clamp(q,0,1)*(w-4)
      r.ImGui_DrawList_AddLine(dl,px,y+1,px,y+h-1,0x7FE08CFF,2)
    elseif not act.loop and dur>0 and elapsed>dur then
      lane_activity[li]=nil
    end
  end

  -- Green = this lane is the key (doing the ducking). Red = this lane is
  -- being ducked. Both ride live levels: loud key sits high, deep duck sits low.
  local key_env=sidechain.visual_key(li)
  if key_env then
    local ky=y+1+(1-key_env)*(h-2)
    r.ImGui_DrawList_AddLine(dl,x+2,ky,x+w-2,ky,0x3AE06AFF,2)
  end
  local duck_gain=sidechain.visual_gain(li)
  if duck_gain<0.995 then
    local gy=y+1+(1-duck_gain)*(h-2)
    r.ImGui_DrawList_AddLine(dl,x+2,gy,x+w-2,gy,0xE23B3BFF,2)
  end
end
-- ReaSamplOmatic5000 cannot play a sample backwards: it has no reverse
-- parameter, and it only accepts a file path, so REAPER's own reversed take
-- section is no use either. The only way through is to write a reversed copy
-- of the item's audio to disk once and load that instead.
local REVERSE_DIR_NAME = "ADFX_SLayer_Reverse"
local REVERSE_MAX_SECONDS = 60
local REVERSE_READ_CHUNK = 32768
local REVERSE_PACK_GROUP = 1024
local REVERSE_PACK_FMT = "<" .. string.rep("f", REVERSE_PACK_GROUP)
local reverse_cache = {}

local function reverse_key(entry)
  return string.format("%s|%.6f|%.6f|%.6f",entry.path or "",entry.offset or 0,entry.length or 0,entry.rate or 1)
end

local function reverse_hash(s)
  -- djb2, kept in 32 bits by hand so this does not depend on the Lua version
  -- REAPER happens to ship. It only has to name a cache file.
  local h=5381
  for i=1,#s do h=(h*33 + s:byte(i)) % 4294967296 end
  return string.format("%08x",h)
end

local function reverse_dir()
  local sep=package.config:sub(1,1)
  local base=r.GetProjectPath and r.GetProjectPath("") or ""
  if not base or base=="" then return nil,nil,"REAPER reports no project media folder" end
  local dir=base..sep..REVERSE_DIR_NAME
  if r.RecursiveCreateDirectory then r.RecursiveCreateDirectory(dir,0) end
  return dir,sep
end

local function reverse_wav_header(chans,rate,frames)
  local data_bytes=frames*chans*4
  -- Format code 3 is IEEE float. The 18-byte fmt chunk and the fact chunk are
  -- what the spec asks of a non-PCM file; plenty of readers skip them, but
  -- writing them costs nothing and keeps the file loadable everywhere.
  return string.pack("<c4I4c4c4I4I2I2I4I4I2I2I2c4I4I4c4I4",
    "RIFF",50+data_bytes,"WAVE",
    "fmt ",18,3,chans,rate,rate*chans*4,chans*4,32,0,
    "fact",4,frames,
    "data",data_bytes)
end

local function write_reversed_wav(entry,out_path)
  if not (r.CreateTakeAudioAccessor and r.GetAudioAccessorSamples and r.new_array and string.pack) then
    return false,"this REAPER build has no audio accessor API"
  end
  local src=entry.take and r.GetMediaItemTake_Source(entry.take)
  if not src then return false,"the source item is gone" end
  local sr=math.floor((r.GetMediaSourceSampleRate and r.GetMediaSourceSampleRate(src)) or 0)
  if sr<=0 then sr=44100 end
  local chans=math.floor((r.GetMediaSourceNumChannels and r.GetMediaSourceNumChannels(src)) or 0)
  chans=clamp(chans>0 and chans or 2,1,8)
  local play_rate=(entry.rate and entry.rate>0) and entry.rate or 1
  -- A take accessor hands back the item as it plays, playrate folded in, over
  -- the item's own length. Reading at the source rate scaled by the playrate
  -- gets every original sample back, and writing the header at the plain
  -- source rate undoes the playrate again - the forward path ignores it too.
  local read_rate=clamp(math.floor(sr*play_rate+0.5),1,768000)

  local ok,acc=pcall(r.CreateTakeAudioAccessor,entry.take)
  if not ok or not acc then return false,"no audio accessor for this take" end
  local a=r.GetAudioAccessorStartTime(acc) or 0
  local b=r.GetAudioAccessorEndTime(acc) or 0
  local span=b-a
  if entry.length and entry.length>0 then span=math.min(span,entry.length) end
  local frames=math.floor(span*read_rate)
  local out_seconds=frames/sr
  if frames<2 then r.DestroyAudioAccessor(acc); return false,"the item has no audio to reverse" end
  if out_seconds>REVERSE_MAX_SECONDS then
    r.DestroyAudioAccessor(acc)
    return false,string.format("the item is %.0fs, over the %ds reverse limit",out_seconds,REVERSE_MAX_SECONDS)
  end

  local f=io.open(out_path,"wb")
  if not f then r.DestroyAudioAccessor(acc); return false,"cannot write into "..REVERSE_DIR_NAME end
  f:write(reverse_wav_header(chans,sr,frames))

  local buf=r.new_array(REVERSE_READ_CHUNK*chans)
  local pos,failed=frames,nil
  while pos>0 do
    local count=math.min(REVERSE_READ_CHUNK,pos)
    local first=pos-count
    -- Clear before every read: a block REAPER calls silent is left untouched,
    -- so the previous block would otherwise be written again in its place.
    if buf.clear then buf.clear() end
    local read_ok,rv=pcall(r.GetAudioAccessorSamples,acc,read_rate,chans,a+first/read_rate,count,buf)
    if not read_ok or (type(rv)=="number" and rv<0) then failed="reading the item's audio failed"; break end
    local data=(rv~=0) and buf.table(1,count*chans) or nil
    local out,vals={},{}
    for s=count-1,0,-1 do
      for c=1,chans do
        vals[#vals+1]=(data and data[s*chans+c]) or 0
        if #vals==REVERSE_PACK_GROUP then out[#out+1]=string.pack(REVERSE_PACK_FMT,table.unpack(vals)); vals={} end
      end
    end
    if #vals>0 then out[#out+1]=string.pack("<"..string.rep("f",#vals),table.unpack(vals)) end
    f:write(table.concat(out))
    pos=first
  end

  f:close()
  r.DestroyAudioAccessor(acc)
  if failed then os.remove(out_path); return false,failed end
  return true
end

--- Path of the reversed render of this pool item, or nil plus a reason.
local function reversed_file_for(entry)
  local key=reverse_key(entry)
  local hit=reverse_cache[key]
  if hit then
    if hit.err then return nil,hit.err end
    local f=io.open(hit.path,"rb")
    if f then f:close(); return hit.path end
  end
  local dir,sep,dir_err=reverse_dir()
  if not dir then reverse_cache[key]={err=dir_err}; return nil,dir_err end
  local stem=basename(entry.path):gsub("%.[^.]*$","")
  stem=stem:gsub("[^%w%-_]","_")
  local out=dir..sep..stem.."_rev_"..reverse_hash(key)..".wav"
  local f=io.open(out,"rb")
  if f then f:close(); reverse_cache[key]={path=out}; return out end
  local ok,err=write_reversed_wav(entry,out)
  if not ok then reverse_cache[key]={err=err}; return nil,err end
  reverse_cache[key]={path=out}
  return out
end

local function load_pool_item(li, entry)
  local E=tracks.layers and tracks.layers[li]
  local L=scenes[selected_scene].layers[li]

  -- If REAPER invalidated/recreated a managed lane track, refresh the cached
  -- engine pointers before touching RS5K. This is especially important during
  -- source assignment, where the project state can still save correctly even
  -- though an old track userdata has just gone stale.
  if not E or not valid_media_track(E.track) then
    local ok=scan_tracks(true)
    E=ok and tracks.layers and tracks.layers[li] or nil
  end
  if not E or not valid_media_track(E.track) or not E.rs5k or E.rs5k<0 or not entry then
    return false
  end
  local path,reversed=entry.path,false
  if L.reverse then
    local rev,why=reversed_file_for(entry)
    if rev then path=rev; reversed=true
    else reverse_note="Reverse unavailable: "..tostring(why)..", playing L"..li.." forward" end
  end
  -- Loading a file into RS5K means reading and decoding it, so it is only done
  -- when the file is actually different. Repeating a shot on the same item is
  -- then parameter writes and nothing else, which is what makes a rack of
  -- sixteen layers cost about what one layer used to.
  local swapped=false
  if E.loaded_path~=path then
    if not set_sample(E.track,E.rs5k,path) then
      -- One last re-resolve handles the narrow race where the pointer changed
      -- between validation and the named-config write.
      local ok=scan_tracks(true)
      E=ok and tracks.layers and tracks.layers[li] or nil
      if not E or not valid_media_track(E.track) or not set_sample(E.track,E.rs5k,path) then
        status="Could not load source into S-Layer L"..li..": engine track reference changed"
        return false
      end
    end
    E.loaded_path=path
    swapped=true
  end
  L.sample=entry.path
  lane_waveform_entry[li]=entry
  if reversed then
    -- The render holds the item's region and nothing else, so the sampler
    -- plays all of it and Start walks into it from the front as usual.
    set_param_norm(E.track,E.rs5k,{"start offset","start pos"},clamp(L.start,0,1))
    set_param_norm(E.track,E.rs5k,{"end offset","end pos"},1)
  elseif entry.source_len and entry.source_len>0 then
    local a=clamp(entry.offset/entry.source_len,0,1)
    local b=clamp((entry.offset + entry.length*entry.rate)/entry.source_len,0,1)
    if b<a then a,b=b,a end
    local effective_start=a + clamp(L.start,0,1)*(b-a)
    set_param_norm(E.track,E.rs5k,{"start offset","start pos"},effective_start)
    set_param_norm(E.track,E.rs5k,{"end offset","end pos"},b)
  end
  return true,swapped
end

--- Re-load the layer's current pool item, for controls that change the file.
local function reload_layer_sample(li)
  local L=scenes[selected_scene].layers[li]
  local pool=refresh_layer_pool(li)
  if #pool>0 then load_pool_item(li,pool[clamp(L.sample_index,1,#pool)]) end
end

local function sync_sources()
  -- The one place that re-reads the items unconditionally: an edit that leaves
  -- the item count alone is invisible to the cache, and this is the button that
  -- exists to pick those up.
  invalidate_pools()
  for li=1,NUM_LAYERS do
    local pool=refresh_layer_pool(li,true)
    local L=scenes[selected_scene].layers[li]
    if #pool>0 then load_pool_item(li,pool[clamp(L.sample_index,1,#pool)]) end
  end
  apply_runtime(true)
  status="Source pools refreshed"
end

--- Point one lane at one track. Saving and re-applying is left to the caller so
--- that assigning a whole selection is one save rather than one per lane.
local function set_layer_source(li,tr)
  if not tr or is_engine_track(tr) then return false end
  local L=scenes[selected_scene].layers[li]
  L.source_guid=r.GetTrackGUID(tr)
  local _,nm=r.GetTrackName(tr); L.source_name=nm
  L.sample_index=1
  invalidate_pools(li)
  local pool=refresh_layer_pool(li)
  if #pool>0 then load_pool_item(li,pool[1]) end
  return true
end

local function assign_source_track(li,tr)
  if not set_layer_source(li,tr) then return end
  save_state(); apply_runtime(true)
end

local function selected_source_tracks()
  local out={}
  for i=0,r.CountSelectedTracks(0)-1 do
    local tr=r.GetSelectedTrack(0,i)
    -- REAPER hands these back in track order, so the lanes end up in the order
    -- the tracks appear in the project.
    if tr and not is_engine_track(tr) then out[#out+1]=tr end
  end
  return out
end

--- True when the track has at least one enabled, online FX. Bypassed or
--- offline plugins do not count: those tracks assign with their original files.
local function track_has_enabled_fx(tr)
  if not tr then return false end
  local n=r.TrackFX_GetCount(tr)
  if n<=0 then return false end
  for fx=0,n-1 do
    local enabled=r.TrackFX_GetEnabled(tr,fx)
    local offline=r.TrackFX_GetOffline and r.TrackFX_GetOffline(tr,fx)
    if enabled and not offline then return true end
  end
  return false
end

local function save_item_selection()
  local out={}
  for i=0,r.CountSelectedMediaItems(0)-1 do
    out[#out+1]=r.GetSelectedMediaItem(0,i)
  end
  return out
end

local function restore_item_selection(saved)
  if r.SelectAllMediaItems then r.SelectAllMediaItems(0,false)
  else r.Main_OnCommand(40289,0) end
  if not saved then return end
  for _,item in ipairs(saved) do
    if r.ValidatePtr2(0,item,"MediaItem*") then r.SetMediaItemSelected(item,true) end
  end
end

local function save_track_selection()
  local out={}
  for i=0,r.CountSelectedTracks(0)-1 do
    out[#out+1]=r.GetSelectedTrack(0,i)
  end
  return out
end

local function restore_track_selection(saved)
  if not (saved and #saved>0) then return end
  if r.SetOnlyTrackSelected then r.SetOnlyTrackSelected(saved[1]) end
  for i=1,#saved do
    if r.ValidatePtr2(0,saved[i],"MediaTrack*") then r.SetTrackSelected(saved[i],true) end
  end
end

-- 40209 = Item: Apply track/take FX to items (as a new take, project channel format).
local ACTION_APPLY_TRACK_TAKE_FX=40209
local ACTION_UNSELECT_ITEMS=40289

-- One table so take / hash / toggle helpers do not add main-chunk locals.
-- Lua's 200-local limit is already close in this file.
local slayer_fx={}
slayer_fx.HASH_EXT="P_EXT:ADFX_SLAYER_FX_HASH"

slayer_fx.take_count=function(item)
  if r.CountTakes then return r.CountTakes(item) end
  if r.GetMediaItemNumTakes then return r.GetMediaItemNumTakes(item) end
  return 1
end
slayer_fx.take_at=function(item,idx)
  if r.GetTake then return r.GetTake(item,idx) end
  return r.GetMediaItemTake(item,idx)
end
slayer_fx.is_fx_take=function(take)
  if not take then return false end
  local _,name=r.GetSetMediaItemTakeInfo_String(take,"P_NAME","",false)
  return name=="ADFX FX"
end
slayer_fx.find_fx=function(item)
  local n=slayer_fx.take_count(item)
  for i=0,n-1 do
    local take=slayer_fx.take_at(item,i)
    if slayer_fx.is_fx_take(take) then return take end
  end
end
slayer_fx.find_dry=function(item)
  local n=slayer_fx.take_count(item)
  for i=0,n-1 do
    local take=slayer_fx.take_at(item,i)
    if take and not slayer_fx.is_fx_take(take) then return take end
  end
end
slayer_fx.audio_items=function(tr)
  local out={}
  if not tr then return out end
  for i=0,r.CountTrackMediaItems(tr)-1 do
    local item=r.GetTrackMediaItem(tr,i)
    local take=item and r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then out[#out+1]=item end
  end
  return out
end
slayer_fx.hash_string=function(s)
  local h=5381
  for i=1,#s do h=(h*33+s:byte(i))%2147483647 end
  return tostring(h)
end
-- skipped = chain matches and every item already has an ADFX FX take
-- missing = chain matches but new items still need a first print
-- all     = first print, or the chain changed
slayer_fx.plan_print=function(hash,stored,missing_n)
  if stored==hash and hash~="" and missing_n==0 then return "skipped" end
  if stored==hash and hash~="" and missing_n>0 then return "missing" end
  return "all"
end
slayer_fx.chain_hash=function(tr)
  local n=r.TrackFX_GetCount(tr)
  local parts={tostring(n)}
  for fx=0,n-1 do
    local _,name=r.TrackFX_GetFXName(tr,fx,"")
    local offline=r.TrackFX_GetOffline and r.TrackFX_GetOffline(tr,fx)
    parts[#parts+1]=name or ""
    parts[#parts+1]=r.TrackFX_GetEnabled(tr,fx) and "1" or "0"
    parts[#parts+1]=offline and "1" or "0"
    if r.TrackFX_GetFXGUID then parts[#parts+1]=r.TrackFX_GetFXGUID(tr,fx) or "" end
    local nparams=r.TrackFX_GetNumParams(tr,fx) or 0
    parts[#parts+1]=tostring(nparams)
    for p=0,nparams-1 do
      parts[#parts+1]=string.format("%.5f",r.TrackFX_GetParam(tr,fx,p) or 0)
    end
  end
  return slayer_fx.hash_string(table.concat(parts,"\n"))
end
slayer_fx.get_hash=function(tr)
  if not r.GetSetMediaTrackInfo_String then return "" end
  local a,b=r.GetSetMediaTrackInfo_String(tr,slayer_fx.HASH_EXT,"",false)
  if type(a)=="string" and a~="" then return a end
  return (type(b)=="string" and b) or ""
end
slayer_fx.set_hash=function(tr,hash)
  if r.GetSetMediaTrackInfo_String then
    r.GetSetMediaTrackInfo_String(tr,slayer_fx.HASH_EXT,hash or "",true)
  end
end
-- Assign + FX can take long enough that the user tabs away. REAPER's default
-- "set media offline when application is not active" then offlines the files
-- we just printed, and later FX takes fail. Hold that preference off for the
-- print, pause while another program is in front, and force new takes online.
slayer_fx.job=nil
slayer_fx.guard_items={}
slayer_fx.guard_until=0
slayer_fx.guard_next=0
slayer_fx.peak_jobs={}
slayer_fx.offlineinact_held=false
slayer_fx.offlineinact_saved=nil

slayer_fx.read_offlineinact=function()
  if r.get_config_var_string then
    local ok,buf=r.get_config_var_string("offlineinact")
    if ok then
      local n=tonumber(buf)
      if n then return n end
    end
  end
  if r.SNM_GetIntConfigVar then return r.SNM_GetIntConfigVar("offlineinact",1) end
  return 1
end

slayer_fx.write_offlineinact=function(value)
  value=tostring(value)
  if r.set_config_var_string then
    -- persist=0 keeps this in memory only; do not rewrite the user's reaper.ini
    local wrote=r.set_config_var_string("offlineinact",value,0)
    if wrote and wrote~=0 then return true end
  end
  if r.SNM_SetIntConfigVar then return r.SNM_SetIntConfigVar("offlineinact",tonumber(value) or 0) end
  return false
end

slayer_fx.hold_offlineinact=function()
  if slayer_fx.offlineinact_held then return end
  local cur=slayer_fx.read_offlineinact()
  slayer_fx.offlineinact_saved=cur
  -- bit 0 = set media offline when inactive. Clear it so a focus change
  -- cannot offline the files we just printed.
  local cleared=cur-(cur%2)
  if cleared~=cur then slayer_fx.write_offlineinact(cleared) end
  slayer_fx.offlineinact_held=true
end

slayer_fx.release_offlineinact=function()
  if not slayer_fx.offlineinact_held then return end
  if slayer_fx.offlineinact_saved~=nil then
    slayer_fx.write_offlineinact(slayer_fx.offlineinact_saved)
  end
  slayer_fx.offlineinact_held=false
  slayer_fx.offlineinact_saved=nil
end

slayer_fx.app_active=function()
  if not (r.JS_Window_GetForeground and r.GetMainHwnd) then return true end
  local fg=r.JS_Window_GetForeground()
  local main=r.GetMainHwnd()
  if not (fg and main) then return true end
  local hwnd=fg
  for _=1,10 do
    if hwnd==main then return true end
    if not r.JS_Window_GetParent then break end
    hwnd=r.JS_Window_GetParent(hwnd)
    if not hwnd then break end
  end
  if r.JS_Window_GetTitle then
    local title=r.JS_Window_GetTitle(fg) or ""
    if title:find("REAPER",1,true) or title:find("ADFX",1,true) then return true end
  end
  return false
end

slayer_fx.chunk_online=function(item)
  if not (r.GetItemStateChunk and r.SetItemStateChunk) then return end
  local ok,chunk=r.GetItemStateChunk(item,"",false)
  if not (ok and type(chunk)=="string") then return end
  local next_chunk=chunk:gsub("\nOFFLINE\n","\n")
  next_chunk=next_chunk:gsub("_OFFLINE_","")
  if next_chunk~=chunk then r.SetItemStateChunk(item,next_chunk,false) end
end

slayer_fx.source_offline=function(src)
  if not src then return false end
  if r.CF_GetMediaSourceOnline then return r.CF_GetMediaSourceOnline(src)==false end
  return false
end

slayer_fx.queue_peaks=function(src,item)
  if not (src and r.PCM_Source_BuildPeaks) then return end
  local need=r.PCM_Source_BuildPeaks(src,0)
  if need and need~=0 then
    slayer_fx.peak_jobs[#slayer_fx.peak_jobs+1]={src=src,item=item}
  end
end

slayer_fx.bring_items_online=function(items,opts)
  if not items then return end
  local build_peaks=not (opts and opts.skip_peaks)
  local only_offline=opts and opts.only_offline
  for _,item in ipairs(items) do
    if r.ValidatePtr2(0,item,"MediaItem*") then
      local dirty=false
      slayer_fx.chunk_online(item)
      local n=slayer_fx.take_count(item)
      for i=0,n-1 do
        local take=slayer_fx.take_at(item,i)
        local src=take and r.GetMediaItemTake_Source(take)
        if src then
          local offline=slayer_fx.source_offline(src)
          if offline or not only_offline then
            if r.CF_SetMediaSourceOnline then r.CF_SetMediaSourceOnline(src,true) end
            if build_peaks and (offline or not only_offline) then slayer_fx.queue_peaks(src,item) end
            dirty=true
          end
        end
      end
      if dirty and r.UpdateItemInProject then r.UpdateItemInProject(item) end
    end
  end
end

slayer_fx.tick_peaks=function()
  local jobs=slayer_fx.peak_jobs
  if #jobs==0 then return end
  if not r.PCM_Source_BuildPeaks then slayer_fx.peak_jobs={}; return end
  local remain={}
  for i=1,#jobs do
    local job=jobs[i]
    local left=r.PCM_Source_BuildPeaks(job.src,1)
    if left==0 then
      r.PCM_Source_BuildPeaks(job.src,2)
      if job.item and r.ValidatePtr2(0,job.item,"MediaItem*") and r.UpdateItemInProject then
        r.UpdateItemInProject(job.item)
      end
    else
      remain[#remain+1]=job
    end
  end
  slayer_fx.peak_jobs=remain
  if #remain==0 then r.UpdateArrange() end
end

slayer_fx.watch_items=function(items)
  if not items then return end
  for i=1,#items do slayer_fx.guard_items[#slayer_fx.guard_items+1]=items[i] end
  slayer_fx.guard_until=r.time_precise()+120
  slayer_fx.guard_next=0
end

slayer_fx.tick_guard=function()
  if slayer_fx.guard_until<=0 then return end
  local now=r.time_precise()
  if now>=slayer_fx.guard_next and #slayer_fx.guard_items>0 then
    slayer_fx.guard_next=now+0.5
    slayer_fx.bring_items_online(slayer_fx.guard_items,{only_offline=true,skip_peaks=false})
  end
  if now>=slayer_fx.guard_until then
    slayer_fx.guard_items={}
    slayer_fx.guard_until=0
    slayer_fx.release_offlineinact()
  end
end

slayer_fx.run_helper=function(filename,ok_status)
  if r.CountSelectedMediaItems(0)<=0 then
    status="Select items in the arrange view first"
    return
  end
  local path=r.GetResourcePath()..ADFX_SEP.."Scripts"..ADFX_SEP.."ADFX"..ADFX_SEP..filename
  if r.file_exists and not r.file_exists(path) then
    status="Helper not installed: "..filename
    return
  end
  local chunk=loadfile(path)
  if not chunk then
    status="Could not load "..filename
    return
  end
  local ok=pcall(chunk)
  status=ok and ok_status or (filename.." failed")
end

slayer_fx.crop_to_dry=function(items)
  for _,item in ipairs(items) do
    local takes=slayer_fx.take_count(item)
    local dry=slayer_fx.find_dry(item) or slayer_fx.take_at(item,0)
    if dry then
      r.SetActiveTake(dry)
      if takes>1 then
        if r.SelectAllMediaItems then r.SelectAllMediaItems(0,false)
        else r.Main_OnCommand(ACTION_UNSELECT_ITEMS,0) end
        r.SetMediaItemSelected(item,true)
        r.Main_OnCommand(40131,0) -- Take: Crop to active take in items
      end
    end
  end
end
slayer_fx.print_items=function(tr,items)
  if r.SelectAllMediaItems then r.SelectAllMediaItems(0,false)
  else r.Main_OnCommand(ACTION_UNSELECT_ITEMS,0) end
  for _,item in ipairs(items) do r.SetMediaItemSelected(item,true) end
  if r.SetOnlyTrackSelected then r.SetOnlyTrackSelected(tr) end
  r.Main_OnCommand(ACTION_APPLY_TRACK_TAKE_FX,0)
  for _,item in ipairs(items) do
    if slayer_fx.take_count(item)>=2 then
      local take=r.GetActiveTake(item)
      if take then r.GetSetMediaItemTakeInfo_String(take,"P_NAME","ADFX FX",true) end
    end
  end
  slayer_fx.bring_items_online(items)
end
slayer_fx.refresh_lanes=function(tr)
  if not tr then return end
  local guid=r.GetTrackGUID(tr)
  for li=1,NUM_LAYERS do
    local L=scenes[selected_scene].layers[li]
    if L.source_guid==guid then
      invalidate_pools(li)
      local pool=refresh_layer_pool(li,true)
      if #pool>0 then load_pool_item(li,pool[clamp(L.sample_index,1,#pool)]) end
      mark_layer_dirty(li)
    end
  end
end
slayer_fx.is_wet=function(tr)
  if not tr then return false end
  local items=slayer_fx.audio_items(tr)
  if #items==0 then return false end
  local fx_n,wet_n=0,0
  for _,item in ipairs(items) do
    local fx=slayer_fx.find_fx(item)
    if fx then
      fx_n=fx_n+1
      if r.GetActiveTake(item)==fx then wet_n=wet_n+1 end
    end
  end
  return fx_n>0 and wet_n==fx_n
end
slayer_fx.lane_has_fx=function(L)
  local tr=L and source_track_for_layer(L)
  if not tr then return false end
  for _,item in ipairs(slayer_fx.audio_items(tr)) do
    if slayer_fx.find_fx(item) then return true end
  end
  return false
end
slayer_fx.any_in_use=function()
  local scene=scenes[selected_scene]
  if not scene then return false end
  for li=1,NUM_LAYERS do
    if slayer_fx.lane_has_fx(scene.layers[li]) then return true end
  end
  return false
end
slayer_fx.set_wet=function(tr,go_wet)
  if not tr then return false end
  local changed=false
  for _,item in ipairs(slayer_fx.audio_items(tr)) do
    local take=go_wet and slayer_fx.find_fx(item) or slayer_fx.find_dry(item)
    if take and r.GetActiveTake(item)~=take then
      r.SetActiveTake(take)
      changed=true
    end
  end
  return changed
end
slayer_fx.apply_random=function(scene,g)
  if not (g and g.enabled) then return end
  local chance=g.chance
  if chance==nil then chance=0.5 end
  for li=1,NUM_LAYERS do
    local L=scene.layers[li]
    if slayer_fx.lane_has_fx(L) then
      local go_wet=math.random()<chance
      slayer_fx.set_wet(source_track_for_layer(L),go_wet)
      L.fx_wet=go_wet
      invalidate_pools(li)
    end
  end
end
slayer_fx.restore_wet=function(scene)
  if not scene then return end
  for li=1,NUM_LAYERS do
    local L=scene.layers[li]
    if L.fx_wet~=nil and slayer_fx.lane_has_fx(L) then
      slayer_fx.set_wet(source_track_for_layer(L),L.fx_wet and true or false)
      invalidate_pools(li)
    end
  end
end

--[[
  Prints the track FX chain onto audio items on `tr` as one replaceable take
  named ADFX FX. A later print crops back to the dry take first so the previous
  FX take is replaced instead of stacked.

  Returns "printed" when at least one item was printed, "skipped" when the
  stored FX hash still matches and every audio item already has an FX take,
  or nil when there is nothing to print.
]]
local function apply_track_fx_to_assets(tr)
  if not track_has_enabled_fx(tr) then return nil end
  local audio_items=slayer_fx.audio_items(tr)
  if #audio_items==0 then return nil end

  local missing=0
  local missing_items={}
  for _,item in ipairs(audio_items) do
    if not slayer_fx.find_fx(item) then
      missing=missing+1
      missing_items[#missing_items+1]=item
    end
  end

  local hash=slayer_fx.chain_hash(tr)
  local plan=slayer_fx.plan_print(hash,slayer_fx.get_hash(tr),missing)
  if plan=="skipped" then return "skipped" end

  local to_print=audio_items
  if plan=="all" then slayer_fx.crop_to_dry(audio_items)
  else to_print=missing_items end
  slayer_fx.print_items(tr,to_print)
  slayer_fx.set_hash(tr,hash)
  return "printed"
end

slayer_fx.toggle_lane=function(li)
  local L=scenes[selected_scene].layers[li]
  local tr=source_track_for_layer(L)
  if not tr then status="Assign a source track first"; return end
  local items=slayer_fx.audio_items(tr)
  if #items==0 then status="L"..li.." source has no audio items"; return end

  local fx_n,wet_n=0,0
  for _,item in ipairs(items) do
    local fx=slayer_fx.find_fx(item)
    if fx then
      fx_n=fx_n+1
      if r.GetActiveTake(item)==fx then wet_n=wet_n+1 end
    end
  end

  if fx_n>0 then
    local go_wet=wet_n<fx_n
    r.Undo_BeginBlock()
    for _,item in ipairs(items) do
      local take=go_wet and slayer_fx.find_fx(item) or slayer_fx.find_dry(item)
      if take then r.SetActiveTake(take) end
    end
    r.UpdateArrange()
    r.Undo_EndBlock(go_wet and "ADFX S-Layer: listen with FX" or "ADFX S-Layer: listen dry",-1)
    L.fx_wet=go_wet
    slayer_fx.refresh_lanes(tr)
    status=go_wet and ("L"..li.." FX on") or ("L"..li.." FX off")
    return
  end

  if not track_has_enabled_fx(tr) then
    status="L"..li.." source has no enabled FX to print"
    return
  end
  local saved_items=save_item_selection()
  local saved_tracks=save_track_selection()
  slayer_fx.hold_offlineinact()
  r.Undo_BeginBlock()
  local result=apply_track_fx_to_assets(tr)
  restore_item_selection(saved_items)
  restore_track_selection(saved_tracks)
  r.UpdateArrange()
  r.Undo_EndBlock("ADFX S-Layer: print track FX",-1)
  slayer_fx.bring_items_online(items)
  slayer_fx.watch_items(items)
  if result=="printed" then
    L.fx_wet=true
    slayer_fx.refresh_lanes(tr)
    status="L"..li.." printed FX"
  else
    status="L"..li.." could not print FX"
  end
end

--- Lay the current track selection into the free lanes, top to bottom. This is
--- the onboarding path: select the tracks once and skip the per-lane menus.
--- `opts.apply_fx` prints each track's enabled FX chain onto its items first,
--- skipping tracks whose stored chain hash still matches.
---
--- Printing is a deferred pipeline so STOP ALL can abort it, and so a focus
--- change cannot freeze REAPER inside a long 40209 render.
local function assign_selected_tracks(opts)
  opts=opts or {}
  if slayer_fx.job then
    status="Assign already running — press STOP ALL to cancel"
    return
  end
  local apply_fx=opts.apply_fx==true
  local sel=selected_source_tracks()
  if #sel==0 then
    status=apply_fx
      and "Select source tracks in REAPER first, then press Assign + FX"
      or "Select source tracks in REAPER first, then press Assign Selected"
    return
  end
  local layers=scenes[selected_scene].layers
  local assigned={}
  local already=0
  for li=1,NUM_LAYERS do
    local g=layers[li].source_guid
    if g~="" then assigned[g]=true end
  end
  for _,tr in ipairs(sel) do
    if assigned[r.GetTrackGUID(tr)] then already=already+1 end
  end

  slayer_fx.hold_offlineinact()
  slayer_fx.job={
    apply_fx=apply_fx,
    sel=sel,
    tracks=sel,
    idx=1,
    printed=0,
    skipped=0,
    already=already,
    assigned=assigned,
    filled={},
    printed_items={},
    saved_items=save_item_selection(),
    saved_tracks=save_track_selection(),
    undo_open=true,
    armed=false,
    queue=nil,
    queue_tr=nil,
    queue_hash=nil,
  }
  r.Undo_BeginBlock()
  if apply_fx then
    status=string.format("Assign + FX 0/%d — STOP ALL cancels",#sel)
  else
    status="Assigning selected tracks…"
  end
end

slayer_fx.assign_lanes=function(job)
  local layers=scenes[selected_scene].layers
  for _,tr in ipairs(job.sel) do
    local guid=r.GetTrackGUID(tr)
    if not job.assigned[guid] then
      local target
      for li=1,NUM_LAYERS do
        if layers[li].source_guid=="" then target=li; break end
      end
      if not target then break end
      if set_layer_source(target,tr) then
        job.filled[#job.filled+1]=target
        job.assigned[guid]=true
      end
    end
  end
end

slayer_fx.apply_assign_result=function(job)
  local printed,skipped,already=job.printed,job.skipped,job.already
  local filled,sel=job.filled,job.sel
  local apply_fx=job.apply_fx
  local function fx_extra()
    if printed>0 and skipped>0 then
      return string.format(", printed FX on %d, skipped %d (unchanged)",printed,skipped)
    end
    if printed>0 then return string.format(", printed FX on %d",printed) end
    if skipped>0 then return string.format(", skipped %d (unchanged)",skipped) end
    return " (no track FX to print — assigned originals)"
  end

  if #filled==0 then
    if apply_fx and (printed>0 or skipped>0) then
      save_state(); apply_runtime(true)
      if printed>0 then
        status="Reprinted FX on "..printed..(skipped>0 and string.format(", skipped %d (unchanged)",skipped) or "")
          .." (lanes already assigned)"
      else
        status=string.format("FX unchanged on %d track%s — nothing to reprint",
          skipped,skipped==1 and "" or "s")
      end
      return
    end
    status="Every lane already has a source track. Press Clear Lanes first"
    return
  end
  save_state(); apply_runtime(true)

  local used=#filled
  local left=#sel-already-used
  -- Free lanes are not always a run: filling the gaps in L1, _, L3, _ lands on
  -- 2 and 4, and calling that "L2-L4" would name a lane that was left alone.
  local where
  if used>1 and filled[used]-filled[1]+1==used then
    where=string.format("L%d-L%d",filled[1],filled[used])
  else
    local names={}
    for i=1,used do names[i]="L"..filled[i] end
    where=table.concat(names,", ")
  end
  local extra=""
  if already>0 then extra=extra..string.format(", %d already assigned",already) end
  if left>0 then extra=extra..string.format(", %d did not fit",left) end
  if apply_fx then extra=extra..fx_extra() end
  status=string.format("Assigned %d track%s to %s%s",
    used,used==1 and "" or "s",where,extra)
end

slayer_fx.finish_job=function(job,cancelled)
  if job.undo_open then
    restore_item_selection(job.saved_items)
    restore_track_selection(job.saved_tracks)
    r.UpdateArrange()
    local label
    if job.apply_fx then
      label=cancelled and "ADFX S-Layer: assign + FX (cancelled)" or "ADFX S-Layer: assign selected with track FX"
    else
      label=cancelled and "ADFX S-Layer: assign selected (cancelled)" or "ADFX S-Layer: assign selected"
    end
    r.Undo_EndBlock(label,-1)
    job.undo_open=false
  end
  slayer_fx.job=nil
  if job.printed_items and #job.printed_items>0 then
    slayer_fx.bring_items_online(job.printed_items)
    slayer_fx.watch_items(job.printed_items)
  else
    slayer_fx.release_offlineinact()
  end
end

slayer_fx.cancel_job=function()
  local job=slayer_fx.job
  if not job then return false end
  slayer_fx.finish_job(job,true)
  return true
end

slayer_fx.queue_track_print=function(job,tr)
  if not track_has_enabled_fx(tr) then return nil end
  local audio_items=slayer_fx.audio_items(tr)
  if #audio_items==0 then return nil end
  local missing_items={}
  for _,item in ipairs(audio_items) do
    if not slayer_fx.find_fx(item) then missing_items[#missing_items+1]=item end
  end
  local hash=slayer_fx.chain_hash(tr)
  local plan=slayer_fx.plan_print(hash,slayer_fx.get_hash(tr),#missing_items)
  if plan=="skipped" then return "skipped" end
  local to_print=audio_items
  if plan=="all" then slayer_fx.crop_to_dry(audio_items)
  else to_print=missing_items end
  job.queue=to_print
  job.queue_tr=tr
  job.queue_hash=hash
  return "queued"
end

slayer_fx.tick_pipeline=function()
  slayer_fx.tick_peaks()
  slayer_fx.tick_guard()
  local job=slayer_fx.job
  if not job then return end
  -- Leave one UI frame after the button press so STOP ALL can be clicked
  -- before the first blocking Apply-FX render starts.
  if not job.armed then
    job.armed=true
    return
  end

  if job.apply_fx then
    if job.queue and #job.queue>0 then
      local item=table.remove(job.queue,1)
      if r.ValidatePtr2(0,item,"MediaItem*") and job.queue_tr
          and r.ValidatePtr2(0,job.queue_tr,"MediaTrack*") then
        slayer_fx.print_items(job.queue_tr,{item})
        job.printed_items[#job.printed_items+1]=item
      end
      status=string.format("Assign + FX %d/%d — STOP ALL cancels",
        math.min(job.idx-1,#job.tracks),#job.tracks)
      return
    end
    if job.queue_tr then
      slayer_fx.set_hash(job.queue_tr,job.queue_hash)
      slayer_fx.refresh_lanes(job.queue_tr)
      slayer_fx.bring_items_online(slayer_fx.audio_items(job.queue_tr))
      job.printed=job.printed+1
      job.queue=nil
      job.queue_tr=nil
      job.queue_hash=nil
    end
    while job.idx<=#job.tracks do
      local tr=job.tracks[job.idx]
      job.idx=job.idx+1
      if r.ValidatePtr2(0,tr,"MediaTrack*") then
        local result=slayer_fx.queue_track_print(job,tr)
        if result=="skipped" then
          job.skipped=job.skipped+1
        elseif result=="queued" then
          status=string.format("Assign + FX %d/%d — STOP ALL cancels",
            math.min(job.idx-1,#job.tracks),#job.tracks)
          return
        end
      end
    end
  end

  slayer_fx.assign_lanes(job)
  slayer_fx.apply_assign_result(job)
  slayer_fx.finish_job(job,false)
end

local function stop_all_voices(set_status, cancel_import)
  -- RS5K one-shots keep ringing after their short trigger note has ended, so a
  -- normal MIDI note-off is not a reliable panic. Briefly taking only the managed
  -- sampler offline resets its active voices while leaving the playback track and
  -- any user FX after RS5K untouched. The loaded FILE0 assignment remains in place.
  -- CHOKE / a new TRIGGER must not abort an in-progress assign. STOP ALL and
  -- CLEAR LANES pass cancel_import so the user can kill the whole pipeline.
  local cancelled=cancel_import and slayer_fx.cancel_job()
  pending_trigger=nil
  pending_ack=nil
  local stopped=0
  if tracks.layers then
    for li=1,NUM_LAYERS do
      local E=tracks.layers[li]
      if E and valid_media_track(E.track) and E.rs5k and E.rs5k>=0 then
        local ok=pcall(function()
          r.TrackFX_SetOffline(E.track,E.rs5k,true)
          r.TrackFX_SetOffline(E.track,E.rs5k,false)
          r.TrackFX_SetEnabled(E.track,E.rs5k,true)
          hide_managed_fx_windows(E.track,E.bridge,E.rs5k)
        end)
        if ok then stopped=stopped+1 end
      end
      lane_activity[li]=nil
    end
  end
  if set_status ~= false then
    if cancelled then
      status=stopped>0 and "Stopped S-Layer voices and cancelled assign" or "Cancelled assign pipeline"
    else
      status=stopped>0 and "Stopped all S-Layer voices" or "No S-Layer voices to stop"
    end
  end
  return stopped
end

local function clear_lane_sources()
  stop_all_voices(false, true)
  local layers=scenes[selected_scene].layers
  for li=1,NUM_LAYERS do
    local L=layers[li]
    L.source_guid=""; L.source_name=""; L.sample=""
    L.sample_index=1; L.pool_count=0
    invalidate_pools(li)
    -- The waveform preview is UI cache, not scene state. Clear the lane-facing
    -- references as soon as its source assignment is removed so stale audio is
    -- never drawn after CLEAR LANES. The shared waveform cache itself can stay.
    lane_waveform_entry[li]=nil
    lane_activity[li]=nil
  end
  narrow_random[selected_scene]={active=false,multiplier=2.0,layers={}}
  save_state(); apply_runtime(true)
  status="Cleared the source track on every lane"
end


local function clear_all_scenes()
  -- This is intentionally a scene reset, not a global-settings reset: CHOKE and
  -- GLOBAL TRIGGER RANDOM remain exactly as the user configured them.
  for si=1,NUM_SCENES do
    scenes[si]=default_scene()
    narrow_random[si]={active=false,multiplier=2.0,layers={}}
  end
  invalidate_pools()
  for li=1,NUM_LAYERS do
    lane_waveform_entry[li]=nil
    lane_activity[li]=nil
  end
  pending_trigger=nil
  pending_ack=nil
  mark_all_dirty()
  mark_state_dirty()
  apply_runtime(true)
  save_state()
  state_dirty=false
  status="Cleared all "..NUM_SCENES.." scenes"
end

--[[
  Shot journal
  ----------------------------------------------------------------------------
  Every trigger that goes out is written down with the wall clock reading it
  went out at, along with the layer values that produced it. The recorder
  timestamps its take the same way, so a point in a recording can be turned
  back into the settings that made the sound at that point.

  Signal Session removes silence from the recorded file. Recorder v1.6.2 keeps
  a compact-file-time -> wall-time segment map, so right-click Restore remains
  aligned with the exact shot even after long pauses between iterations.

  The journal is memory only and deliberately so: it describes this session's
  sounds, and the recorder's takes do not outlive it either.
]]
local SHOT_JOURNAL_MAX = 512
-- A shot is matched to a moment in the recording if it fired at or before it.
-- The tolerance covers the take's own timing slack: a buffer export is anchored
-- by counting frames back from now, and a shot is written a frame or so before
-- its audio reaches the capture plug-in.
local SHOT_MATCH_TOLERANCE = 0.050
local shot_journal = {}
-- When recorder restore is used, LAST TRIGGER should replay that restored rack
-- even though the journal's newest entry may still describe a later audition.
local retrigger_override = nil

local function record_shot(fire, bypass_random)
  local scene=scenes[selected_scene]
  local layers={}
  for li=1,NUM_LAYERS do
    -- The whole layer, so a restore does not have to know which fields matter.
    local L=copy_table(scene.layers[li])
    L.fired=fire[li] and true or false
    local tr=source_track_for_layer(scene.layers[li])
    if tr then L.fx_wet=slayer_fx.is_wet(tr) end
    layers[li]=L
  end
  local randomized={}
  if not bypass_random then
    for _,name in ipairs(GLOBAL_RANDOM_ORDER) do
      if global_trigger_random[name].enabled then randomized[#randomized+1]=name end
    end
  end
  shot_journal[#shot_journal+1]={
    at=r.time_precise(), scene=selected_scene, layers=layers, randomized=randomized,
    sc=pending_trigger and pending_trigger.sc and copy_table(pending_trigger.sc) or nil}
  if #shot_journal>SHOT_JOURNAL_MAX then table.remove(shot_journal,1) end
end

--- The shot that was sounding at a wall clock reading, or nil plus a reason.
local function shot_at_wall_time(wall)
  if not wall then return nil,"this take has no timing information" end
  if #shot_journal==0 then return nil,"nothing has been triggered yet this session" end
  for i=#shot_journal,1,-1 do
    if shot_journal[i].at<=wall+SHOT_MATCH_TOLERANCE then return shot_journal[i] end
  end
  return nil,"that point is before the first shot of this session"
end

local function scene_is_empty(si)
  for li=1,NUM_LAYERS do
    if scenes[si].layers[li].source_guid~="" then return false end
  end
  return true
end

--- Where a restored shot should land: an untouched scene if there is one, so
--- nothing a user built is overwritten, otherwise the next scene along.
local function restore_target_scene()
  for si=1,NUM_SCENES do
    if si~=selected_scene and scene_is_empty(si) then return si,true end
  end
  return (selected_scene%NUM_SCENES)+1,false
end

--- Rebuild a recorded shot in its own scene and switch to it.
local function restore_shot(shot)
  -- Entering recorder-restore isolation must not destroy the broad random setup
  -- the user was exploring with. Preserve the FIRST setup until RESTORE is
  -- released; repeated restores while isolated keep pointing back to that setup.
  if not restore_global_random_snapshot then
    restore_global_random_snapshot=copy_table(global_trigger_random)
    sidechain.restore_snapshot=copy_table(sidechain)
    sidechain.restore_snapshot.SOURCE=nil
    sidechain.restore_snapshot.FX_NAMES=nil
    sidechain.restore_snapshot.MODE_LABELS=nil
    sidechain.restore_snapshot.SCHEMA_TAG=nil
    restore_lane_random_snapshot={}
    for li=1,NUM_LAYERS do
      -- The shot journal preserves whether that lane was using RND when this
      -- sound was created. Restore pins the exact item temporarily; releasing
      -- the lock puts that original per-lane RND choice back.
      restore_lane_random_snapshot[li]=shot.layers[li].random_sample and true or false
    end
  end

  local si,was_empty=restore_target_scene()
  local target={layers={}}
  for li=1,NUM_LAYERS do
    local L=copy_table(shot.layers[li])
    L.fired=nil
    -- Pin the item this shot actually used. Left on RND, the next trigger in
    -- the restored scene would pick a different one and the point of restoring
    -- would be lost.
    L.random_sample=false
    target.layers[li]=L
  end
  scenes[si]=target
  slayer_fx.restore_wet(target)
  narrow_random[si]={active=false,multiplier=2.0,layers={}}
  -- LAST TRIGGER/T is a diagnostic replay of the state the user is looking at.
  -- A recorder restore therefore becomes its source immediately, instead of
  -- falling back to whatever happened to be the newest shot in the journal.
  retrigger_override={layers=copy_table(target.layers),randomized={},
    sc=shot.sc and copy_table(shot.sc) or nil}

  -- A restored shot is an exact diagnostic selection. Temporarily disable ALL
  -- currently-enabled Global Trigger Random parameters so a normal TRIGGER does
  -- not immediately move away from the restored values. RESTORE restores
  -- this complete setup when the user is ready to resume exploration.
  local turned_off={}
  for _,name in ipairs(GLOBAL_RANDOM_ORDER) do
    local g=global_trigger_random[name]
    if g and g.enabled then g.enabled=false; turned_off[#turned_off+1]=name end
  end
  -- Pin SIDECHAIN to the shot: no value/mode rolls, and the combo/mins match
  -- what that take actually used so a later TRIGGER stays on the restored duck.
  sidechain.rnd=false
  sidechain.rnd_mode=false
  if shot.sc then
    sidechain.mode=clamp(shot.sc.mode or 0,0,4)
    if shot.sc.amount then
      sidechain.amount_min=clamp(shot.sc.amount,0,1)
      sidechain.amount_max=clamp(shot.sc.amount,0,1)
    end
    if shot.sc.attack then
      sidechain.attack_min=clamp(shot.sc.attack,0,50)
      sidechain.attack_max=clamp(shot.sc.attack,0,50)
    end
    if shot.sc.release then
      sidechain.release_min=clamp(shot.sc.release,0,800)
      sidechain.release_max=clamp(shot.sc.release,0,800)
    end
    if shot.sc.thresh then
      sidechain.thresh_min=clamp(shot.sc.thresh,0,1)
      sidechain.thresh_max=clamp(shot.sc.thresh,0,1)
    end
    turned_off[#turned_off+1]="SIDECHAIN"
  end

  save_state()
  selected_scene=si
  invalidate_pools()
  sync_sources()
  mark_all_dirty()
  apply_runtime(true)
  save_state()

  local msg=string.format("Restored that shot into Scene %d%s",si,
    was_empty and "" or " (it was not empty)")
  if #turned_off>0 then
    msg=msg..", global random off for "..table.concat(turned_off,", ")
  end
  status=msg
  return msg
end

-- Recorder mode is intentionally independent of restored S-Layer state.
-- Only the next Auto-trigger is suppressed after a restore; the user's Auto/Signal
-- preference itself is never changed.
local suppress_next_recorder_auto=false

--- Right click menu entry handed to the recorder strip.
local function restore_from_take_position(at)
  local wall=recorder and recorder:wall_time_at(at)
  local shot,why=shot_at_wall_time(wall)
  if not shot then
    status="Cannot restore: "..tostring(why)
    return status
  end

  -- Preserve the recorder mode. The first normal trigger after a diagnostic
  -- restore is ignored by Auto only; Signal Session remains armed and can wake
  -- normally because it was explicitly started by the user.
  suppress_next_recorder_auto=true
  return restore_shot(shot)
end

local function dispatch_pending_trigger()
  if not pending_trigger or r.time_precise()<pending_trigger.when then return end
  trigger_counter=trigger_counter+1
  -- Anything else in this script may have borrowed the gmem attachment, and a
  -- trigger written into the wrong space is a note that never sounds.
  r.gmem_attach(GMEM_NAME)
  -- Told here rather than in trigger(): this is the frame the note actually
  -- goes out on, so an automatic take does not open on the loading window.
  -- Snapshot at fire time: a normal TRIGGER always follows. LAST TRIGGER
  -- follows only when REC LAST is on. When it is off, pause/close the open
  -- follow take first so the replay cannot land in a session that is still
  -- capturing from the previous TRIGGER.
  local is_last=pending_trigger.last_trigger==true
  local follow_recorder=pending_trigger.follow_recorder
  if follow_recorder==nil then
    follow_recorder=(not is_last) or last_trigger_follow
  end
  if recorder then
    if follow_recorder then
      local skip_auto = suppress_next_recorder_auto
        and type(recorder.auto_enabled)=="function" and recorder:auto_enabled()
      if skip_auto then
        suppress_next_recorder_auto=false
      else
        local ok,err=pcall(recorder.signal_trigger,recorder)
        if not ok then status="Recorder trigger error: "..tostring(err) end
      end
    elseif is_last and type(recorder.skip_follow)=="function" then
      pcall(recorder.skip_follow,recorder)
    end
  end
  -- Recorder calls temporarily borrow gmem. Re-attach defensively even when the
  -- recorder reported an error, so the note below can never land in its block.
  r.gmem_attach(GMEM_NAME)
  -- Side-chain values must be latched before the layer counters change, so
  -- each duck JSFX sees a complete shot (mode + amount + times) on the same
  -- key-counter edge that starts its envelope.
  local sc=pending_trigger.sc
  if sc then
    r.gmem_write(sidechain.GMEM_MODE,sc.mode or 0)
    r.gmem_write(sidechain.GMEM_AMOUNT,sc.amount or 0)
    r.gmem_write(sidechain.GMEM_ATTACK,sc.attack or 0)
    r.gmem_write(sidechain.GMEM_RELEASE,sc.release or 0)
    r.gmem_write(sidechain.GMEM_THRESH,sc.thresh or 0)
  else
    r.gmem_write(sidechain.GMEM_MODE,0)
    r.gmem_write(sidechain.GMEM_AMOUNT,0)
    r.gmem_write(sidechain.GMEM_ATTACK,0)
    r.gmem_write(sidechain.GMEM_RELEASE,0)
    r.gmem_write(sidechain.GMEM_THRESH,0)
  end
  -- Shuffle map: -1 means this lane is not a bed. Written every shot so a
  -- leftover Pair/Bank trigger cannot keep a stale directed pair alive.
  for i=0,15 do
    local key=-1
    if sc and sc.mode==4 and sc.map then key=sc.map[i] or -1 end
    r.gmem_write(sidechain.GMEM_SHUFFLE+i,key)
  end
  r.gmem_write(1,pending_trigger.velocity or 110)
  local fire=pending_trigger.layers
  local n=pending_trigger.count
  local chosen=pending_trigger.chosen
  for li=1,NUM_LAYERS do
    if fire[li] then
      r.gmem_write(9+li,trigger_counter)
      note_lane_trigger(li,pending_trigger.visuals and pending_trigger.visuals[li])
    end
  end
  sidechain.note_shot(sc,fire)
  -- Written here, next to the note going out, so the journal's clock and the
  -- recorder's are reading the same moment.
  record_shot(fire, pending_trigger.bypass_random)
  pending_trigger=nil
  pending_ack={when=r.time_precise()+0.120,counter=trigger_counter,layers=fire,count=n,chosen=chosen}
  status=string.format("Trigger sent to %d layer%s...",n,n==1 and "" or "s")
end

local function verify_trigger_ack()
  if not pending_ack or r.time_precise()<pending_ack.when then return end
  r.gmem_attach(GMEM_NAME)
  local seen=0
  local missing={}
  for li=1,NUM_LAYERS do
    if pending_ack.layers[li] then
      local ack=math.floor((r.gmem_read(29+li) or 0)+0.5)
      if ack==pending_ack.counter then seen=seen+1 else missing[#missing+1]=tostring(li) end
    end
  end
  local expected=pending_ack.count
  local picks=pending_ack.chosen or {}
  pending_ack=nil
  if seen==expected then
    status=string.format("Triggered %d layer%s - %s",seen,seen==1 and "" or "s",#picks>0 and table.concat(picks,"  ") or "realtime bridge confirmed")
  else
    status=string.format("Trigger bridge failure: %d/%d layers acknowledged (missing L%s)",seen,expected,table.concat(missing,",L"))
  end
end

local function choose_random_no_repeat(pool_count, previous_index)
  if pool_count <= 0 then return nil end
  if pool_count == 1 then return 1 end
  previous_index = clamp(tonumber(previous_index) or 1, 1, pool_count)
  -- Pick uniformly from every slot except the one used last time.
  -- This guarantees that RND always means a NEW source on each trigger.
  local pick = math.random(1, pool_count - 1)
  if pick >= previous_index then pick = pick + 1 end
  return pick
end

local function rand_range(a,b)
  if a>b then a,b=b,a end
  return a + math.random()*(b-a)
end

local function restore_lane_random_after_recorder_restore()
  if not restore_lane_random_snapshot then return false end
  local scene=scenes[selected_scene]
  if not (scene and scene.layers) then return false end
  local changed=false
  for li=1,NUM_LAYERS do
    if restore_lane_random_snapshot[li] ~= nil then
      local v=restore_lane_random_snapshot[li] and true or false
      if scene.layers[li].random_sample ~= v then
        scene.layers[li].random_sample=v
        changed=true
      end
    end
  end
  -- Keep the snapshot for the lifetime of recorder-restore isolation. Narrow can
  -- temporarily resume those lane-RND choices, then turning Narrow OFF can return
  -- to the exact isolated state (all lane RND OFF). RESTORE is the action that
  -- finally consumes/clears this snapshot and returns to normal exploration.
  if changed then mark_state_dirty() end
  return changed
end

local release_restore_iso_settings

local function toggle_narrow_random_from_current()
  local nr=narrow_random[selected_scene]
  if nr.active then
    nr.active=false
    if restore_global_random_snapshot then
      -- Recorder restore has two useful audition states:
      --   1) isolated exact shot: all lane RND OFF + all broad Global Random OFF
      --   2) Narrow audition: saved lane RND states resumed + Narrow offsets active
      -- Turning Narrow OFF returns to state 1. It deliberately does NOT release
      -- recorder-restore isolation; the flashing RESTORE button remains the only
      -- explicit exit back to the user's pre-restore exploration setup.
      local scene=scenes[selected_scene]
      if scene and scene.layers then
        for li=1,NUM_LAYERS do scene.layers[li].random_sample=false end
      end
      for _,name in ipairs(GLOBAL_RANDOM_ORDER) do
        local g=global_trigger_random[name]
        if g then g.enabled=false end
      end
      sidechain.rnd=false
      sidechain.rnd_mode=false
      mark_state_dirty()
      status="Narrow OFF - returned to restored-shot isolation (lane RND + Global Random off)"
    else
      mark_state_dirty()
      status="Narrow OFF - normal Global Trigger Random settings active"
    end
    return
  end

  -- A recorder restore pins exact source items by temporarily forcing every
  -- lane's RND checkbox off. Narrow Current is the point where the user resumes
  -- controlled variation, so put those lane-RND choices back BEFORE capturing
  -- the current sweet spot. Global random remains isolated until RESTORE is used.
  local rnd_restored=restore_lane_random_after_recorder_restore()

  local scene=scenes[selected_scene]
  nr.layers={}
  for li=1,NUM_LAYERS do
    local L=scene.layers[li]
    nr.layers[li]={pitch=L.pitch,volume_db=L.volume_db,pan=L.pan,start=L.start}
  end
  nr.active=true

  -- Narrow is a self-contained mode. Never rewrite the user's broad GLOBAL
  -- TRIGGER RANDOM configuration; switching Narrow off should reveal exactly
  -- the enable states and ranges that were configured before it was enabled.
  mark_state_dirty()
  status=rnd_restored and "Captured narrow sweet spot - lane RND settings restored" or "Captured current rack as narrow random sweet spot"
end

function sidechain.note_shot(sc, fire)
  -- Mode Off writes no duck, so the previous envelope is left to finish.
  -- CHOKE does not cancel it either; a later active shot replaces this.
  if not sc or (sc.mode or 0)==0 then return end
  local fired={}
  for i=1,NUM_LAYERS do fired[i]=fire and fire[i] and true or false end
  sidechain.last_shot={
    at=r.time_precise(),
    mode=sc.mode,
    amount=clamp(sc.amount or 0,0,1),
    attack=math.max(0,(sc.attack or 0)*0.001),
    release=math.max(0,(sc.release or 0)*0.001),
    fired=fired,
  }
end

function sidechain.visual_key(li)
  -- Envelope of a lane that is currently a key for the live SIDECHAIN mode.
  -- Nil when this lane is not doing any ducking (Off, or not in the key bank).
  r.gmem_attach(GMEM_NAME)
  local mode=math.floor((r.gmem_read(sidechain.GMEM_MODE) or 0)+0.5)
  if mode<1 or mode>4 then return nil end
  local layer=li-1
  if mode==1 and layer>=8 then return nil end
  if mode==2 and layer<8 then return nil end
  if mode==4 then
    local used=false
    for bed=0,15 do
      local key=math.floor((r.gmem_read(sidechain.GMEM_SHUFFLE+bed) or -1)+0.5)
      if key==layer then used=true break end
    end
    if not used then return nil end
  end
  local env=r.gmem_read(100+layer)
  if type(env)~="number" then return nil end
  env=clamp(env,0,1)
  local thresh=tonumber(r.gmem_read(sidechain.GMEM_THRESH)) or 0
  if env<=thresh then return nil end
  return env
end

function sidechain.visual_gain(li)
  -- Read the live JSFX gain so the red line rides the key audio, not a
  -- one-shot TRIGGER envelope. slider6 is parameter index 5.
  local E=tracks.layers and tracks.layers[li]
  if not (E and E.track and E.duck and E.duck>=0) then return 1 end
  if r.ValidatePtr2 and not r.ValidatePtr2(0,E.track,"MediaTrack*") then return 1 end
  local g=r.TrackFX_GetParam(E.track,E.duck,5)
  if type(g)~="number" then return 1 end
  return clamp(g,0,1)
end

function sidechain.next_shuffle_map()
  -- Pair every lane with a random mate, like Pair but the matching is new
  -- each TRIGGER: shuffle 0..15 and take (0,1) (2,3) … (14,15).
  local order={}
  for i=0,15 do order[i+1]=i end
  for i=16,2,-1 do
    local j=math.random(1,i)
    order[i],order[j]=order[j],order[i]
  end
  local map={}
  for i=1,16,2 do
    local a,b=order[i],order[i+1]
    map[a]=b
    map[b]=a
  end
  return map
end

function sidechain.roll(replay_shot)
  -- LAST TRIGGER / a recorder-restored override keep the exact duck that
  -- sounded. A missing journal field (pre-0.2.78 shots) writes Off.
  if replay_shot then
    local sc=replay_shot.sc
    if not sc then return {mode=0,amount=0,attack=0,release=0,thresh=0} end
    return {
      mode=clamp(sc.mode or 0,0,4),
      amount=clamp(sc.amount or 0,0,1),
      attack=clamp(sc.attack or 0,0,50),
      release=clamp(sc.release or 0,0,800),
      thresh=clamp(sc.thresh or 0,0,1),
      map=sc.map and copy_table(sc.map) or nil,
    }
  end
  if sidechain.mode==0 then
    return {mode=0,amount=0,attack=0,release=0,thresh=0}
  end
  local mode=sidechain.mode
  if sidechain.rnd_mode then
    mode=math.random(1,4)
  end
  local amount,attack,release,thresh
  if sidechain.rnd then
    amount=rand_range(sidechain.amount_min,sidechain.amount_max)
    attack=rand_range(sidechain.attack_min,sidechain.attack_max)
    release=rand_range(sidechain.release_min,sidechain.release_max)
    thresh=rand_range(sidechain.thresh_min,sidechain.thresh_max)
  else
    amount=sidechain.amount_min
    attack=sidechain.attack_min
    release=sidechain.release_min
    thresh=sidechain.thresh_min
  end
  local map=nil
  if mode==4 then
    map=sidechain.next_shuffle_map()
  end
  return {
    mode=mode,
    amount=clamp(amount,0,1),
    attack=clamp(attack,0,50),
    release=clamp(release,0,800),
    thresh=clamp(thresh,0,1),
    map=map,
  }
end

local function apply_global_trigger_random(scene)
  local gp=global_trigger_random.Pitch
  local gv=global_trigger_random.Volume
  local gpan=global_trigger_random.Pan
  local gst=global_trigger_random.Start
  local grev=global_trigger_random.Reverse
  local nr=narrow_random[selected_scene]
  local narrow_mul=math.max(NARROW_MULTIPLIER_MIN,(nr and nr.multiplier) or 2.0)
  for li=1,NUM_LAYERS do
    local L=scene.layers[li]
    local c=nr and nr.active and nr.layers[li] or nil
    if c then
      -- Narrow owns the four continuous values while active, independently of
      -- the broad Global enable checkboxes. The broad configuration is preserved
      -- untouched underneath this mode and resumes immediately when Narrow is off.
      local d=NARROW_RANDOM_SPREAD.Pitch*narrow_mul
      L.pitch=clamp(rand_range(c.pitch-d,c.pitch+d),-24,24)
      d=NARROW_RANDOM_SPREAD.Volume*narrow_mul
      L.volume_db=clamp(rand_range(c.volume_db-d,c.volume_db+d),-60,12)
      d=NARROW_RANDOM_SPREAD.Pan*narrow_mul
      L.pan=clamp(rand_range(c.pan-d,c.pan+d),-1,1)
      d=NARROW_RANDOM_SPREAD.Start*narrow_mul
      L.start=clamp(rand_range(c.start-d,c.start+d),0,1)
      -- Reverse / Loop / Mute / Solo are intentionally untouched in narrow mode.
    else
      if gp.enabled then L.pitch=clamp(rand_range(gp.min,gp.max),-24,24) end
      if gv.enabled then L.volume_db=clamp(rand_range(gv.min,gv.max),-60,12) end
      if gpan.enabled then L.pan=clamp(rand_range(gpan.min,gpan.max),-1,1) end
      if gst.enabled then L.start=clamp(rand_range(gst.min,gst.max),0,1) end
      if grev.enabled then L.reverse=math.random()<grev.chance end
    end
  end
  -- FX wet/dry is a separate take switch, not a lane slider. Narrow leaves it
  -- alone the same way it leaves Reverse / Loop / Mute / Solo alone.
  if not (nr and nr.active) then
    slayer_fx.apply_random(scene,global_trigger_random.FX)
  end
end

local function trigger(velocity, replay_shot)
  local ok,reason=scan_tracks()
  if not ok then
    status="Playback engine needs repair: "..tostring(reason).." (use Repair Engine once)"
    return
  end

  -- CHOKE is rack-wide: every previous S-Layer voice dies before the new set is
  -- prepared. This is deliberately stronger than RS5K Max voices=1, which only
  -- steals a voice when that SAME lane receives another note and therefore lets
  -- long sounds on non-firing lanes stack indefinitely.
  if choke then stop_all_voices(false) end

  local scene=scenes[selected_scene]
  local bypass_random = replay_shot ~= nil

  if replay_shot then
    -- Put the rack back exactly where the previous shot was. This is intentionally
    -- deterministic: global parameter randomizers and per-lane RND item picking are
    -- both skipped below. Mute/Solo are the exception: LAST TRIGGER is a diagnostic
    -- tool, so the CURRENT M/S state must stay live while the sound itself is frozen.
    local live_mute,live_solo={},{}
    for li=1,NUM_LAYERS do
      live_mute[li]=scene.layers[li].mute
      live_solo[li]=scene.layers[li].solo
    end
    for li=1,NUM_LAYERS do
      scene.layers[li]=copy_table(replay_shot.layers[li])
      scene.layers[li].fired=nil
      scene.layers[li].mute=live_mute[li]
      scene.layers[li].solo=live_solo[li]
    end
    slayer_fx.restore_wet(scene)
    invalidate_pools()
  else
    -- A fresh trigger supersedes any recorder-restored diagnostic snapshot.
    -- Once a new sound is made, LAST TRIGGER should follow that newest sound.
    retrigger_override=nil
    apply_global_trigger_random(scene)
  end

  reverse_note=""
  local anysolo=solo_logic(scene)
  local fire={}; local visuals={}; local count=0; local loaded_any=false
  local chosen={}
  local swaps=0
  for li=1,NUM_LAYERS do
    local L=scene.layers[li]
    if not L.mute and (not anysolo or L.solo) then
      local pool=refresh_layer_pool(li)
      if #pool>0 then
        if bypass_random then
          -- The recorded shot already contains the item index that actually fired.
          L.sample_index=clamp(L.sample_index,1,#pool)
        elseif L.random_sample then
          L.sample_index=choose_random_no_repeat(#pool,L.sample_index)
        else
          L.sample_index=clamp(L.sample_index,1,#pool)
        end
        local ok_load,swapped=load_pool_item(li,pool[L.sample_index])
        if ok_load then
          fire[li]=true; count=count+1; loaded_any=true
          visuals[li]={entry=pool[L.sample_index],start=L.start,pitch=L.pitch,reverse=L.reverse,loop=L.loop}
          if swapped then swaps=swaps+1 end
          chosen[#chosen+1]=string.format("L%d:%d/%d",li,L.sample_index,#pool)
        end
      end
    end
  end
  apply_runtime(true)
  if not loaded_any then status="Nothing triggered: assigned pools have no playable audio items"; return end

  local wait=(swaps>0) and math.min(PRE_ROLL.BASE+PRE_ROLL.PER_SWAP*swaps,PRE_ROLL.MAX) or PRE_ROLL.NONE
  pending_trigger={
    when=r.time_precise()+wait, velocity=velocity or 110, layers=fire, visuals=visuals, count=count,
    chosen=chosen, bypass_random=bypass_random,
    last_trigger=bypass_random,
    follow_recorder=(not bypass_random) or last_trigger_follow,
    sc=sidechain.roll(replay_shot),
  }
  if bypass_random then
    status=swaps>0
      and string.format("LAST TRIGGER loading %d source%s: %s",swaps,swaps==1 and "" or "s",table.concat(chosen,"  "))
      or "LAST TRIGGER: "..table.concat(chosen,"  ")
  else
    status=swaps>0
      and string.format("Loading %d new source%s: %s",swaps,swaps==1 and "" or "s",table.concat(chosen,"  "))
      or "Triggering: "..table.concat(chosen,"  ")
  end
end

local function trigger_last(velocity)
  local shot=retrigger_override or shot_journal[#shot_journal]
  if not shot then
    status="LAST TRIGGER unavailable: trigger a sound once first"
    return
  end
  trigger(velocity or 115,shot)
end

local function source_combo(li)
  local L=scenes[selected_scene].layers[li]
  local current=L.source_name~="" and L.source_name or "(select source track)"
  r.ImGui_SetNextItemWidth(ctx,180)
  if r.ImGui_BeginCombo(ctx,"##source",current) then
    for ti=0,r.CountTracks(0)-1 do
      local tr=r.GetTrack(0,ti)
      if not is_engine_track(tr) then
        local _,nm=r.GetTrackName(tr); if nm=="" then nm="Track "..(ti+1) end
        local guid=r.GetTrackGUID(tr); local sel=guid==L.source_guid
        if r.ImGui_Selectable(ctx,nm,sel) then assign_source_track(li,tr) end
      end
    end
    r.ImGui_EndCombo(ctx)
  end
end

local global_toggle_rects = {}
local global_toggle_drag = nil

local function segment_hits_rect(x0,y0,x1,y1,rc)
  local dx,dy=x1-x0,y1-y0
  local t0,t1=0,1
  local function clip(p,q)
    if math.abs(p)<1e-9 then return q>=0 end
    local t=q/p
    if p<0 then
      if t>t1 then return false end
      if t>t0 then t0=t end
    else
      if t<t0 then return false end
      if t<t1 then t1=t end
    end
    return true
  end
  return clip(-dx,x0-rc.x0) and clip(dx,rc.x1-x0) and
         clip(-dy,y0-rc.y0) and clip(dy,rc.y1-y0)
end

local function global_toggle_checkbox(name,g)
  local changed,v=r.ImGui_Checkbox(ctx,name,g.enabled)
  if changed then g.enabled=v; mark_state_dirty() end

  if r.ImGui_GetItemRectMin and r.ImGui_GetItemRectMax then
    local x0,y0=r.ImGui_GetItemRectMin(ctx)
    local x1,y1=r.ImGui_GetItemRectMax(ctx)
    global_toggle_rects[name]={x0=x0,y0=y0,x1=x1,y1=y1}
  end

  -- A normal click still toggles one box.  Keep holding the left button and
  -- sweep through the other global enable boxes to paint that new state across
  -- them.  Geometry is used rather than IsItemHovered so ImGui's active item
  -- capture cannot block the boxes crossed later in the drag.
  if r.ImGui_IsItemClicked and r.ImGui_IsItemClicked(ctx,0) then
    local mx,my=r.ImGui_GetMousePos(ctx)
    global_toggle_drag={target=g.enabled,visited={[name]=true},px=mx,py=my}
  end
end

local function update_global_toggle_drag()
  if not global_toggle_drag then return end
  if not (r.ImGui_IsMouseDown and r.ImGui_IsMouseDown(ctx,0)) then
    global_toggle_drag=nil
    return
  end
  local mx,my=r.ImGui_GetMousePos(ctx)
  local changed=false
  for _,name in ipairs(GLOBAL_RANDOM_ORDER) do
    local rc=global_toggle_rects[name]
    if rc and not global_toggle_drag.visited[name] and
       segment_hits_rect(global_toggle_drag.px,global_toggle_drag.py,mx,my,rc) then
      local g=global_trigger_random[name]
      if g.enabled~=global_toggle_drag.target then
        g.enabled=global_toggle_drag.target
        changed=true
      end
      global_toggle_drag.visited[name]=true
    end
  end
  global_toggle_drag.px,global_toggle_drag.py=mx,my
  if changed then mark_state_dirty() end
end

-- Fixed local-window x positions for the GLOBAL TRIGGER RANDOM grid.  Keeping
-- these independent of label width is what makes Pitch / Volume / Pan and their
-- paired Start / Reverse controls read as a clean three-row matrix.
local GLOBAL_GRID = {
  left_min_label = 82,
  left_min_value = 116,
  left_max_label = 215,
  left_max_value = 252,
  right_name     = 376,
  right_mid_label= 466,
  right_mid_value= 505,
  right_max_label= 604,
  right_max_value= 641,
  narrow_button   = 765,
  narrow_range_label = 893,
  narrow_range_value = 946,
  iso_button = 1056,
}

local function global_drag_value_tip(label,value,fmt)
  if r.ImGui_IsItemActive and r.ImGui_IsItemActive(ctx) and r.ImGui_SetTooltip then
    r.ImGui_SetTooltip(ctx,label.."  "..string.format(fmt,value))
  end
end

local function draw_global_range(name,lo,hi,fmt,width,side)
  local g=global_trigger_random[name]
  r.ImGui_PushID(ctx,"global_random_"..name)

  if side=="right" then
    r.ImGui_SameLine(ctx,GLOBAL_GRID.right_name)
  end
  global_toggle_checkbox(name,g)

  local min_label_x = side=="right" and GLOBAL_GRID.right_mid_label or GLOBAL_GRID.left_min_label
  local min_value_x = side=="right" and GLOBAL_GRID.right_mid_value or GLOBAL_GRID.left_min_value
  local max_label_x = side=="right" and GLOBAL_GRID.right_max_label or GLOBAL_GRID.left_max_label
  local max_value_x = side=="right" and GLOBAL_GRID.right_max_value or GLOBAL_GRID.left_max_value

  r.ImGui_SameLine(ctx,min_label_x); r.ImGui_Text(ctx,"Min")
  r.ImGui_SameLine(ctx,min_value_x); r.ImGui_SetNextItemWidth(ctx,width)
  local changed,v=r.ImGui_SliderDouble(ctx,"##min",g.min,lo,hi,fmt)
  global_drag_value_tip(name.." Min",v,fmt)
  if changed then g.min=math.min(v,g.max); mark_state_dirty() end

  r.ImGui_SameLine(ctx,max_label_x); r.ImGui_Text(ctx,"Max")
  r.ImGui_SameLine(ctx,max_value_x); r.ImGui_SetNextItemWidth(ctx,width)
  changed,v=r.ImGui_SliderDouble(ctx,"##max",g.max,lo,hi,fmt)
  global_drag_value_tip(name.." Max",v,fmt)
  if changed then g.max=math.max(v,g.min); mark_state_dirty() end
  r.ImGui_PopID(ctx)
end

local function draw_global_reverse(width)
  local g=global_trigger_random.Reverse
  r.ImGui_PushID(ctx,"global_random_Reverse")
  r.ImGui_SameLine(ctx,GLOBAL_GRID.right_name)
  global_toggle_checkbox("Reverse",g)
  r.ImGui_SameLine(ctx,GLOBAL_GRID.right_mid_label); r.ImGui_Text(ctx,"Odds")
  r.ImGui_SameLine(ctx,GLOBAL_GRID.right_mid_value); r.ImGui_SetNextItemWidth(ctx,width)
  local changed,v=r.ImGui_SliderDouble(ctx,"##chance",g.chance*100,0,100,"%.0f%%")
  global_drag_value_tip("Reverse Odds",v,"%.0f%%")
  if changed then g.chance=clamp(v/100,0,1); mark_state_dirty() end
  r.ImGui_PopID(ctx)
end

local function draw_global_fx(width)
  local g=global_trigger_random.FX
  r.ImGui_PushID(ctx,"global_random_FX")
  r.ImGui_SameLine(ctx,GLOBAL_GRID.right_name)
  local any=slayer_fx.any_in_use()
  local disabled=false
  if not any and r.ImGui_BeginDisabled then
    r.ImGui_BeginDisabled(ctx,true)
    disabled=true
  end
  global_toggle_checkbox("FX",g)
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,any
      and "When enabled, each TRIGGER independently turns each source's printed FX take on or off.\nOdds is the chance that lane listens to the FX take.\nSources with no FX take are left alone."
      or "Print FX on a source first (per-lane FX or ASSIGN + FX).\nThis randomizer only applies to tracks that already have an FX take.")
  end
  r.ImGui_SameLine(ctx,GLOBAL_GRID.right_mid_label); r.ImGui_Text(ctx,"Odds")
  r.ImGui_SameLine(ctx,GLOBAL_GRID.right_mid_value); r.ImGui_SetNextItemWidth(ctx,width)
  local changed,v=r.ImGui_SliderDouble(ctx,"##chance",g.chance*100,0,100,"%.0f%%")
  global_drag_value_tip("FX Odds",v,"%.0f%%")
  if changed then g.chance=clamp(v/100,0,1); mark_state_dirty() end
  if disabled then r.ImGui_EndDisabled(ctx) end
  r.ImGui_PopID(ctx)
end

release_restore_iso_settings=function()
  if not restore_global_random_snapshot then return end
  -- RESTORE is the explicit exit from recorder-restore isolation. If Narrow is
  -- currently auditioning the captured sweet spot, stop that mode first so the
  -- reinstated broad Global Random setup becomes effective immediately.
  local nr=narrow_random[selected_scene]
  if nr then nr.active=false end
  for _,name in ipairs(GLOBAL_RANDOM_ORDER) do
    local saved=restore_global_random_snapshot[name]
    local g=global_trigger_random[name]
    if saved and g then
      g.enabled=saved.enabled and true or false
      g.min=saved.min
      g.max=saved.max
      if g.chance~=nil then g.chance=saved.chance or g.chance end
    end
  end

  -- Reinstate the saved lane RND states together with the broad Global Random
  -- setup. The snapshot is preserved while Narrow is auditioned specifically so
  -- Narrow can be toggled on/off repeatedly before RESTORE finally exits isolation.
  if restore_lane_random_snapshot then
    local scene=scenes[selected_scene]
    if scene and scene.layers then
      for li=1,NUM_LAYERS do
        if restore_lane_random_snapshot[li] ~= nil then
          scene.layers[li].random_sample=restore_lane_random_snapshot[li] and true or false
        end
      end
    end
  end

  if sidechain.restore_snapshot then
    local saved=sidechain.restore_snapshot
    sidechain.mode=clamp(saved.mode or 0,0,4)
    sidechain.rnd=saved.rnd and true or false
    sidechain.rnd_mode=saved.rnd_mode and true or false
    sidechain.amount_min=saved.amount_min
    sidechain.amount_max=saved.amount_max
    sidechain.attack_min=saved.attack_min
    sidechain.attack_max=saved.attack_max
    sidechain.release_min=saved.release_min
    sidechain.release_max=saved.release_max
    sidechain.thresh_min=saved.thresh_min
    sidechain.thresh_max=saved.thresh_max
  end

  restore_global_random_snapshot=nil
  sidechain.restore_snapshot=nil
  restore_lane_random_snapshot=nil
  mark_state_dirty()
  status="Restore lock released - Global Random and lane RND settings restored"
end

local function draw_narrow_controls()
  local nr=narrow_random[selected_scene]
  r.ImGui_SameLine(ctx,GLOBAL_GRID.narrow_button)
  local narrow_on=nr and nr.active
  local narrow_label=narrow_on and "NARROW CURRENT *" or "NARROW CURRENT"
  -- Green = Narrow is driving Trigger. Red = normal Global randomization is active.
  local styled=r.ImGui_PushStyleColor and r.ImGui_PopStyleColor and r.ImGui_Col_Button
  local pushed=0
  if styled then
    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(),narrow_on and 0x287A3CFF or 0x8A3030FF); pushed=pushed+1
    if r.ImGui_Col_ButtonHovered then r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonHovered(),narrow_on and 0x32964AFF or 0xA83A3AFF); pushed=pushed+1 end
    if r.ImGui_Col_ButtonActive then r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonActive(),narrow_on and 0x1F6330FF or 0x742727FF); pushed=pushed+1 end
  end
  local pressed=r.ImGui_Button(ctx,narrow_label)
  if pushed>0 then r.ImGui_PopStyleColor(ctx,pushed) end
  if pressed then toggle_narrow_random_from_current() end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    local m=math.max(NARROW_MULTIPLIER_MIN,(nr and nr.multiplier) or 2.0)
    r.ImGui_SetTooltip(ctx,string.format(
      "Capture every lane's CURRENT Pitch / Volume / Pan / Start as a sweet spot.\n"..
      "Range x %.2f gives approximately:\n  Pitch +/-%.2f st   Volume +/-%.2f dB\n  Pan +/-%.3f   Start +/-%.4f\n"..
      "Reverse, FX, Loop, Mute and Solo stay unchanged.\n"..
      "The slider drag range is 0-4x; Ctrl+click/type a larger value if needed.\n\n"..
      "Click again to turn Narrow off. During recorder-restore isolation,\nthis returns to the exact restored state (lane RND + Global Random OFF).\nUse RESTORE to exit isolation and reinstate the previous random settings.",
      m,NARROW_RANDOM_SPREAD.Pitch*m,NARROW_RANDOM_SPREAD.Volume*m,
      NARROW_RANDOM_SPREAD.Pan*m,NARROW_RANDOM_SPREAD.Start*m))
  end

  r.ImGui_SameLine(ctx,GLOBAL_GRID.narrow_range_label); r.ImGui_Text(ctx,"Range x")
  r.ImGui_SameLine(ctx,GLOBAL_GRID.narrow_range_value); r.ImGui_SetNextItemWidth(ctx,96)
  local changed,v=r.ImGui_SliderDouble(ctx,"##narrow_multiplier",
    math.max(NARROW_MULTIPLIER_MIN,(nr and nr.multiplier) or 2.0),
    NARROW_MULTIPLIER_MIN,NARROW_MULTIPLIER_MAX,"%.2fx")
  global_drag_value_tip("Narrow Range",v,"%.2fx")
  if changed then nr.multiplier=math.max(NARROW_MULTIPLIER_MIN,v); mark_state_dirty() end

  -- Only visible while a recorder-restored shot is isolated. The restore action
  -- deliberately disables relevant global randomizers so the exact shot can be
  -- auditioned; this button exits that temporary lock and reinstates the entire
  -- previous Global Trigger Random configuration.
  if restore_global_random_snapshot then
    r.ImGui_SameLine(ctx,GLOBAL_GRID.iso_button)

    -- Flash RESTORE while the recorder-restored rack is isolated. The pulse is
    -- intentionally UI-only: it does not touch project state or create undo data.
    local flash_on=(math.floor(r.time_precise()*2.5)%2)==0
    local restore_pushed=0
    if r.ImGui_PushStyleColor then
      if r.ImGui_Col_Button then
        r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(),flash_on and 0xD96B18FF or 0x7A3210FF); restore_pushed=restore_pushed+1
      end
      if r.ImGui_Col_ButtonHovered then
        r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonHovered(),flash_on and 0xF58A2AFF or 0xA44715FF); restore_pushed=restore_pushed+1
      end
      if r.ImGui_Col_ButtonActive then
        r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonActive(),flash_on and 0xFF9B38FF or 0xC25718FF); restore_pushed=restore_pushed+1
      end
    end
    local restore_pressed=r.ImGui_Button(ctx,"RESTORE")
    if restore_pushed>0 then r.ImGui_PopStyleColor(ctx,restore_pushed) end
    if restore_pressed then release_restore_iso_settings() end
    if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
      r.ImGui_SetTooltip(ctx,"Restored shot is temporarily isolated.\nClick RESTORE to exit isolation and reinstate the previous Pitch / Volume / Pan / Start / Reverse / FX / SIDECHAIN Global Random setup and lane RND states.\nNARROW CURRENT can temporarily resume lane RND + narrow variation; turning Narrow OFF returns to this isolated state.")
    end
  end
end

function sidechain.draw_minmax(id, label, vmin, vmax, lo, hi, fmt, width)
  r.ImGui_PushID(ctx,id)
  r.ImGui_Text(ctx,label)
  r.ImGui_SameLine(ctx)
  r.ImGui_Text(ctx,"Min")
  r.ImGui_SameLine(ctx)
  r.ImGui_SetNextItemWidth(ctx,width)
  local changed,v=r.ImGui_SliderDouble(ctx,"##min",vmin,lo,hi,fmt)
  global_drag_value_tip(label.." Min",v,fmt)
  if changed then vmin=math.min(v,vmax) end
  r.ImGui_SameLine(ctx)
  r.ImGui_Text(ctx,"Max")
  r.ImGui_SameLine(ctx)
  r.ImGui_SetNextItemWidth(ctx,width)
  changed,v=r.ImGui_SliderDouble(ctx,"##max",vmax,lo,hi,fmt)
  global_drag_value_tip(label.." Max",v,fmt)
  if changed then vmax=math.max(v,vmin) end
  r.ImGui_PopID(ctx)
  return vmin,vmax
end

function sidechain.draw()
  r.ImGui_Spacing(ctx)
  r.ImGui_Text(ctx,"SIDECHAIN")
  r.ImGui_SameLine(ctx)
  r.ImGui_TextDisabled(ctx,"Rides the key lane's audio against Threshold. Mode Off writes no duck.")

  r.ImGui_PushID(ctx,"sidechain")
  r.ImGui_Text(ctx,"Mode")
  r.ImGui_SameLine(ctx)
  r.ImGui_SetNextItemWidth(ctx,140)
  local mode_label=sidechain.MODE_LABELS[sidechain.mode+1] or "Off"
  if r.ImGui_BeginCombo(ctx,"##sc_mode",mode_label) then
    for i=0,4 do
      local selected=sidechain.mode==i
      if r.ImGui_Selectable(ctx,sidechain.MODE_LABELS[i+1],selected) then
        sidechain.mode=i
        mark_state_dirty()
      end
      if selected and r.ImGui_SetItemDefaultFocus then r.ImGui_SetItemDefaultFocus(ctx) end
    end
    r.ImGui_EndCombo(ctx)
  end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"Off: no ducking.\n1-8→9-16: L1-L8 audio ducks L9-L16 when above Threshold.\n9-16→1-8: L9-L16 audio ducks L1-L8.\nPair: each lane ducks its mate (L1↔L9 … L8↔L16).\nShuffle: same as Pair, but every TRIGGER re-rolls all 8 mates (any lane ↔ any other).\nAmount is max depth; the duck rides the key level, not a one-shot.")
  end

  r.ImGui_SameLine(ctx)
  local rnd_changed,rnd_on=r.ImGui_Checkbox(ctx,"RND",sidechain.rnd)
  if rnd_changed then sidechain.rnd=rnd_on and true or false; mark_state_dirty() end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"On: roll Amount / Threshold / Attack / Release in their min-max ranges on each TRIGGER.\nOff: use each Min as the fixed value. Ignored when Mode is Off.")
  end

  r.ImGui_SameLine(ctx)
  local rm_changed,rm_on=r.ImGui_Checkbox(ctx,"RND MODE",sidechain.rnd_mode)
  if rm_changed then sidechain.rnd_mode=rm_on and true or false; mark_state_dirty() end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"On: pick Bank, Invert, Pair, or Shuffle on each TRIGGER. Never picks Off.\nIgnored when Mode is Off.")
  end

  local w=80
  local amin,amax=sidechain.draw_minmax("sc_amount","Amount",
    sidechain.amount_min,sidechain.amount_max,0,1,"%.2f",w)
  if amin~=sidechain.amount_min or amax~=sidechain.amount_max then
    sidechain.amount_min,sidechain.amount_max=amin,amax
    mark_state_dirty()
  end
  r.ImGui_SameLine(ctx,300)
  local tmin,tmax=sidechain.draw_minmax("sc_thresh","Threshold",
    sidechain.thresh_min,sidechain.thresh_max,0,1,"%.2f",w)
  if tmin~=sidechain.thresh_min or tmax~=sidechain.thresh_max then
    sidechain.thresh_min,sidechain.thresh_max=tmin,tmax
    mark_state_dirty()
  end
  r.ImGui_SameLine(ctx,640)
  local atmin,atmax=sidechain.draw_minmax("sc_attack","Attack",
    sidechain.attack_min,sidechain.attack_max,0,50,"%.1f ms",w)
  if atmin~=sidechain.attack_min or atmax~=sidechain.attack_max then
    sidechain.attack_min,sidechain.attack_max=atmin,atmax
    mark_state_dirty()
  end
  r.ImGui_SameLine(ctx,980)
  local rmin,rmax=sidechain.draw_minmax("sc_release","Release",
    sidechain.release_min,sidechain.release_max,20,800,"%.0f ms",w)
  if rmin~=sidechain.release_min or rmax~=sidechain.release_max then
    sidechain.release_min,sidechain.release_max=rmin,rmax
    mark_state_dirty()
  end
  r.ImGui_PopID(ctx)
end

local function draw_global_trigger_random()
  r.ImGui_Text(ctx,"GLOBAL TRIGGER RANDOM")
  r.ImGui_SameLine(ctx)
  r.ImGui_TextDisabled(ctx,"Enabled parameters randomize independently on every TRIGGER")

  -- Remember the screen-space origin of the control grid so the section
  -- dividers stay locked to the same fixed columns as the controls.
  local grid_x,grid_top_y=nil,nil
  if r.ImGui_GetCursorScreenPos then
    grid_x,grid_top_y=r.ImGui_GetCursorScreenPos(ctx)
  end

  -- Fixed three-row grid:
  --   Pitch  Min [ ] Max [ ]     Start   Min [ ] Max [ ]     NARROW CURRENT  Range x [ ]
  --   Volume Min [ ] Max [ ]     Reverse Odds [ ]
  --   Pan    Min [ ] Max [ ]     FX      Odds [ ]
  draw_global_range("Pitch",-24,24,"%.1f st",92,"left")
  draw_global_range("Start",0,1,"%.3f",92,"right")
  draw_narrow_controls()

  draw_global_range("Volume",-60,12,"%.1f dB",92,"left")
  draw_global_reverse(92)

  draw_global_range("Pan",-1,1,"%.2f",92,"left")
  draw_global_fx(92)

  -- Subtle vertical separators between the three logical sections.
  -- The first sits between the left range matrix and Start/Reverse; the
  -- second sits between Start/Reverse and Narrow Current.
  if grid_x and grid_top_y and r.ImGui_GetItemRectMax and
     r.ImGui_GetWindowDrawList and r.ImGui_DrawList_AddLine then
    local _,grid_bottom_y=r.ImGui_GetItemRectMax(ctx)
    if grid_bottom_y then
      local dl=r.ImGui_GetWindowDrawList(ctx)
      local y0=grid_top_y+3
      local y1=grid_bottom_y-1
      local divider_col=0x3A3D42FF
      -- Both section gaps are 32 px wide; place each divider at its midpoint.
      -- Left: 344..376 -> 360.  Right: 733..765 -> 749.
      r.ImGui_DrawList_AddLine(dl,grid_x+360,y0,grid_x+360,y1,divider_col,1.0)
      r.ImGui_DrawList_AddLine(dl,grid_x+749,y0,grid_x+749,y1,divider_col,1.0)
    end
  end

  sidechain.draw()
  update_global_toggle_drag()
end

-- How far the pointer must travel before a right-drag counts as a paint. A bare
-- right-click on a control must leave the value alone.
local PAINT_ARM_PX = 4

-- Every column a right-drag can paint and a Reset button can restore. The
-- ranges have to match the control drawn for the column below.
--   toggle  -- a checkbox: the whole drag writes one state rather than mapping x
--   all     -- the value changes what other lanes sound like, so re-apply all
--   finish  -- expensive work, deferred to the end of the gesture
local PAINT_COLUMNS = {
  RND   = {order=1, toggle=true, default=true, label="RND",
           get=function(L) return L.random_sample end, set=function(L,v) L.random_sample=v end},
  Pitch = {order=2, lo=-24, hi=24, default=0,
           set=function(L,v) L.pitch=v end},
  Start = {order=3, lo=0, hi=1, default=0,
           set=function(L,v) L.start=v end},
  Vol   = {order=4, lo=-60, hi=12, default=0, label="Vol",
           set=function(L,v) L.volume_db=v end},
  Pan   = {order=5, lo=-1, hi=1, default=0,
           set=function(L,v) L.pan=v end},
  Loop  = {order=6, toggle=true, default=false,
           get=function(L) return L.loop end, set=function(L,v) L.loop=v end},
  -- Reverse swaps the file the sampler holds, which can mean rendering the item
  -- backwards, so the reload waits until the drag is over.
  Rev   = {order=7, toggle=true, default=false,
           get=function(L) return L.reverse end, set=function(L,v) L.reverse=v end,
           finish=function(li) reload_layer_sample(li) end},
  M     = {order=8, toggle=true, default=false, all=true, label="Mute",
           get=function(L) return L.mute end, set=function(L,v) L.mute=v end},
  S     = {order=9, toggle=true, default=false, all=true, label="Solo",
           get=function(L) return L.solo end, set=function(L,v) L.solo=v end},
}
local PAINT_ORDER = {}
for name in pairs(PAINT_COLUMNS) do PAINT_ORDER[#PAINT_ORDER+1]=name end
table.sort(PAINT_ORDER,function(a,b) return PAINT_COLUMNS[a].order<PAINT_COLUMNS[b].order end)

local function reset_column(name)
  local col=PAINT_COLUMNS[name]
  local scene=scenes[selected_scene]
  if col.finish then reverse_note="" end
  for li=1,NUM_LAYERS do
    col.set(scene.layers[li],col.default)
    if col.finish then col.finish(li) end
  end
  mark_all_dirty(); mark_state_dirty()
  return col.label or name
end

local function paint_note_rect(name, li)
  if not (r.ImGui_GetItemRectMin and r.ImGui_GetItemRectMax) then return end
  local x0,y0=r.ImGui_GetItemRectMin(ctx)
  local x1,y1=r.ImGui_GetItemRectMax(ctx)
  local col=paint_rects[name]
  if not col then col={}; paint_rects[name]=col end
  local rc=col[li]
  if rc then rc.x0,rc.y0,rc.x1,rc.y1=x0,y0,x1,y1 else col[li]={x0=x0,y0=y0,x1=x1,y1=y1} end
end

local function paint_apply(li, x)
  local col=PAINT_COLUMNS[paint.column]
  local L=scenes[selected_scene].layers[li]
  if col.toggle then
    -- A checkbox has nothing to read off the x axis. The drag carries one
    -- state, the opposite of what the box it started on held, so a drag turns
    -- a run of lanes on or off the way it looks like it should.
    col.set(L,paint.target)
  else
    -- One x-to-value scale for the whole gesture, taken from the row it started
    -- on. A per-row scale would make one straight line mean different values on
    -- rows that are not the same width.
    local f=clamp((x-paint.x0)/math.max(paint.x1-paint.x0,1),0,1)
    col.set(L, col.lo+f*(col.hi-col.lo))
  end
  if not paint.painted[li] then paint.count=paint.count+1 end
  paint.painted[li]=true
  if col.all then mark_all_dirty() else mark_layer_dirty(li) end
end

local function paint_begin(name, li)
  if paint then return end
  if not (r.ImGui_IsItemClicked and r.ImGui_IsItemClicked(ctx,1)) then return end
  local rc=paint_rects[name] and paint_rects[name][li]
  if not rc then return end
  local col=PAINT_COLUMNS[name]
  local mx,my=r.ImGui_GetMousePos(ctx)
  paint={column=name,anchor=li,x0=rc.x0,x1=rc.x1,
         ax=mx,ay=my,px=mx,py=my,painted={},count=0,armed=false,
         target=col.toggle and (not col.get(scenes[selected_scene].layers[li])) or nil}
end

local function paint_update()
  if not paint then return end
  local mx,my=r.ImGui_GetMousePos(ctx)
  local changed=false

  if not paint.armed and math.abs(mx-paint.ax)+math.abs(my-paint.ay)>PAINT_ARM_PX then
    paint.armed=true
    -- Rewind to where the button went down so the sweep below covers the whole
    -- gesture, then give the starting lane the value it was pressed at.
    paint.px,paint.py=paint.ax,paint.ay
    paint_apply(paint.anchor,paint.ax)
    changed=true
  end

  if paint.armed then
    local rects=paint_rects[paint.column] or {}
    if my~=paint.py then
      -- Sweep the segment travelled since the previous frame instead of asking
      -- which row the pointer is in now. The UI runs at defer rate, so a quick
      -- flick crosses a whole lane between two frames and a point test would
      -- simply miss it. A lane is claimed where the line crosses its middle,
      -- which is also what makes a line that stops halfway into a lane leave
      -- that lane alone.
      for li=1,NUM_LAYERS do
        local rc=rects[li]
        if rc and not paint.painted[li] then
          local mid=(rc.y0+rc.y1)*0.5
          if (paint.py-mid)*(my-mid)<=0 then
            paint_apply(li, paint.px+(mx-paint.px)*((mid-paint.py)/(my-paint.py)))
            changed=true
          end
        end
      end
    end
    if r.ImGui_GetWindowDrawList and r.ImGui_DrawList_AddLine then
      r.ImGui_DrawList_AddLine(r.ImGui_GetWindowDrawList(ctx),
        paint.ax,paint.ay,mx,my,0x7FE08CFF,2.0)
    end
    if r.ImGui_SetTooltip then
      local col=PAINT_COLUMNS[paint.column]
      local what=col.label or paint.column
      if col.toggle then what=what..(paint.target and " on" or " off") end
      r.ImGui_SetTooltip(ctx,string.format("Painting %s  %d lane%s",
        what,paint.count,paint.count==1 and "" or "s"))
    end
  end

  paint.px,paint.py=mx,my
  if changed then mark_state_dirty() end
  if not (r.ImGui_IsMouseDown and r.ImGui_IsMouseDown(ctx,1)) then
    local col=PAINT_COLUMNS[paint.column]
    if paint.count>0 then
      -- Anything too slow to do mid-drag happens here, once per painted lane.
      if col.finish then
        reverse_note=""
        for li=1,NUM_LAYERS do if paint.painted[li] then col.finish(li) end end
      end
      status=string.format("Painted %s across %d lane%s",
        col.label or paint.column,paint.count,paint.count==1 and "" or "s")
      mark_state_dirty()
    end
    paint=nil
  end
end

local function draw_adfx_logo()
  if not r.ImGui_Image then return end
  if not adfx_logo then adfx_logo=create_adfx_logo() end
  if not adfx_logo then return end

  -- Original artwork is 1357x204 (~6.65:1). 300x45 preserves that ratio and
  -- keeps the branding subordinate to the transport controls.
  local ok = pcall(r.ImGui_Image,ctx,adfx_logo,300,45)
  if not ok then
    -- If ReaImGui invalidated the resource across a collapse/restore transition,
    -- rebuild it instead of allowing the UI frame to terminate with an assertion.
    adfx_logo=create_adfx_logo()
    if adfx_logo then pcall(r.ImGui_Image,ctx,adfx_logo,300,45) end
  end
end

local function draw_main()
  local scene=scenes[selected_scene]
  if r.ImGui_Button(ctx,"TRIGGER",120,34) then trigger(115) end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx,"LAST TRIGGER [T]",140,34) then trigger_last(115) end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"Replay the exact previous shot, or the rack most recently restored from the Recorder. Bypasses GLOBAL TRIGGER RANDOM, SIDECHAIN rolls, and every lane's RND item selection so the same sound can be diagnosed repeatedly. Shortcut: T")
  end
  r.ImGui_SameLine(ctx)
  local lf_changed,lf_on=r.ImGui_Checkbox(ctx,"REC LAST",last_trigger_follow)
  if lf_changed then
    last_trigger_follow=lf_on and true or false
    mark_state_dirty()
    status=last_trigger_follow
      and "REC LAST on — LAST TRIGGER will follow Auto / Signal Session"
      or "REC LAST off — LAST TRIGGER will not be recorded"
  end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"On: LAST TRIGGER / T follows Auto and Signal Session the same way TRIGGER does\nOff: LAST TRIGGER is diagnostic only. An open Signal Session is paused, and an open Auto take is closed, so the replay is not recorded.")
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx,"STOP ALL",92,34) then stop_all_voices(true, true) end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"Immediately stops every currently sounding S-Layer voice, cancels any trigger waiting to fire, and aborts ASSIGN / ASSIGN + FX if either is still importing")
  end
  r.ImGui_SameLine(ctx)
  local chk,chv=r.ImGui_Checkbox(ctx,"CHOKE",choke)
  if chk then choke=chv; mark_all_dirty(); mark_state_dirty() end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"On: every new TRIGGER stops ALL previous S-Layer voices before the new set plays\nOff: shots overlap and ring out over each other")
  end
  r.ImGui_SameLine(ctx)
  local nsel=#selected_source_tracks()
  local job=slayer_fx.job
  local assign_label=job and not job.apply_fx
    and "ASSIGNING…##assign"
    or string.format("ASSIGN SELECTED (%d)##assign",nsel)
  if r.ImGui_Button(ctx,assign_label) then
    if not job then assign_selected_tracks() end
  end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"Fills the free lanes from the top with the tracks selected in REAPER,\nin the order they appear in the project.\n\nSelect the tracks, press this once, and skip the per-lane menus.\nSTOP ALL cancels the import if it is still running.")
  end
  r.ImGui_SameLine(ctx)
  local fx_label
  if job and job.apply_fx then
    fx_label=string.format("ASSIGN + FX %d/%d##assignfx",
      math.min(math.max(0,job.idx-1),#job.tracks),#job.tracks)
  else
    fx_label=string.format("ASSIGN + FX (%d)##assignfx",nsel)
  end
  if r.ImGui_Button(ctx,fx_label) then
    if not job then assign_selected_tracks({apply_fx=true}) end
  end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"Same as ASSIGN SELECTED, but first prints each track's enabled FX\nchain onto its audio items.\n\nEach item keeps the original take plus one FX take. Using this again\nreplaces that FX take only on tracks whose FX settings changed, and\nstill reprints those tracks if they are already assigned.\n\nTracks with no enabled FX, or no audio items, skip the print and\nassign with the original files.\n\nPrints one track at a time so STOP ALL can abort the pipeline.")
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx,"CLEAR LANES##clear") then clear_lane_sources() end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"Stops all S-Layer voices, then unassigns the source track on all "..NUM_LAYERS.." lanes.\nEverything else about the lane is left alone")
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx,"TAKE 1##take1",70,34) then
    slayer_fx.run_helper("ADFX_Helper; set selected items to take 1.lua",
      "Set selected items to Take 1")
  end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"Set Take 1 active on every selected item and crop away the other takes")
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx,"+2 SEC##add2s",70,34) then
    slayer_fx.run_helper("ADFX_Helper; add 2 seconds to selected items.lua",
      "Added 2 seconds to selected items")
  end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"Add 2 seconds to the end of every selected item and push following items on the same track so they do not overlap")
  end

  -- Branding shares the transport row but is separated enough that it never
  -- reads as another control. The transparent PNG keeps the dark UI visible.
  if adfx_logo then
    r.ImGui_SameLine(ctx,0,24)
    draw_adfx_logo()
  end

  -- Compact second row: scene selection and scene-management actions.
  r.ImGui_Text(ctx,"SCENES"); r.ImGui_SameLine(ctx)
  for i=1,NUM_SCENES do
    if i>1 then r.ImGui_SameLine(ctx) end
    if r.ImGui_Button(ctx,tostring(i)..(selected_scene==i and " *" or ""),35,0) then
      save_state(); selected_scene=i; sync_sources()
    end
  end
  r.ImGui_SameLine(ctx); if r.ImGui_Button(ctx,"Copy Scene") then
    local dst=(selected_scene%NUM_SCENES)+1
    scenes[dst]=copy_table(scenes[selected_scene])
    narrow_random[dst]=copy_table(narrow_random[selected_scene])
    status="Copied Scene "..selected_scene.." to "..dst
    save_state()
  end
  r.ImGui_SameLine(ctx); if r.ImGui_Button(ctx,"CLEAR ALL SCENES") then clear_all_scenes() end
  if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetTooltip(ctx,"Resets all "..NUM_SCENES.." scenes to empty lanes. Global random settings and CHOKE are left unchanged.")
  end
  r.ImGui_Separator(ctx)
  draw_global_trigger_random()
  r.ImGui_Separator(ctx)
  -- One click puts a column back to the value a fresh layer has, which is the
  -- way out of a randomized or painted set that went nowhere.
  r.ImGui_Text(ctx,"RESET")
  for _,name in ipairs(PAINT_ORDER) do
    local col=PAINT_COLUMNS[name]
    r.ImGui_SameLine(ctx)
    if r.ImGui_SmallButton(ctx,(col.label or name).."##reset") then
      status="Reset "..reset_column(name).." on all "..NUM_LAYERS.." layers"
    end
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_SmallButton(ctx,"All##reset") then
    for _,name in ipairs(PAINT_ORDER) do reset_column(name) end
    status="Reset every layer control to its default"
  end
  r.ImGui_Separator(ctx)
  -- One header row for the toggle cluster. ImGui checkboxes are box-then-label,
  -- so "Loop" used to sit between two boxes. Names live here; lanes draw boxes
  -- only. Positions come from the previous frame's lane row.
  if PAINT_COLUMNS.Loop.hx and r.ImGui_SetCursorPosX then
    local header=r.ImGui_TextDisabled or r.ImGui_Text
    r.ImGui_SetCursorPosX(ctx,PAINT_COLUMNS.Loop.hx)
    header(ctx,"Loop")
    if PAINT_COLUMNS.Rev.hx then
      r.ImGui_SameLine(ctx); r.ImGui_SetCursorPosX(ctx,PAINT_COLUMNS.Rev.hx); header(ctx,"Rev")
    end
    if PAINT_COLUMNS.M.hx then
      r.ImGui_SameLine(ctx); r.ImGui_SetCursorPosX(ctx,PAINT_COLUMNS.M.hx); header(ctx,"Mute")
    end
    if PAINT_COLUMNS.S.hx then
      r.ImGui_SameLine(ctx); r.ImGui_SetCursorPosX(ctx,PAINT_COLUMNS.S.hx); header(ctx,"Solo")
    end
  end
  for i=1,NUM_LAYERS do
    local L=scene.layers[i]; r.ImGui_PushID(ctx,"layer"..i)
    -- Fixed lane-label column: keep every assignment/control column identical
    -- for L1-L9 and L10-L16 instead of letting the text width shift the row.
    r.ImGui_Text(ctx,"L"..i)
    r.ImGui_SameLine(ctx,30)
    source_combo(i)
    r.ImGui_SameLine(ctx); if r.ImGui_SmallButton(ctx,"USE SELECTED") then local tr=r.GetSelectedTrack(0,0); if tr then assign_source_track(i,tr) else status="Select a REAPER source track first" end end
    r.ImGui_SameLine(ctx)
    do
      local src=source_track_for_layer(L)
      local wet=src and slayer_fx.is_wet(src)
      local tinted=false
      if wet and r.ImGui_PushStyleColor then
        local col=r.ImGui_Col_Button
        if type(col)=="function" then col=col() end
        if type(col)=="number" then
          tinted=pcall(r.ImGui_PushStyleColor,ctx,col,0x2E8B57FF)
        end
      end
      if r.ImGui_SmallButton(ctx,"FX") then slayer_fx.toggle_lane(i) end
      if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
        r.ImGui_SetTooltip(ctx,"Toggle this lane's source between the printed FX take and the original.\nFirst click prints the track FX if there is no FX take yet.\nGreen = listening to the FX take.\nASSIGN + FX reprints only tracks whose FX settings changed.")
      end
      if tinted then r.ImGui_PopStyleColor(ctx,1) end
    end
    r.ImGui_SameLine(ctx); draw_lane_waveform(i,L)
    r.ImGui_SameLine(ctx)
    do
      local items_x=r.ImGui_GetCursorPosX and r.ImGui_GetCursorPosX(ctx)
      r.ImGui_Text(ctx,string.format("%3d items",L.pool_count or 0))
      if items_x then r.ImGui_SameLine(ctx,items_x+ITEMS_COL_W)
      else r.ImGui_SameLine(ctx) end
    end
    local ch,v=r.ImGui_Checkbox(ctx,"RND",L.random_sample)
    paint_note_rect("RND",i); paint_begin("RND",i)
    if ch then L.random_sample=v; mark_state_dirty() end
    -- Always reserve the Item slider so Loop/Rev/Mute/Solo stay on a grid.
    r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx,95)
    local item_max=math.max(L.pool_count or 0,1)
    ch,v=r.ImGui_SliderInt(ctx,"Item",L.sample_index,1,item_max)
    if ch and not L.random_sample and (L.pool_count or 0)>0 then
      L.sample_index=v; local pool=refresh_layer_pool(i); load_pool_item(i,pool[v]); mark_state_dirty()
    end
    -- Each painted column notes its rect and offers itself to a right-drag
    -- immediately after being drawn, while the item is still the current one.
    r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx,95); ch,v=r.ImGui_SliderDouble(ctx,"Pitch",L.pitch,-24,24,"%.1f st")
    paint_note_rect("Pitch",i); paint_begin("Pitch",i)
    if ch then L.pitch=v; mark_layer_dirty(i); mark_state_dirty() end
    r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx,80); ch,v=r.ImGui_SliderDouble(ctx,"Start",L.start,0,1,"%.3f")
    paint_note_rect("Start",i); paint_begin("Start",i)
    if ch then L.start=v; mark_layer_dirty(i); mark_state_dirty() end
    r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx,90); ch,v=r.ImGui_SliderDouble(ctx,"Vol",L.volume_db,-60,12,"%.1f dB")
    paint_note_rect("Vol",i); paint_begin("Vol",i)
    if ch then L.volume_db=v; mark_layer_dirty(i); mark_state_dirty() end
    r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx,80); ch,v=r.ImGui_SliderDouble(ctx,"Pan",L.pan,-1,1,"%.2f")
    paint_note_rect("Pan",i); paint_begin("Pan",i)
    if ch then L.pan=v; mark_layer_dirty(i); mark_state_dirty() end
    r.ImGui_SameLine(ctx)
    if r.ImGui_TextDisabled then r.ImGui_TextDisabled(ctx,"|") else r.ImGui_Text(ctx,"|") end
    -- Unlabeled boxes under the header. Fixed column width keeps every lane
    -- on the same grid even though "Mute" is wider than a checkbox.
    local toggle_w=46
    local function lane_toggle(col_id,value,last)
      r.ImGui_SameLine(ctx)
      local start_x=r.ImGui_GetCursorPosX and r.ImGui_GetCursorPosX(ctx)
      if start_x then PAINT_COLUMNS[col_id].hx=start_x end
      local changed,on=r.ImGui_Checkbox(ctx,"##"..col_id,value)
      paint_note_rect(col_id,i); paint_begin(col_id,i)
      if start_x and not last then r.ImGui_SameLine(ctx,start_x+toggle_w) end
      return changed,on
    end
    ch,v=lane_toggle("Loop",L.loop)
    if ch then L.loop=v; mark_layer_dirty(i); mark_state_dirty() end
    ch,v=lane_toggle("Rev",L.reverse)
    if ch then L.reverse=v; reverse_note=""; reload_layer_sample(i); mark_layer_dirty(i); mark_state_dirty() end
    if r.ImGui_SetTooltip and r.ImGui_IsItemHovered and r.ImGui_IsItemHovered(ctx) then
      r.ImGui_SetTooltip(ctx,"Reverse playback\nThe item's audio is rendered backwards into the project's\n"..REVERSE_DIR_NAME.." folder the first time, then reused")
    end
    ch,v=lane_toggle("M",L.mute)
    if ch then L.mute=v; mark_all_dirty(); mark_state_dirty() end
    ch,v=lane_toggle("S",L.solo,true)
    if ch then L.solo=v; mark_all_dirty(); mark_state_dirty() end
    r.ImGui_PopID(ctx)
  end
  -- Runs after the rows so the gesture works from this frame's rects.
  paint_update()
  -- The tip sits under the rows it describes, where the eye already is after
  -- reading a lane, rather than up in the transport row.
  local hint="Right-drag any lane control down the column to paint every lane the line crosses"
  if r.ImGui_TextDisabled then r.ImGui_TextDisabled(ctx,hint) else r.ImGui_Text(ctx,hint) end
end

local function draw_header()
  -- Persistent header is intentionally status-only. Engine repair remains under
  -- File > Repair Engine, and pool synchronization is automatic.
  r.ImGui_Text(ctx,status)
  if reverse_note~="" then r.ImGui_SameLine(ctx); r.ImGui_Text(ctx,"| "..reverse_note) end
  r.ImGui_Separator(ctx)
end

-- Shared ADFX output recorder, slotted in as a footer strip. The module lives
-- under Scripts/ADFX/Modules so the Sound Design Pad loads the same copy.
local RECORDER_STRIP_H = 64
do
  local function no_recorder()
    return {
      reserved_height = function() return 0 end,
      draw = function() end,
      shutdown = function() end,
      consume_space = function() return false end,
      signal_trigger = function() end,
      skip_follow = function() end,
      tick = function() end,
      auto_enabled = function() return false end,
      signal_enabled = function() return false end,
      capture_status = function() return 'unavailable' end,
    }
  end

  if RECORDER_MODULE_MISSING then
    recorder = no_recorder()
    status = "Recorder not installed - install ADFX_Recorder.lua in Scripts/ADFX/Modules"
  else
    local ok, Recorder = pcall(dofile, RECORDER_MODULE_PATH)
    if not ok or type(Recorder) ~= "table" or type(Recorder.new) ~= "function" then
      recorder = no_recorder()
      status = "ADFX_Recorder.lua could not load - reinstall or update the recorder module"
    else
      local built_ok, built = pcall(Recorder.new, {
        id          = "adfx_s_layer",
        name_prefix = "ADFX_S-Layer",
        label       = "RECORDER",
        height      = RECORDER_STRIP_H,
        capture     = "track",
        get_source_track = find_root_track,
        backend     = "buffer",
        host_gmem   = GMEM_NAME,
        allow_auto_record = true,
        auto_record = false,
        signal_record = true,
        transport   = "isolated",
        menu_items  = {
          {
            label  = "Restore S-Layer settings from here",
            action = function(at) return restore_from_take_position(at) end,
          },
        },
      })
      if built_ok and type(built) == "table" then
        recorder = built
      else
        recorder = no_recorder()
        status = "ADFX Recorder could not initialize - reinstall or update ADFX_Recorder.lua"
      end
    end
  end
end


local recorder_capture_last=nil
local function update_recorder_capture_status()
  if not recorder or type(recorder.capture_status)~="function" then return end
  local ok,st=pcall(recorder.capture_status,recorder)
  if not ok or not st or st==recorder_capture_last then return end
  local old=recorder_capture_last
  recorder_capture_last=st
  if st=="lost" then status="Recorder Lost - attempting recovery"
  elseif st=="ready" and old=="lost" then status="Recorder Recovered"
  elseif st=="ready" and old~=nil then status="Recorder Ready"
  elseif st=="transport" then status="Recorder capture unavailable - transport fallback active" end
end

local function loop()
  if not open then save_state(); recorder:shutdown(); return end
  -- Tall enough for sixteen lanes plus the recorder. The rows scroll in their
  -- own child, so a smaller window is still usable.
  r.ImGui_SetNextWindowSize(ctx,1380,880,r.ImGui_Cond_FirstUseEver())
  local visible; visible,open=r.ImGui_Begin(ctx,TITLE,open,r.ImGui_WindowFlags_MenuBar())
  if visible then
    if r.ImGui_BeginMenuBar(ctx) then
      if r.ImGui_BeginMenu(ctx,"File") then
        if r.ImGui_MenuItem(ctx,"Save state") then save_state(); status="State saved in project" end
        if r.ImGui_MenuItem(ctx,"Repair Engine") then
          if install_bridge_if_missing() then
            sidechain.install_if_missing()
            rebuild_tracks()
            sync_sources()
          end
        end
        r.ImGui_EndMenu(ctx)
      end
      if r.ImGui_BeginMenu(ctx,"Help") then
        r.ImGui_Text(ctx,"v"..VERSION.." | track-pool / visible per-layer FX workflow")
        r.ImGui_Text(ctx,"Each layer references a REAPER source track; its audio items form the sample pool.")
        r.ImGui_Text(ctx,"Select tracks in REAPER and press ASSIGN SELECTED to fill the free lanes in track order.")
        r.ImGui_Text(ctx,"ASSIGN + FX prints each track's enabled FX chain onto its items first, then assigns.")
        r.ImGui_Text(ctx,"ASSIGN + FX reprints only tracks whose FX settings changed, including already-assigned tracks.")
        r.ImGui_Text(ctx,"TAKE 1 and +2 SEC run the matching ADFX item helpers on the current arrange selection.")
        r.ImGui_Text(ctx,"STOP ALL also cancels ASSIGN / ASSIGN + FX while either is still importing.")
        r.ImGui_Text(ctx,"Each item keeps the original take plus one FX take; a later print replaces that FX take.")
        r.ImGui_Text(ctx,"The per-lane FX button toggles that source between the original take and the printed FX take.")
        r.ImGui_Text(ctx,"GLOBAL TRIGGER RANDOM FX independently turns each printed FX take on or off per TRIGGER.")
        r.ImGui_Text(ctx,"That FX randomizer is disabled until at least one assigned source has an FX take.")
        r.ImGui_Text(ctx,"Tracks with no enabled FX skip the print and assign with the original files.")
        r.ImGui_Text(ctx,"Each ADFX S-Layer playback track owns FX 1-3 (bridge, RS5K, duck); place your plugins after the duck.")
        r.ImGui_Text(ctx,"Repair Engine preserves all user FX after the managed duck.")
        r.ImGui_Text(ctx,"SIDECHAIN rides the key lane's audio against Threshold (Bank / Invert / Pair / Shuffle). Amount is max depth.")
        r.ImGui_Text(ctx,"The JSFX bridge remains only for realtime trigger delivery.")
        r.ImGui_Text(ctx,"Every layer control is on its row.")
        r.ImGui_Text(ctx,"Loop / Rev / Mute / Solo are the four boxes under those headers at the right of each lane.")
        r.ImGui_Text(ctx,"Right-drag a control down its column to paint every lane the line crosses.")
        r.ImGui_Text(ctx,"On a checkbox the whole drag writes one state, the opposite of the box it started on.")
        r.ImGui_Text(ctx,"RESET puts one column, or every column, back to a fresh layer's values.")
        r.ImGui_Text(ctx,"Space auditions unless the recorder timeline owns a selection; then Space plays/stops that recorder selection.")
        r.ImGui_Text(ctx,"T replays the exact last trigger with all randomization bypassed; current Mute/Solo still apply.")
        r.ImGui_Text(ctx,"REC LAST (on by default) lets LAST TRIGGER follow Auto and Signal Session; uncheck it for a silent diagnostic replay.")
        r.ImGui_Text(ctx,"Double-click the recording to play from there; then Space stops it.")
        r.ImGui_Text(ctx,"Right-click a point in the recording to restore the rack that made that sound, in a spare scene.")
        r.ImGui_Text(ctx,"Granular/stretch DSP is not included.")
        r.ImGui_EndMenu(ctx)
      end
      r.ImGui_EndMenuBar(ctx)
    end
    process_waveform_queue()
    draw_header()

    -- Draw the recorder BEFORE resolving keyboard shortcuts. Its draw pass owns
    -- the recorder timeline interaction/selection state. This is important: if
    -- the user has made a selection in the recorder timeline, consume_space()
    -- must see that selection before S-Layer decides that Space means TRIGGER.
    local footer_h = recorder:reserved_height(ctx)
    local body_child_open = r.ImGui_BeginChild(ctx,"##adfx_slayer_body",0,-footer_h,0,0)
    if body_child_open then
      draw_main()
      -- ReaImGui can report the child as unavailable on the frame the parent
      -- window is collapsed. Pair EndChild only with a child that actually
      -- opened, otherwise EndChild may assert that the current window is not a
      -- child window.
      r.ImGui_EndChild(ctx)
    end
    recorder:draw(ctx)

    -- Keyboard priority while S-Layer owns focus:
    --   1. Recorder timeline playback/selection gets Space first.
    --   2. Only when the recorder declines the key does Space audition S-Layer.
    -- REAPER gets its normal Space behavior again as soon as focus leaves this
    -- window.
    local slayer_focused=false
    if r.ImGui_IsWindowFocused then
      local flags = r.ImGui_FocusedFlags_RootAndChildWindows and r.ImGui_FocusedFlags_RootAndChildWindows() or 0
      slayer_focused = r.ImGui_IsWindowFocused(ctx, flags)
    end
    if slayer_focused and r.ImGui_IsKeyPressed and r.ImGui_Key_Space then
      if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Space(), false) then
        -- consume_space() owns both stopping an existing recorder audition and
        -- starting playback of the active recorder timeline selection. S-Layer
        -- only fires when there is no recorder action for Space to perform.
        if not recorder:consume_space() then trigger(115) end
      end
    end

    -- T remains reserved by S-Layer while this window owns focus.
    if slayer_focused and r.ImGui_IsKeyPressed and r.ImGui_Key_T then
      if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_T(), false) then
        trigger_last(115)
      end
    end
    r.ImGui_End(ctx)
  else
    -- Recorder health/finalization must continue even while the S-Layer window
    -- is collapsed. Recorder:draw() owns tick() on visible frames.
    if recorder and type(recorder.tick)=="function" then recorder:tick() end
  end
  update_recorder_capture_status()
  local pipe_ok,pipe_err=pcall(slayer_fx.tick_pipeline)
  if not pipe_ok then
    status="Assign pipeline error — recorder left running"
    if type(pipe_err)=="string" then status=status..": "..pipe_err end
  end
  dispatch_pending_trigger()
  verify_trigger_ack()
  apply_runtime(false)
  if state_dirty and r.time_precise()-last_state_change>0.40 then
    save_state(); state_dirty=false
  end
  r.defer(loop)
end

r.atexit(function()
  slayer_fx.cancel_job()
  slayer_fx.release_offlineinact()
  save_state()
  recorder:shutdown()
end)
loop()