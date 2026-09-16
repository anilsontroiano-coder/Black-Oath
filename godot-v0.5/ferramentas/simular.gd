extends SceneTree
## Uso: godot --headless --path godot-v0.5 --script ferramentas/simular.gd -- 1000
const Bots = preload("res://nucleo/bots.gd")
const Simulador = preload("res://nucleo/simulador_combate.gd")

func _initialize() -> void:
	var argumentos: PackedStringArray = OS.get_cmdline_user_args()
	var quantidade: int = clampi(int(argumentos[0]), 1, 100000) if not argumentos.is_empty() else 1000
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260916
	var vitorias: int = 0
	var derrotas: int = 0
	var empates: int = 0
	var tempo_total: float = 0.0
	var inicio: int = Time.get_ticks_msec()
	for indice: int in range(quantidade):
		var ciclo: int = 1 + indice % 4
		var jogador: Dictionary = Bots.gerar(ciclo, 0, rng)
		var inimigo: Dictionary = Bots.gerar(ciclo, 0, rng)
		var resultado: Dictionary = Simulador.new().lutar(jogador, inimigo, false)
		tempo_total += float(resultado["tempo"])
		if bool(resultado["empate"]): empates += 1
		elif bool(resultado["vitoria"]): vitorias += 1
		else: derrotas += 1
	var duracao: int = Time.get_ticks_msec() - inicio
	print(JSON.stringify({"combates": quantidade, "vitorias_lado_1": vitorias, "vitorias_lado_2": derrotas, "empates": empates, "duracao_media_segundos": tempo_total / float(quantidade), "execucao_ms": duracao}))
	quit()
