--[[
  REAPER Companion - Portuguese Language Pack
--]]

local translations = {
  -- Settings Window
  settings = {
    title = "Configurações",
    tabs = {
      general = "Geral",
      stats = "Estatísticas",
      system = "Sistema"
    },
    general = {
      appearance = "Aparência",
      current_skin = "Pele atual: ",
      none = "Nenhuma",
      change_skin = "Trocar pele",
      modules = "Módulos",
      show_stats_box = "Mostrar caixa de estatísticas",
      stats_box_scale = "Escala da caixa de estatísticas",
      offset_x = "Deslocamento X",
      offset_y = "Deslocamento Y",
      text_offset_x = "Deslocamento de texto X",
      text_offset_y = "Deslocamento de texto Y",
      reset_stats_box_defaults = "Redefinir padrões",
      show_pomodoro_timer = "Mostrar temporizador",
      timer_scale = "Escala do temporizador",
      reset_timer_defaults = "Redefinir temporizador",
      enable_treasure_box = "Habilitar caixa do tesouro",
      treasure_box_hint = "  (Recompensas aparecem após sessões de foco)",
      right_click_to_reset = "Clique direito para redefinir",
      window_docking = "Encaixe de janela",
      enable_docking = "Habilitar encaixe",
      docking_description = "Permitir que a janela se encaixe na janela principal do REAPER.\nQuando habilitado, a barra de título aparece e 'Sempre no topo' é removido.",
      docking_instruction = "Clique com o botão direito na barra de título e selecione 'Encaixar',\nou arraste a janela para as bordas do REAPER para encaixar.",
      docking_note = "Nota: Quando encaixada, a janela se torna parte da janela principal do REAPER.",
      window_docked_status = "Status da janela: ",
      window_docked = "Encaixada",
      window_floating = "Flutuante"
    },
    stats = {
      lifetime_stats = "Estatísticas gerais",
      label = "Rótulo",
      value = "Valor",
      total_focus = "Foco total:",
      total_time = "Tempo total:",
      operations = "Operações:",
      economy = "Economia",
      balance = "Saldo: ",
      today_earned = "Ganho hoje: ",
      manage_data = "Gerenciar dados",
      reset_daily_limit = "Redefinir limite diário"
    },
    system = {
      about = "Sobre",
      version = "Version 1.0.4.3",
      language = "Idioma",
      change_interface_language = "  Alterar idioma da interface",
      instructions = "Instruções",
      show_instructions = "Mostrar instruções",
      view_instructions_again = "  Ver instruções novamente",
      auto_start = "Inicialização automática",
      auto_start_on_launch = "Executar automaticamente ao iniciar REAPER",
      auto_start_description = "  Executar ReaPet automaticamente ao iniciar REAPER",
      reset_settings = "Redefinir configurações",
      reset_preferences = "Redefinir preferências",
      reset_preferences_description = "  Redefinir todas as configurações, exceto moedas e skins",
      factory_reset = "Redefinir para padrão de fábrica",
      factory_reset_description = "  Redefinir todas as configurações incluindo moedas e skins",
      reset_complete_title = "Redefinição concluída",
      reset_preferences_complete = "Preferências redefinidas para os padrões (moedas e skins preservados)",
      factory_reset_complete = "Todas as configurações redefinidas para os padrões de fábrica (incluindo moedas e skins)",
      factory_reset_complete_title = "Redefinição de fábrica concluída",
      exit = "Sair",
      close_companion = "Fechar ReaPet",
      exit_hint = "  Fechar ReaPet"
    }
  },
  -- Pomodoro Settings Window
  pomodoro_settings = {
    title = "Configurações do temporizador",
    start = "Iniciar",
    skip = "Pular",
    preset = "Predefinição",
    save = "Salvar",
    confirm = "Confirmar",
    cancel = "Cancelar",
    focus = "Foco",
    short_break = "Pausa curta",
    long_break = "Pausa longa",
    auto_start_breaks = "Iniciar pausas automaticamente",
    auto_start_focus = "Iniciar foco automaticamente",
    long_break_interval = "Intervalo de pausa longa",
    focus_sessions = "sessões de foco",
    time_format = "MM:SS",
    done = "Concluído"
  },
  -- Shop Window
  shop = {
    title = "Loja de peles",
    unlock = "Desbloquear",
    cost = "Custo",
    coins = "Moedas",
    insufficient_funds = "Fundos insuficientes",
    close = "Fechar",
    purchase = "Comprar",
    cancel = "Cancelar",
    balance = "Saldo",
    daily = "Diário",
    my_collection = "MINHA COLEÇÃO",
    shop = "LOJA",
    blind_box = "Caixa surpresa"
  },
  -- Welcome Window
  welcome = {
    title = "🎉 Bem-vindo ao ReaPet!",
    subtitle = "Seu pequeno companheiro no REAPER ～",
    quick_guide = "📚 Guia rápido",
    stats_title = "📊 Caixa de estatísticas",
    stats_1 = "   • Rastreia suas operações neste projeto",
    stats_2 = "   • Clique para ver seu tempo ativo",
    timer_title = "🍅 Temporizador",
    timer_1 = "   • Clique para iniciar uma sessão de foco",
    timer_2 = "   • Clique direito para ajustar as configurações",
    treasure_title = "🎁 Caixa do tesouro",
    treasure_1 = "   • Aparece após completar uma sessão",
    treasure_2 = "   • Clique para coletar suas moedas!",
    coins_title = "💰 Moedas",
    coins_1 = "   • Ganhe moedas completando sessões",
    coins_2 = "   • 1 minuto de foco = 1 moeda",
    coins_3 = "   • Você pode ganhar até 600 moedas por dia",
    coins_4 = "   • Se atingir o limite diário, pode redefini-lo em Configurações (Descanse!)",
    shop_title = "🛒 Loja",
    shop_1 = "   • Clique no botão do lado direito da mesa",
    shop_2 = "   • Use suas moedas para obter novas peles",
    shop_3 = "   • Escolha compra direta ou experimente a caixa surpresa",
    settings_title = "⚙️ Configurações",
    settings_1 = "   • Clique direito no seu animal para abrir configurações",
    settings_2 = "   • Ajuste como as coisas aparecem e funcionam",
    bonus_title = "🎁 Presente de boas-vindas: 500 moedas!",
    bonus_subtitle = "Você pode obter seu primeiro amigo animal agora mesmo! ～",
    button = "Entendi! Vamos começar"
  }
}

return translations
