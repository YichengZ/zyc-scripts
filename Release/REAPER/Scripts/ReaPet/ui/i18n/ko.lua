--[[
  REAPER Companion - 한국어 언어 팩
--]]

local translations = {
  -- Settings Window
  settings = {
    title = "설정",
    tabs = {
      general = "일반",
      stats = "통계",
      system = "시스템"
    },
    general = {
      appearance = "외관",
      current_skin = "현재 스킨: ",
      none = "없음",
      change_skin = "스킨 변경",
      modules = "모듈",
      show_stats_box = "통계 상자 표시",
      stats_box_scale = "통계 상자 크기",
      offset_x = "X 오프셋",
      offset_y = "Y 오프셋",
      text_offset_x = "텍스트 X 오프셋",
      text_offset_y = "텍스트 Y 오프셋",
      reset_stats_box_defaults = "통계 상자 기본값 재설정",
      show_pomodoro_timer = "포모도로 타이머 표시",
      timer_scale = "타이머 크기",
      reset_timer_defaults = "타이머 기본값 재설정",
      enable_treasure_box = "보물상자 활성화",
      treasure_box_hint = "  (집중 세션 완료 후 보상이 나타납니다)",
      right_click_to_reset = "우클릭하여 재설정",
      window_docking = "창 도킹",
      enable_docking = "도킹 활성화",
      docking_description = "REAPER 메인 창에 창을 도킹할 수 있습니다.\n활성화 시 제목 표시줄이 나타나고 '항상 위'가 제거됩니다.",
      docking_instruction = "제목 표시줄을 우클릭하고 '도킹'을 선택하거나,\n창을 REAPER 가장자리로 끌어 도킹합니다.",
      docking_note = "참고: 도킹되면 창이 REAPER 메인 창의 일부가 됩니다.",
      window_docked_status = "창 상태: ",
      window_docked = "도킹됨",
      window_floating = "플로팅"
    },
    stats = {
      lifetime_stats = "평생 통계",
      label = "레이블",
      value = "값",
      total_focus = "총 집중 시간:",
      total_time = "총 시간:",
      operations = "작업 횟수:",
      economy = "경제",
      balance = "잔액: ",
      today_earned = "오늘 획득: ",
      manage_data = "데이터 관리",
      reset_daily_limit = "일일 한도 재설정"
    },
    system = {
      about = "정보",
      version = "Version 1.0.4.3",
      language = "언어",
      change_interface_language = "  인터페이스 언어 변경",
      instructions = "설명",
      show_instructions = "설명 보기",
      view_instructions_again = "  설명 다시 보기",
      auto_start = "자동 시작",
      auto_start_on_launch = "REAPER 시작 시 자동 실행",
      auto_start_description = "  REAPER 시작 시 ReaPet 자동 실행",
      exit = "종료",
      close_companion = "컴패니언 닫기",
      exit_hint = "  REAPER 컴패니언 종료"
    }
  },
  -- Pomodoro Settings Window
  pomodoro_settings = {
    title = "타이머 설정",
    start = "시작",
    skip = "건너뛰기",
    preset = "프리셋",
    save = "저장",
    confirm = "확인",
    cancel = "취소",
    focus = "집중",
    short_break = "짧은 휴식",
    long_break = "긴 휴식",
    auto_start_breaks = "자동 휴식 시작",
    auto_start_focus = "자동 집중 시작",
    long_break_interval = "긴 휴식 간격",
    focus_sessions = "집중 세션",
    time_format = "MM:SS",
    done = "완료"
  },
  -- Shop Window
  shop = {
    title = "스킨 상점",
    unlock = "잠금 해제",
    cost = "가격",
    coins = "코인",
    insufficient_funds = "잔액 부족",
    close = "닫기",
    purchase = "구매",
    cancel = "취소",
    balance = "잔액",
    daily = "오늘",
    my_collection = "내 컬렉션",
    shop = "상점",
    blind_box = "블라인드 박스"
  },
  -- Welcome Window
  welcome = {
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
    coins_4 = "   • 일일 한도에 도달하면 설정에서 리셋할 수 있어요 (휴식을 취하세요!)",
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
  }
}

return translations

