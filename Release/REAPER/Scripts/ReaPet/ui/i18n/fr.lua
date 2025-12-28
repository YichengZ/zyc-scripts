--[[
  REAPER Companion - French Language Pack
--]]

local translations = {
  -- Settings Window
  settings = {
    title = "Paramètres",
    tabs = {
      general = "Général",
      stats = "Statistiques",
      system = "Système"
    },
    general = {
      appearance = "Apparence",
      current_skin = "Peau actuelle: ",
      none = "Aucune",
      change_skin = "Changer de peau",
      modules = "Modules",
      show_stats_box = "Afficher la boîte de statistiques",
      stats_box_scale = "Échelle de la boîte de statistiques",
      offset_x = "Décalage X",
      offset_y = "Décalage Y",
      text_offset_x = "Décalage du texte X",
      text_offset_y = "Décalage du texte Y",
      reset_stats_box_defaults = "Réinitialiser les valeurs par défaut",
      show_pomodoro_timer = "Afficher le minuteur",
      timer_scale = "Échelle du minuteur",
      reset_timer_defaults = "Réinitialiser le minuteur",
      enable_treasure_box = "Activer le coffre au trésor",
      treasure_box_hint = "  (Les récompenses apparaissent après les sessions de concentration)",
      right_click_to_reset = "Clic droit pour réinitialiser",
      window_docking = "Ancrage de fenêtre",
      enable_docking = "Activer l'ancrage",
      docking_description = "Permettre à la fenêtre de s'ancrer à la fenêtre principale de REAPER.\nLorsqu'il est activé, la barre de titre apparaît et 'Toujours au premier plan' est supprimé.",
      docking_instruction = "Clic droit sur la barre de titre et sélectionnez 'Ancrer',\nou faites glisser la fenêtre vers les bords de REAPER pour ancrer.",
      docking_note = "Note: Lorsqu'elle est ancrée, la fenêtre fait partie de la fenêtre principale de REAPER.",
      window_docked_status = "État de la fenêtre: ",
      window_docked = "Ancrée",
      window_floating = "Flottante"
    },
    stats = {
      lifetime_stats = "Statistiques globales",
      label = "Étiquette",
      value = "Valeur",
      total_focus = "Concentration totale:",
      total_time = "Temps total:",
      operations = "Opérations:",
      economy = "Économie",
      balance = "Solde: ",
      today_earned = "Gagné aujourd'hui: ",
      manage_data = "Gérer les données",
      reset_daily_limit = "Réinitialiser la limite quotidienne"
    },
    system = {
      about = "À propos",
      version = "Version 1.0.4.3",
      language = "Langue",
      change_interface_language = "  Changer la langue de l'interface",
      instructions = "Instructions",
      show_instructions = "Afficher les instructions",
      view_instructions_again = "  Voir les instructions à nouveau",
      auto_start = "Démarrage automatique",
      auto_start_on_launch = "Exécuter automatiquement au démarrage de REAPER",
      auto_start_description = "  Exécuter ReaPet automatiquement au démarrage de REAPER",
      exit = "Quitter",
      close_companion = "Fermer le compagnon",
      exit_hint = "  Quitter le compagnon REAPER"
    }
  },
  -- Pomodoro Settings Window
  pomodoro_settings = {
    title = "Paramètres du minuteur",
    start = "Démarrer",
    skip = "Passer",
    preset = "Préréglage",
    save = "Enregistrer",
    confirm = "Confirmer",
    cancel = "Annuler",
    focus = "Concentration",
    short_break = "Pause courte",
    long_break = "Pause longue",
    auto_start_breaks = "Démarrer les pauses automatiquement",
    auto_start_focus = "Démarrer la concentration automatiquement",
    long_break_interval = "Intervalle de pause longue",
    focus_sessions = "sessions de concentration",
    time_format = "MM:SS",
    done = "Terminé"
  },
  -- Shop Window
  shop = {
    title = "Boutique de skins",
    unlock = "Déverrouiller",
    cost = "Coût",
    coins = "Pièces",
    insufficient_funds = "Fonds insuffisants",
    close = "Fermer",
    purchase = "Acheter",
    cancel = "Annuler",
    balance = "Solde",
    daily = "Quotidien",
    my_collection = "MA COLLECTION",
    shop = "BOUTIQUE",
    blind_box = "Boîte surprise"
  },
  -- Welcome Window
  welcome = {
    title = "🎉 Bienvenue dans ReaPet!",
    subtitle = "Votre petit compagnon dans REAPER ～",
    quick_guide = "📚 Guide rapide",
    stats_title = "📊 Boîte de statistiques",
    stats_1 = "   • Suit vos opérations dans ce projet",
    stats_2 = "   • Cliquez pour voir votre temps actif",
    timer_title = "🍅 Minuteur",
    timer_1 = "   • Cliquez pour démarrer une session de concentration",
    timer_2 = "   • Clic droit pour ajuster les paramètres",
    treasure_title = "🎁 Coffre au trésor",
    treasure_1 = "   • Apparaît après avoir terminé une session",
    treasure_2 = "   • Cliquez pour collecter vos pièces!",
    coins_title = "💰 Pièces",
    coins_1 = "   • Gagnez des pièces en terminant des sessions",
    coins_2 = "   • 1 minute de concentration = 1 pièce",
    coins_3 = "   • Vous pouvez gagner jusqu'à 600 pièces par jour",
    coins_4 = "   • Si vous atteignez la limite quotidienne, vous pouvez la réinitialiser dans Paramètres (Reposez-vous!)",
    shop_title = "🛒 Boutique",
    shop_1 = "   • Cliquez sur le bouton à droite du bureau",
    shop_2 = "   • Utilisez vos pièces pour obtenir de nouveaux skins",
    shop_3 = "   • Choisissez l'achat direct ou essayez la boîte surprise",
    settings_title = "⚙️ Paramètres",
    settings_1 = "   • Clic droit sur votre animal pour ouvrir les paramètres",
    settings_2 = "   • Ajustez l'apparence et le fonctionnement",
    bonus_title = "🎁 Cadeau de bienvenue: 500 pièces!",
    bonus_subtitle = "Vous pouvez obtenir votre premier ami animal tout de suite! ～",
    button = "Compris! Commençons"
  }
}

return translations
