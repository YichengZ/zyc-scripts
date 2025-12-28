--[[
  REAPER Companion - 商店窗口 UI (Stable - No Clipper)
  
  优化记录:
  1. [Stability] 移除了不稳定的 ListClipper。对于皮肤商店这种量级的数据(几十个)，
     直接渲染不仅性能完全足够，而且能保证 100% 不报错。
  2. [Design] 保持了所有的卡片样式、购买弹窗和交互逻辑。
--]]

local Shop = {}

local SkinManager = require('ui.skins.skin_manager')
local CoinSystem = require('core.coin_system')
local ShopSystem = require('core.shop_system')
local Config = require('config')
local TransformationEffect = require('ui.transformation_effect')
local Debug = require('utils.debug')
local I18n = require('utils.i18n')
local r = reaper

-- 皮肤预览缓存
local skin_preview_cache = {}
-- 随机宝箱图片缓存
local random_box_image = nil

-- 购买确认状态
local shop_purchase_confirm = nil
local popup_pos = {x=0, y=0}
local should_open_popup = false 

-- ========= 样式配置 =========
local Style = {
  window_bg = 0x2A2A2AFF, 
  text_col = 0xE0E0E0FF,  
  text_dim = 0x999999FF,  
  accent_col = 0x4D9FFFFF, 
  gold_col = 0xFFD700FF,   
  
  btn_primary = 0x4D9FFFFF, 
  btn_hover = 0x5DAFFFFF,
  btn_active = 0x3D8FEFFF,
  
  close_btn_hover = 0x3A3A3AFF,
  close_btn_active = 0x4A4A4AFF,
  close_text = 0xCCCCCCFF,
  
  card = {
    bg_owned = 0x333333FF,      
    bg_locked = 0x252525FF,     
    bg_hover = 0x3D3D3DFF,      
    
    border_owned = 0x444444FF,  
    border_selected = 0x4D9FFFFF, 
    border_hover = 0x666666FF,  
    border_blind = 0xFFD700FF,  
    
    radius = 8.0,               
    shadow_col = 0x00000060,    
  },
  
  price_tag = {
    bg = 0x000000AA,            
    text = 0xFFD700FF,          
  }
}

-- ========= 辅助函数 =========

local function format_number(n)
  local left, num, right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
  return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local function format_price(n)
  if n >= 1000 then
    local k = string.format("%.1f", n / 1000)
    if k:sub(-2) == ".0" then k = k:sub(1, -3) end
    return k .. "k"
  else
    return tostring(n)
  end
end

local function get_skin_folder(skin_id)
  if skin_id == "bear_base" then return "bear_base"
  elseif skin_id == "cat_base" then return "cat_base"
  elseif skin_id == "rabbit_base" then return "rabbit_base"
  elseif skin_id == "chick_base" then return "chick_base"
  elseif skin_id == "dog_base" then return "dog_base"
  elseif skin_id == "onion_base" then return "onion_base"
  elseif skin_id == "koala_base" then return "koala_base"
  elseif skin_id == "lion_base" then return "lion_base"
  elseif skin_id == "panda_base" then return "panda_base"
  end
  return "cat_base"  
end

local function load_skin_previews(ctx, script_path, skins)
  if not skins then return end
  
  for _, skin in ipairs(skins) do
    if skin.preview_image and not skin_preview_cache[skin.id] then
      local skin_folder = get_skin_folder(skin.id)
      local preview_path = script_path .. "assets/skins/" .. skin_folder .. "/" .. skin.preview_image
      
      if r.file_exists and r.file_exists(preview_path) then
        local preview_img = r.ImGui_CreateImage(preview_path)
        if preview_img then
          r.ImGui_Attach(ctx, preview_img)
          skin_preview_cache[skin.id] = preview_img
        end
      end
    end
  end
end

-- 绘制购买确认弹窗
local function draw_purchase_popup(ctx, skins, tracker, main_win_info)
  local should_close_shop = false

  if should_open_popup then
    r.ImGui_OpenPopup(ctx, "PurchasePopup")
    should_open_popup = false
  end

  if not shop_purchase_confirm then return false end
  
  r.ImGui_SetNextWindowPos(ctx, popup_pos.x + 10, popup_pos.y + 10, r.ImGui_Cond_Appearing())
  
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), 12, 12)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(), 8.0)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PopupBg(), Style.window_bg)
  
  if r.ImGui_BeginPopup(ctx, "PurchasePopup") then
    
    local is_blind_box = (shop_purchase_confirm == "blind_box")
    local price = is_blind_box and ShopSystem.get_blind_box_price() or shop_purchase_confirm.price
    local skin_name = is_blind_box and I18n.get("shop.blind_box") or (skins and (function()
      for _, s in ipairs(skins) do
        if s.id == shop_purchase_confirm.skin_id then return s.name end
      end
      return "Unknown"
    end)() or "Unknown")
    
    r.ImGui_Text(ctx, I18n.get("shop.unlock") .. " " .. skin_name .. "?")
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    
    r.ImGui_Text(ctx, I18n.get("shop.cost") .. ": ")
    r.ImGui_SameLine(ctx)
    r.ImGui_TextColored(ctx, Style.gold_col, format_number(price) .. " " .. I18n.get("shop.coins"))
    r.ImGui_Spacing(ctx)
    
    local current_balance = CoinSystem.get_balance()
    local btn_w, btn_h = 80, 24
    
    if current_balance < price then
      r.ImGui_TextColored(ctx, 0xFF6666FF, I18n.get("shop.insufficient_funds"))
      r.ImGui_Spacing(ctx)
      if r.ImGui_Button(ctx, I18n.get("shop.close"), btn_w, btn_h) then
        r.ImGui_CloseCurrentPopup(ctx)
        shop_purchase_confirm = nil
      end
    else
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), Style.btn_primary)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), Style.btn_hover)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), Style.btn_active)
      
      if r.ImGui_Button(ctx, I18n.get("shop.purchase"), btn_w, btn_h) then
        local success, result, message
        local unlocked_skin_id = nil
        
        if is_blind_box then
          success, result, message = ShopSystem.buy_blind_box()
          if success and result and result.id then unlocked_skin_id = result.id end
        else
          success, message = ShopSystem.buy_specific_skin(shop_purchase_confirm.skin_id)
          if success then unlocked_skin_id = shop_purchase_confirm.skin_id end
        end
        
        if success then
          local global_stats = tracker:get_global_stats()
          Config.save_to_data(global_stats)
          tracker:save_global_data()
          CoinSystem.save()
          ShopSystem.save()
          
          if unlocked_skin_id and main_win_info then
             local box_cx = (main_win_info.x or 0) + (main_win_info.w or 200) * 0.5
             local box_floor_y = main_win_info.floor_y or ((main_win_info.y or 0) + (main_win_info.h or 200) * 0.70)
             
             TransformationEffect.trigger_unlock(
               unlocked_skin_id, 
               box_cx, 
               box_floor_y, 
               1.0, 
               function()
                 SkinManager.set_active_skin(unlocked_skin_id)
               end
             )
          else
             TransformationEffect.trigger() 
             if unlocked_skin_id then SkinManager.set_active_skin(unlocked_skin_id) end
          end
          
          should_close_shop = true
        end
        
        r.ImGui_CloseCurrentPopup(ctx)
        shop_purchase_confirm = nil
      end
      r.ImGui_PopStyleColor(ctx, 3)
      
      r.ImGui_SameLine(ctx)
      if r.ImGui_Button(ctx, "Cancel", btn_w, btn_h) then
        r.ImGui_CloseCurrentPopup(ctx)
        shop_purchase_confirm = nil
      end
    end
    
    r.ImGui_EndPopup(ctx)
  end
  
  r.ImGui_PopStyleColor(ctx, 1)
  r.ImGui_PopStyleVar(ctx, 2)
  
  return should_close_shop
end

-- 绘制皮肤网格项
local function draw_skin_item(ctx, dl, skin, item_size, is_selected, is_owned, is_blind_box, active_id, tracker)
  r.ImGui_PushID(ctx, skin.id)
  
  local button_id = "skin_btn_" .. skin.id
  local clicked = r.ImGui_InvisibleButton(ctx, button_id, item_size, item_size)
  local is_hovered = r.ImGui_IsItemHovered(ctx)
  local is_active = r.ImGui_IsItemActive(ctx)
  
  if clicked then
    local mx, my = r.ImGui_GetMousePos(ctx)
    popup_pos = {x = mx, y = my}
    
    if is_blind_box then
      shop_purchase_confirm = "blind_box"
      should_open_popup = true 
      
    elseif not is_owned then
      shop_purchase_confirm = {skin_id = skin.id, price = ShopSystem.get_direct_buy_price()}
      should_open_popup = true 
      
    elseif SkinManager.set_active_skin(skin.id) then
      local global_stats = tracker:get_global_stats()
      Config.save_to_data(global_stats)
      tracker:save_global_data()
    end
  end
  
  local screen_x, screen_y = r.ImGui_GetItemRectMin(ctx)
  local screen_x2, screen_y2 = r.ImGui_GetItemRectMax(ctx)
  
  local hover_offset = (is_hovered and not is_active) and -2.0 or 0.0
  screen_y = screen_y + hover_offset
  screen_y2 = screen_y2 + hover_offset
  
  if is_hovered then
    r.ImGui_DrawList_AddRectFilled(dl, screen_x + 2, screen_y + 4, screen_x2 - 2, screen_y2 + 4, Style.card.shadow_col, Style.card.radius)
  end
  
  local bg_color = is_owned and Style.card.bg_owned or Style.card.bg_locked
  if is_hovered then bg_color = Style.card.bg_hover end
  
  if is_owned and skin.accent then
    local ar, ag, ab, aa = r.ImGui_ColorConvertU32ToDouble4(skin.accent)
    local bg_r, bg_g, bg_b, _ = r.ImGui_ColorConvertU32ToDouble4(bg_color)
    bg_color = r.ImGui_ColorConvertDouble4ToU32(bg_r * 0.8 + ar * 0.2, bg_g * 0.8 + ag * 0.2, bg_b * 0.8 + ab * 0.2, 1.0)
  end
  
  r.ImGui_DrawList_AddRectFilled(dl, screen_x, screen_y, screen_x2, screen_y2, bg_color, Style.card.radius)
  
  if is_blind_box then
    local padding = item_size * 0.1
    if random_box_image then
      -- 使用 RandomBox.png 图片
      r.ImGui_DrawList_AddImage(dl, random_box_image, 
        screen_x + padding, screen_y + padding, 
        screen_x2 - padding, screen_y2 - padding)
    else
      -- 如果没有加载图片，显示问号作为后备
      local text_size = item_size * 0.4
      local text_x = screen_x + (item_size - text_size) * 0.5
      local text_y = screen_y + (item_size - text_size) * 0.5
      local q_col = Style.card.border_blind 
      if r.ImGui_DrawList_AddTextEx then
        r.ImGui_DrawList_AddTextEx(dl, nil, text_size, text_x, text_y, q_col, "?")
      else
        r.ImGui_DrawList_AddText(dl, text_x, text_y, q_col, "?")
      end
    end
  else
    local preview_img = skin_preview_cache[skin.id]
    local padding = item_size * 0.1
    
    if preview_img then
      r.ImGui_DrawList_AddImage(dl, preview_img, 
        screen_x + padding, screen_y + padding, 
        screen_x2 - padding, screen_y2 - padding)
    else
      r.ImGui_DrawList_AddRectFilled(dl, 
        screen_x + padding, screen_y + padding, 
        screen_x2 - padding, screen_y2 - padding, 
        skin.accent or Style.card.border_owned, Style.card.radius * 0.5)
    end
  end
  
  if not is_owned or is_blind_box then
    local price = is_blind_box and 500 or ShopSystem.get_direct_buy_price()
    local price_str = format_price(price)
    
    local tag_h = 18 
    local tag_y = screen_y2 - tag_h - 4
    local tag_w = item_size - 8
    local tag_x = screen_x + 4
    
    r.ImGui_DrawList_AddRectFilled(dl, tag_x, tag_y, tag_x + tag_w, tag_y + tag_h, Style.price_tag.bg, 6.0) 
    
    local text_w, text_h = r.ImGui_CalcTextSize(ctx, price_str)
    local text_x = tag_x + (tag_w - text_w) * 0.5
    local text_y = tag_y + (tag_h - text_h) * 0.5
    r.ImGui_DrawList_AddText(dl, text_x, text_y, Style.price_tag.text, price_str)
    
    if not is_owned then
      r.ImGui_DrawList_AddText(dl, screen_x2 - 18, screen_y + 4, Style.text_dim, "🔒")
    end
  end
  
  local border_col = Style.card.border_owned
  local border_thick = 1.0
  
  if is_selected then
    border_col = Style.card.border_selected
    border_thick = 2.5 
    r.ImGui_DrawList_AddRect(dl, screen_x-1, screen_y-1, screen_x2+1, screen_y2+1, border_col & 0xFFFFFF60, Style.card.radius, 0, 3.5)
  elseif is_blind_box then
    border_col = Style.card.border_blind
    border_thick = 2.0
  elseif is_hovered then
    border_col = Style.card.border_hover
    border_thick = 1.5
  end
  
  r.ImGui_DrawList_AddRect(dl, screen_x, screen_y, screen_x2, screen_y2, border_col, Style.card.radius, 0, border_thick)
  
  r.ImGui_PopID(ctx)
end

-- ========= 主绘制函数 =========
function Shop.draw(ctx, open, data)
  if not open then 
    skin_preview_cache = {}
    shop_purchase_confirm = nil
    should_open_popup = false 
    return false 
  end
  
  local tracker = data.tracker
  local script_path = data.script_path
  
  -- 加载随机宝箱图片（如果还没有加载）
  if not random_box_image then
    local random_box_path = script_path .. "assets/skins/shop/blindbox.png"
    if r.file_exists and r.file_exists(random_box_path) then
      local img = r.ImGui_CreateImage(random_box_path)
      if img then
        r.ImGui_Attach(ctx, img)
        random_box_image = img
      end
    end
  end
  local main_window_x = data.main_window_x or 100
  local main_window_y = data.main_window_y or 100
  local main_window_w = data.main_window_w or 200
  local main_window_h = data.main_window_h or 200
  
  local PADDING = 12
  local ITEM_SPACING = 8
  local COLS = 3
  local BASE_ITEM_SIZE = 80
  
  local content_w = COLS * BASE_ITEM_SIZE + (COLS - 1) * ITEM_SPACING + PADDING * 2
  local content_h = 400 
  
  r.ImGui_SetNextWindowSize(ctx, content_w, content_h, r.ImGui_Cond_FirstUseEver())
  r.ImGui_SetNextWindowPos(ctx, main_window_x + main_window_w + 10, main_window_y, r.ImGui_Cond_Appearing())
  
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), Style.window_bg)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), Style.text_col)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(), 16.0) 
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), PADDING, PADDING)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), ITEM_SPACING, ITEM_SPACING)
  
  local flags = r.ImGui_WindowFlags_NoCollapse() | r.ImGui_WindowFlags_NoScrollbar() | r.ImGui_WindowFlags_NoTitleBar()
  local visible, new_open = r.ImGui_Begin(ctx, I18n.get("shop.title"), true, flags)
  
  if visible then
    r.ImGui_Text(ctx, "Skin Shop")
    
    local win_w = r.ImGui_GetWindowWidth(ctx)
    local btn_size = 24
    r.ImGui_SameLine(ctx, win_w - btn_size - 8) 
    
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0) 
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), Style.close_btn_hover)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), Style.close_btn_active)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), Style.close_text)
    
    if r.ImGui_Button(ctx, "×", btn_size, btn_size) then
      new_open = false
    end
    
    r.ImGui_PopStyleColor(ctx, 4)
    r.ImGui_Spacing(ctx)
    
    local balance = CoinSystem.get_balance()
    local daily = CoinSystem.get_daily_remaining()
    
    r.ImGui_TextColored(ctx, Style.gold_col, I18n.get("shop.balance") .. ":")
    r.ImGui_SameLine(ctx)
    r.ImGui_TextColored(ctx, Style.gold_col, format_number(balance))
    
    r.ImGui_SameLine(ctx)
    local avail_w = r.ImGui_GetContentRegionAvail(ctx)
    local daily_text = I18n.get("shop.daily") .. ": " .. daily
    local daily_w = r.ImGui_CalcTextSize(ctx, daily_text)
    r.ImGui_SetCursorPosX(ctx, r.ImGui_GetCursorPosX(ctx) + avail_w - daily_w)
    r.ImGui_TextColored(ctx, Style.text_dim, daily_text)
    
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    
    local skins, active_id = SkinManager.get_skins()
    local owned_list = {}
    local locked_list = {}
    
    table.insert(locked_list, { id = "blind_box", name = I18n.get("shop.blind_box"), accent = 0xFFD700FF })
    
    if skins then
      for _, s in ipairs(skins) do
        if ShopSystem.is_owned(s.id) then table.insert(owned_list, s)
        else table.insert(locked_list, s) end
      end
    end
    
    local all_to_load = {}
    for _, s in ipairs(owned_list) do table.insert(all_to_load, s) end
    for _, s in ipairs(locked_list) do if s.id ~= "blind_box" then table.insert(all_to_load, s) end end
    load_skin_previews(ctx, script_path, all_to_load)
    
    local dl = r.ImGui_GetWindowDrawList(ctx)
    local win_w = r.ImGui_GetWindowWidth(ctx)
    local avail_w_grid = win_w - PADDING * 2
    local item_size = math.floor((avail_w_grid - (COLS - 1) * ITEM_SPACING) / COLS)
    
    local total_rows = math.ceil(#owned_list / COLS) + math.ceil(#locked_list / COLS)
    local has_separator = (#owned_list > 0 and #locked_list > 0)
    if has_separator then total_rows = total_rows + 1 end
    
    -- [简单稳定版] 直接渲染循环 (无 Clipper)
    -- 这个数量级直接循环性能完全没问题，且 100% 不会报错
    for row = 0, total_rows - 1 do
       local owned_rows = math.ceil(#owned_list / COLS)
       if row < owned_rows then
         if row == 0 then r.ImGui_TextColored(ctx, Style.text_dim, I18n.get("shop.my_collection")) end
         for col = 0, COLS - 1 do
           local idx = row * COLS + col + 1
           if idx <= #owned_list then
             local skin = owned_list[idx]
             local is_selected = (skin.id == active_id)
             draw_skin_item(ctx, dl, skin, item_size, is_selected, true, false, active_id, tracker)
             if col < COLS - 1 then r.ImGui_SameLine(ctx) end
           end
         end
       elseif has_separator and row == owned_rows then
         r.ImGui_Dummy(ctx, 0, 4) 
         r.ImGui_Separator(ctx)
         r.ImGui_Dummy(ctx, 0, 4)
       else
         local shop_row = row - (has_separator and (owned_rows + 1) or owned_rows)
         if shop_row == 0 then r.ImGui_TextColored(ctx, Style.text_dim, I18n.get("shop.shop")) end
         for col = 0, COLS - 1 do
           local idx = shop_row * COLS + col + 1
           if idx <= #locked_list then
             local skin = locked_list[idx]
             local is_blind = (skin.id == "blind_box")
             draw_skin_item(ctx, dl, skin, item_size, false, false, is_blind, active_id, tracker)
             if col < COLS - 1 then r.ImGui_SameLine(ctx) end
           end
         end
       end
    end
    
    local main_win_info = {
      x = main_window_x, y = main_window_y,
      w = main_window_w, h = main_window_h,
      floor_y = data.floor_y 
    }
    local should_close = draw_purchase_popup(ctx, skins, tracker, main_win_info)
    if should_close then new_open = false end
  end
  
  r.ImGui_End(ctx)
  r.ImGui_PopStyleVar(ctx, 3) 
  r.ImGui_PopStyleColor(ctx, 2)
  
  if not visible then
    skin_preview_cache = {}
    shop_purchase_confirm = nil
    should_open_popup = false
    -- 注意：不清理 random_box_image，因为它可以在窗口关闭后继续使用
  end
  
  return new_open
end

return Shop