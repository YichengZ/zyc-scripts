local I18n = {}

local current_lang = "en"
local translations_cache = {}
local base_path = nil

local supported_languages = {
  "en", "zh", "es", "pt", "fr", "de", "it", "ru", "ja", "ko", 
  "tr", "th", "vi", "id"
}

local language_names = {
  en = "English",
  zh = "中文",
  es = "Español",
  pt = "Português",
  fr = "Français",
  de = "Deutsch",
  it = "Italiano",
  ru = "Русский",
  ja = "日本語",
  ko = "한국어",
  tr = "Türkçe",
  th = "ไทย",
  vi = "Tiếng Việt",
  id = "Bahasa Indonesia"
}

function I18n.init(lang, path)
  lang = lang or "en"
  if not I18n.is_supported(lang) then
    lang = "en"
  end
  if path then
    base_path = path
  end
  current_lang = lang
  I18n.load_language(lang)
end

function I18n.load_language(lang)
  if translations_cache[lang] then
    return
  end
  
  local script_path = base_path
  if not script_path then
    script_path = debug.getinfo(2, 'S').source:match('@(.+[/\\])')
    if script_path and script_path:match('utils[/\\]') then
      script_path = script_path:match('(.+[/\\])utils[/\\]')
    end
  end
  if not script_path then
    script_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])')
    if script_path and script_path:match('utils[/\\]') then
      script_path = script_path:match('(.+[/\\])utils[/\\]')
    end
  end
  local lang_file = script_path .. 'i18n/' .. lang .. '.lua'
  
  local ok, translations = pcall(function()
    local f = loadfile(lang_file)
    if f then
      return f()
    end
    return nil
  end)
  
  if ok and translations then
    translations_cache[lang] = translations
  else
    if lang ~= "en" then
      I18n.load_language("en")
      current_lang = "en"
    end
  end
end

function I18n.set_language(lang)
  if not I18n.is_supported(lang) then
    return false
  end
  
  if lang ~= current_lang then
    current_lang = lang
    I18n.load_language(lang)
  end
  
  return true
end

function I18n.get_current_language()
  return current_lang
end

function I18n.get(key, default)
  if not key then
    return default or key
  end
  
  if not translations_cache[current_lang] then
    I18n.load_language(current_lang)
  end
  
  local translations = translations_cache[current_lang]
  if not translations then
    if current_lang ~= "en" then
      I18n.load_language("en")
      translations = translations_cache["en"]
    end
  end
  
  if not translations then
    return default or key
  end
  
  local keys = {}
  for k in key:gmatch("[^.]+") do
    table.insert(keys, k)
  end
  
  local value = translations
  for _, k in ipairs(keys) do
    if type(value) == "table" then
      value = value[k]
    else
      break
    end
  end
  
  if value and type(value) == "string" then
    return value
  end
  
  if current_lang ~= "en" and translations_cache["en"] then
    value = translations_cache["en"]
    for _, k in ipairs(keys) do
      if type(value) == "table" then
        value = value[k]
      else
        break
      end
    end
    if value and type(value) == "string" then
      return value
    end
  end
  
  return default or key
end

function I18n.is_supported(lang)
  for _, supported in ipairs(supported_languages) do
    if supported == lang then
      return true
    end
  end
  return false
end

function I18n.get_supported_languages()
  return supported_languages
end

function I18n.get_language_name(lang)
  return language_names[lang] or lang
end

return I18n

