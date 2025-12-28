--[[
  REAPER Companion - English Language Pack
--]]

local translations = {
  -- Settings Window
  settings = {
    title = "Settings",
    tabs = {
      general = "General",
      stats = "Stats",
      system = "System"
    },
    general = {
      appearance = "Appearance",
      current_skin = "Current Skin: ",
      none = "None",
      change_skin = "Change Skin",
      modules = "Modules",
      show_stats_box = "Show Stats Box",
      stats_box_scale = "Stats Box Scale",
      offset_x = "Offset X",
      offset_y = "Offset Y",
      text_offset_x = "Text Offset X",
      text_offset_y = "Text Offset Y",
      reset_stats_box_defaults = "Reset Stats Box Defaults",
      show_pomodoro_timer = "Show Pomodoro Timer",
      timer_scale = "Timer Scale",
      reset_timer_defaults = "Reset Timer Defaults",
      enable_treasure_box = "Enable Treasure Box",
      treasure_box_hint = "  (Rewards appear after focus sessions)",
      right_click_to_reset = "Right-click to reset",
      window_docking = "Window Docking",
      enable_docking = "Enable Docking",
      docking_description = "Allow window to dock to REAPER main window.\nWhen enabled, title bar appears and 'Always On Top' is removed.",
      docking_instruction = "Right-click title bar and select 'Dock',\nor drag window to REAPER edges to dock.",
      docking_note = "Note: When docked, window becomes part of REAPER main window.",
      window_docked_status = "Window Status: ",
      window_docked = "Docked",
      window_floating = "Floating"
    },
    stats = {
      lifetime_stats = "Lifetime Stats",
      label = "Label",
      value = "Value",
      total_focus = "Total Focus:",
      total_time = "Total Time:",
      operations = "Operations:",
      economy = "Economy",
      balance = "Balance: ",
      today_earned = "Today Earned: ",
      manage_data = "Manage Data",
      reset_daily_limit = "Reset Daily Limit"
    },
    system = {
      about = "About",
      version = "Version 1.0.4.3",
      language = "Language",
      change_interface_language = "  Change interface language",
      instructions = "Instructions",
      show_instructions = "Show Instructions",
      view_instructions_again = "  View instructions again",
      auto_start = "Auto-start",
      auto_start_on_launch = "Auto-start on REAPER launch",
      auto_start_description = "  Automatically run ReaPet when REAPER starts",
      startup_actions = "Startup Actions",
      open_startup_actions = "Open Startup Actions Settings",
      startup_actions_description = "  Configure commands to run automatically when REAPER starts",
      exit = "Exit",
      close_companion = "Close Companion",
      exit_hint = "  Exit the REAPER Companion"
    }
  },
  -- Pomodoro Settings Window
  pomodoro_settings = {
    title = "Timer Settings",
    start = "Start",
    skip = "Skip",
    preset = "Preset",
    save = "Save",
    confirm = "Confirm",
    cancel = "Cancel",
    focus = "Focus",
    short_break = "Short Break",
    long_break = "Long Break",
    auto_start_breaks = "Auto Start Breaks",
    auto_start_focus = "Auto Start Focus",
    long_break_interval = "Long Break Interval",
    focus_sessions = "focus sessions",
    time_format = "MM:SS",
    done = "Done"
  },
  -- Shop Window
  shop = {
    title = "Skin Shop",
    unlock = "Unlock",
    cost = "Cost",
    coins = "Coins",
    insufficient_funds = "Insufficient funds",
    close = "Close",
    purchase = "Purchase",
    cancel = "Cancel",
    balance = "Balance",
    daily = "Daily",
    my_collection = "MY COLLECTION",
    shop = "SHOP",
    blind_box = "Blind Box"
  },
  -- Welcome Window
  welcome = {
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
    coins_4 = "   • If you reach the daily limit, you can reset it in Settings (Take a rest!)",
    shop_title = "🛒 Shop",
    shop_1 = "   • Click the button on the right side of the desk",
    shop_2 = "   • Use your coins to get new pet skins",
    shop_3 = "   • Choose direct purchase or try the blind box",
    settings_title = "⚙️ Settings",
    settings_1 = "   • Right-click your pet to open settings",
    settings_2 = "   • Adjust how things look and work",
    startup_actions_title = "🚀 Startup Actions",
    startup_actions_1 = "   • Automatically run ReaPet when REAPER starts",
    startup_actions_2 = "   • Configure commands to run on REAPER launch",
    startup_actions_3 = "   • Click the button below to set it up",
    startup_actions_button = "Open Startup Actions Settings",
    bonus_title = "🎁 Welcome Gift: 500 Coins!",
    bonus_subtitle = "You can draw your first animal friend right away! ～",
    button = "Got it! Let's Start"
  }
}

return translations

