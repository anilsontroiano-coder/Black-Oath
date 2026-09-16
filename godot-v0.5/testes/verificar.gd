extends SceneTree

const Jornada = preload("res://nucleo/jornada.gd")
const Simulador = preload("res://nucleo/simulador_combate.gd")
const Itens = preload("res://dados/itens.gd")
const Grade = preload("res://nucleo/tabuleiro.gd")
const Bots = preload("res://nucleo/bots.gd")
const Salvar = preload("res://nucleo/salvamento.gd")
var falhas: int = 0
var verificacoes: int = 0

func _initialize() -> void:
	_executar.call_deferred()

func _checar(condicao: bool, mensagem: String) -> void:
	verificacoes += 1
	if not condicao:
		falhas += 1
		printerr("FALHOU: " + mensagem)

func _ficha(ids: Array[String], vida: int = 100) -> Dictionary:
	var tabuleiro: Array[Dictionary] = Grade.vazio()
	for indice: int in range(ids.size()):
		if not ids[indice].is_empty():
			tabuleiro[indice] = Itens.criar(ids[indice])
	return {"nome": "Teste", "tabuleiro": tabuleiro, "vida": vida, "vida_maxima": vida}

func _executar() -> void:
	var jogador: Dictionary = _ficha(["lamina", "estrela"])
	var antes: Dictionary = jogador.duplicate(true)
	var sim: RefCounted = Simulador.new()
	var espelho: Dictionary = sim.lutar(jogador, jogador, true)
	_checar(bool(espelho["empate"]), "Builds idênticas resolvem mortes simultâneas sem vantagem de lado")
	_checar(jogador == antes, "A simulação não altera a ficha original")
	var sem_tela: Dictionary = sim.lutar(jogador, jogador, false)
	_checar(sem_tela["eventos"] == espelho["eventos"] and sem_tela["tempo"] == espelho["tempo"], "Execução sem quadros preserva o resultado")
	var condenacao: Dictionary = sim.lutar(_ficha([]), _ficha([]), true)
	var primeiro: Dictionary = (condenacao["eventos"] as Array)[0]
	_checar(is_equal_approx(float(primeiro["tempo"]), 31.0), "Condenação começa exatamente aos 31 segundos")
	_checar(str(primeiro["texto"]).contains("5 de dano"), "Primeira Condenação causa 5 de dano")
	_checar(float(condenacao["tempo"]) < 60.0, "Condenação termina uma luta sem ataques")
	var certo: Dictionary = sim.lutar(_ficha(["vela", "estrela"]), _ficha([], 500), true)
	var errado: Dictionary = sim.lutar(_ficha(["estrela", "vela"]), _ficha([], 500), true)
	_checar(_primeira_ativacao(certo, 1) < _primeira_ativacao(errado, 0), "Vela à esquerda antecipa a Estrela")
	_checar(Grade.vizinho(3, "direita") == -1 and Grade.vizinho(4, "acima") == 0, "Adjacência respeita as duas linhas")
	var chefe: Dictionary = _ficha(["corrente"], 500)
	chefe["rei"] = true
	var rei: Dictionary = sim.lutar(_ficha(["lamina"], 500), chefe, true)
	_checar(_contar_eventos(rei, "copia") > 0, "Rei copia a terceira ativação")
	var porta: Dictionary = sim.lutar(_ficha(["porta"], 1), _ficha(["lamina"]), true)
	_checar(_contar_eventos(porta, "porta") == 1, "Última Porta evita a morte uma única vez")
	var chuva: Dictionary = sim.lutar(_ficha(["chuva"]), _ficha(["corrente"]), true)
	var ultimo_quadro: Dictionary = (chuva["quadros"] as Array).back()
	var alvo: Dictionary = (ultimo_quadro["lados"] as Array)[1]
	_checar(int(alvo["veneno"]) >= 2, "Veneno persiste naturalmente")
	var lua: Dictionary = _ficha(["coracao"], 100)
	lua["vida"] = 30
	lua["reliquia"] = "lua_negra"
	var bloqueio: Dictionary = sim.lutar(lua, _ficha([]), true)
	var no_decimo: Dictionary = (bloqueio["quadros"] as Array)[100]
	_checar(int(((no_decimo["lados"] as Array)[0] as Dictionary)["vida"]) == 30, "Lua Negra bloqueia Cura no combate")
	_testar_jornada()
	_testar_bots()
	print("VERIFICAÇÕES: %d | FALHAS: %d" % [verificacoes, falhas])
	quit(1 if falhas > 0 else 0)

func _primeira_ativacao(resultado: Dictionary, indice: int) -> float:
	for evento: Dictionary in resultado["eventos"]:
		if int(evento["lado"]) == 0 and int(evento["indice"]) == indice:
			return float(evento["tempo"])
	return INF

func _contar_eventos(resultado: Dictionary, tipo: String) -> int:
	var total: int = 0
	for evento: Dictionary in resultado["eventos"]:
		if str(evento["tipo"]) == tipo:
			total += 1
	return total

func _testar_jornada() -> void:
	var j: RefCounted = Jornada.new()
	j.nova(12345)
	_checar(j.vida == 100 and j.ouro == 10 and j.determinacao == 8 and j.corrupcao == 0, "Atributos iniciais do Errante")
	_checar(j.jurar("sangue") and j.vida_maxima == 85, "Juramento cobra sacrifício")
	var saldo: int = j.ouro
	j.adquirir(Itens.criar("chuva"))
	_checar(j.ouro == saldo + 2, "Improviso premia nova categoria")
	j.adquirir(Itens.criar("coracao"))
	_checar(j.ouro == saldo + 2, "Improviso é limitado a uma vez por ciclo")
	var copia: Dictionary = j.exportar()
	var erro: Error = Salvar.guardar(copia, "user://teste-jornada.dat")
	var restaurada: RefCounted = Jornada.new()
	_checar(erro == OK and restaurada.importar(Salvar.carregar("user://teste-jornada.dat")), "Salvamento e restauração válidos")
	_checar(restaurada.exportar() == copia, "Restaurar preserva ofertas, recursos e estado do sorteio")
	var ouro_antes: int = j.ouro
	j.ouro = 0
	var etapa_antes: int = j.passo
	_checar(not j.comprar(0, "ouro") and j.passo == etapa_antes, "Compra sem Ouro não consome escolha")
	j.ouro = ouro_antes
	while j.cabe_item():
		j.adquirir(Itens.criar("lamina"))
	var cheia: Array = j.tabuleiro.duplicate(true)
	j.ouro = 100
	_checar(not j.comprar(0, "ouro") and j.ouro == 100 and j.tabuleiro == cheia, "Compra sem espaço não cobra nem substitui itens")
	j.nova(77)
	j.alterar_corrupcao(100)
	_checar(j.fase != "encerrada" and j.abismo_pendente, "100 de Corrupção abre evento sem morte automática")
	_checar(j.resolver_abismo(true) and j.vida_maxima == 80, "Pacto do Abismo concede item e cobra Vida Máxima")
	j.nova(42)
	var etapas: Array[String] = []
	for _ciclo: int in range(4):
		etapas.append(j.etapa())
		j.jurar("ganancia")
		j.partir()
		j.partir()
		etapas.append(j.etapa())
		_checar(j.iniciar_combate("cacada", 0, false), "Caçada pode iniciar na etapa correta")
		var pendente: Dictionary = j.exportar()
		_checar(restaurada.importar(pendente), "Pode restaurar combate pendente")
		_checar(not j.trocar(0, 1), "Tabuleiro é bloqueado durante a batalha")
		j.concluir_combate()
		_checar(not j.concluir_combate(), "Recompensa não pode ser aplicada duas vezes")
		j.partir()
		j.partir()
		etapas.append(j.etapa())
		var revelado: Dictionary = j.adversario.duplicate(true)
		j.continuar_corvo()
		j.trocar(0, 1)
		j.iniciar_combate("duelo", 0, false)
		_checar((j.batalha as Dictionary)["inimigo"] == revelado, "Duelo usa exatamente o adversário visto pelo Corvo")
		# Resultado controlado testa a condição de progressão, separado do equilíbrio.
		var resultado: Dictionary = (j.batalha as Dictionary)["resultado"]
		resultado["vitoria"] = true
		resultado["empate"] = false
		j.concluir_combate()
	_checar(j.fase == "cacada_final" and j.vitorias == 4, "Quatro vitórias abrem Caçada Final")
	_checar(etapas.slice(0, 3) == ["Juramento", "Caçada", "O Corvo"], "Ordem central do ciclo")
	j.iniciar_combate("final", 0, false)
	j.concluir_combate()
	_checar(j.fase == "chefe", "Caçada Final abre o chefe")
	j.iniciar_combate("chefe", 0, false)
	j.concluir_combate()
	_checar(j.fase == "encerrada" and not j.desfecho.is_empty(), "Chefe conclui a jornada")
	j.nova(7)
	j.determinacao = 2
	j.passo = 7
	j.preparar_etapa()
	j.iniciar_combate("duelo", 0, false)
	var derrota: Dictionary = (j.batalha as Dictionary)["resultado"]
	derrota["vitoria"] = false
	derrota["empate"] = false
	j.concluir_combate()
	_checar(j.fase == "encerrada" and j.determinacao == 0, "Determinação zero encerra a jornada")
	var invalido: Dictionary = copia.duplicate(true)
	invalido["tabuleiro"] = [{"id": "nao_existe", "nivel": 20}]
	_checar(not restaurada.importar(invalido), "Salvamento incompatível é rejeitado")
	DirAccess.remove_absolute("user://teste-jornada.dat")

func _testar_bots() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8
	for ciclo: int in range(1, 8):
		for nome: String in Bots.ARQUETIPOS:
			var bot: Dictionary = Bots.gerar(ciclo, 75, rng, nome)
			_checar(int(bot["gasto"]) <= int(bot["orcamento"]) and Grade.ocupados(bot["tabuleiro"]) >= 2, "Bot %s ciclo %d respeita orçamento" % [nome, ciclo])
			_checar(int(bot["vida"]) == 100 and Bots.espiar(bot).size() == 2, "Bot escala equipamento e fornece somente duas pistas")
