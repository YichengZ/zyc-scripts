--[[
  REAPER Companion - Indonesian Language Pack
--]]

local translations = {
  -- Settings Window
  settings = {
    title = "Pengaturan",
    tabs = {
      general = "Umum",
      stats = "Statistik",
      system = "Sistem"
    },
    general = {
      appearance = "Tampilan",
      current_skin = "Skin saat ini: ",
      none = "Tidak ada",
      change_skin = "Ubah skin",
      modules = "Modul",
      show_stats_box = "Tampilkan kotak statistik",
      stats_box_scale = "Skala kotak statistik",
      offset_x = "Offset X",
      offset_y = "Offset Y",
      text_offset_x = "Offset teks X",
      text_offset_y = "Offset teks Y",
      reset_stats_box_defaults = "Reset ke default",
      show_pomodoro_timer = "Tampilkan timer",
      timer_scale = "Skala timer",
      reset_timer_defaults = "Reset timer",
      enable_treasure_box = "Aktifkan kotak harta",
      treasure_box_hint = "  (Hadiah muncul setelah sesi fokus)",
      right_click_to_reset = "Klik kanan untuk reset",
      window_docking = "Docking jendela",
      enable_docking = "Aktifkan docking",
      docking_description = "Izinkan jendela untuk terhubung ke jendela utama REAPER.\nSaat diaktifkan, bilah judul muncul dan 'Selalu di Atas' dihapus.",
      docking_instruction = "Klik kanan pada bilah judul dan pilih 'Dock',\natau seret jendela ke tepi REAPER untuk menghubungkan.",
      docking_note = "Catatan: Saat terhubung, jendela menjadi bagian dari jendela utama REAPER.",
      window_docked_status = "Status jendela: ",
      window_docked = "Terhubung",
      window_floating = "Mengambang"
    },
    stats = {
      lifetime_stats = "Statistik seumur hidup",
      label = "Label",
      value = "Nilai",
      total_focus = "Total fokus:",
      total_time = "Total waktu:",
      operations = "Operasi:",
      economy = "Ekonomi",
      balance = "Saldo: ",
      today_earned = "Diperoleh hari ini: ",
      manage_data = "Kelola data",
      reset_daily_limit = "Reset batas harian"
    },
    system = {
      about = "Tentang",
      version = "Version 1.0.4.3",
      language = "Bahasa",
      change_interface_language = "  Ubah bahasa antarmuka",
      instructions = "Instruksi",
      show_instructions = "Tampilkan instruksi",
      view_instructions_again = "  Lihat instruksi lagi",
      auto_start = "Mulai otomatis",
      auto_start_on_launch = "Jalankan otomatis saat REAPER dimulai",
      auto_start_description = "  Jalankan ReaPet otomatis saat REAPER dimulai",
      exit = "Keluar",
      close_companion = "Tutup pendamping",
      exit_hint = "  Keluar dari pendamping REAPER"
    }
  },
  -- Pomodoro Settings Window
  pomodoro_settings = {
    title = "Pengaturan timer",
    start = "Mulai",
    skip = "Lewati",
    preset = "Prasetel",
    save = "Simpan",
    confirm = "Konfirmasi",
    cancel = "Batal",
    focus = "Fokus",
    short_break = "Istirahat pendek",
    long_break = "Istirahat panjang",
    auto_start_breaks = "Mulai istirahat otomatis",
    auto_start_focus = "Mulai fokus otomatis",
    long_break_interval = "Interval istirahat panjang",
    focus_sessions = "sesi fokus",
    time_format = "MM:SS",
    done = "Selesai"
  },
  -- Shop Window
  shop = {
    title = "Toko skin",
    unlock = "Buka kunci",
    cost = "Biaya",
    coins = "Koin",
    insufficient_funds = "Dana tidak mencukupi",
    close = "Tutup",
    purchase = "Beli",
    cancel = "Batal",
    balance = "Saldo",
    daily = "Harian",
    my_collection = "KOLEKSI SAYA",
    shop = "TOKO",
    blind_box = "Kotak misteri"
  },
  -- Welcome Window
  welcome = {
    title = "🎉 Selamat datang di ReaPet!",
    subtitle = "Pendamping kecil Anda di REAPER ～",
    quick_guide = "📚 Panduan cepat",
    stats_title = "📊 Kotak statistik",
    stats_1 = "   • Melacak operasi Anda di proyek ini",
    stats_2 = "   • Klik untuk melihat waktu aktif Anda",
    timer_title = "🍅 Timer",
    timer_1 = "   • Klik untuk memulai sesi fokus",
    timer_2 = "   • Klik kanan untuk menyesuaikan pengaturan timer",
    treasure_title = "🎁 Kotak harta",
    treasure_1 = "   • Muncul setelah Anda menyelesaikan sesi",
    treasure_2 = "   • Klik untuk mengumpulkan koin Anda!",
    coins_title = "💰 Koin",
    coins_1 = "   • Dapatkan koin dengan menyelesaikan sesi",
    coins_2 = "   • 1 menit fokus = 1 koin",
    coins_3 = "   • Anda bisa mendapatkan hingga 600 koin per hari",
    coins_4 = "   • Jika mencapai batas harian, Anda bisa meresetnya di Pengaturan (Istirahatlah!)",
    shop_title = "🛒 Toko",
    shop_1 = "   • Klik tombol di sisi kanan meja",
    shop_2 = "   • Gunakan koin Anda untuk mendapatkan skin baru",
    shop_3 = "   • Pilih pembelian langsung atau coba kotak misteri",
    settings_title = "⚙️ Pengaturan",
    settings_1 = "   • Klik kanan pada hewan peliharaan Anda untuk membuka pengaturan",
    settings_2 = "   • Sesuaikan tampilan dan cara kerjanya",
    bonus_title = "🎁 Hadiah selamat datang: 500 koin!",
    bonus_subtitle = "Anda bisa mendapatkan teman hewan pertama Anda sekarang juga! ～",
    button = "Mengerti! Mari mulai"
  }
}

return translations
