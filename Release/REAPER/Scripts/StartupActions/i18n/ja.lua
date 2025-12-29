local translations = {
  window = {
    title = "起動時アクション",
    status_active = "有効",
    status_inactive = "未登録",
    current_global_id = "現在のグローバルID: ",
    auto_save_hint = "変更は自動的に保存・登録されます",
    default_actions = "REAPER起動時に実行するコマンド",
    user_actions = "ユーザーコマンド",
    drag_to_reorder = "(ドラッグして並べ替え)",
    add_action = "起動時に実行するコマンドを追加",
    delete = "削除",
    select_action = "アクションリストからアクションを選択してください",
    cancel = "キャンセル",
    open_action_list = "アクションリストを開く",
    use_selected = "選択を使用"
  },
  messages = {
    must_install_reaimgui = "ReaImGui拡張が必要です！",
    must_install_jsapi = "js_ReaScriptAPI拡張が必要です！\nReaPackからインストールしてください。",
    invalid_action_id = "無効なアクションID",
    config_load_failed = "設定の読み込みに失敗しました",
    action_already_exists = "アクションは既に存在します",
    save_config_failed = "設定の保存に失敗しました: ",
    action_added = "アクションが正常に追加されました",
    action_exists = "このアクションは既に存在します。",
    cannot_get_runner_id = "Runner IDを取得できません",
    please_install_sws = "最新のSWS拡張をインストールしてください！",
    startup_set = "起動アクションが設定されました！\n現在の起動: ",
    will_replace_startup = "これによりSWSのグローバル起動アクションが変更されます。\n\n",
    your_current_startup = "現在のグローバル起動アクションは:\n",
    none = "(なし)",
    click_ok_to_continue = "続行するにはOKをクリックしてください。",
    setup_complete = "✅ 設定完了！",
    action_list_not_found = "アクションリストが見つかりません。アクションリスト領域をクリックしてください",
    no_selection = "選択が検出されませんでした",
    cannot_read_command_id = "コマンドIDを読み取れません",
    cannot_resolve_action_id = "アクションIDを解決できません: ",
    read_action_failed = "アクションの読み取りに失敗しました: "
  }
}

return translations
