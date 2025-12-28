--[[
  REAPER Companion - 全局国际化 (i18n) 模块
  统一管理所有 UI 文本的多语言支持
--]]

local I18n = {}

-- 当前语言（默认英文）
local current_lang = "en"

-- 翻译缓存
local translations_cache = {}

-- 支持的语言列表（按使用人数和重要性排序）
local supported_languages = {
  "en", "zh", "es", "pt", "fr", "de", "it", "ru", "ja", "ko", 
  "tr", "th", "vi", "id"
}

-- 语言显示名称（本地化）
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

-- 语言代码（用于显示，让用户即使不懂语言也能识别）
local language_codes = {
  en = "EN",
  zh = "ZH",
  es = "ES",
  pt = "PT",
  fr = "FR",
  de = "DE",
  it = "IT",
  ru = "RU",
  ja = "JA",
  ko = "KO",
  tr = "TR",
  th = "TH",
  vi = "VI",
  id = "ID"
}

-- ========= 初始化 =========
-- @param lang 语言代码 (en, zh, ko, ja)
function I18n.init(lang)
  lang = lang or "en"
  if not I18n.is_supported(lang) then
    lang = "en"  -- 默认回退到英文
  end
  current_lang = lang
  I18n.load_language(lang)
end

-- ========= 加载语言包 =========
-- @param lang 语言代码
function I18n.load_language(lang)
  if translations_cache[lang] then
    return  -- 已经加载过
  end
  
  local ok, translations = pcall(function()
    return require("ui.i18n." .. lang)
  end)
  
  if ok and translations then
    translations_cache[lang] = translations
  else
    -- 如果加载失败，使用英文作为后备
    if lang ~= "en" then
      I18n.load_language("en")
      current_lang = "en"
    end
  end
end

-- ========= 设置语言 =========
-- @param lang 语言代码
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

-- ========= 获取当前语言 =========
function I18n.get_current_language()
  return current_lang
end

-- ========= 获取翻译 =========
-- @param key 翻译键（支持点号分隔的命名空间，如 "settings.general.title"）
-- @param default 默认值（如果找不到翻译）
-- @return 翻译后的文本
function I18n.get(key, default)
  if not key then
    return default or key
  end
  
  -- 确保当前语言已加载
  if not translations_cache[current_lang] then
    I18n.load_language(current_lang)
  end
  
  local translations = translations_cache[current_lang]
  if not translations then
    -- 如果当前语言加载失败，尝试加载英文
    if current_lang ~= "en" then
      I18n.load_language("en")
      translations = translations_cache["en"]
    end
  end
  
  if not translations then
    return default or key
  end
  
  -- 支持点号分隔的键（如 "settings.general.title"）
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
  
  -- 如果找不到，尝试英文后备
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

-- ========= 检查语言是否支持 =========
-- @param lang 语言代码
function I18n.is_supported(lang)
  for _, supported in ipairs(supported_languages) do
    if supported == lang then
      return true
    end
  end
  return false
end

-- ========= 获取所有支持的语言 =========
function I18n.get_supported_languages()
  return supported_languages
end

-- ========= 获取语言显示名称 =========
-- @param lang 语言代码
function I18n.get_language_name(lang)
  return language_names[lang] or lang
end

-- ========= 获取语言代码（用于显示）=========
-- @param lang 语言代码
function I18n.get_language_code(lang)
  return language_codes[lang] or lang:upper()
end

-- ========= 获取语言显示文本（带代码）=========
-- @param lang 语言代码
-- @return 格式：🌐 EN - English
function I18n.get_language_display(lang)
  local code = I18n.get_language_code(lang)
  local name = I18n.get_language_name(lang)
  return "🌐 " .. code .. " - " .. name
end

-- ========= 自动检测系统语言 =========
-- 尝试从 REAPER 环境检测语言
function I18n.detect_system_language()
  -- REAPER 没有直接的 API 获取系统语言
  -- 可以尝试从操作系统检测，但这里先返回 nil，让用户手动选择
  return nil
end

return I18n

