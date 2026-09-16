extends SceneTree

const Cena = preload("res://cenas/principal.tscn")
var jogo: Control
var falhas: int = 0
var verificacoes: int = 0

func _initialize() -> void:
	_executar.call_deferred()

func _checar(condicao: bool, texto: String) -> void:
	verificacoes += 1
	if not condicao:
		falhas += 1
		printerr("FALHOU NA INTERFACE: " + texto)

func _assentar() -> void:
	await process_frame
	await process_frame

func _encontrar(no: Node, texto: String) -> Button:
	if no is Button and (no as Button).text == texto and (no as Button).is_visible_in_tree():
		return no as Button
	for filho: Node in no.get_children():
		var achado: Button = _encontrar(filho, texto)
		if achado != null:
			return achado
	return null

func _pressionar(texto: String) -> void:
	var botao: Button = _encontrar(jogo, texto)
	_checar(botao != null, "Botão disponível: " + texto)
	if botao != null:
		var movimento: InputEventMouseMotion = InputEventMouseMotion.new()
		movimento.position = botao.get_global_rect().get_center()
		jogo.get_viewport().push_input(movimento, true)
		await process_frame
		var evento: InputEventMouseButton = InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.position = botao.get_global_rect().get_center()
		evento.global_position = evento.position
		evento.pressed = true
		jogo.get_viewport().push_input(evento, true)
		await process_frame
		evento = evento.duplicate() as InputEventMouseButton
		evento.pressed = false
		jogo.get_viewport().push_input(evento, true)
		await _assentar()

func _larguras(no: Node) -> void:
	if no is Button and (no as Button).is_visible_in_tree():
		var botao: Button = no as Button
		_checar(botao.get_global_rect().end.x <= jogo.get_viewport_rect().size.x + 1.0, "Botão cabe na largura: " + botao.text)
	for filho: Node in no.get_children():
		_larguras(filho)

func _executar() -> void:
	jogo = Cena.instantiate() as Control
	root.add_child(jogo)
	await _assentar()
	jogo.carregada = false
	jogo._mostrar_menu()
	await _assentar()
	_larguras(jogo)
	await _pressionar("Iniciar jornada")
	_checar(jogo.tela == "heroi", "Toque abre escolha de herói")
	jogo._nova()
	await _assentar()
	_larguras(jogo)
	await _pressionar("Assumir juramento")
	_checar(jogo.jornada.passo == 1, "Toque assume juramento e avança")
	for indice: int in range(3):
		jogo._mostrar_rota(indice)
		await _assentar()
		_larguras(jogo)
	jogo._mostrar_tabuleiro()
	await _assentar()
	_larguras(jogo)
	var primeiro: Dictionary = jogo.jornada.tabuleiro[0].duplicate(true)
	jogo._selecionar(0, false)
	await _assentar()
	jogo._selecionar(1, false)
	await _assentar()
	_checar(jogo.jornada.tabuleiro[1] == primeiro, "Troca por dois toques preserva o item")
	jogo.jornada.passo = 7
	jogo.jornada.preparar_etapa()
	jogo._iniciar_batalha("duelo", 0)
	await _assentar()
	_larguras(jogo)
	_checar(jogo.tela == "batalha" and jogo.reproduzindo, "Combate abre reprodução")
	jogo._pular_batalha()
	await _assentar()
	_checar(not jogo.reproduzindo and jogo.resultado_caixa.is_visible_in_tree(), "Pular animação mostra resultado")
	jogo._terminar_batalha()
	await _assentar()
	_checar(jogo.tela == "etapa" and jogo.jornada.batalha.is_empty(), "Continuar resolve uma vez e volta à jornada")
	jogo._mostrar_configuracoes()
	await _assentar()
	_larguras(jogo)
	print("INTERFACE: %d verificações | %d falhas" % [verificacoes, falhas])
	jogo.queue_free()
	await process_frame
	quit(1 if falhas > 0 else 0)
