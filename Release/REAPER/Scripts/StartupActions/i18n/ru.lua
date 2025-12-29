local translations = {
  window = {
    title = "Действия при запуске",
    status_active = "Активно",
    status_inactive = "Не зарегистрировано",
    current_global_id = "Текущий глобальный ID: ",
    auto_save_hint = "Изменения сохраняются и регистрируются автоматически",
    default_actions = "Команды для запуска при старте REAPER",
    user_actions = "Пользовательские команды",
    drag_to_reorder = "(Перетащите для изменения порядка)",
    add_action = "Добавить команду для выполнения при запуске",
    delete = "Удалить",
    select_action = "Выберите действие в списке действий",
    cancel = "Отмена",
    open_action_list = "Открыть список действий",
    use_selected = "Использовать выбранное"
  },
  messages = {
    must_install_reaimgui = "Требуется расширение ReaImGui!",
    must_install_jsapi = "Требуется расширение js_ReaScriptAPI!\nПожалуйста, установите его из ReaPack.",
    invalid_action_id = "Неверный ID действия",
    config_load_failed = "Не удалось загрузить конфигурацию",
    action_already_exists = "Действие уже существует",
    save_config_failed = "Не удалось сохранить конфигурацию: ",
    action_added = "Действие успешно добавлено",
    action_exists = "Это действие уже существует.",
    cannot_get_runner_id = "Не удалось получить ID Runner",
    please_install_sws = "Пожалуйста, установите последнюю версию расширения SWS!",
    startup_set = "Действие при запуске установлено!\nТекущий запуск: ",
    will_replace_startup = "Это изменит вашу глобальную стартовую команду SWS.\n\n",
    your_current_startup = "Ваша текущая глобальная стартовая команда:\n",
    none = "(Нет)",
    click_ok_to_continue = "Нажмите OK, чтобы продолжить.",
    setup_complete = "✅ Настройка завершена!",
    action_list_not_found = "Список действий не найден, пожалуйста, нажмите на область списка действий",
    no_selection = "Выбор не обнаружен",
    cannot_read_command_id = "Не удалось прочитать ID команды",
    cannot_resolve_action_id = "Не удалось разрешить ID действия: ",
    read_action_failed = "Не удалось прочитать действие: "
  }
}

return translations
