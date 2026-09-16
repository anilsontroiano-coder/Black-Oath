extends RefCounted

const Itens = preload("res://dados/itens.gd")
const Grade = preload("res://nucleo/tabuleiro.gd")
const Corrupcao = preload("res://nucleo/corrupcao.gd")

const ARQUETIPOS: Dictionary = {
	"Sangrador": ["dentes", "coracao", "lamina", "vela", "dentes", "corrente", "coracao", "ampulheta"],
	"Alquimista": ["chuva", "chuva", "ampulheta", "corrente", "frasco", "coracao", "sino", "chuva"],
	"Guardião": ["lamina", "corrente", "sino", "estrela", "vela", "corrente", "ampulheta", "lamina"],
	"Ocultista": ["estrela", "vela", "coracao", "frasco", "ampulheta", "dentes", "sol", "porta"]
}

static func gerar(ciclo: int, corrupcao: int, rng: RandomNumberGenerator, arquetipo: String = "") -> Dictionary:
	var nomes: Array = ARQUETIPOS.keys()
	var nome: String = arquetipo if not arquetipo.is_empty() else str(nomes[rng.randi_range(0, nomes.size() - 1)])
	var ordem: Array = ARQUETIPOS[nome]
	var tabuleiro: Array[Dictionary] = Grade.vazio()
	var orcamento: int = 15 + maxi(0, ciclo - 1) * 11 + Corrupcao.faixa(corrupcao) * 3
	var restante: int = orcamento
	var familiar: String = ""
	var reliquia: String = ""
	if ciclo >= 2:
		familiar = "rato" if nome == "Guardião" else "corvo"
		restante -= 6
	if ciclo >= 3:
		reliquia = "lua_negra" if nome in ["Ocultista", "Alquimista"] else "coracao_santo"
		restante -= 10
	var limite: int = mini(8, 2 + ciclo)
	var posicao: int = 0
	for id: String in ordem:
		if posicao >= limite:
			break
		var item: Dictionary = Itens.criar(id)
		var custo: int = Itens.preco(item)
		if custo <= restante:
			tabuleiro[posicao] = item
			restante -= custo
			posicao += 1
	# Só usa a peça básica do próprio arquétipo ao completar espaços.
	var basico: String = "chuva" if nome == "Alquimista" else "lamina"
	while posicao < limite and restante >= Itens.preco(Itens.criar(basico)):
		var item: Dictionary = Itens.criar(basico)
		tabuleiro[posicao] = item
		restante -= Itens.preco(item)
		posicao += 1
	for indice: int in range(posicao):
		var atual: Dictionary = tabuleiro[indice]
		if int(atual["nivel"]) >= 3:
			continue
		var melhorado: Dictionary = Itens.criar(str(atual["id"]), int(atual["nivel"]) + 1)
		var custo: int = Itens.preco(melhorado) - Itens.preco(atual)
		if custo <= restante:
			tabuleiro[indice] = melhorado
			restante -= custo
	# Uma vela precede um item ofensivo, sem atravessar linhas.
	for indice: int in range(7):
		if tabuleiro[indice].is_empty():
			continue
		if str(tabuleiro[indice]["id"]) == "vela" and indice % 4 == 3:
			var troca: Dictionary = tabuleiro[0]
			tabuleiro[0] = tabuleiro[indice]
			tabuleiro[indice] = troca
	return {"nome": nome, "vida": 100, "vida_maxima": 100, "tabuleiro": tabuleiro, "familiar": familiar, "reliquia": reliquia, "orcamento": orcamento, "gasto": orcamento - restante, "modificadores": {}}

static func espiar(ficha: Dictionary) -> Array[String]:
	var contagem: Dictionary = {}
	var armas: int = 0
	var maior: float = 0.0
	for instancia: Dictionary in ficha["tabuleiro"]:
		if instancia.is_empty():
			continue
		var item: Dictionary = Itens.dados(instancia)
		maior = maxf(maior, float(item["recarga"]))
		var categorias: Array = item["categorias"]
		if categorias.has("Arma"):
			armas += 1
		for categoria: String in categorias:
			contagem[categoria] = int(contagem.get(categoria, 0)) + 1
	var principal: String = "Desconhecida"
	var quantidade: int = 0
	for categoria: String in contagem:
		if int(contagem[categoria]) > quantidade:
			principal = categoria
			quantidade = int(contagem[categoria])
	var pistas: Array[String] = ["Categoria mais presente: %s." % principal]
	if armas > 0:
		pistas.append("Carrega %d %s." % [armas, "Arma" if armas == 1 else "Armas"])
	else:
		pistas.append("Maior recarga: %.0f segundos." % maior)
	return pistas
