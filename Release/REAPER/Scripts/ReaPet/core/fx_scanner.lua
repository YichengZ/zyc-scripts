-- Lightweight FX scanner for this project (inspired by Sexan's parser)
-- Provides: generate_fx_list(), filter_third_party_vst()

local r = reaper

local M = {}

local function parse_vst(name, ident)
  if not name:match("^VST") then return nil end
  local os_type = r.GetOS()
  local clean_ident = ident
  if os_type:match("Win") then
    clean_ident = ident:reverse():match("(.-)\\")
    if clean_ident then clean_ident = clean_ident:reverse():gsub(" ", "_"):gsub("-", "_") end
  else
    clean_ident = ident:reverse():match("(.-)/")
    if clean_ident then clean_ident = clean_ident:reverse():gsub(" ", "_"):gsub("-", "_") end
  end
  return {
    name = name,
    type = (name:match("^(%S+):") or "Unknown"),
    identifier = clean_ident or ident,
    path = ident,
    last_used = 0,
    use_count = 0
  }
end

local function parse_jsfx(name, ident)
  if not name:match("^JS:") then return nil end
  return { name = name, type = "JS", identifier = ident, path = ident, last_used = 0, use_count = 0 }
end

local function parse_au(name, ident)
  if not name:match("^AU") then return nil end
  return { name = name, type = (name:match("^(%S+):") or "AU"), identifier = ident, path = ident, last_used = 0, use_count = 0 }
end

local function parse_clap(name, ident)
  if not name:match("^CLAP") then return nil end
  return { name = name, type = (name:match("^(%S+):") or "CLAP"), identifier = ident, path = ident, last_used = 0, use_count = 0 }
end

local function parse_lv2(name, ident)
  if not name:match("^LV2") then return nil end
  return { name = name, type = (name:match("^(%S+):") or "LV2"), identifier = ident, path = ident, last_used = 0, use_count = 0 }
end

function M.generate_fx_list()
  local plugin_names = {}
  local plugin_info_list = {}

  -- Enumerate installed FX
  for i = 0, math.huge do
    local retval, name, ident = r.EnumInstalledFX(i)
    if not retval then break end
    local info = parse_vst(name, ident) or parse_jsfx(name, ident) or parse_au(name, ident) or parse_clap(name, ident) or parse_lv2(name, ident)
    if info then
      plugin_names[#plugin_names + 1] = name
      plugin_info_list[#plugin_info_list + 1] = info
    end
  end

  return plugin_names, plugin_info_list
end

local builtin_patterns = {
  "ReaEQ", "ReaComp", "ReaVerb", "ReaDelay", "ReaPitch", "ReaGate",
  "ReaLimit", "ReaXcomp", "ReaFir", "ReaSynth", "ReaTune",
  "ReaSamplOmatic5000", "ReaVoice", "ReaSurround", "Container", "Video processor"
}

local function is_allowed_vst(name)
  return name:match("^VST:") or name:match("^VSTi:") or name:match("^VST3:") or name:match("^VST3i:")
end

function M.filter_third_party_vst(list)
  local out = {}
  for i = 1, #list do
    local p = list[i]
    local name = p.name or p
    local is_builtin = false
    for _, pat in ipairs(builtin_patterns) do
      if name:find(pat, 1, true) then is_builtin = true break end
    end
    if (not is_builtin) and is_allowed_vst(name) then
      out[#out + 1] = p
    end
  end
  return out
end

return M


