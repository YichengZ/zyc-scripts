--[[
  REAPER Companion - Skin Manager
  负责皮肤注册、加载、切换以及对外统一接口
--]]

local Config = require('config')

local SkinManager = {}
local ctx_ref = nil
local script_path_ref = nil

-- 已注册的皮肤元数据
-- 注意：bongo_cat, sleepy_duck, base_skin 已移除（测试版本）
local skin_defs = {
  {
    id = "cat_base",
    name = "Cat PNG (Base)",
    description = "Cat rendered using PNG layers (cat_base version).",
    module = "ui.skins.cat_base",
    accent = 0xFFE8D58C,
    preview_image = "cat_base.png",  -- 使用 cat_base.png 作为预览图
  },
  {
    id = "bear_base",
    name = "Bear PNG (Base)",
    description = "Bear rendered using PNG layers (bear_base version).",
    module = "ui.skins.bear_base",
    accent = 0xFFD4A574,  -- 棕色系，适合熊
    preview_image = "bear_base.png",  -- 使用 bear_base.png 作为预览图
  },
  {
    id = "rabbit_base",
    name = "Rabbit PNG (Base)",
    description = "Rabbit rendered using PNG layers (rabbit_base version).",
    module = "ui.skins.rabbit_base",
    accent = 0xFFE8D5C8,  -- 浅粉色系，适合兔子
    preview_image = "rabbit_base.png",  -- 使用 rabbit_base.png 作为预览图
  },
  {
    id = "chick_base",
    name = "Chick PNG (Base)",
    description = "Chick rendered using PNG layers (chick_base version).",
    module = "ui.skins.chick_base",
    accent = 0xFFFFF9C6,  -- 黄色系，适合小鸡
    preview_image = "chick_base.png",  -- 使用 chick_base.png 作为预览图
  },
  {
    id = "dog_base",
    name = "Dog PNG (Base)",
    description = "Dog rendered using PNG layers (dog_base version).",
    module = "ui.skins.dog_base",
    accent = 0xFFD4B88C,  -- 棕色系，适合狗狗
    preview_image = "dog_base.png",  -- 使用 dog_base.png 作为预览图
  },
  {
    id = "onion_base",
    name = "Onion PNG (Base)",
    description = "Onion rendered using PNG layers (onion_base version).",
    module = "ui.skins.onion_base",
    accent = 0xFFD8C6FF,  -- 淡紫色系，适合洋葱
    preview_image = "onion_base.png",  -- 使用 onion_base.png 作为预览图
  },
  {
    id = "koala_base",
    name = "Koala PNG (Base)",
    description = "Koala rendered using PNG layers (koala_base version).",
    module = "ui.skins.koala_base",
    accent = 0xFFC8D8FF,  -- 淡蓝灰色系，适合考拉
    preview_image = "koala_base.png",  -- 使用 koala_base.png 作为预览图
  },
  {
    id = "lion_base",
    name = "Lion PNG (Base)",
    description = "Lion rendered using PNG layers (lion_base version).",
    module = "ui.skins.lion_base",
    accent = 0xFFFFB84D,  -- 金黄色系，适合狮子
    preview_image = "lion_base.png",  -- 使用 lion_base.png 作为预览图
  }
}

local loaded_skins = {}
local active_skin
-- active_skin_id will be set from Config.CURRENT_SKIN_ID in init()
local active_skin_id = nil
local layout_dirty = false

local function load_skin(def)
  if not loaded_skins[def.id] then
    local skin = require(def.module)
    if skin.init then skin.init(ctx_ref, script_path_ref) end
    loaded_skins[def.id] = skin
  end
  return loaded_skins[def.id]
end

function SkinManager.init(ctx, script_path)
  ctx_ref = ctx
  script_path_ref = script_path
  
  -- Load saved skin ID from Config (which was loaded from global_stats in main.lua)
  active_skin_id = Config.CURRENT_SKIN_ID or "cat_base"
  
  -- Try to load the saved skin
  for _, def in ipairs(skin_defs) do
    if def.id == active_skin_id then
      active_skin = load_skin(def)
      break
    end
  end

  -- Fallback to first available skin if saved skin ID is invalid
  if not active_skin then
    active_skin = load_skin(skin_defs[1])
    active_skin_id = skin_defs[1].id
    Config.CURRENT_SKIN_ID = active_skin_id
  end
end

function SkinManager.get_skins()
  local list = {}
  for _, def in ipairs(skin_defs) do
    list[#list+1] = {
      id = def.id,
      name = def.name,
      description = def.description,
      accent = def.accent,
      preview_image = def.preview_image  -- Include preview_image in returned list
    }
  end
  return list, active_skin_id
end

function SkinManager.get_skin_meta(id)
  for _, def in ipairs(skin_defs) do
    if def.id == id then return def end
  end
end

function SkinManager.get_active_skin()
  return active_skin
end

function SkinManager.get_active_skin_id()
  return active_skin_id
end

function SkinManager.set_active_skin(id)
  if id == active_skin_id then return false end
  for _, def in ipairs(skin_defs) do
    if def.id == id then
      active_skin = load_skin(def)
      active_skin_id = id
      Config.CURRENT_SKIN_ID = id
      layout_dirty = true
      -- Note: The caller should save the config to global_stats and call tracker:save_global_data()
      -- This is done in main.lua when switching skins from the UI
      return true
    end
  end
  return false
end

function SkinManager.is_layout_dirty()
  return layout_dirty
end

function SkinManager.consume_layout_dirty()
  if layout_dirty then
    layout_dirty = false
    return true
  end
  return false
end

local function call(method, ...)
  if active_skin and active_skin[method] then
    return active_skin[method](...)
  end
end

function SkinManager.update(...)
  call("update", ...)
end

function SkinManager.draw(...)
  call("draw", ...)
end

function SkinManager.draw_paws(...)
  call("draw_paws", ...)
end

function SkinManager.trigger(action_type, is_manual)
  call("trigger_action", action_type, is_manual)
end

function SkinManager.get_last_manual_tap_time()
  return call("get_last_manual_tap_time") or 0
end

function SkinManager.get_recommended_size()
  local w, h = call("get_recommended_size")
  if not w or not h then
    local cfg = Config.BONGO_CAT
    return cfg.base_w, cfg.base_h
  end
  return w, h
end

-- 获取当前皮肤的绘制区域信息（供其他模块使用，确保 UI 元素与图片保持相对位置）
function SkinManager.get_draw_rect()
  return call("get_draw_rect")
end

return SkinManager

