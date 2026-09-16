extends RefCounted

const Itens = preload("res://dados/itens.gd")
const Juramentos = preload("res://dados/juramentos.gd")
const Vinculos = preload("res://dados/vinculos.gd")
const Inimigos = preload("res://dados/inimigos.gd")
const Grade = preload("res://nucleo/tabuleiro.gd")
const Corrupcao = preload("res://nucleo/corrupcao.gd")
const Bots = preload("res://nucleo/bots.gd")
const Simulador = preload("res://nucleo/simulador_combate.gd")
const ETAPAS: Array[String] = ["Juramento", "Escolha", "Escolha", "Caçada", "Escolha", "Escolha", "O Corvo", "Preparação", "Duelo"]
const META_VITORIAS: int = 4

var ciclo: int = 1
var passo: int = 0
var vida: int = 100
var vida_maxima: int = 100
var ouro: int = 10
var determinacao: int = 8
var corrupcao: int = 0
var vitorias: int = 0
var fase: String = "jornada"
var desfecho: String = ""
var reliquia: String = ""
var familiar: String = ""
var tabuleiro: Array[Dictionary] = []
var reserva: Array[Dictionary] = []
var juramentos: Array[String] = []
var caminhos: Array[Dictionary] = []
var adversario: Dictionary = {}
var batalha: Dictionary = {}
var improviso_usado: bool = false
var abismo_visto: bool = false
var abismo_pendente: bool = false
var mensagem: String = ""
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func nova(semente: int = -1) -> void:
	ciclo = 1
	passo = 0
	vida = 100
	vida_maxima = 100
	ouro = 10
	determinacao = 8
	corrupcao = 0
	vitorias = 0
	fase = "jornada"
	desfecho = ""
	reliquia = ""
	familiar = ""
	reserva.clear()
	juramentos.clear()
	caminhos.clear()
	adversario.clear()
	batalha.clear()
	improviso_usado = false
	abismo_visto = false
	abismo_pendente = false
	mensagem = ""
	if semente < 0:
		rng.randomize()
	else:
		rng.seed = semente
	tabuleiro = Grade.vazio()
	var iniciais: Array[String] = ["vela", "lamina", "corrente", "estrela"]
	for indice: int in range(iniciais.size()):
		tabuleiro[indice] = Itens.criar(iniciais[indice])

func etapa() -> String:
	if abismo_pendente:
		return "O Abismo"
	match fase:
		"cacada_final": return "Caçada Final"
		"chefe": return "Rei sem Sombra"
		"encerrada": return "Fim da jornada"
	return ETAPAS[passo]

func jurar(id: String) -> bool:
	if etapa() != "Juramento" or not batalha.is_empty():
		return false
	if not id in ["sangue", "ganancia", "cinzas"]:
		return false
	if id == "sangue":
		if vida_maxima <= 15:
			mensagem = "Vida Máxima insuficiente para este sacrifício."
			return false
		vida_maxima -= 15
		vida = mini(vida, vida_maxima)
	juramentos.append(id)
	mensagem = "O juramento acompanhará você até o fim da jornada."
	_avancar()
	return true

func _avancar() -> void:
	passo += 1
	caminhos.clear()
	preparar_etapa()

func preparar_etapa() -> void:
	if fase != "jornada":
		return
	if etapa() == "Escolha" and caminhos.is_empty():
		var oferta: Dictionary = _sortear_item()
		caminhos.append({"tipo": "mercador", "nome": "Mercador Errante", "icone": 5, "descricao": "Uma mercadoria conhecida, por Ouro.", "item": oferta})
		var servicos: Array[String] = ["capela", "ferreiro", "ruinas"]
		var servico: String = servicos[rng.randi_range(0, servicos.size() - 1)]
		var descricoes: Dictionary = {
			"capela": {"tipo": "capela", "nome": "Capela Esquecida", "icone": 13, "descricao": "Cura 24 e remove 12 de Corrupção. Rejeita você a partir de 75 de Corrupção."},
			"ferreiro": {"tipo": "ferreiro", "nome": "Ferreiro", "icone": 0, "descricao": "Escolha um item para subir de raridade e ganhar uma propriedade."},
			"ruinas": {"tipo": "ruinas", "nome": "Vila em Ruínas", "icone": 11, "descricao": "Recolha 4 de Ouro ou descanse para recuperar 20 de Vida."}
		}
		caminhos.append(descricoes[servico])
		var especial: int = rng.randi_range(0, 3)
		if especial == 0:
			var id: String = "corvo" if rng.randi_range(0, 1) == 0 else "rato"
			caminhos.append({"tipo": "familiar", "nome": "Bosque Retorcido", "icone": int((Vinculos.FAMILIARES[id] as Dictionary)["icone"]), "descricao": "Um Familiar pode acompanhar sua jornada.", "id": id})
		elif especial == 1:
			var id: String = "lua_negra" if rng.randi_range(0, 1) == 0 else "coracao_santo"
			caminhos.append({"tipo": "reliquia", "nome": "Santuário Lunar", "icone": int((Vinculos.RELIQUIAS[id] as Dictionary)["icone"]), "descricao": "Uma Relíquia concede poder e impõe uma regra.", "id": id})
		else:
			caminhos.append({"tipo": "sangue", "nome": "Mercador de Sangue", "icone": 4, "descricao": "Pague com Ouro, Vida Máxima ou Corrupção.", "item": _sortear_item(1)})
	elif passo >= 6 and adversario.is_empty():
		adversario = Bots.gerar(ciclo, corrupcao, rng)

func _sortear_item(minimo: int = 0) -> Dictionary:
	var maximo: int = clampi(1 + int(float(ciclo - 1) / 2.0) + int(float(Corrupcao.faixa(corrupcao)) / 2.0), 1, 3)
	var possibilidades: Array[String] = []
	for id: String in Itens.DEFINICOES:
		var base: Dictionary = Itens.DEFINICOES[id]
		var nivel: int = int(base["nivel"])
		if nivel >= minimo and nivel <= maximo:
			possibilidades.append(id)
	return Itens.criar(possibilidades[rng.randi_range(0, possibilidades.size() - 1)])

func preco_mercador(item: Dictionary) -> int:
	var modificadores: Dictionary = Juramentos.modificadores(juramentos)
	return int(ceil(float(Itens.preco(item)) * float(modificadores["precos"])))

func cabe_item() -> bool:
	return Grade.ocupados(tabuleiro) < Grade.ESPACOS or reserva.size() < Grade.LIMITE_RESERVA

func adquirir(item: Dictionary) -> bool:
	if not cabe_item():
		mensagem = "Tabuleiro e reserva cheios. Venda um item antes de adquirir outro."
		return false
	var possuidos: Array = tabuleiro.duplicate(true)
	possuidos.append_array(reserva)
	var categorias_atuais: Array[String] = Itens.categorias(possuidos)
	var categorias_novas: Array[String] = Itens.categorias([item])
	var novidade: bool = false
	for categoria: String in categorias_novas:
		if not categorias_atuais.has(categoria):
			novidade = true
	var colocado: bool = false
	for indice: int in range(tabuleiro.size()):
		if tabuleiro[indice].is_empty():
			tabuleiro[indice] = item.duplicate(true)
			colocado = true
			break
	if not colocado:
		reserva.append(item.duplicate(true))
	if novidade and not improviso_usado:
		improviso_usado = true
		ouro += 2
		mensagem += " Improviso: nova categoria, +2 de Ouro."
	return true

func comprar(indice: int, pagamento: String) -> bool:
	if etapa() != "Escolha" or indice < 0 or indice >= caminhos.size() or not batalha.is_empty():
		return false
	var caminho: Dictionary = caminhos[indice]
	var tipo: String = str(caminho["tipo"])
	if not tipo in ["mercador", "sangue", "familiar", "reliquia"]:
		return false
	var item: Dictionary = caminho.get("item", {})
	if not item.is_empty() and not cabe_item():
		mensagem = "Sem espaço. Venda um item na reserva ou no tabuleiro."
		return false
	var preco: int = preco_mercador(item) if not item.is_empty() else int(ceil(float(6 if tipo == "familiar" else 10) * float(Juramentos.modificadores(juramentos)["precos"])))
	if tipo != "sangue" and pagamento != "ouro":
		return false
	match pagamento:
		"ouro":
			if ouro < preco:
				mensagem = "Ouro insuficiente. Você pode vender um item ou escolher outro caminho."
				return false
			ouro -= preco
		"vida":
			if vida_maxima <= 8:
				mensagem = "Este preço consumiria toda a sua Vida Máxima."
				return false
			vida_maxima -= 8
			vida = mini(vida, vida_maxima)
		"corrupcao":
			if corrupcao >= 100:
				mensagem = "O Abismo já cobrou tudo que podia. Escolha outro pagamento."
				return false
			alterar_corrupcao(12)
		_: return false
	mensagem = "Negócio concluído."
	if not item.is_empty():
		adquirir(item)
	elif tipo == "familiar":
		familiar = str(caminho["id"])
	elif tipo == "reliquia":
		reliquia = str(caminho["id"])
	_avancar()
	return true

func evento(indice: int, opcao: String = "") -> bool:
	if etapa() != "Escolha" or indice < 0 or indice >= caminhos.size() or not batalha.is_empty():
		return false
	var tipo: String = str(caminhos[indice]["tipo"])
	match tipo:
		"capela":
			if corrupcao >= 75:
				mensagem = "A Capela rejeita sua presença. Escolha outro caminho."
				return false
			var recuperada: int = curar(24)
			alterar_corrupcao(-12)
			mensagem = "Recuperou %d de Vida. Corrupção reduzida em até 12." % recuperada
		"ruinas":
			if opcao == "descansar":
				mensagem = "O repouso recuperou %d de Vida." % curar(20)
			else:
				ouro += 4
				mensagem = "Encontrou 4 de Ouro entre as ruínas."
		_: return false
	_avancar()
	return true

func melhorar(indice: int, na_reserva: bool = false) -> bool:
	if etapa() != "Escolha" or not batalha.is_empty():
		return false
	var ha_ferreiro: bool = false
	for caminho: Dictionary in caminhos:
		if str(caminho["tipo"]) == "ferreiro":
			ha_ferreiro = true
	if not ha_ferreiro:
		return false
	var lista: Array[Dictionary] = reserva if na_reserva else tabuleiro
	if indice < 0 or indice >= lista.size() or lista[indice].is_empty():
		return false
	var item: Dictionary = lista[indice]
	var nivel: int = int(item["nivel"])
	var custo: int = 4 + nivel * 2
	if nivel >= 3 or ouro < custo:
		mensagem = "Raridade máxima ou Ouro insuficiente."
		return false
	ouro -= custo
	item["nivel"] = nivel + 1
	mensagem = "O item agora é %s e ganhou uma propriedade relacionada." % Itens.RARIDADES[nivel + 1]
	_avancar()
	return true

func partir() -> void:
	if etapa() == "Escolha" and batalha.is_empty():
		mensagem = "Você preservou seus recursos e seguiu caminho."
		_avancar()

func curar(quantidade: int) -> int:
	if reliquia == "lua_negra":
		return 0
	var fator: float = float(Juramentos.modificadores(juramentos)["cura"])
	if reliquia == "coracao_santo":
		fator *= 1.5
	var antes: int = vida
	vida = mini(vida_maxima, vida + int(round(float(quantidade) * fator)))
	return vida - antes

func alterar_corrupcao(quantidade: int) -> void:
	corrupcao = clampi(corrupcao + quantidade, 0, 100)
	if corrupcao == 100 and not abismo_visto:
		abismo_pendente = true

func resolver_abismo(aceitar: bool) -> bool:
	if not abismo_pendente or not batalha.is_empty():
		return false
	if aceitar:
		if vida_maxima <= 20 or not cabe_item():
			mensagem = "Precisa de espaço e mais de 20 de Vida Máxima."
			return false
		vida_maxima -= 20
		vida = mini(vida, vida_maxima)
		adquirir(Itens.criar("porta"))
		mensagem = "O Abismo tomou 20 de Vida Máxima e entregou A Última Porta."
	else:
		determinacao = maxi(0, determinacao - 2)
		corrupcao = 70
		mensagem = "Resistiu ao Abismo: -2 de Determinação; Corrupção reduzida para 70."
	abismo_visto = true
	abismo_pendente = false
	if determinacao <= 0:
		_encerrar("A determinação se apagou ao resistir ao Abismo.")
	preparar_etapa()
	return true

func trocar(origem: int, destino: int) -> bool:
	if not batalha.is_empty() or origem < 0 or destino < 0 or origem >= 8 or destino >= 8:
		return false
	var item: Dictionary = tabuleiro[origem]
	tabuleiro[origem] = tabuleiro[destino]
	tabuleiro[destino] = item
	return true

func equipar(indice_reserva: int, destino: int) -> bool:
	if not batalha.is_empty() or indice_reserva < 0 or indice_reserva >= reserva.size() or destino < 0 or destino >= 8:
		return false
	var anterior: Dictionary = tabuleiro[destino]
	tabuleiro[destino] = reserva[indice_reserva]
	if anterior.is_empty():
		reserva.remove_at(indice_reserva)
	else:
		reserva[indice_reserva] = anterior
	return true

func guardar_item(indice: int) -> bool:
	if not batalha.is_empty() or indice < 0 or indice >= 8 or tabuleiro[indice].is_empty() or reserva.size() >= Grade.LIMITE_RESERVA:
		return false
	reserva.append(tabuleiro[indice])
	tabuleiro[indice] = {}
	return true

func vender(indice: int, na_reserva: bool = false) -> bool:
	if not batalha.is_empty():
		return false
	var lista: Array[Dictionary] = reserva if na_reserva else tabuleiro
	if indice < 0 or indice >= lista.size() or lista[indice].is_empty():
		return false
	ouro += maxi(1, int(float(Itens.preco(lista[indice])) / 2.0))
	if na_reserva:
		reserva.remove_at(indice)
	else:
		tabuleiro[indice] = {}
	mensagem = "Item vendido pela metade do valor, arredondada para baixo."
	return true

func ficha() -> Dictionary:
	return {"nome": "O Errante", "vida": vida, "vida_maxima": vida_maxima, "tabuleiro": tabuleiro.duplicate(true), "familiar": familiar, "reliquia": reliquia, "modificadores": Juramentos.modificadores(juramentos)}

func iniciar_combate(tipo: String, dificuldade: int = 0, gravar: bool = true) -> bool:
	if not batalha.is_empty() or fase == "encerrada" or abismo_pendente:
		return false
	var inimigo: Dictionary = {}
	match tipo:
		"cacada":
			if etapa() != "Caçada": return false
			inimigo = Inimigos.cacada(dificuldade, ciclo, Corrupcao.faixa(corrupcao))
		"duelo":
			if etapa() != "Preparação" and etapa() != "Duelo": return false
			passo = 8
			preparar_etapa()
			inimigo = adversario.duplicate(true)
		"final":
			if fase != "cacada_final": return false
			inimigo = Inimigos.cacada(1, 4, Corrupcao.faixa(corrupcao))
			inimigo["nome"] = "Sentinela do Limiar"
		"chefe":
			if fase != "chefe": return false
			inimigo = Inimigos.rei(corrupcao)
		_: return false
	var jogador: Dictionary = ficha()
	var resultado: Dictionary = Simulador.new().lutar(jogador, inimigo, gravar)
	batalha = {"tipo": tipo, "dificuldade": clampi(dificuldade, 0, 2), "jogador": jogador, "inimigo": inimigo, "resultado": resultado}
	return true

func concluir_combate() -> bool:
	if batalha.is_empty():
		return false
	var resultado: Dictionary = batalha["resultado"]
	var venceu: bool = bool(resultado["vitoria"])
	var empate: bool = bool(resultado["empate"])
	var tipo: String = str(batalha["tipo"])
	var dificuldade: int = int(batalha["dificuldade"])
	batalha = {}
	match tipo:
		"cacada":
			if venceu:
				var recompensa: Dictionary = Inimigos.CACA[dificuldade]
				var faixa: int = Corrupcao.faixa(corrupcao)
				var bonus: int = faixa if faixa >= 2 else 0
				var ganho: int = int(recompensa["ouro"]) + int(Juramentos.modificadores(juramentos)["cacada"]) + bonus
				ouro += ganho
				vida = maxi(1, int(resultado["vida_jogador"]))
				alterar_corrupcao(int(recompensa["corrupcao"]))
				mensagem = "Caçada vencida: +%d de Ouro. Ferimentos permanecem até o próximo ciclo." % ganho
				if dificuldade == 2:
					var premio: Dictionary = _sortear_item(1)
					if cabe_item():
						adquirir(premio)
					else:
						ouro += Itens.preco(premio)
						mensagem += " Prêmio convertido em Ouro porque não havia espaço."
			else:
				vida = maxi(1, vida - 12)
				mensagem = "Retirada da Caçada: perdeu até 12 de Vida; nenhuma recompensa."
			_avancar()
		"duelo":
			if venceu:
				vitorias += 1
				ouro += 5 + ciclo
				mensagem = "Duelo vencido. +%d de Ouro." % (5 + ciclo)
			else:
				determinacao = maxi(0, determinacao - (1 if empate else 2))
				mensagem = "Empate: -1 de Determinação." if empate else "Duelo perdido: -2 de Determinação."
			if determinacao <= 0:
				_encerrar("Sua determinação chegou ao fim.")
			elif vitorias >= META_VITORIAS:
				fase = "cacada_final"
				vida = vida_maxima
			else:
				ciclo += 1
				passo = 0
				vida = vida_maxima
				improviso_usado = false
				adversario.clear()
				caminhos.clear()
		"final":
			if not venceu:
				determinacao = maxi(0, determinacao - 2)
			if determinacao <= 0:
				_encerrar("A Sentinela apagou sua última esperança.")
			else:
				fase = "chefe"
				vida = vida_maxima
				mensagem = "A passagem está aberta. Prepare-se para o Rei sem Sombra."
		"chefe":
			_encerrar("Você quebrou o juramento do Rei sem Sombra." if venceu else "O Rei sem Sombra tomou sua última promessa.")
	return true

func continuar_corvo() -> void:
	if etapa() == "O Corvo" and batalha.is_empty():
		_avancar()

func _encerrar(texto: String) -> void:
	fase = "encerrada"
	desfecho = texto

func exportar() -> Dictionary:
	return {"ciclo": ciclo, "passo": passo, "vida": vida, "vida_maxima": vida_maxima, "ouro": ouro, "determinacao": determinacao, "corrupcao": corrupcao, "vitorias": vitorias, "fase": fase, "desfecho": desfecho, "reliquia": reliquia, "familiar": familiar, "tabuleiro": tabuleiro.duplicate(true), "reserva": reserva.duplicate(true), "juramentos": juramentos.duplicate(), "caminhos": caminhos.duplicate(true), "adversario": adversario.duplicate(true), "batalha": batalha.duplicate(true), "improviso_usado": improviso_usado, "abismo_visto": abismo_visto, "abismo_pendente": abismo_pendente, "mensagem": mensagem, "rng_estado": rng.state, "rng_semente": rng.seed}

func importar(dados: Dictionary) -> bool:
	if not _valido(dados):
		return false
	ciclo = int(dados["ciclo"])
	passo = int(dados["passo"])
	vida = int(dados["vida"])
	vida_maxima = int(dados["vida_maxima"])
	ouro = int(dados["ouro"])
	determinacao = int(dados["determinacao"])
	corrupcao = int(dados["corrupcao"])
	vitorias = int(dados["vitorias"])
	fase = str(dados["fase"])
	desfecho = str(dados.get("desfecho", ""))
	reliquia = str(dados["reliquia"])
	familiar = str(dados["familiar"])
	tabuleiro.assign(dados["tabuleiro"])
	reserva.assign(dados["reserva"])
	juramentos.assign(dados["juramentos"])
	caminhos.assign(dados["caminhos"])
	adversario = (dados["adversario"] as Dictionary).duplicate(true)
	batalha = (dados["batalha"] as Dictionary).duplicate(true)
	improviso_usado = bool(dados["improviso_usado"])
	abismo_visto = bool(dados["abismo_visto"])
	abismo_pendente = bool(dados["abismo_pendente"])
	mensagem = str(dados.get("mensagem", ""))
	rng.seed = int(dados["rng_semente"])
	rng.state = int(dados["rng_estado"])
	return true

func _valido(dados: Dictionary) -> bool:
	for chave: String in ["ciclo", "passo", "vida", "vida_maxima", "ouro", "determinacao", "corrupcao", "vitorias", "rng_estado", "rng_semente"]:
		if not dados.get(chave) is int:
			return false
	for chave: String in ["reliquia", "familiar"]:
		if not dados.get(chave) is String:
			return false
	if int(dados["ciclo"]) < 1 or int(dados["ouro"]) < 0 or int(dados["vida"]) < 1 or int(dados["vida"]) > int(dados["vida_maxima"]):
		return false
	if int(dados["corrupcao"]) < 0 or int(dados["corrupcao"]) > 100 or int(dados["determinacao"]) < 0 or int(dados["determinacao"]) > 8:
		return false
	if int(dados["passo"]) < 0 or int(dados["passo"]) >= ETAPAS.size() or int(dados["vida_maxima"]) < 1:
		return false
	if not str(dados.get("fase", "")) in ["jornada", "cacada_final", "chefe", "encerrada"]:
		return false
	for chave: String in ["tabuleiro", "reserva", "juramentos", "caminhos"]:
		if not dados.get(chave) is Array:
			return false
	if (dados["tabuleiro"] as Array).size() != 8 or (dados["reserva"] as Array).size() > Grade.LIMITE_RESERVA:
		return false
	for chave: String in ["tabuleiro", "reserva"]:
		for valor: Variant in dados[chave]:
			if not valor is Dictionary:
				return false
			var item: Dictionary = valor
			if item.is_empty():
				continue
			if not Itens.DEFINICOES.has(str(item.get("id", ""))) or not item.get("nivel") is int:
				return false
			var base: Dictionary = Itens.DEFINICOES[str(item["id"])]
			if int(item["nivel"]) < int(base["nivel"]) or int(item["nivel"]) > 3:
				return false
	for id: Variant in dados["juramentos"]:
		if not str(id) in ["sangue", "ganancia", "cinzas"]:
			return false
	for chave: String in ["adversario", "batalha"]:
		if not dados.get(chave) is Dictionary:
			return false
	for chave: String in ["improviso_usado", "abismo_visto", "abismo_pendente"]:
		if not dados.get(chave) is bool:
			return false
	if not str(dados.get("reliquia", "")).is_empty() and not Vinculos.RELIQUIAS.has(str(dados["reliquia"])):
		return false
	if not str(dados.get("familiar", "")).is_empty() and not Vinculos.FAMILIARES.has(str(dados["familiar"])):
		return false
	return true
