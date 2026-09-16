extends Control

const Jornada = preload("res://nucleo/jornada.gd")
const Salvar = preload("res://nucleo/salvamento.gd")
const Itens = preload("res://dados/itens.gd")
const Juramentos = preload("res://dados/juramentos.gd")
const Vinculos = preload("res://dados/vinculos.gd")
const Inimigos = preload("res://dados/inimigos.gd")
const Bots = preload("res://nucleo/bots.gd")
const Corrupcao = preload("res://nucleo/corrupcao.gd")
const Grade = preload("res://nucleo/tabuleiro.gd")
const Tema = preload("res://interface/tema.gd")
const Espaco = preload("res://interface/espaco_item.gd")
const Sons = preload("res://audio/sons.gd")

var jornada: Jornada = Jornada.new()
var sons: Sons = Sons.new()
var conteudo: VBoxContainer
var rolagem: ScrollContainer
var rodape: HBoxContainer
var cabecalho: VBoxContainer
var marca: Label
var indicadores: Array[Label] = []
var ciclo_rotulo: Label
var sombra: ColorRect
var material_cenario: ShaderMaterial
var tela: String = "menu"
var carregada: bool = false
var selecionado: int = -1
var selecao_reserva: bool = false
var erro_salvamento: bool = false
var opcoes: Dictionary = {"musica": true, "efeitos": true, "movimento": true, "filtro": true}
var reproduzindo: bool = false
var tempo_batalha: float = 0.0
var velocidade: float = 1.0
var proximo_evento: int = 0
var quadros: Array = []
var eventos: Array = []
var relogio: Label
var registro: Label
var linhas_registro: Array[String] = []
var vidas: Array[Label] = []
var estados: Array[Label] = []
var barras_vida: Array[ProgressBar] = []
var cartas_batalha: Array = []
var resultado_caixa: VBoxContainer
var botao_velocidade: Button

func _ready() -> void:
	theme = Tema.criar()
	_montar_base()
	add_child(sons)
	_carregar_opcoes()
	var salvo: Dictionary = Salvar.carregar()
	carregada = jornada.importar(salvo) if not salvo.is_empty() else false
	_mostrar_menu()
	get_tree().auto_accept_quit = false
	# Captura/automação só existe em compilações de depuração, por argumento local.
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--captura"):
		_capturas.call_deferred()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if carregada:
			_salvar()
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if tela == "menu":
			get_tree().quit()
		elif tela == "batalha":
			_salvar()
			_mostrar_menu()
		else:
			_mostrar_menu() if not carregada else _mostrar_etapa()

func _montar_base() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cenario: TextureRect = TextureRect.new()
	cenario.texture = load("res://arte/caminho.png") as Texture2D
	cenario.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cenario.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cenario.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cenario.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_cenario = ShaderMaterial.new()
	material_cenario.shader = load("res://efeitos/passado.gdshader") as Shader
	cenario.material = material_cenario
	add_child(cenario)
	sombra = ColorRect.new()
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sombra)
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 16)
	margem.add_theme_constant_override("margin_right", 16)
	margem.add_theme_constant_override("margin_top", 20)
	margem.add_theme_constant_override("margin_bottom", 18)
	if OS.get_name() == "Android":
		var segura: Rect2i = DisplayServer.get_display_safe_area()
		var janela: Vector2i = DisplayServer.window_get_size()
		if janela.y > 0:
			var fator: float = get_viewport_rect().size.y / float(janela.y)
			margem.add_theme_constant_override("margin_top", maxi(20, int(float(segura.position.y) * fator) + 8))
			margem.add_theme_constant_override("margin_bottom", maxi(18, int(float(janela.y - segura.end.y) * fator) + 8))
	add_child(margem)
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	margem.add_child(coluna)
	marca = Tema.texto("BLACK OATH", 27, Tema.TEXTO, true)
	coluna.add_child(marca)
	cabecalho = VBoxContainer.new()
	cabecalho.add_theme_constant_override("separation", 8)
	coluna.add_child(cabecalho)
	var recursos: GridContainer = GridContainer.new()
	recursos.columns = 2
	recursos.add_theme_constant_override("separation", 6)
	cabecalho.add_child(recursos)
	for _indice: int in range(4):
		var painel: PanelContainer = PanelContainer.new()
		painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		painel.add_theme_stylebox_override("panel", Tema.caixa(Color(0.04, 0.06, 0.10, 0.93)))
		recursos.add_child(painel)
		var rotulo: Label = Tema.texto("", 17)
		painel.add_child(rotulo)
		indicadores.append(rotulo)
	ciclo_rotulo = Tema.texto("", 15, Tema.OURO)
	cabecalho.add_child(ciclo_rotulo)
	rolagem = ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.follow_focus = true
	coluna.add_child(rolagem)
	conteudo = VBoxContainer.new()
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_theme_constant_override("separation", 14)
	rolagem.add_child(conteudo)
	rodape = HBoxContainer.new()
	rodape.add_theme_constant_override("separation", 8)
	coluna.add_child(rodape)
	_botao("Tabuleiro", _mostrar_tabuleiro, rodape, 58)
	_botao("Regras", _mostrar_regras, rodape, 58)
	_botao("Menu", _mostrar_menu, rodape, 58)

func _limpar(nova_tela: String) -> void:
	reproduzindo = false
	tela = nova_tela
	conteudo.add_theme_constant_override("separation", 8 if nova_tela == "batalha" else 14)
	for filho: Node in conteudo.get_children():
		conteudo.remove_child(filho)
		filho.queue_free()
	vidas.clear()
	estados.clear()
	barras_vida.clear()
	cartas_batalha.clear()
	rolagem.scroll_vertical = 0
	marca.visible = nova_tela != "menu"
	cabecalho.visible = carregada and nova_tela in ["etapa", "rota", "tabuleiro", "ferreiro", "regras"]
	rodape.visible = carregada and nova_tela != "batalha" and nova_tela != "menu"
	sombra.color = Color(0.02, 0.03, 0.06, 0.72 if nova_tela != "menu" else 0.15)
	if cabecalho.visible:
		_atualizar_recursos()

func _atualizar_recursos() -> void:
	indicadores[0].text = "Vida  %d/%d" % [jornada.vida, jornada.vida_maxima]
	indicadores[1].text = "Ouro  %d" % jornada.ouro
	indicadores[2].text = "Determinação  %d/8" % jornada.determinacao
	indicadores[3].text = "Corrupção  %d" % jornada.corrupcao
	indicadores[1].add_theme_color_override("font_color", Tema.OURO)
	indicadores[3].add_theme_color_override("font_color", Tema.VERMELHO if jornada.corrupcao >= 50 else Tema.SUAVE)
	ciclo_rotulo.text = "Ciclo %d   ·   %d de %d vitórias   ·   %s" % [jornada.ciclo, jornada.vitorias, Jornada.META_VITORIAS, Corrupcao.nome(jornada.corrupcao)]

func _texto(texto: String, tamanho: int = 18, cor: Color = Tema.TEXTO, pai: Node = null, titulo: bool = false) -> Label:
	var rotulo: Label = Tema.texto(texto, tamanho, cor, titulo)
	(conteudo if pai == null else pai).add_child(rotulo)
	return rotulo

func _titulo(texto: String, subtitulo: String = "") -> void:
	_texto(texto, 27, Tema.TEXTO, null, true)
	if not subtitulo.is_empty():
		_texto(subtitulo, 17, Tema.SUAVE)

func _botao(texto: String, acao: Callable, pai: Node = null, altura: int = 64) -> Button:
	var botao: Button = Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(0, altura)
	botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao.add_theme_font_size_override("font_size", 18 if altura >= 64 else 16)
	botao.pressed.connect(func() -> void:
		sons.tocar("toque")
		acao.call()
	)
	(conteudo if pai == null else pai).add_child(botao)
	return botao

func _painel() -> VBoxContainer:
	var fundo: PanelContainer = PanelContainer.new()
	fundo.add_theme_stylebox_override("panel", Tema.caixa(Color(0.045, 0.067, 0.11, 0.95)))
	conteudo.add_child(fundo)
	var caixa: VBoxContainer = VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 10)
	fundo.add_child(caixa)
	return caixa

func _imagem(textura: Texture2D, altura: int, pai: Node = null) -> TextureRect:
	var imagem: TextureRect = TextureRect.new()
	imagem.texture = textura
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.custom_minimum_size = Vector2(0, altura)
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(conteudo if pai == null else pai).add_child(imagem)
	return imagem

func _espaco(altura: int) -> void:
	var espaco: Control = Control.new()
	espaco.custom_minimum_size.y = altura
	conteudo.add_child(espaco)

func _mostrar_menu() -> void:
	_limpar("menu")
	_espaco(25)
	_texto("BLACK\nOATH", 65, Color("dfd8c9"), null, true)
	_texto("CADA JORNADA COBRA UM PREÇO", 14, Tema.OURO)
	_espaco(160)
	if carregada and jornada.fase != "encerrada":
		_botao("Continuar jornada", _mostrar_etapa)
		_texto("Ciclo %d · %s" % [jornada.ciclo, jornada.etapa()], 16, Tema.SUAVE)
	_botao("Iniciar jornada" if not carregada else "Iniciar nova jornada", _mostrar_heroi)
	_botao("Configurações", _mostrar_configuracoes)
	_botao("Sair", func() -> void: get_tree().quit())
	_texto("v0.5 · O preço da promessa", 14, Tema.SUAVE)

func _mostrar_heroi() -> void:
	_limpar("heroi")
	rodape.visible = false
	_titulo("Escolha seu herói", "Uma promessa ainda pode mudar o destino.")
	_imagem(Tema.retrato(0), 200)
	_titulo("O Errante")
	_texto("100 de Vida · 10 de Ouro\n8 de Determinação · 0 de Corrupção", 18, Tema.OURO)
	var caixa: VBoxContainer = _painel()
	_texto("Improviso", 23, Tema.TEXTO, caixa, true)
	_texto("Na primeira aquisição de uma categoria nova em cada ciclo, recebe 2 de Ouro. Itens na reserva também contam.", 18, Tema.SUAVE, caixa)
	if carregada and jornada.fase != "encerrada":
		_texto("Começar substituirá a jornada salva.", 17, Tema.VERMELHO)
	_botao("Jurar e partir", _nova)
	_botao("Voltar", _mostrar_menu)

func _nova() -> void:
	jornada.nova()
	carregada = true
	_salvar()
	_mostrar_etapa()

func _mostrar_etapa() -> void:
	if not carregada:
		_mostrar_menu()
		return
	if not jornada.batalha.is_empty():
		_mostrar_batalha()
		return
	jornada.preparar_etapa()
	_salvar()
	_limpar("etapa")
	if not jornada.mensagem.is_empty():
		_texto(jornada.mensagem.strip_edges(), 16, Tema.OURO)
	if erro_salvamento:
		_texto("Não foi possível guardar a jornada neste aparelho.", 16, Tema.VERMELHO)
	match jornada.etapa():
		"Juramento": _juramentos()
		"Escolha": _caminhos()
		"Caçada": _cacada()
		"O Corvo": _corvo()
		"Preparação", "Duelo": _preparacao()
		"O Abismo": _abismo()
		"Caçada Final": _cacada_final()
		"Rei sem Sombra": _chefe()
		"Fim da jornada": _fim()

func _agir(acao: Callable) -> void:
	acao.call()
	_salvar()
	_mostrar_etapa()

func _juramentos() -> void:
	_titulo("O juramento", "Escolha um poder. Aceite um sacrifício.\nOs efeitos se acumulam durante a jornada.")
	for juramento: Dictionary in Juramentos.TODOS:
		var caixa: VBoxContainer = _painel()
		_imagem(Tema.icone(int(juramento["icone"])), 68, caixa)
		_texto(str(juramento["nome"]), 21, Tema.TEXTO, caixa, true)
		_texto(str(juramento["beneficio"]), 17, Tema.AZUL, caixa)
		_texto(str(juramento["sacrificio"]), 17, Tema.VERMELHO, caixa)
		var id: String = str(juramento["id"])
		_botao("Assumir juramento", func() -> void: _agir(func() -> void: jornada.jurar(id)), caixa)

func _caminhos() -> void:
	var numero: int = jornada.passo if jornada.passo < 3 else jornada.passo - 1
	_titulo("A encruzilhada", "Escolha %d de 4 · Só um caminho será seguido." % numero)
	for indice: int in range(jornada.caminhos.size()):
		var caminho: Dictionary = jornada.caminhos[indice]
		var caixa: VBoxContainer = _painel()
		var linha: HBoxContainer = HBoxContainer.new()
		caixa.add_child(linha)
		var imagem: TextureRect = _imagem(Tema.icone(int(caminho["icone"])), 68, linha)
		imagem.custom_minimum_size.x = 68
		var titulo: Label = _texto(str(caminho["nome"]), 21, Tema.TEXTO, linha, true)
		titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_texto(str(caminho["descricao"]), 17, Tema.SUAVE, caixa)
		if caminho.has("item"):
			var item: Dictionary = Itens.dados(caminho["item"])
			_texto("%s · %s" % [str(item["nome"]), str(item["raridade"])], 17, Tema.RARIDADES[int(item["nivel"])], caixa)
		_botao("Examinar caminho", _mostrar_rota.bind(indice), caixa)
	_botao("Seguir sem gastar", func() -> void: _agir(jornada.partir))

func _mostrar_rota(indice: int) -> void:
	_limpar("rota")
	var caminho: Dictionary = jornada.caminhos[indice]
	var tipo: String = str(caminho["tipo"])
	_titulo(str(caminho["nome"]))
	if not jornada.mensagem.is_empty():
		_texto(jornada.mensagem, 16, Tema.OURO)
	if tipo in ["mercador", "sangue"]:
		var instancia: Dictionary = caminho["item"]
		_detalhes_item(instancia)
		_botao("Comprar · %d de Ouro" % jornada.preco_mercador(instancia), _comprar.bind(indice, "ouro"))
		if tipo == "sangue":
			_botao("Sacrificar 8 de Vida Máxima", _comprar.bind(indice, "vida"))
			_botao("Aceitar +12 de Corrupção", _comprar.bind(indice, "corrupcao"))
			_texto("Escolha apenas uma forma de pagamento.", 16, Tema.SUAVE)
	elif tipo in ["reliquia", "familiar"]:
		var id: String = str(caminho["id"])
		var dados: Dictionary = Vinculos.RELIQUIAS[id] if tipo == "reliquia" else Vinculos.FAMILIARES[id]
		_imagem(Tema.icone(int(dados["icone"])), 180)
		_titulo(str(dados["nome"]), str(dados["descricao"]))
		_texto("Possui um espaço próprio. Ao adquirir, substitui o vínculo atual desse tipo.", 17, Tema.SUAVE)
		var preco: int = int(ceil(float(dados["preco"]) * float(Juramentos.modificadores(jornada.juramentos)["precos"])))
		_botao("Vincular · %d de Ouro" % preco, _comprar.bind(indice, "ouro"))
	elif tipo == "ferreiro":
		_texto("Escolha qual item melhorar. A propriedade nova acompanha sua função original.", 18, Tema.SUAVE)
		for posicao: int in range(jornada.tabuleiro.size()):
			_oferta_melhoria(posicao, false)
		for posicao: int in range(jornada.reserva.size()):
			_oferta_melhoria(posicao, true)
	elif tipo == "capela":
		_imagem(Tema.icone(13), 160)
		_texto(str(caminho["descricao"]), 19, Tema.SUAVE)
		if jornada.reliquia == "lua_negra":
			_texto("Lua Negra impede a Cura. A purificação ainda reduz Corrupção.", 18, Tema.VERMELHO)
		_botao("Pedir acolhimento", func() -> void: _agir(func() -> void: jornada.evento(indice)))
	elif tipo == "ruinas":
		_imagem(Tema.icone(11), 160)
		_texto("A vila está vazia. Ainda há moedas sob as pedras e abrigo entre as paredes.", 19, Tema.SUAVE)
		_botao("Recolher 4 de Ouro", func() -> void: _agir(func() -> void: jornada.evento(indice, "ouro")))
		_botao("Descansar · Cura 20", func() -> void: _agir(func() -> void: jornada.evento(indice, "descansar")))
	_botao("Voltar aos caminhos", _mostrar_etapa)

func _comprar(indice: int, pagamento: String) -> void:
	if jornada.comprar(indice, pagamento):
		_salvar()
		_mostrar_etapa()
	else:
		_mostrar_rota(indice)

func _oferta_melhoria(indice: int, na_reserva: bool) -> void:
	var lista: Array[Dictionary] = jornada.reserva if na_reserva else jornada.tabuleiro
	var instancia: Dictionary = lista[indice]
	if instancia.is_empty():
		return
	var item: Dictionary = Itens.dados(instancia)
	if int(item["nivel"]) >= 3:
		return
	var caixa: VBoxContainer = _painel()
	_imagem(Tema.icone(int(item["icone"])), 72, caixa)
	_texto(str(item["nome"]), 20, Tema.TEXTO, caixa, true)
	_texto(str(item["melhoria"]), 17, Tema.AZUL, caixa)
	_botao("Melhorar · %d de Ouro" % (4 + int(item["nivel"]) * 2), func() -> void: _agir(func() -> void: jornada.melhorar(indice, na_reserva)), caixa)

func _detalhes_item(instancia: Dictionary, pai: Node = null) -> void:
	var item: Dictionary = Itens.dados(instancia)
	_imagem(Tema.icone(int(item["icone"])), 112, pai)
	_texto(str(item["nome"]), 24, Tema.TEXTO, pai, true)
	_texto("%s · Recarga %.1f s" % [str(item["raridade"]), float(item["recarga"])], 17, Tema.RARIDADES[int(item["nivel"])], pai)
	_texto(" · ".join(item["categorias"]), 16, Tema.SUAVE, pai)
	_texto(Itens.descricao(instancia), 18, Tema.TEXTO, pai)

func _cacada() -> void:
	_titulo("A Caçada", "Mais perigo, mais recompensa.\nNa retirada, perde até 12 de Vida.")
	for indice: int in range(Inimigos.CACA.size()):
		var inimigo: Dictionary = Inimigos.CACA[indice]
		var caixa: VBoxContainer = _painel()
		_imagem(Tema.icone(15) if indice == 0 else Tema.retrato(5 if indice == 1 else 6), 95, caixa)
		_texto(str(inimigo["nome"]), 22, Tema.TEXTO, caixa, true)
		var faixa: int = Corrupcao.faixa(jornada.corrupcao)
		var ganho: int = int(inimigo["ouro"]) + int(Juramentos.modificadores(jornada.juramentos)["cacada"]) + (faixa if faixa >= 2 else 0)
		_texto("%s · +%d de Ouro · +%d de Corrupção" % [str(inimigo["risco"]), ganho, int(inimigo["corrupcao"])], 16, Tema.OURO, caixa)
		if indice == 2:
			_texto("Também entrega um item Raro ou melhor.", 17, Tema.AZUL, caixa)
		_botao("Iniciar Caçada", _iniciar_batalha.bind("cacada", indice), caixa)

func _corvo() -> void:
	_titulo("O Corvo", "Ele viu apenas fragmentos do que espera por você.")
	_imagem(Tema.icone(14), 190)
	for pista: String in Bots.espiar(jornada.adversario):
		var caixa: VBoxContainer = _painel()
		_texto(pista, 21, Tema.OURO, caixa)
	_texto("O restante continua oculto. Reorganize seus itens usando essas pistas.", 18, Tema.SUAVE)
	_botao("Preparar o tabuleiro", func() -> void: _agir(jornada.continuar_corvo))

func _preparacao() -> void:
	_titulo("Antes do Duelo", "O adversário já foi definido. Suas escolhas de posição ainda podem mudar a luta.")
	_texto("\n".join(Bots.espiar(jornada.adversario)), 18, Tema.OURO)
	_desenhar_grade(jornada.tabuleiro, 0, false)
	_texto("Toque em Tabuleiro para examinar, trocar, guardar ou vender itens.", 17, Tema.SUAVE)
	_vinculos()
	_botao("Enfrentar o adversário", _iniciar_batalha.bind("duelo", 0))
	_texto("Derrota: −2 de Determinação. Empate: −1.\nCada novo ciclo começa com sua Vida restaurada.", 16, Tema.SUAVE)

func _desenhar_grade(itens: Array, compacto: int, editavel: bool, lado: int = -1) -> Array:
	var grade: GridContainer = GridContainer.new()
	grade.columns = 4
	conteudo.add_child(grade)
	var cartas: Array = []
	for indice: int in range(8):
		var carta: Espaco = Espaco.new()
		carta.configurar(itens[indice], indice, compacto)
		carta.arrastavel = editavel
		if editavel:
			carta.pressed.connect(_selecionar.bind(indice, false))
			carta.mover.connect(_mover_arrastando)
			carta.selecionar(selecionado == indice and not selecao_reserva)
		else:
			if not (itens[indice] as Dictionary).is_empty():
				carta.pressed.connect(_popup_item.bind(itens[indice]))
		grade.add_child(carta)
		cartas.append(carta)
	if lado >= 0:
		cartas_batalha.append(cartas)
	return cartas

func _mostrar_tabuleiro() -> void:
	if not jornada.batalha.is_empty():
		return
	_limpar("tabuleiro")
	_titulo("Seu tabuleiro", "Toque em um item e depois no destino para trocar. Também pode arrastar entre espaços.")
	_desenhar_grade(jornada.tabuleiro, 0, true)
	_texto("A Vela afeta a direita na mesma linha.\nAs duas linhas possuem quatro espaços.", 16, Tema.OURO)
	if selecionado >= 0:
		var lista: Array[Dictionary] = jornada.reserva if selecao_reserva else jornada.tabuleiro
		if selecionado < lista.size() and not lista[selecionado].is_empty():
			var instancia: Dictionary = lista[selecionado]
			var caixa: VBoxContainer = _painel()
			_detalhes_item(instancia, caixa)
			if not selecao_reserva:
				_botao("Guardar na reserva", _guardar_selecionado, caixa)
			_botao("Vender · +%d de Ouro" % maxi(1, int(float(Itens.preco(instancia)) / 2.0)), _vender_selecionado, caixa)
			_botao("Cancelar seleção", _cancelar_selecao, caixa)
	if not jornada.reserva.is_empty():
		_texto("Reserva · %d/%d" % [jornada.reserva.size(), Grade.LIMITE_RESERVA], 23, Tema.TEXTO, null, true)
		_texto("Escolha um item da reserva e toque no destino do tabuleiro.", 17, Tema.SUAVE)
		for indice: int in range(jornada.reserva.size()):
			var item: Dictionary = Itens.dados(jornada.reserva[indice])
			_botao(("◆ " if selecionado == indice and selecao_reserva else "") + str(item["nome"]), _selecionar.bind(indice, true))
	_vinculos()
	_botao("Voltar à jornada", _mostrar_etapa)

func _selecionar(indice: int, na_reserva: bool) -> void:
	sons.tocar("toque")
	if selecionado >= 0 and not na_reserva:
		if selecao_reserva:
			jornada.equipar(selecionado, indice)
		else:
			jornada.trocar(selecionado, indice)
		selecionado = -1
		selecao_reserva = false
		_salvar()
	else:
		selecionado = indice
		selecao_reserva = na_reserva
	_mostrar_tabuleiro()

func _mover_arrastando(origem: int, destino: int) -> void:
	jornada.trocar(origem, destino)
	selecionado = -1
	_salvar()
	_mostrar_tabuleiro()

func _guardar_selecionado() -> void:
	jornada.guardar_item(selecionado)
	_cancelar_selecao()

func _vender_selecionado() -> void:
	jornada.vender(selecionado, selecao_reserva)
	_cancelar_selecao()

func _cancelar_selecao() -> void:
	selecionado = -1
	selecao_reserva = false
	_salvar()
	_mostrar_tabuleiro()

func _vinculos() -> void:
	var caixa: VBoxContainer = _painel()
	_texto("Vínculos", 21, Tema.TEXTO, caixa, true)
	for tipo: String in ["reliquia", "familiar"]:
		var id: String = jornada.reliquia if tipo == "reliquia" else jornada.familiar
		var titulo: String = "Relíquia" if tipo == "reliquia" else "Familiar"
		if id.is_empty():
			_texto(titulo + " · Nenhum", 17, Tema.SUAVE, caixa)
		else:
			var dados: Dictionary = Vinculos.RELIQUIAS[id] if tipo == "reliquia" else Vinculos.FAMILIARES[id]
			_imagem(Tema.icone(int(dados["icone"])), 62, caixa)
			_texto(str(dados["nome"]), 18, Tema.OURO, caixa)
			_texto(str(dados["descricao"]), 16, Tema.SUAVE, caixa)

func _abismo() -> void:
	_titulo("O Abismo", "Corrupção 100 · Perdido")
	_imagem(Tema.icone(11), 180)
	_texto("Você chegou longe demais para ser ignorado. Uma porta se abre onde nada deveria existir.", 20, Tema.SUAVE)
	_botao("Ceder 20 de Vida Máxima", func() -> void: _agir(func() -> void: jornada.resolver_abismo(true)))
	_texto("Recebe A Última Porta. Corrupção permanece em 100 e seus inimigos continuam mais perigosos.", 18, Tema.OURO)
	_botao("Resistir · −2 de Determinação", func() -> void: _agir(func() -> void: jornada.resolver_abismo(false)))
	_texto("Corrupção cai para 70. Se a Determinação acabar, a jornada termina.", 18, Tema.SUAVE)

func _cacada_final() -> void:
	_titulo("Caçada Final", "Quatro vitórias. Uma promessa ainda não foi paga.")
	_imagem(Tema.retrato(5), 210)
	_texto("A Sentinela do Limiar guarda o último caminho. Perder custa 2 de Determinação. Se sobreviver, você alcançará o Rei com a Vida restaurada.", 19, Tema.SUAVE)
	_botao("Atravessar o limiar", _iniciar_batalha.bind("final", 0))

func _chefe() -> void:
	_titulo("Rei sem Sombra", "O último devedor da noite")
	_imagem(Tema.retrato(7), 220)
	_texto("Toda terceira ativação de cada um dos seus itens é copiada pelo Rei. A cópia usa o efeito daquele item contra você.", 20, Tema.OURO)
	_texto("Acelerar tudo tem um preço. Você ainda pode reorganizar o tabuleiro antes de entrar.", 18, Tema.SUAVE)
	_botao("Enfrentar o Rei", _iniciar_batalha.bind("chefe", 0))

func _fim() -> void:
	_titulo("A promessa terminou")
	_imagem(Tema.retrato(0), 185)
	_texto(jornada.desfecho, 24, Tema.OURO, null, true)
	_texto("%d vitórias · %d ciclos\n%d de Corrupção · %d juramentos" % [jornada.vitorias, jornada.ciclo, jornada.corrupcao, jornada.juramentos.size()], 19, Tema.SUAVE)
	_botao("Uma nova jornada", _mostrar_heroi)
	_botao("Voltar ao menu", _mostrar_menu)

func _iniciar_batalha(tipo: String, dificuldade: int) -> void:
	if jornada.iniciar_combate(tipo, dificuldade, true):
		_salvar()
		_mostrar_batalha()

func _mostrar_batalha() -> void:
	_limpar("batalha")
	var batalha: Dictionary = jornada.batalha
	var resultado: Dictionary = batalha["resultado"]
	quadros = resultado["quadros"]
	eventos = resultado["eventos"]
	proximo_evento = 0
	tempo_batalha = 0.0
	velocidade = 1.0
	linhas_registro.clear()
	var inimigo: Dictionary = batalha["inimigo"]
	var jogador: Dictionary = batalha["jogador"]
	relogio = _texto("Duelo · 0,0 s", 21, Tema.OURO)
	_bloco_vida(str(inimigo["nome"]), int(inimigo["vida_maxima"]))
	_desenhar_grade(inimigo["tabuleiro"], 2, false, 1)
	_bloco_vida("O Errante", int(jogador["vida_maxima"]))
	_desenhar_grade(jogador["tabuleiro"], 1, false, 0)
	var caixa: VBoxContainer = _painel()
	registro = _texto("Os itens começam a carregar…", 15, Tema.SUAVE, caixa)
	registro.custom_minimum_size.y = 65
	var controles: HBoxContainer = HBoxContainer.new()
	conteudo.add_child(controles)
	botao_velocidade = _botao("Velocidade 1×", _acelerar, controles)
	_botao("Ver resultado", _pular_batalha, controles)
	resultado_caixa = _painel()
	var titulo: String = "Vitória" if bool(resultado["vitoria"]) else ("Empate" if bool(resultado["empate"]) else "Derrota")
	_texto(titulo, 29, Tema.OURO, resultado_caixa, true)
	_texto("Você: %d de Vida · Adversário: %d\nDuração: %.1f segundos" % [int(resultado["vida_jogador"]), int(resultado["vida_inimigo"]), float(resultado["tempo"])], 17, Tema.SUAVE, resultado_caixa)
	_botao("Continuar", _terminar_batalha, resultado_caixa)
	resultado_caixa.get_parent().visible = false
	_botao("Guardar e voltar ao menu", _mostrar_menu)
	reproduzindo = true
	_atualizar_batalha()

func _bloco_vida(nome_lado: String, maximo: int) -> void:
	var rotulo: Label = _texto(nome_lado, 19, Tema.TEXTO)
	vidas.append(rotulo)
	var barra: ProgressBar = ProgressBar.new()
	barra.max_value = maximo
	barra.value = maximo
	barra.show_percentage = false
	barra.custom_minimum_size.y = 10
	conteudo.add_child(barra)
	barras_vida.append(barra)
	var rotulo_estados: Label = _texto("Sem efeitos", 13, Tema.SUAVE)
	estados.append(rotulo_estados)

func _process(delta: float) -> void:
	if not reproduzindo:
		return
	var resultado: Dictionary = jornada.batalha["resultado"]
	tempo_batalha = minf(tempo_batalha + delta * velocidade, float(resultado["tempo"]))
	_atualizar_batalha()
	if tempo_batalha >= float(resultado["tempo"]):
		reproduzindo = false
		resultado_caixa.get_parent().visible = true
		sons.tocar("sino")

func _atualizar_batalha() -> void:
	if quadros.is_empty():
		return
	var indice: int = clampi(int(round(tempo_batalha / 0.1)), 0, quadros.size() - 1)
	var quadro: Dictionary = quadros[indice]
	var lados: Array = quadro["lados"]
	var inimigo: Dictionary = jornada.batalha["inimigo"]
	relogio.text = ("Condenação" if tempo_batalha >= 31.0 else "Combate automático") + " · %.1f s" % tempo_batalha
	for visual: int in range(2):
		var lado: int = 1 - visual
		var estado: Dictionary = lados[lado]
		vidas[visual].text = "%s · %d/%d" % [str(inimigo["nome"]) if lado == 1 else "O Errante", int(estado["vida"]), int(estado["vida_maxima"])]
		barras_vida[visual].value = int(estado["vida"])
		var efeitos: Array[String] = []
		var nomes: Dictionary = {"escudo": "Escudo", "sangramento": "Sangramento", "veneno": "Veneno", "marca": "Marca", "pressa": "Pressa", "lentidao": "Lentidão"}
		for chave: String in nomes:
			if float(estado[chave]) > 0.0:
				efeitos.append("%s %d" % [str(nomes[chave]), int(ceil(float(estado[chave])))])
		estados[visual].text = " · ".join(efeitos) if not efeitos.is_empty() else "Sem efeitos"
		var cartas: Array = cartas_batalha[visual]
		var recargas: Array = estado["recargas"]
		for posicao: int in range(cartas.size()):
			var carta: Espaco = cartas[posicao]
			if carta.barra != null:
				carta.barra.value = float(recargas[posicao])
	while proximo_evento < eventos.size() and float((eventos[proximo_evento] as Dictionary)["tempo"]) <= tempo_batalha:
		var evento: Dictionary = eventos[proximo_evento]
		linhas_registro.append(str(evento["texto"]))
		if linhas_registro.size() > 2:
			linhas_registro.pop_front()
		var lado: int = int(evento["lado"])
		var posicao: int = int(evento["indice"])
		if lado >= 0 and posicao >= 0:
			var carta: Espaco = (cartas_batalha[1 - lado] as Array)[posicao]
			if bool(opcoes["movimento"]):
				carta.pulsar()
		if reproduzindo and tempo_batalha - float(evento["tempo"]) < 0.2:
			sons.tocar("impacto" if str(evento["tipo"]) == "item" else "sino")
		proximo_evento += 1
	registro.text = "\n".join(linhas_registro) if not linhas_registro.is_empty() else "Os itens começam a carregar…"

func _acelerar() -> void:
	velocidade = 1.0 if velocidade >= 4.0 else velocidade * 2.0
	botao_velocidade.text = "Velocidade %d×" % int(velocidade)

func _pular_batalha() -> void:
	reproduzindo = false
	tempo_batalha = float((jornada.batalha["resultado"] as Dictionary)["tempo"])
	_atualizar_batalha()
	resultado_caixa.get_parent().visible = true
	rolagem.set_deferred("scroll_vertical", 10000)

func _terminar_batalha() -> void:
	reproduzindo = false
	jornada.concluir_combate()
	_salvar()
	_mostrar_etapa()

func _popup_item(instancia: Dictionary) -> void:
	var janela: AcceptDialog = AcceptDialog.new()
	janela.title = str(Itens.dados(instancia)["nome"])
	janela.dialog_text = Itens.descricao(instancia)
	janela.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	janela.get_label().custom_minimum_size = Vector2(300, 170)
	janela.get_ok_button().text = "Fechar"
	janela.get_ok_button().custom_minimum_size.y = 58
	janela.confirmed.connect(janela.queue_free)
	janela.canceled.connect(janela.queue_free)
	add_child(janela)
	janela.popup_centered(Vector2i(int(get_viewport_rect().size.x) - 32, 310))

func _mostrar_regras() -> void:
	_limpar("regras")
	_titulo("As leis da jornada")
	var regras: Array[Dictionary] = [
		{"titulo": "O caminho", "texto": "Juramento → duas Escolhas → Caçada → duas Escolhas → O Corvo → Preparação → Duelo. Quatro vitórias abrem a Caçada Final e o Rei sem Sombra. Derrotas podem prolongar a jornada."},
		{"titulo": "Determinação", "texto": "Seu ânimo para continuar. Começa em 8. Derrota em Duelo custa 2; empate custa 1. Em zero, a jornada termina. Vida é restaurada na passagem ao próximo ciclo; esse reinício não é Cura."},
		{"titulo": "Posicionamento", "texto": "Cada item ocupa um dos 8 espaços. Direita e esquerda não atravessam linhas. Toque duas vezes, primeiro na origem e depois no destino. Itens guardados na reserva não ativam em combate."},
		{"titulo": "Recargas e Condenação", "texto": "Cada item ativa quando sua barra enche. Os dois lados resolvem ações simultâneas. Aos 31 s, a Condenação atravessa Escudo: 5 de dano; aos 32 s, 10; depois 15, 20 e assim por diante. Os itens continuam ativos."},
		{"titulo": "Efeitos", "texto": "Escudo absorve dano. Sangramento causa dano por segundo e perde 1 de intensidade a cada segundo. Veneno atravessa Escudo e não diminui. Pressa carrega 35% mais rápido; Lentidão, 25% mais devagar. Cada Marca aumenta o dano direto recebido em 1."},
		{"titulo": "Corrupção", "texto": "0–24 Estável; 25–49 Maculado; 50–74 Corrompido; 75–99 Condenado; 100 Perdido. Aumenta o acesso a raridades e os recursos dos inimigos. A partir de 50, Caçadas ganham Ouro extra. Capelas rejeitam a partir de 75. Em 100, o Abismo propõe um pacto perigoso."},
		{"titulo": "Pactos e vínculos", "texto": "Todo Juramento cobra um sacrifício e dura a jornada. Uma Relíquia e um Familiar podem ser usados fora dos 8 espaços. Leia as regras: a Lua Negra bloqueia até a Cura dos eventos."},
		{"titulo": "Economia", "texto": "Uma compra nunca substitui um item ao acaso. O excedente vai à reserva, com 12 espaços. Venda pela metade do valor para abrir espaço. Mercadores de Sangue aceitam Ouro, 8 de Vida Máxima ou 12 de Corrupção: escolha um pagamento."},
		{"titulo": "O Rei", "texto": "A terceira ativação de cada item, e cada múltiplo de três, cria uma cópia sombria do efeito. A cópia não cria outras cópias. A Última Porta só evita uma morte por combate."}
	]
	for regra: Dictionary in regras:
		var caixa: VBoxContainer = _painel()
		_texto(str(regra["titulo"]), 22, Tema.OURO, caixa, true)
		_texto(str(regra["texto"]), 18, Tema.SUAVE, caixa)
	if carregada:
		_texto("Seu estado: %s\n%s" % [Corrupcao.nome(jornada.corrupcao), Corrupcao.descricao(jornada.corrupcao)], 18, Tema.OURO)
	_botao("Voltar", _mostrar_etapa if carregada else _mostrar_menu)

func _mostrar_configuracoes() -> void:
	_limpar("configuracoes")
	rodape.visible = false
	_titulo("Configurações", "Ajuste o som e a atmosfera.")
	var nomes: Dictionary = {"musica": "Música", "efeitos": "Efeitos sonoros", "movimento": "Movimento e brilhos", "filtro": "Textura de época"}
	for chave: String in nomes:
		_botao("%s · %s" % [str(nomes[chave]), "Ligado" if bool(opcoes[chave]) else "Desligado"], _alternar_opcao.bind(chave))
	_texto("A música é original. A textura de época afeta o cenário; textos e botões mantêm a legibilidade.", 18, Tema.SUAVE)
	_botao("Como jogar", _mostrar_regras)
	_botao("Voltar", _mostrar_menu)

func _alternar_opcao(chave: String) -> void:
	opcoes[chave] = not bool(opcoes[chave])
	var arquivo: ConfigFile = ConfigFile.new()
	for nome_opcao: String in opcoes:
		arquivo.set_value("preferencias", nome_opcao, opcoes[nome_opcao])
	arquivo.save("user://preferencias.cfg")
	_aplicar_opcoes()
	_mostrar_configuracoes()

func _carregar_opcoes() -> void:
	var arquivo: ConfigFile = ConfigFile.new()
	if arquivo.load("user://preferencias.cfg") == OK:
		for chave: String in opcoes:
			opcoes[chave] = bool(arquivo.get_value("preferencias", chave, true))
	_aplicar_opcoes()

func _aplicar_opcoes() -> void:
	sons.configurar(bool(opcoes["musica"]), bool(opcoes["efeitos"]))
	material_cenario.set_shader_parameter("movimento", bool(opcoes["movimento"]))
	material_cenario.set_shader_parameter("intensidade", 0.45 if bool(opcoes["filtro"]) else 0.0)

func _salvar() -> void:
	if carregada:
		erro_salvamento = Salvar.guardar(jornada.exportar()) != OK

func _capturas() -> void:
	var pasta: String = "user://capturas"
	DirAccess.make_dir_recursive_absolute(pasta)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(pasta + "/menu.png")
	jornada.nova(2468)
	carregada = true
	_mostrar_etapa()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(pasta + "/juramento.png")
	_mostrar_tabuleiro()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(pasta + "/tabuleiro.png")
	jornada.jurar("ganancia")
	_mostrar_etapa()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(pasta + "/escolhas.png")
	jornada.passo = 7
	jornada.preparar_etapa()
	_iniciar_batalha("duelo", 0)
	tempo_batalha = 12.0
	_atualizar_batalha()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(pasta + "/combate.png")
	print("Capturas: " + ProjectSettings.globalize_path(pasta))
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit.call_deferred()
