--[[
  REAPER Companion - 欢迎窗口多语言支持
--]]

local WelcomeI18n = {}

-- 语言包
local translations = {
  en = {
    title = "🎉 Welcome to ReaPet!",
    subtitle = "Your little companion in REAPER ～",
    quick_guide = "📚 Quick Guide",
    stats_title = "📊 Stats Box",
    stats_1 = "   • Tracks your operations in this project",
    stats_2 = "   • Click it to see your active time instead",
    timer_title = "🍅 Timer",
    timer_1 = "   • Click to start a focus session",
    timer_2 = "   • Right-click to adjust the timer settings",
    treasure_title = "🎁 Treasure Box",
    treasure_1 = "   • Appears after you complete a focus session",
    treasure_2 = "   • Click it to collect your coins!",
    coins_title = "💰 Coins",
    coins_1 = "   • Earn coins by finishing focus sessions",
    coins_2 = "   • 1 minute of focus = 1 coin",
    coins_3 = "   • You can earn up to 600 coins per day",
    shop_title = "🛒 Shop",
    shop_1 = "   • Click the button on the right side of the desk",
    shop_2 = "   • Use your coins to get new pet skins",
    shop_3 = "   • Choose direct purchase or try the blind box",
    settings_title = "⚙️ Settings",
    settings_1 = "   • Right-click your pet to open settings",
    settings_2 = "   • Adjust how things look and work",
    bonus_title = "🎁 Welcome Gift: 500 Coins!",
    bonus_subtitle = "You can draw your first animal friend right away! ～",
    button = "Got it! Let's Start"
  },
  zh = {
    title = "🎉 欢迎使用 ReaPet!",
    subtitle = "在 REAPER 中感受动物小伙伴的陪伴 ～",
    quick_guide = "📚 快速指南",
    stats_title = "📊 计数窗口",
    stats_1 = "   • 会记录你在当前项目中的操作次数",
    stats_2 = "   • 点击可以切换到显示活跃时间",
    timer_title = "🍅 计时器",
    timer_1 = "   • 点击开始专注时间",
    timer_2 = "   • 右键可以调整计时器设置",
    treasure_title = "🎁 宝箱",
    treasure_1 = "   • 完成专注时间后就会出现",
    treasure_2 = "   • 点击就能领取金币！",
    coins_title = "💰 金币",
    coins_1 = "   • 完成专注时间就能获得金币",
    coins_2 = "   • 专注 1 分钟 = 1 金币",
    coins_3 = "   • 每天最多能获得 600 金币",
    shop_title = "🛒 商店",
    shop_1 = "   • 点击桌子右边的按钮",
    shop_2 = "   • 用金币解锁新的宠物皮肤",
    shop_3 = "   • 可以直接购买，也可以试试盲盒",
    settings_title = "⚙️ 设置",
    settings_1 = "   • 右键点击宠物打开设置",
    settings_2 = "   • 可以调整外观和各项功能",
    bonus_title = "🎁 欢迎礼物: 500 金币!",
    bonus_subtitle = "现在就可以抽第一个动物朋友啦！～",
    button = "知道啦，开始吧！"
  },
  ko = {
    title = "🎉 ReaPet에 오신 것을 환영합니다!",
    subtitle = "REAPER에서 함께할 동물 친구 ～",
    quick_guide = "📚 빠른 가이드",
    stats_title = "📊 통계 숫자",
    stats_1 = "   • 현재 프로젝트에서의 작업 수를 추적해요",
    stats_2 = "   • 클릭하면 활성 시간으로 바뀝니다",
    timer_title = "🍅 타이머",
    timer_1 = "   • 클릭해서 집중 세션을 시작하세요",
    timer_2 = "   • 우클릭하면 타이머 설정을 조정할 수 있어요",
    treasure_title = "🎁 보물상자",
    treasure_1 = "   • 집중 세션을 완료하면 나타나요",
    treasure_2 = "   • 클릭하면 코인을 받을 수 있어요!",
    coins_title = "💰 코인",
    coins_1 = "   • 집중 세션을 완료하면 코인을 얻어요",
    coins_2 = "   • 1분 집중 = 1 코인",
    coins_3 = "   • 하루에 최대 600 코인까지 얻을 수 있어요",
    shop_title = "🛒 상점",
    shop_1 = "   • 책상 오른쪽 버튼을 클릭하세요",
    shop_2 = "   • 코인으로 새로운 펫 스킨을 얻을 수 있어요",
    shop_3 = "   • 직접 구매하거나 블라인드 박스를 시도해보세요",
    settings_title = "⚙️ 설정",
    settings_1 = "   • 펫을 우클릭하면 설정을 열 수 있어요",
    settings_2 = "   • 외관과 기능을 조정할 수 있어요",
    bonus_title = "🎁 환영 선물: 500 코인!",
    bonus_subtitle = "지금 바로 첫 번째 동물 친구를 뽑을 수 있어요! ～",
    button = "알겠어요! 시작할게요"
  },
  ja = {
    title = "🎉 ReaPetへようこそ！",
    subtitle = "REAPERで一緒に過ごす動物の友達 ～",
    quick_guide = "📚 クイックガイド",
    stats_title = "📊 統計数字",
    stats_1 = "   • 現在のプロジェクトでの操作数を記録します",
    stats_2 = "   • クリックするとアクティブ時間に切り替わります",
    timer_title = "🍅 タイマー",
    timer_1 = "   • クリックして集中セッションを開始しましょう",
    timer_2 = "   • 右クリックでタイマーの設定を調整できます",
    treasure_title = "🎁 宝箱",
    treasure_1 = "   • 集中セッションを完了すると現れます",
    treasure_2 = "   • クリックするとコインがもらえます！",
    coins_title = "💰 コイン",
    coins_1 = "   • 集中セッションを完了するとコインがもらえます",
    coins_2 = "   • 1分の集中 = 1コイン",
    coins_3 = "   • 1日に最大600コインまで獲得できます",
    shop_title = "🛒 ショップ",
    shop_1 = "   • 机の右側のボタンをクリックしてください",
    shop_2 = "   • コインで新しいペットスキンを手に入れられます",
    shop_3 = "   • 直接購入するか、ブラインドボックスを試してみてください",
    settings_title = "⚙️ 設定",
    settings_1 = "   • ペットを右クリックすると設定が開きます",
    settings_2 = "   • 外観や機能を調整できます",
    bonus_title = "🎁 ウェルカムギフト: 500コイン！",
    bonus_subtitle = "今すぐ最初の動物の友達を抽選できます！～",
    button = "わかりました！始めましょう"
  }
}

-- 获取翻译
function WelcomeI18n.get(lang, key)
  lang = lang or "en"
  local t = translations[lang] or translations["en"]
  return t[key] or key
end

-- 获取所有支持的语言
function WelcomeI18n.get_languages()
  return {"en", "zh", "ko", "ja"}
end

-- 获取语言显示名称
function WelcomeI18n.get_language_name(lang)
  local names = {
    en = "English",
    zh = "中文",
    ko = "한국어",
    ja = "日本語"
  }
  return names[lang] or lang
end

return WelcomeI18n

