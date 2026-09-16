extends Control

var titulo: Label
var subtitulo: Label
var status: Label
var painel: VBoxContainer
var log_box: RichTextLabel
var botoes_tabuleiro: Array[Button] = []
var selecao_slot := -1

func _ready() -> void:
    _montar_base()
    _mostrar_menu()

func _montar_base() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var fundo := ColorRect.new()
    fundo.color = Color("08101f")
    fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(fundo)

    var margem := MarginContainer.new()
    margem.add_theme_constant_override("margin_left", 28)
    margem.add_theme_constant_override("margin_right", 28)
    margem.add_theme_constant_override("margin_top", 42)
    margem.add_theme_constant_override("margin_bottom", 36)
    margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margem)

    var raiz := VBoxContainer.new()
    raiz.add_theme_constant_override("separation", 18)
    margem.add_child(raiz)

    titulo = Label.new()
    titulo.text = "BLACK OATH"
    titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    titulo.add_theme_font_size_override("font_size", 44)
    raiz.add_child(titulo)

    subtitulo = Label.new()
    subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitulo.add_theme_font_size_override("font_size", 19)
    subtitulo.modulate = Color("bfc7d8")
    raiz.add_child(subtitulo)

    status = Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size", 18)
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    raiz.add_child(status)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    raiz.add_child(scroll)

    painel = VBoxContainer.new()
    painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    painel.add_theme_constant_override("separation", 14)
    scroll.add_child(painel)

    log_box = RichTextLabel.new()
    log_box.custom_minimum_size = Vector2(0, 260)
    log_box.fit_content = false
    log_box.scroll_active = true
    log_box.bbcode_enabled = true
    log_box.visible = false
    raiz.add_child(log_box)

func _limpar_painel() -> void:
    for filho in painel.get_children():
        filho.queue_free()
    log_box.visible = false
    log_box.text = ""
    botoes_tabuleiro.clear()
    selecao_slot = -1

func _atualizar_status() -> void:
    status.text = "Vida %d/%d   •   Ouro %d   •   Determinação %d   •   Corrupção %d\nCiclo %d   •   Vitórias %d" % [GameState.vida, GameState.vida_maxima, GameState.ouro, GameState.determinacao, GameState.corrupcao, GameState.ciclo, GameState.vitorias]

func _botao(texto: String, acao: Callable) -> Button:
    var b := Button.new()
    b.text = texto
    b.custom_minimum_size = Vector2(0, 74)
    b.add_theme_font_size_override("font_size", 20)
    b.pressed.connect(acao)
    painel.add_child(b)
    return b

func _mostrar_menu() -> void:
    _limpar_painel()
    subtitulo.text = "Cada jornada cobra um preço."
    status.text = "Protótipo Godot v0.4"
    _botao("INICIAR JORNADA", _iniciar)
    _botao("SOBRE O PROTÓTIPO", func(): _mostrar_texto("Esta versão migra Black Oath para Godot 4 e GDScript. O núcleo já roda sem depender do HTML."))

func _mostrar_texto(texto: String) -> void:
    _limpar_painel()
    subtitulo.text = "Registro"
    status.text = texto
    _botao("VOLTAR", _mostrar_menu)

func _iniciar() -> void:
    GameState.nova_jornada()
    _mostrar_etapa()

func _mostrar_etapa() -> void:
    _limpar_painel()
    _atualizar_status()
    if GameState.determinacao <= 0:
        subtitulo.text = "Sua determinação acabou."
        _botao("NOVA JORNADA", _iniciar)
        return

    match GameState.etapa:
        "escolha": _mostrar_escolha()
        "cacada": _mostrar_cacada()
        "preparacao": _mostrar_preparacao()
        "duelo": _executar_duelo()

func _mostrar_escolha() -> void:
    subtitulo.text = "Escolha seu próximo passo"
    _botao("MERCADOR ERRANTE\nCompre uma oportunidade por 4 de Ouro", func(): _evento_mercador())
    _botao("FERREIRO\nFortaleça sua arma principal", func(): _evento_ferreiro())
    _botao("CAPELA ESQUECIDA\nReduza a Corrupção", func(): _evento_capela())

func _evento_mercador() -> void:
    if GameState.ouro >= 4:
        GameState.ouro -= 4
        var opcoes := ["segundo_coracao", "ampulheta_sem_areia", "corrente_ferro"]
        var id: String = opcoes.pick_random()
        if GameState.tabuleiro.size() < 4:
            GameState.tabuleiro.append(GameState.criar_item(id))
        else:
            GameState.tabuleiro[randi() % 4] = GameState.criar_item(id)
    GameState.proxima_etapa()
    _mostrar_etapa()

func _evento_ferreiro() -> void:
    var item: Dictionary = GameState.tabuleiro[0]
    item.dano = int(item.dano) + 5
    item.nivel = int(item.nivel) + 1
    GameState.proxima_etapa()
    _mostrar_etapa()

func _evento_capela() -> void:
    GameState.corrupcao = max(0, GameState.corrupcao - 12)
    GameState.vida = min(GameState.vida_maxima, GameState.vida + 8)
    GameState.proxima_etapa()
    _mostrar_etapa()

func _mostrar_cacada() -> void:
    subtitulo.text = "Caçada"
    _botao("RATO DE TÚMULO\nFácil • +4 Ouro", func(): _resolver_cacada(70, 4, 0))
    _botao("CAVALEIRO SEM ROSTO\nMédio • +7 Ouro", func(): _resolver_cacada(95, 7, 1))
    _botao("SANTO OCO\nDifícil • +10 Ouro • +5 Corrupção", func(): _resolver_cacada(120, 10, 5))

func _resolver_cacada(vida_inimigo: int, recompensa: int, corrupcao_extra: int) -> void:
    var inimigo := _build_inimigo(GameState.ciclo, vida_inimigo >= 100)
    var resultado := CombatSimulator.lutar(GameState.tabuleiro, inimigo, GameState.vida, vida_inimigo)
    if resultado.vitoria:
        GameState.ouro += recompensa
    else:
        GameState.vida = max(1, GameState.vida - 12)
    GameState.corrupcao += corrupcao_extra
    GameState.proxima_etapa()
    _mostrar_etapa()

func _mostrar_preparacao() -> void:
    subtitulo.text = "O Corvo retorna: reorganize seu tabuleiro"
    status.text += "\nInformação: o adversário usa uma mistura de dano e defesa."
    _mostrar_tabuleiro()
    _botao("INICIAR DUELO", func(): GameState.proxima_etapa(); _mostrar_etapa())

func _mostrar_tabuleiro() -> void:
    for idx in range(GameState.tabuleiro.size()):
        var item: Dictionary = GameState.tabuleiro[idx]
        var b := _botao("%d. %s\n%s" % [idx + 1, item.nome, item.descricao], func(i = idx): _selecionar_slot(i))
        botoes_tabuleiro.append(b)

func _selecionar_slot(idx: int) -> void:
    if selecao_slot < 0:
        selecao_slot = idx
        botoes_tabuleiro[idx].text = "◆ " + botoes_tabuleiro[idx].text
    elif selecao_slot == idx:
        _mostrar_preparacao()
    else:
        var temp: Dictionary = GameState.tabuleiro[selecao_slot]
        GameState.tabuleiro[selecao_slot] = GameState.tabuleiro[idx]
        GameState.tabuleiro[idx] = temp
        _mostrar_preparacao()

func _executar_duelo() -> void:
    _limpar_painel()
    _atualizar_status()
    subtitulo.text = "Duelo"
    var inimigo := _build_inimigo(GameState.ciclo, true)
    var resultado := CombatSimulator.lutar(GameState.tabuleiro, inimigo, GameState.vida, 100 + (GameState.ciclo - 1) * 10)

    log_box.visible = true
    var linhas: Array[String] = resultado.logs
    var inicio := max(0, linhas.size() - 16)
    log_box.text = "\n".join(linhas.slice(inicio))

    if resultado.vitoria:
        status.text += "\n\nVITÓRIA — você sobreviveu ao duelo."
    else:
        status.text += "\n\nDERROTA — sua Determinação foi ferida."
    GameState.concluir_duelo(resultado.vitoria)
    _botao("CONTINUAR", _mostrar_etapa)

func _build_inimigo(ciclo: int, forte: bool) -> Array[Dictionary]:
    var ids := ["lamina_desgastada", "corrente_ferro", "segundo_coracao", "ampulheta_sem_areia"]
    if forte:
        ids[1] = "estrela_adormecida"
    var build: Array[Dictionary] = []
    for id in ids:
        var item := GameState.criar_item(id)
        if ciclo >= 3 and int(item.dano) > 0:
            item.dano = int(item.dano) + (ciclo - 2) * 3
        build.append(item)
    return build
