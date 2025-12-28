--[[
  REAPER Companion - Turkish Language Pack
--]]

local translations = {
  -- Settings Window
  settings = {
    title = "Ayarlar",
    tabs = {
      general = "Genel",
      stats = "İstatistikler",
      system = "Sistem"
    },
    general = {
      appearance = "Görünüm",
      current_skin = "Mevcut görünüm: ",
      none = "Yok",
      change_skin = "Görünümü değiştir",
      modules = "Modüller",
      show_stats_box = "İstatistik kutusunu göster",
      stats_box_scale = "İstatistik kutusu ölçeği",
      offset_x = "Ofset X",
      offset_y = "Ofset Y",
      text_offset_x = "Metin ofseti X",
      text_offset_y = "Metin ofseti Y",
      reset_stats_box_defaults = "Varsayılanları sıfırla",
      show_pomodoro_timer = "Zamanlayıcıyı göster",
      timer_scale = "Zamanlayıcı ölçeği",
      reset_timer_defaults = "Zamanlayıcıyı sıfırla",
      enable_treasure_box = "Hazine kutusunu etkinleştir",
      treasure_box_hint = "  (Ödüller odaklanma oturumlarından sonra görünür)",
      right_click_to_reset = "Sıfırlamak için sağ tıklayın",
      window_docking = "Pencere yerleştirme",
      enable_docking = "Yerleştirmeyi etkinleştir",
      docking_description = "Pencereyi REAPER ana penceresine yerleştirmeye izin ver.\nEtkinleştirildiğinde, başlık çubuğu görünür ve 'Her Zaman Üstte' kaldırılır.",
      docking_instruction = "Başlık çubuğuna sağ tıklayın ve 'Yerleştir'i seçin,\nveya pencereyi REAPER kenarlarına sürükleyerek yerleştirin.",
      docking_note = "Not: Yerleştirildiğinde, pencere REAPER ana penceresinin bir parçası haline gelir.",
      window_docked_status = "Pencere durumu: ",
      window_docked = "Yerleştirilmiş",
      window_floating = "Yüzen"
    },
    stats = {
      lifetime_stats = "Yaşam boyu istatistikler",
      label = "Etiket",
      value = "Değer",
      total_focus = "Toplam odaklanma:",
      total_time = "Toplam süre:",
      operations = "İşlemler:",
      economy = "Ekonomi",
      balance = "Bakiye: ",
      today_earned = "Bugün kazanılan: ",
      manage_data = "Verileri yönet",
      reset_daily_limit = "Günlük limiti sıfırla"
    },
    system = {
      about = "Hakkında",
      version = "Sürüm 1.0.3",
      language = "Dil",
      change_interface_language = "  Arayüz dilini değiştir",
      instructions = "Talimatlar",
      show_instructions = "Talimatları göster",
      view_instructions_again = "  Talimatları tekrar görüntüle",
      auto_start = "Otomatik başlatma",
      auto_start_on_launch = "REAPER başlatıldığında otomatik çalıştır",
      auto_start_description = "  REAPER başlatıldığında ReaPet'i otomatik çalıştır",
      exit = "Çıkış",
      close_companion = "Yoldaşı kapat",
      exit_hint = "  REAPER yoldaşından çık"
    }
  },
  -- Pomodoro Settings Window
  pomodoro_settings = {
    title = "Zamanlayıcı ayarları",
    start = "Başlat",
    skip = "Atla",
    preset = "Ön ayar",
    save = "Kaydet",
    confirm = "Onayla",
    cancel = "İptal",
    focus = "Odaklanma",
    short_break = "Kısa mola",
    long_break = "Uzun mola",
    auto_start_breaks = "Molaları otomatik başlat",
    auto_start_focus = "Odaklanmayı otomatik başlat",
    long_break_interval = "Uzun mola aralığı",
    focus_sessions = "odaklanma oturumları",
    time_format = "DD:SS",
    done = "Tamamlandı"
  },
  -- Shop Window
  shop = {
    title = "Görünüm mağazası",
    unlock = "Kilidi aç",
    cost = "Maliyet",
    coins = "Jetonlar",
    insufficient_funds = "Yetersiz bakiye",
    close = "Kapat",
    purchase = "Satın al",
    cancel = "İptal",
    balance = "Bakiye",
    daily = "Günlük",
    my_collection = "KOLEKSİYONUM",
    shop = "MAĞAZA",
    blind_box = "Sürpriz kutu"
  },
  -- Welcome Window
  welcome = {
    title = "🎉 ReaPet'e hoş geldiniz!",
    subtitle = "REAPER'daki küçük yoldaşınız ～",
    quick_guide = "📚 Hızlı kılavuz",
    stats_title = "📊 İstatistik kutusu",
    stats_1 = "   • Bu projedeki işlemlerinizi takip eder",
    stats_2 = "   • Aktif zamanınızı görmek için tıklayın",
    timer_title = "🍅 Zamanlayıcı",
    timer_1 = "   • Bir odaklanma oturumu başlatmak için tıklayın",
    timer_2 = "   • Zamanlayıcı ayarlarını düzenlemek için sağ tıklayın",
    treasure_title = "🎁 Hazine kutusu",
    treasure_1 = "   • Bir oturumu tamamladıktan sonra görünür",
    treasure_2 = "   • Jetonlarınızı toplamak için tıklayın!",
    coins_title = "💰 Jetonlar",
    coins_1 = "   • Oturumları tamamlayarak jeton kazanın",
    coins_2 = "   • 1 dakika odaklanma = 1 jeton",
    coins_3 = "   • Günde 600 jeton kazanabilirsiniz",
    coins_4 = "   • Günlük limite ulaşırsanız, Ayarlar'da sıfırlayabilirsiniz (Dinlenin!)",
    shop_title = "🛒 Mağaza",
    shop_1 = "   • Masanın sağ tarafındaki düğmeye tıklayın",
    shop_2 = "   • Yeni görünümler almak için jetonlarınızı kullanın",
    shop_3 = "   • Doğrudan satın almayı seçin veya sürpriz kutusunu deneyin",
    settings_title = "⚙️ Ayarlar",
    settings_1 = "   • Ayarları açmak için evcil hayvanınıza sağ tıklayın",
    settings_2 = "   • Görünümü ve işleyişi ayarlayın",
    bonus_title = "🎁 Hoş geldin hediyesi: 500 jeton!",
    bonus_subtitle = "İlk hayvan arkadaşınızı hemen alabilirsiniz! ～",
    button = "Anladım! Başlayalım"
  }
}

return translations
