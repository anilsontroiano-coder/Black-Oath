extends SceneTree
## Percorre jornadas reais com decisões simples, sem alterar resultados de combate.
const Jornada = preload("res://nucleo/jornada.gd")
const Itens = preload("res://dados/itens.gd")
const Grade = preload("res://nucleo/tabuleiro.gd")

func _initialize() -> void:
	var encerradas: int = 0
	var chegaram_ao_rei: int = 0
	var venceram_rei: int = 0
	for semente: int in range(50):
		var j: Jornada = Jornada.new()
		j.nova(semente)
		var acoes: int = 0
		while j.fase != "encerrada" and acoes < 160:
			acoes += 1
			match j.etapa():
				"Juramento": j.jurar("ganancia")
				"Escolha": _escolher(j)
				"Caçada":
					j.iniciar_combate("cacada", 0, false)
					j.concluir_combate()
				"O Corvo": j.continuar_corvo()
				"Preparação", "Duelo":
					j.iniciar_combate("duelo", 0, false)
					j.concluir_combate()
				"O Abismo": j.resolver_abismo(j.vida_maxima > 20 and j.cabe_item())
				"Caçada Final":
					j.iniciar_combate("final", 0, false)
					j.concluir_combate()
				"Rei sem Sombra":
					chegaram_ao_rei += 1
					j.iniciar_combate("chefe", 0, false)
					if bool((j.batalha["resultado"] as Dictionary)["vitoria"]):
						venceram_rei += 1
					j.concluir_combate()
		if j.fase == "encerrada":
			encerradas += 1
	print(JSON.stringify({"jornadas": 50, "encerradas_sem_travar": encerradas, "chegaram_ao_rei": chegaram_ao_rei, "venceram_rei": venceram_rei, "politica": "Compras simples, recuperação e Caçadas fáceis; sem reorganização otimizada."}))
	quit(0 if encerradas == 50 else 1)

func _escolher(j: Jornada) -> void:
	for indice: int in range(j.caminhos.size()):
		var tipo: String = str(j.caminhos[indice]["tipo"])
		if j.vida * 2 < j.vida_maxima:
			if tipo == "capela" and j.corrupcao < 75 and j.evento(indice): return
			if tipo == "ruinas" and j.evento(indice, "descansar"): return
	for indice: int in range(j.caminhos.size()):
		var caminho: Dictionary = j.caminhos[indice]
		var tipo: String = str(caminho["tipo"])
		if tipo in ["mercador", "sangue"] and Grade.ocupados(j.tabuleiro) < 8:
			if j.comprar(indice, "ouro"): return
			if tipo == "sangue" and j.corrupcao < 85 and j.comprar(indice, "corrupcao"): return
		elif tipo == "familiar" and j.familiar.is_empty():
			if j.comprar(indice, "ouro"): return
		elif tipo == "reliquia" and j.reliquia.is_empty():
			if j.comprar(indice, "ouro"): return
		elif tipo == "ferreiro":
			for posicao: int in range(j.tabuleiro.size()):
				if not j.tabuleiro[posicao].is_empty() and int(Itens.dados(j.tabuleiro[posicao]).get("dano", 0)) > 0:
					if j.melhorar(posicao): return
	for indice: int in range(j.caminhos.size()):
		var tipo: String = str(j.caminhos[indice]["tipo"])
		if tipo in ["ruinas", "capela"] and j.evento(indice): return
	j.partir()
