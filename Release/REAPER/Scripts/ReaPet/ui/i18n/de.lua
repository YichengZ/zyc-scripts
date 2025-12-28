--[[
  REAPER Companion - German Language Pack
--]]

local translations = {
  -- Settings Window
  settings = {
    title = "Einstellungen",
    tabs = {
      general = "Allgemein",
      stats = "Statistiken",
      system = "System"
    },
    general = {
      appearance = "Aussehen",
      current_skin = "Aktuelles Skin: ",
      none = "Keines",
      change_skin = "Skin ändern",
      modules = "Module",
      show_stats_box = "Statistik-Box anzeigen",
      stats_box_scale = "Statistik-Box Skalierung",
      offset_x = "Versatz X",
      offset_y = "Versatz Y",
      text_offset_x = "Text-Versatz X",
      text_offset_y = "Text-Versatz Y",
      reset_stats_box_defaults = "Standardwerte zurücksetzen",
      show_pomodoro_timer = "Timer anzeigen",
      timer_scale = "Timer-Skalierung",
      reset_timer_defaults = "Timer zurücksetzen",
      enable_treasure_box = "Schatzkiste aktivieren",
      treasure_box_hint = "  (Belohnungen erscheinen nach Fokus-Sitzungen)",
      right_click_to_reset = "Rechtsklick zum Zurücksetzen",
      window_docking = "Fenster-Docking",
      enable_docking = "Docking aktivieren",
      docking_description = "Fenster am REAPER-Hauptfenster andocken lassen.\nWenn aktiviert, erscheint die Titelleiste und 'Immer im Vordergrund' wird entfernt.",
      docking_instruction = "Rechtsklick auf die Titelleiste und 'Andocken' auswählen,\noder Fenster zu REAPER-Rändern ziehen, um anzudocken.",
      docking_note = "Hinweis: Wenn angedockt, wird das Fenster Teil des REAPER-Hauptfensters.",
      window_docked_status = "Fensterstatus: ",
      window_docked = "Angedockt",
      window_floating = "Schwebend"
    },
    stats = {
      lifetime_stats = "Lebenszeit-Statistiken",
      label = "Bezeichnung",
      value = "Wert",
      total_focus = "Gesamtfokus:",
      total_time = "Gesamtzeit:",
      operations = "Operationen:",
      economy = "Wirtschaft",
      balance = "Guthaben: ",
      today_earned = "Heute verdient: ",
      manage_data = "Daten verwalten",
      reset_daily_limit = "Tageslimit zurücksetzen"
    },
    system = {
      about = "Über",
      version = "Version 1.0.4.1",
      language = "Sprache",
      change_interface_language = "  Interface-Sprache ändern",
      instructions = "Anleitung",
      show_instructions = "Anleitung anzeigen",
      view_instructions_again = "  Anleitung erneut anzeigen",
      auto_start = "Automatischer Start",
      auto_start_on_launch = "Beim Start von REAPER automatisch ausführen",
      auto_start_description = "  ReaPet beim Start von REAPER automatisch ausführen",
      exit = "Beenden",
      close_companion = "Begleiter schließen",
      exit_hint = "  REAPER-Begleiter beenden"
    }
  },
  -- Pomodoro Settings Window
  pomodoro_settings = {
    title = "Timer-Einstellungen",
    start = "Starten",
    skip = "Überspringen",
    preset = "Voreinstellung",
    save = "Speichern",
    confirm = "Bestätigen",
    cancel = "Abbrechen",
    focus = "Fokus",
    short_break = "Kurze Pause",
    long_break = "Lange Pause",
    auto_start_breaks = "Pausen automatisch starten",
    auto_start_focus = "Fokus automatisch starten",
    long_break_interval = "Intervall für lange Pause",
    focus_sessions = "Fokus-Sitzungen",
    time_format = "MM:SS",
    done = "Fertig"
  },
  -- Shop Window
  shop = {
    title = "Skin-Shop",
    unlock = "Freischalten",
    cost = "Kosten",
    coins = "Münzen",
    insufficient_funds = "Unzureichende Mittel",
    close = "Schließen",
    purchase = "Kaufen",
    cancel = "Abbrechen",
    balance = "Guthaben",
    daily = "Täglich",
    my_collection = "MEINE SAMMLUNG",
    shop = "SHOP",
    blind_box = "Überraschungsbox"
  },
  -- Welcome Window
  welcome = {
    title = "🎉 Willkommen bei ReaPet!",
    subtitle = "Dein kleiner Begleiter in REAPER ～",
    quick_guide = "📚 Schnellanleitung",
    stats_title = "📊 Statistik-Box",
    stats_1 = "   • Verfolgt deine Operationen in diesem Projekt",
    stats_2 = "   • Klicke, um deine aktive Zeit zu sehen",
    timer_title = "🍅 Timer",
    timer_1 = "   • Klicke, um eine Fokus-Sitzung zu starten",
    timer_2 = "   • Rechtsklick, um die Timer-Einstellungen anzupassen",
    treasure_title = "🎁 Schatzkiste",
    treasure_1 = "   • Erscheint nach Abschluss einer Sitzung",
    treasure_2 = "   • Klicke, um deine Münzen zu sammeln!",
    coins_title = "💰 Münzen",
    coins_1 = "   • Verdiene Münzen durch Abschluss von Sitzungen",
    coins_2 = "   • 1 Minute Fokus = 1 Münze",
    coins_3 = "   • Du kannst bis zu 600 Münzen pro Tag verdienen",
    coins_4 = "   • Wenn du das Tageslimit erreichst, kannst du es in den Einstellungen zurücksetzen (Ruhe dich aus!)",
    shop_title = "🛒 Shop",
    shop_1 = "   • Klicke auf die Schaltfläche rechts am Schreibtisch",
    shop_2 = "   • Verwende deine Münzen, um neue Pet-Skins zu erhalten",
    shop_3 = "   • Wähle Direktkauf oder probiere die Überraschungsbox",
    settings_title = "⚙️ Einstellungen",
    settings_1 = "   • Rechtsklick auf dein Pet, um Einstellungen zu öffnen",
    settings_2 = "   • Passe Aussehen und Funktionsweise an",
    bonus_title = "🎁 Willkommensgeschenk: 500 Münzen!",
    bonus_subtitle = "Du kannst sofort deinen ersten Tierfreund ziehen! ～",
    button = "Verstanden! Los geht's"
  }
}

return translations
