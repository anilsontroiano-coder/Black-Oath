extends RefCounted

const Itens = preload("res://dados/itens.gd")
const Grade = preload("res://nucleo/tabuleiro.gd")
const CACA: Array[Dictionary] = [
	{"nome": "Rato de Túmulo", "risco": "Fácil", "icone": 15, "vida": 60, "ouro": 4, "corrupcao": 0, "itens": ["lamina", "corrente"]},
	{"nome": "Cavaleiro sem Rosto", "risco": "Médio", "icone": 0, "vida": 90, "ouro": 7, "corrupcao": 2, "itens": ["lamina", "dentes", "corrente"]},
	{"nome": "Santo Oco", "risco": "Difícil", "icone": 13, "vida": 100, "ouro": 10, "corrupcao": 5, "itens": ["vela", "estrela", "coracao", "sino"]}
]

static func cacada(indice: int, ciclo: int, faixa: int) -> Dictionary:
	var base: Dictionary = CACA[clampi(indice, 0, 2)]
	var tabuleiro: Array[Dictionary] = Grade.vazio()
	var ids: Array = base["itens"]
	for posicao: int in range(ids.size()):
		var item: Dictionary = Itens.criar(str(ids[posicao]))
		if ciclo >= 3 or faixa >= 2:
			item["nivel"] = mini(3, int(item["nivel"]) + 1)
		tabuleiro[posicao] = item
	if ciclo >= 4:
		tabuleiro[4] = Itens.criar("ampulheta")
	return {"nome": base["nome"], "vida": base["vida"], "vida_maxima": base["vida"], "tabuleiro": tabuleiro, "familiar": "corvo" if faixa >= 2 else "", "reliquia": "lua_negra" if faixa >= 3 else "", "modificadores": {}}

static func rei(corrupcao: int) -> Dictionary:
	var tabuleiro: Array[Dictionary] = Grade.vazio()
	var ids: Array[String] = ["vela", "estrela", "sino", "coracao", "dentes", "corrente"]
	for indice: int in range(ids.size()):
		tabuleiro[indice] = Itens.criar(ids[indice])
	if corrupcao >= 75:
		tabuleiro[6] = Itens.criar("frasco")
	return {"nome": "Rei sem Sombra", "vida": 130, "vida_maxima": 130, "tabuleiro": tabuleiro, "familiar": "corvo", "reliquia": "", "modificadores": {}, "rei": true}
