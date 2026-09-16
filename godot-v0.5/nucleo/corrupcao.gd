extends RefCounted

static func faixa(valor: int) -> int:
	return mini(4, int(float(maxi(0, valor)) / 25.0))

static func nome(valor: int) -> String:
	var nomes: Array[String] = ["Estável", "Maculado", "Corrompido", "Condenado", "Perdido"]
	return nomes[faixa(valor)]

static func descricao(valor: int) -> String:
	var textos: Array[String] = [
		"Os santuários ainda reconhecem você.",
		"Itens estranhos aparecem mais cedo. Adversários recebem mais recursos.",
		"O impossível é mais frequente. Caçadas rendem +2 de Ouro e os inimigos ganham melhores equipamentos.",
		"Capelas rejeitam você. Caçadas rendem +3 de Ouro; adversários são muito mais bem equipados.",
		"O Abismo abre uma passagem. Chegar aqui não encerra a jornada."
	]
	return textos[faixa(valor)]
