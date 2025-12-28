--[[
  REAPER Companion - Vietnamese Language Pack
--]]

local translations = {
  -- Settings Window
  settings = {
    title = "Cài đặt",
    tabs = {
      general = "Chung",
      stats = "Thống kê",
      system = "Hệ thống"
    },
    general = {
      appearance = "Giao diện",
      current_skin = "Giao diện hiện tại: ",
      none = "Không có",
      change_skin = "Đổi giao diện",
      modules = "Mô-đun",
      show_stats_box = "Hiển thị hộp thống kê",
      stats_box_scale = "Tỷ lệ hộp thống kê",
      offset_x = "Độ lệch X",
      offset_y = "Độ lệch Y",
      text_offset_x = "Độ lệch văn bản X",
      text_offset_y = "Độ lệch văn bản Y",
      reset_stats_box_defaults = "Đặt lại mặc định",
      show_pomodoro_timer = "Hiển thị bộ hẹn giờ",
      timer_scale = "Tỷ lệ bộ hẹn giờ",
      reset_timer_defaults = "Đặt lại bộ hẹn giờ",
      enable_treasure_box = "Bật hộp kho báu",
      treasure_box_hint = "  (Phần thưởng xuất hiện sau các phiên tập trung)",
      right_click_to_reset = "Nhấp chuột phải để đặt lại",
      window_docking = "Gắn cửa sổ",
      enable_docking = "Bật gắn cửa sổ",
      docking_description = "Cho phép cửa sổ gắn vào cửa sổ chính của REAPER.\nKhi bật, thanh tiêu đề sẽ xuất hiện và 'Luôn ở trên cùng' sẽ bị loại bỏ.",
      docking_instruction = "Nhấp chuột phải vào thanh tiêu đề và chọn 'Gắn',\nhoặc kéo cửa sổ đến các cạnh của REAPER để gắn.",
      docking_note = "Lưu ý: Khi được gắn, cửa sổ trở thành một phần của cửa sổ chính REAPER.",
      window_docked_status = "Trạng thái cửa sổ: ",
      window_docked = "Đã gắn",
      window_floating = "Nổi"
    },
    stats = {
      lifetime_stats = "Thống kê tổng thể",
      label = "Nhãn",
      value = "Giá trị",
      total_focus = "Tổng thời gian tập trung:",
      total_time = "Tổng thời gian:",
      operations = "Thao tác:",
      economy = "Kinh tế",
      balance = "Số dư: ",
      today_earned = "Kiếm được hôm nay: ",
      manage_data = "Quản lý dữ liệu",
      reset_daily_limit = "Đặt lại giới hạn hàng ngày"
    },
    system = {
      about = "Giới thiệu",
      version = "Phiên bản 1.0.3",
      language = "Ngôn ngữ",
      change_interface_language = "  Thay đổi ngôn ngữ giao diện",
      instructions = "Hướng dẫn",
      show_instructions = "Hiển thị hướng dẫn",
      view_instructions_again = "  Xem lại hướng dẫn",
      auto_start = "Tự động khởi động",
      auto_start_on_launch = "Tự động chạy khi khởi động REAPER",
      auto_start_description = "  Tự động chạy ReaPet khi khởi động REAPER",
      exit = "Thoát",
      close_companion = "Đóng bạn đồng hành",
      exit_hint = "  Thoát khỏi bạn đồng hành REAPER"
    }
  },
  -- Pomodoro Settings Window
  pomodoro_settings = {
    title = "Cài đặt bộ hẹn giờ",
    start = "Bắt đầu",
    skip = "Bỏ qua",
    preset = "Cài đặt sẵn",
    save = "Lưu",
    confirm = "Xác nhận",
    cancel = "Hủy",
    focus = "Tập trung",
    short_break = "Nghỉ ngắn",
    long_break = "Nghỉ dài",
    auto_start_breaks = "Tự động bắt đầu nghỉ",
    auto_start_focus = "Tự động bắt đầu tập trung",
    long_break_interval = "Khoảng thời gian nghỉ dài",
    focus_sessions = "phiên tập trung",
    time_format = "MM:SS",
    done = "Hoàn thành"
  },
  -- Shop Window
  shop = {
    title = "Cửa hàng giao diện",
    unlock = "Mở khóa",
    cost = "Chi phí",
    coins = "Xu",
    insufficient_funds = "Không đủ tiền",
    close = "Đóng",
    purchase = "Mua",
    cancel = "Hủy",
    balance = "Số dư",
    daily = "Hàng ngày",
    my_collection = "BỘ SƯU TẬP CỦA TÔI",
    shop = "CỬA HÀNG",
    blind_box = "Hộp bí ẩn"
  },
  -- Welcome Window
  welcome = {
    title = "🎉 Chào mừng đến với ReaPet!",
    subtitle = "Người bạn nhỏ của bạn trong REAPER ～",
    quick_guide = "📚 Hướng dẫn nhanh",
    stats_title = "📊 Hộp thống kê",
    stats_1 = "   • Theo dõi các thao tác của bạn trong dự án này",
    stats_2 = "   • Nhấp để xem thời gian hoạt động của bạn",
    timer_title = "🍅 Bộ hẹn giờ",
    timer_1 = "   • Nhấp để bắt đầu phiên tập trung",
    timer_2 = "   • Nhấp chuột phải để điều chỉnh cài đặt",
    treasure_title = "🎁 Hộp kho báu",
    treasure_1 = "   • Xuất hiện sau khi bạn hoàn thành phiên",
    treasure_2 = "   • Nhấp để thu thập xu của bạn!",
    coins_title = "💰 Xu",
    coins_1 = "   • Kiếm xu bằng cách hoàn thành phiên",
    coins_2 = "   • 1 phút tập trung = 1 xu",
    coins_3 = "   • Bạn có thể kiếm tối đa 600 xu mỗi ngày",
    coins_4 = "   • Nếu đạt giới hạn hàng ngày, bạn có thể đặt lại trong Cài đặt (Nghỉ ngơi!)",
    shop_title = "🛒 Cửa hàng",
    shop_1 = "   • Nhấp vào nút ở bên phải bàn làm việc",
    shop_2 = "   • Sử dụng xu của bạn để có giao diện mới",
    shop_3 = "   • Chọn mua trực tiếp hoặc thử hộp bí ẩn",
    settings_title = "⚙️ Cài đặt",
    settings_1 = "   • Nhấp chuột phải vào thú cưng của bạn để mở cài đặt",
    settings_2 = "   • Điều chỉnh giao diện và cách hoạt động",
    bonus_title = "🎁 Quà chào mừng: 500 xu!",
    bonus_subtitle = "Bạn có thể nhận ngay người bạn động vật đầu tiên! ～",
    button = "Hiểu rồi! Bắt đầu thôi"
  }
}

return translations
