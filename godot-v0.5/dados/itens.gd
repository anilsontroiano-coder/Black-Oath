extends RefCounted
## Definições imutáveis. O tabuleiro guarda somente id e nível da instância.

const RARIDADES: Array[String] = ["Comum", "Raro", "Épico", "Lendário"]
const DEFINICOES: Dictionary = {
	"lamina": {"nome": "Lâmina Desgastada", "curto": "Lâmina\nDesgastada", "icone": 0, "nivel": 0, "preco": 5, "recarga": 6.0, "dano": 12, "categorias": ["Ferro", "Arma"], "descricao": "Causa 12 de dano.", "melhoria": "Também aplica Sangramento."},
	"vela": {"nome": "Vela Funerária", "curto": "Vela\nFunerária", "icone": 1, "nivel": 0, "preco": 4, "recarga": 8.0, "avanco": 1.2, "categorias": ["Fogo", "Túmulo"], "descricao": "Adianta em 1,2 s o item à direita, na mesma linha.", "melhoria": "Também adianta o item abaixo."},
	"corrente": {"nome": "Corrente de Ferro", "curto": "Corrente\nde Ferro", "icone": 2, "nivel": 0, "preco": 5, "recarga": 7.0, "escudo": 10, "categorias": ["Ferro", "Túmulo"], "descricao": "Gera 10 de Escudo.", "melhoria": "Se já possuir Escudo, aplica Marca."},
	"estrela": {"nome": "Estrela Adormecida", "curto": "Estrela\nAdormecida", "icone": 3, "nivel": 1, "preco": 9, "recarga": 18.0, "dano": 42, "categorias": ["Lua", "Cósmico"], "descricao": "Causa 42 de dano. Ao despertar, remove sua Lentidão.", "melhoria": "Parte do impacto atravessa Escudo."},
	"coracao": {"nome": "Segundo Coração", "curto": "Segundo\nCoração", "icone": 4, "nivel": 1, "preco": 8, "recarga": 9.0, "dano": 10, "cura": 4, "categorias": ["Sangue", "Carne", "Sombrio"], "descricao": "Causa 10 de dano e cura 4. Abaixo de metade da Vida, dobra ambos.", "melhoria": "A cura também adianta os itens adjacentes."},
	"ampulheta": {"nome": "Ampulheta sem Areia", "curto": "Ampulheta\nsem Areia", "icone": 5, "nivel": 1, "preco": 9, "recarga": 10.0, "avanco": 2.0, "categorias": ["Tempo", "Memória"], "descricao": "Adianta em 2 s o outro item com mais tempo restante.", "melhoria": "Também remove a Lentidão do portador."},
	"frasco": {"nome": "Frasco da Meia-Noite", "curto": "Frasco da\nMeia-Noite", "icone": 6, "nivel": 1, "preco": 10, "recarga": 11.0, "categorias": ["Sombrio", "Alquimia", "Maldição"], "descricao": "Dá Pressa aos outros itens de Sombrio por 5 s.", "melhoria": "Também adianta esses itens em 1 s."},
	"dentes": {"nome": "Dentes da Lua", "curto": "Dentes\nda Lua", "icone": 7, "nivel": 1, "preco": 9, "recarga": 7.0, "dano": 6, "sangramento": 3, "categorias": ["Sangue", "Lua", "Arma"], "descricao": "Causa 6 de dano e aplica 3 de Sangramento. Contra um alvo sangrando, ganha Pressa por 2 s.", "melhoria": "Sangramento também gera Escudo para você."},
	"chuva": {"nome": "Chuva no Frasco", "curto": "Chuva\nno Frasco", "icone": 8, "nivel": 0, "preco": 6, "recarga": 6.0, "veneno": 2, "categorias": ["Clima", "Alquimia"], "descricao": "Aplica 2 de Veneno. Veneno atravessa Escudo e não diminui naturalmente.", "melhoria": "Também aplica Lentidão por 2 s."},
	"sino": {"nome": "Garganta do Sino", "curto": "Garganta\ndo Sino", "icone": 9, "nivel": 1, "preco": 10, "recarga": 10.0, "escudo": 4, "categorias": ["Eco", "Ferro", "Ritual"], "descricao": "Gera 4 de Escudo e aplica Lentidão por 4 s. A cada terceira ativação, aplica Marca.", "melhoria": "O toque também adianta o item acima."},
	"sol": {"nome": "Fragmento do Sol Morto", "curto": "Fragmento\ndo Sol Morto", "icone": 10, "nivel": 2, "preco": 16, "recarga": 8.0, "dano": 55, "categorias": ["Fogo", "Cósmico"], "descricao": "Armazena duas cargas. Na terceira ativação, explode: 55 de dano e 15 de Escudo.", "melhoria": "A explosão também dá Pressa por 5 s."},
	"porta": {"nome": "A Última Porta", "curto": "A Última\nPorta", "icone": 11, "nivel": 3, "preco": 23, "recarga": 20.0, "escudo": 6, "categorias": ["Vazio", "Sombrio", "Maldição"], "descricao": "Uma vez por combate, evita a morte: fica com 1 de Vida e prepara todo o tabuleiro para ativar no próximo instante. Ao recarregar, gera 6 de Escudo.", "melhoria": "Raridade máxima."}
}

static func criar(id: String, nivel: int = -1) -> Dictionary:
	assert(DEFINICOES.has(id), "Item desconhecido: " + id)
	var base: Dictionary = DEFINICOES[id]
	return {"id": id, "nivel": int(base["nivel"]) if nivel < 0 else clampi(nivel, int(base["nivel"]), 3)}

static func dados(instancia: Dictionary) -> Dictionary:
	if instancia.is_empty():
		return {}
	var id: String = str(instancia["id"])
	var item: Dictionary = (DEFINICOES[id] as Dictionary).duplicate(true)
	var nivel: int = int(instancia["nivel"])
	var melhorias: int = nivel - int(item["nivel"])
	item["id"] = id
	item["nivel"] = nivel
	item["melhorias"] = melhorias
	item["raridade"] = RARIDADES[nivel]
	for atributo: String in ["dano", "escudo", "cura", "sangramento", "veneno"]:
		if item.has(atributo):
			item[atributo] = int(round(float(item[atributo]) * (1.0 + float(melhorias) * 0.25)))
	if item.has("avanco"):
		item["avanco"] = float(item["avanco"]) + float(melhorias) * 0.5
	item["preco"] = preco(instancia)
	return item

static func preco(instancia: Dictionary) -> int:
	var base: Dictionary = DEFINICOES[str(instancia["id"])]
	var faixa: Array[int] = [0, 5, 11, 18]
	return int(base["preco"]) + faixa[int(instancia["nivel"])] - faixa[int(base["nivel"])]

static func descricao(instancia: Dictionary) -> String:
	var item: Dictionary = dados(instancia)
	var texto: String = str(item["descricao"])
	if int(item["melhorias"]) > 0:
		texto += "\nMelhoria: " + str(item["melhoria"])
		var valores: Array[String] = []
		for atributo: String in ["dano", "escudo", "cura", "sangramento", "veneno", "avanco"]:
			if item.has(atributo):
				valores.append("%s: %s" % [atributo.capitalize(), str(item[atributo])])
		texto += "\nValores atuais — " + "; ".join(valores) + "."
	return texto

static func categorias(tabuleiro: Array) -> Array[String]:
	var resultado: Array[String] = []
	for instancia: Dictionary in tabuleiro:
		if instancia.is_empty():
			continue
		var item: Dictionary = dados(instancia)
		for categoria: String in item["categorias"]:
			if not resultado.has(categoria):
				resultado.append(categoria)
	return resultado
