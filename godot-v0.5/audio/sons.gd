extends Node

var musica: AudioStreamPlayer = AudioStreamPlayer.new()
var efeitos: Array[AudioStreamPlayer] = []
var indice: int = 0
var musica_ativa: bool = true
var efeitos_ativos: bool = true
var modo_silencioso: bool = DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().has("--captura")

func _ready() -> void:
	add_child(musica)
	musica.volume_db = -15.0
	if not modo_silencioso and ResourceLoader.exists("res://audio/entre_cinzas.ogg"):
		musica.stream = load("res://audio/entre_cinzas.ogg") as AudioStream
		musica.finished.connect(_repetir)
		musica.play()
	for _i: int in range(4):
		var voz: AudioStreamPlayer = AudioStreamPlayer.new()
		voz.volume_db = -12.0
		add_child(voz)
		efeitos.append(voz)

func _repetir() -> void:
	if musica_ativa:
		musica.play()

func configurar(com_musica: bool, com_efeitos: bool) -> void:
	musica_ativa = com_musica and not modo_silencioso
	efeitos_ativos = com_efeitos and not modo_silencioso
	if musica_ativa and not musica.playing and musica.stream != null:
		musica.play()
	elif not musica_ativa:
		musica.stop()

func tocar(nome: String) -> void:
	if not efeitos_ativos or efeitos.is_empty():
		return
	var caminho: String = "res://audio/" + nome + ".wav"
	if not ResourceLoader.exists(caminho):
		return
	var voz: AudioStreamPlayer = efeitos[indice]
	indice = (indice + 1) % efeitos.size()
	voz.stream = load(caminho) as AudioStream
	voz.play()

func _exit_tree() -> void:
	musica.stop()
	for voz: AudioStreamPlayer in efeitos:
		voz.stop()
