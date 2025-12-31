--[[
  REAPER Companion - 商店窗口 UI (Elegant UI Version)
  
  优化记录:
  1. [Scrollbar] 移除了原生的厚重滚动条，采用 6px 窄边、全圆角、透明背景的现代设计。
  2. [Layout] 优化了 Child Window 的 Padding，确保滚动条不会遮挡卡片边框。
  3. [Visual] 抓取块颜色与主题 Accent Color 统一。
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
  
  -- 优雅滚动条配置
  scrollbar = {
    size = 6.0,                -- 窄细宽度
    rounding = 12.0,           -- 全圆角
    bg = 0x00000000,           -- 背景完全透明
    grab = 0x66666660,         -- 默认抓取块半透明
    grab_hover = 0x888888AA,   -- 悬停变亮
    grab_active = 0x4D9FFFFF,  -- 激活时使用主题蓝
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
  local mapping = {
    bear_base = "bear_base", cat_base = "cat_base", rabbit_base = "rabbit_base",
    chick_base = "chick_base", dog_base = "dog_base", onion_base = "onion_base",
    koala_base = "koala_base", lion_base = "lion_base", panda_base = "panda_base"
  }
  return mapping[skin_id] or "cat_base"
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

local function draw_purchase_popup(ctx, skins, tracker, main_win_info)
  local should_close_shop = false
  if should_open_popup then r.ImGui_OpenPopup(ctx, "PurchasePopup") should_open_popup = false end
  if not shop_purchase_confirm then return false end
  
  r.ImGui_SetNextWindowPos(ctx, popup_pos.x + 10, popup_pos.y + 10, r.ImGui_Cond_Appearing())
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), 12, 12)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(), 8.0)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PopupBg(), Style.window_bg)
  
  if r.ImGui_BeginPopup(ctx, "PurchasePopup") then
    local is_blind_box = (shop_purchase_confirm == "blind_box")
    local price = is_blind_box and ShopSystem.get_blind_box_price() or shop_purchase_confirm.price
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
      r.ImGui_TextColored(ctx, Style.text_dim, I18n.get("shop.earn_tip", "Tip: Click the timer on main window \nand complete focus sessions to earn coins!"))
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
             TransformationEffect.trigger_unlock(unlocked_skin_id, box_cx, box_floor_y, 1.0, function() SkinManager.set_active_skin(unlocked_skin_id) end)
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
      if r.ImGui_Button(ctx, "Cancel", btn_w, btn_h) then r.ImGui_CloseCurrentPopup(ctx) shop_purchase_confirm = nil end
    end
    r.ImGui_EndPopup(ctx)
  end
  r.ImGui_PopStyleColor(ctx, 1)
  r.ImGui_PopStyleVar(ctx, 2)
  return should_close_shop
end

local function draw_skin_item(ctx, dl, skin, item_size, is_selected, is_owned, is_blind_box, active_id, tracker)
  r.ImGui_PushID(ctx, skin.id)
  local clicked = r.ImGui_InvisibleButton(ctx, "skin_btn_" .. skin.id, item_size, item_size)
  local is_hovered = r.ImGui_IsItemHovered(ctx)
  local is_active = r.ImGui_IsItemActive(ctx)
  
  if clicked then
    local mx, my = r.ImGui_GetMousePos(ctx)
    popup_pos = {x = mx, y = my}
    if is_blind_box then shop_purchase_confirm = "blind_box" should_open_popup = true 
    elseif not is_owned then shop_purchase_confirm = {skin_id = skin.id, price = ShopSystem.get_direct_buy_price()} should_open_popup = true 
    elseif SkinManager.set_active_skin(skin.id) then
      local global_stats = tracker:get_global_stats()
      Config.save_to_data(global_stats)
      tracker:save_global_data()
    end
  end
  
  local sx, sy = r.ImGui_GetItemRectMin(ctx)
  local sx2, sy2 = r.ImGui_GetItemRectMax(ctx)
  local hover_offset = (is_hovered and not is_active) and -2.0 or 0.0
  sy, sy2 = sy + hover_offset, sy2 + hover_offset
  
  if is_hovered then r.ImGui_DrawList_AddRectFilled(dl, sx + 2, sy + 4, sx2 - 2, sy2 + 4, Style.card.shadow_col, Style.card.radius) end
  
  local bg_color = is_owned and Style.card.bg_owned or Style.card.bg_locked
  if is_hovered then bg_color = Style.card.bg_hover end
  if is_owned and skin.accent then
    local ar, ag, ab, aa = r.ImGui_ColorConvertU32ToDouble4(skin.accent)
    local bg_r, bg_g, bg_b, _ = r.ImGui_ColorConvertU32ToDouble4(bg_color)
    bg_color = r.ImGui_ColorConvertDouble4ToU32(bg_r * 0.8 + ar * 0.2, bg_g * 0.8 + ag * 0.2, bg_b * 0.8 + ab * 0.2, 1.0)
  end
  
  r.ImGui_DrawList_AddRectFilled(dl, sx, sy, sx2, sy2, bg_color, Style.card.radius)
  
  local padding = item_size * 0.1
  if is_blind_box then
    if random_box_image then r.ImGui_DrawList_AddImage(dl, random_box_image, sx + padding, sy + padding, sx2 - padding, sy2 - padding)
    else r.ImGui_DrawList_AddText(dl, sx + item_size*0.4, sy + item_size*0.4, Style.card.border_blind, "?") end
  else
    local preview_img = skin_preview_cache[skin.id]
    if preview_img then r.ImGui_DrawList_AddImage(dl, preview_img, sx + padding, sy + padding, sx2 - padding, sy2 - padding)
    else r.ImGui_DrawList_AddRectFilled(dl, sx + padding, sy + padding, sx2 - padding, sy2 - padding, skin.accent or Style.card.border_owned, Style.card.radius * 0.5) end
  end
  
  if not is_owned or is_blind_box then
    local price_str = format_price(is_blind_box and ShopSystem.get_blind_box_price() or ShopSystem.get_direct_buy_price())
    local tag_h, tag_w = 18, item_size - 8
    local tag_x, tag_y = sx + 4, sy2 - 22
    r.ImGui_DrawList_AddRectFilled(dl, tag_x, tag_y, tag_x + tag_w, tag_y + tag_h, Style.price_tag.bg, 6.0) 
    local tw, th = r.ImGui_CalcTextSize(ctx, price_str)
    r.ImGui_DrawList_AddText(dl, tag_x + (tag_w - tw)*0.5, tag_y + (tag_h - th)*0.5, Style.price_tag.text, price_str)
    if not is_owned then r.ImGui_DrawList_AddText(dl, sx2 - 18, sy + 4, Style.text_dim, "🔒") end
  end
  
  local border_col, border_thick = Style.card.border_owned, 1.0
  if is_selected then border_col, border_thick = Style.card.border_selected, 2.5 r.ImGui_DrawList_AddRect(dl, sx-1, sy-1, sx2+1, sy2+1, border_col & 0xFFFFFF60, Style.card.radius, 0, 3.5)
  elseif is_blind_box then border_col, border_thick = Style.card.border_blind, 2.0
  elseif is_hovered then border_col, border_thick = Style.card.border_hover, 1.5 end
  r.ImGui_DrawList_AddRect(dl, sx, sy, sx2, sy2, border_col, Style.card.radius, 0, border_thick)
  r.ImGui_PopID(ctx)
end

-- ========= 主绘制函数 =========
function Shop.draw(ctx, open, data)
  if not open then 
    -- skin_preview_cache = {}  
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
  
  local PADDING, ITEM_SPACING, COLS, BASE_ITEM_SIZE = 12, 8, 3, 80
  local content_w, content_h = COLS * BASE_ITEM_SIZE + (COLS - 1) * ITEM_SPACING + PADDING * 2, 400 
  
  r.ImGui_SetNextWindowSize(ctx, content_w + 10, content_h, r.ImGui_Cond_FirstUseEver())
  r.ImGui_SetNextWindowPos(ctx, main_window_x + main_window_w + 10, main_window_y, r.ImGui_Cond_Appearing())
  
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), Style.window_bg)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), Style.text_col)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(), 16.0) 
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), PADDING, PADDING)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), ITEM_SPACING, ITEM_SPACING)
  
  local flags = r.ImGui_WindowFlags_NoCollapse() | r.ImGui_WindowFlags_NoTitleBar()
  local win_title = (I18n.get("shop.title") or "Shop") .. "###ZycShopWindow"
  local visible, new_open = r.ImGui_Begin(ctx, win_title, true, flags)
  
  if visible then
    local win_w, win_h = r.ImGui_GetWindowWidth(ctx), r.ImGui_GetWindowHeight(ctx)
    local dl = r.ImGui_GetWindowDrawList(ctx)
    local wx, wy = r.ImGui_GetWindowPos(ctx)
    
    -- 标题栏
    r.ImGui_Text(ctx, I18n.get("shop.title") or "Shop")
    r.ImGui_SameLine(ctx, win_w - 32) 
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0) 
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), Style.close_btn_hover)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), Style.close_btn_active)
    if r.ImGui_Button(ctx, "×", 24, 24) then new_open = false end
    r.ImGui_PopStyleColor(ctx, 3)
    r.ImGui_Separator(ctx)
    
    -- === 优雅滚动条样式注入 ===
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ScrollbarSize(), Style.scrollbar.size)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ScrollbarRounding(), Style.scrollbar.rounding)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ScrollbarBg(), Style.scrollbar.bg)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ScrollbarGrab(), Style.scrollbar.grab)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ScrollbarGrabHovered(), Style.scrollbar.grab_hover)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ScrollbarGrabActive(), Style.scrollbar.grab_active)

    -- 内容区域 (增加少量宽度 Offset 以防滚动条挡住卡片)
    local av_w, av_h = r.ImGui_GetContentRegionAvail(ctx)
    -- 注意：ReaImGui 的 BeginChild 不支持 flags 参数，滚动条会自动显示
    r.ImGui_BeginChild(ctx, "ShopContent", av_w, av_h)
    
    local balance, daily = CoinSystem.get_balance(), CoinSystem.get_daily_remaining()
    local balance_text = I18n.get("shop.balance") .. ": " .. format_number(balance)
    -- 使用 "Daily Limit" 更清晰，并留出滚动条空间
    local daily_text = I18n.get("shop.daily_limit") .. ": " .. daily
    
    -- 绘制余额（左侧）
    r.ImGui_TextColored(ctx, Style.gold_col, balance_text)
    
    -- 绘制每日剩余（右侧对齐，留出滚动条空间）
    local scrollbar_width = Style.scrollbar.size + 4  -- 滚动条宽度 + padding
    local daily_w = r.ImGui_CalcTextSize(ctx, daily_text)
    r.ImGui_SameLine(ctx, av_w - daily_w - scrollbar_width)
    r.ImGui_TextColored(ctx, Style.text_dim, daily_text)
    
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    
    local skins, active_id = SkinManager.get_skins()
    local owned, locked = {}, {{ id = "blind_box", name = I18n.get("shop.blind_box"), accent = 0xFFD700FF }}
    if skins then
      for _, s in ipairs(skins) do
        if ShopSystem.is_owned(s.id) then table.insert(owned, s) else table.insert(locked, s) end
      end
    end
    
    local to_load = {}
    for _, s in ipairs(owned) do table.insert(to_load, s) end
    for _, s in ipairs(locked) do if s.id ~= "blind_box" then table.insert(to_load, s) end end
    load_skin_previews(ctx, script_path, to_load)
    
    local item_size = math.floor((av_w - 12 - (COLS-1)*ITEM_SPACING) / COLS)
    
    -- 渲染逻辑
    local function render_list(list, title, is_owned_list)
      if #list == 0 then return end
      r.ImGui_TextColored(ctx, Style.text_dim, title)
      for i, item in ipairs(list) do
        local is_blind = (item.id == "blind_box")
        draw_skin_item(ctx, dl, item, item_size, item.id == active_id, is_owned_list, is_blind, active_id, tracker)
        if i % COLS ~= 0 and i ~= #list then r.ImGui_SameLine(ctx) end
      end
      r.ImGui_Spacing(ctx) r.ImGui_Spacing(ctx)
    end

    render_list(owned, I18n.get("shop.my_collection"), true)
    if #owned > 0 and #locked > 0 then r.ImGui_Separator(ctx) r.ImGui_Spacing(ctx) end
    render_list(locked, I18n.get("shop.shop"), false)
    
    local main_info = { x = main_window_x, y = main_window_y, w = main_window_w, h = main_window_h, floor_y = data.floor_y }
    if draw_purchase_popup(ctx, skins, tracker, main_info) then new_open = false end
    
    r.ImGui_EndChild(ctx)
    
    -- 弹出样式
    r.ImGui_PopStyleColor(ctx, 4)
    r.ImGui_PopStyleVar(ctx, 2)
  end
  
  r.ImGui_End(ctx)
  r.ImGui_PopStyleVar(ctx, 3) 
  r.ImGui_PopStyleColor(ctx, 2)
  
  if not visible then skin_preview_cache, shop_purchase_confirm, should_open_popup = {}, nil, false end
  
  return new_open
end

return Shop