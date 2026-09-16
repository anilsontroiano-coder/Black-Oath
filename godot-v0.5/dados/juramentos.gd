extends RefCounted

const TODOS: Array[Dictionary] = [
	{"id": "sangue", "nome": "Juramento de Sangue", "icone": 4, "beneficio": "Armas causam +20% de dano.", "sacrificio": "Perde 15 de Vida Máxima."},
	{"id": "ganancia", "nome": "Juramento da Ganância", "icone": 2, "beneficio": "Cada Caçada vencida rende +3 de Ouro.", "sacrificio": "Preços dos mercadores aumentam 20%."},
	{"id": "cinzas", "nome": "Juramento das Cinzas", "icone": 10, "beneficio": "Itens de Fogo carregam 25% mais rápido.", "sacrificio": "Toda Cura é reduzida em 30%."}
]

static func modificadores(ids: Array) -> Dictionary:
	var resultado: Dictionary = {"armas": 1.0, "precos": 1.0, "cacada": 0, "fogo": 1.0, "cura": 1.0}
	for id: String in ids:
		match id:
			"sangue": resultado["armas"] = float(resultado["armas"]) + 0.2
			"ganancia":
				resultado["precos"] = float(resultado["precos"]) + 0.2
				resultado["cacada"] = int(resultado["cacada"]) + 3
			"cinzas":
				resultado["fogo"] = float(resultado["fogo"]) + 0.25
				resultado["cura"] = float(resultado["cura"]) * 0.7
	return resultado
