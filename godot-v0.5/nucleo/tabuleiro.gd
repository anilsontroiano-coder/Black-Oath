extends RefCounted

const ESPACOS: int = 8
const COLUNAS: int = 4
const LIMITE_RESERVA: int = 12

static func vazio() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for _indice: int in range(ESPACOS):
		resultado.append({})
	return resultado

static func vizinho(indice: int, direcao: String) -> int:
	match direcao:
		"direita": return indice + 1 if indice % COLUNAS < COLUNAS - 1 else -1
		"esquerda": return indice - 1 if indice % COLUNAS > 0 else -1
		"acima": return indice - COLUNAS if indice >= COLUNAS else -1
		"abaixo": return indice + COLUNAS if indice < ESPACOS - COLUNAS else -1
	return -1

static func adjacentes(indice: int) -> Array[int]:
	var resultado: Array[int] = []
	for direcao: String in ["direita", "esquerda", "acima", "abaixo"]:
		var outro: int = vizinho(indice, direcao)
		if outro >= 0:
			resultado.append(outro)
	return resultado

static func ocupados(itens: Array) -> int:
	var total: int = 0
	for item: Dictionary in itens:
		if not item.is_empty():
			total += 1
	return total
