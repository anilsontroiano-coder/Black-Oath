extends RefCounted
## Simulação determinística em passos de 100 ms. Não usa cenas, relógio real ou áudio.
## Ações prontas são coletadas dos dois lados antes da resolução simultânea.

const Itens = preload("res://dados/itens.gd")
const Grade = preload("res://nucleo/tabuleiro.gd")
const Vinculos = preload("res://dados/vinculos.gd")
const PASSO: float = 0.1
const LIMITE_PASSOS: int = 600

var lados: Array[Dictionary] = []
var pendentes: Array[Dictionary] = []
var eventos: Array[Dictionary] = []
var quadros: Array[Dictionary] = []
var instante: int = 0
var registrar: bool = true

func lutar(jogador: Dictionary, inimigo: Dictionary, gravar_quadros: bool = true) -> Dictionary:
	lados = [_preparar(jogador), _preparar(inimigo)]
	eventos.clear()
	quadros.clear()
	instante = 0
	registrar = gravar_quadros
	if registrar:
		_gravar_quadro()
	while instante < LIMITE_PASSOS and int(lados[0]["vida"]) > 0 and int(lados[1]["vida"]) > 0:
		instante += 1
		pendentes = [_vazio(), _vazio()]
		var acoes: Array[Dictionary] = []
		for lado: int in range(2):
			_avancar(lado, acoes)
		for acao: Dictionary in acoes:
			var lado: int = int(acao["lado"])
			var indice: int = int(acao["indice"])
			if indice == -1:
				_familiar(lado)
				continue
			var runtime: Dictionary = (lados[lado]["itens"] as Array)[indice]
			var item: Dictionary = runtime["item"]
			runtime["ativacoes"] = int(runtime["ativacoes"]) + 1
			_efeito(lado, indice, item, int(runtime["ativacoes"]), false)
			if lado == 0 and bool(lados[1]["rei"]) and int(runtime["ativacoes"]) % 3 == 0:
				_evento(1, -1, "copia", "O Rei sem Sombra copia %s." % str(item["nome"]))
				_efeito(1, -1, item, int(runtime["ativacoes"]), true)
		if instante >= 310 and instante % 10 == 0:
			var dano: int = (int(float(instante) / 10.0) - 30) * 5
			for lado: int in range(2):
				_somar(lado, "puro", dano)
			_evento(-1, -1, "condenacao", "Condenação: %d de dano em ambos, atravessando Escudo." % dano)
		for lado: int in range(2):
			_resolver(lado)
		if registrar:
			_gravar_quadro()
	var vida_j: int = int(lados[0]["vida"])
	var vida_i: int = int(lados[1]["vida"])
	var vitoria: bool = vida_j > 0 and vida_i <= 0
	var empate: bool = (vida_j <= 0 and vida_i <= 0) or (vida_j > 0 and vida_i > 0)
	return {"vitoria": vitoria, "empate": empate, "vida_jogador": maxi(0, vida_j), "vida_inimigo": maxi(0, vida_i), "tempo": float(instante) * PASSO, "eventos": eventos.duplicate(true), "quadros": quadros.duplicate(true)}

func _preparar(ficha: Dictionary) -> Dictionary:
	var itens: Array[Dictionary] = []
	var tabuleiro: Array = ficha.get("tabuleiro", [])
	for indice: int in range(Grade.ESPACOS):
		var instancia: Dictionary = tabuleiro[indice] if indice < tabuleiro.size() else {}
		if instancia.is_empty():
			itens.append({})
		else:
			var item: Dictionary = Itens.dados(instancia)
			itens.append({"item": item, "restante": float(item["recarga"]), "ativacoes": 0, "pressa": 0.0})
	var vida_maxima: int = int(ficha.get("vida_maxima", 100))
	var familiar: String = str(ficha.get("familiar", ""))
	var tempo_familiar: float = 8.0
	if not familiar.is_empty():
		tempo_familiar = float((Vinculos.FAMILIARES[familiar] as Dictionary)["recarga"])
	return {"vida": clampi(int(ficha.get("vida", vida_maxima)), 1, vida_maxima), "vida_maxima": vida_maxima, "escudo": 0, "sangramento": 0, "veneno": 0, "marca": 0, "pressa": 0.0, "lentidao": 0.0, "itens": itens, "reliquia": str(ficha.get("reliquia", "")), "familiar": familiar, "tempo_familiar": tempo_familiar, "modificadores": ficha.get("modificadores", {}), "rei": bool(ficha.get("rei", false)), "porta_usada": false}

func _vazio() -> Dictionary:
	return {"dano": 0, "puro": 0, "cura": 0, "escudo": 0, "sangramento": 0, "veneno": 0, "marca": 0, "pressa": 0.0, "lentidao": 0.0}

func _somar(lado: int, campo: String, valor: int) -> void:
	pendentes[lado][campo] = int(pendentes[lado][campo]) + valor

func _avancar(lado: int, acoes: Array[Dictionary]) -> void:
	var estado: Dictionary = lados[lado]
	for efeito: String in ["pressa", "lentidao"]:
		estado[efeito] = maxf(0.0, float(estado[efeito]) - PASSO)
	if instante % 10 == 0:
		_somar(lado, "dano", int(estado["sangramento"]))
		_somar(lado, "puro", int(estado["veneno"]))
		estado["sangramento"] = maxi(0, int(estado["sangramento"]) - 1)
	var itens: Array = estado["itens"]
	for indice: int in range(itens.size()):
		var runtime: Dictionary = itens[indice]
		if runtime.is_empty():
			continue
		runtime["pressa"] = maxf(0.0, float(runtime["pressa"]) - PASSO)
		var item: Dictionary = runtime["item"]
		var velocidade: float = _velocidade(estado, item, float(runtime["pressa"]))
		runtime["restante"] = float(runtime["restante"]) - PASSO * velocidade
		if float(runtime["restante"]) <= 0.00001:
			runtime["restante"] = float(item["recarga"])
			acoes.append({"lado": lado, "indice": indice})
	if not str(estado["familiar"]).is_empty():
		estado["tempo_familiar"] = float(estado["tempo_familiar"]) - PASSO
		if float(estado["tempo_familiar"]) <= 0.00001:
			var familiar: Dictionary = Vinculos.FAMILIARES[str(estado["familiar"])]
			estado["tempo_familiar"] = float(familiar["recarga"])
			acoes.append({"lado": lado, "indice": -1})

func _velocidade(estado: Dictionary, item: Dictionary, pressa_item: float) -> float:
	var velocidade: float = 1.0
	var categorias: Array = item["categorias"]
	var modificadores: Dictionary = estado["modificadores"]
	if str(estado["reliquia"]) == "lua_negra":
		velocidade *= 1.2
	elif str(estado["reliquia"]) == "coracao_santo" and categorias.has("Maldição"):
		velocidade *= 0.75
	if categorias.has("Fogo"):
		velocidade *= float(modificadores.get("fogo", 1.0))
	if float(estado["pressa"]) > 0.0 or pressa_item > 0.0:
		velocidade *= 1.35
	if float(estado["lentidao"]) > 0.0:
		velocidade *= 0.75
	return velocidade

func _adiantar(lado: int, indice: int, segundos: float) -> void:
	var itens: Array = lados[lado]["itens"]
	if indice < 0 or indice >= itens.size():
		return
	var runtime: Dictionary = itens[indice]
	if not runtime.is_empty():
		runtime["restante"] = maxf(0.0, float(runtime["restante"]) - segundos)

func _efeito(lado: int, indice: int, item: Dictionary, ativacoes: int, copia: bool) -> void:
	var estado: Dictionary = lados[lado]
	var oponente: int = 1 - lado
	var id: String = str(item["id"])
	var melhoria: bool = int(item["melhorias"]) > 0
	var dano: int = int(item.get("dano", 0))
	var cura: int = int(item.get("cura", 0))
	var escudo: int = int(item.get("escudo", 0))
	var modificadores: Dictionary = estado["modificadores"]
	var categorias: Array = item["categorias"]
	var origem: String = "Você" if lado == 0 else "Adversário"
	if id == "coracao" and int(estado["vida"]) * 2 < int(estado["vida_maxima"]):
		dano *= 2
		cura *= 2
	if id == "sol":
		if ativacoes % 3 == 0:
			escudo = 15
			if melhoria:
				pendentes[lado]["pressa"] = 5.0
		else:
			dano = 0
	if categorias.has("Arma"):
		dano = int(round(float(dano) * float(modificadores.get("armas", 1.0))))
	if dano > 0:
		dano += int(lados[oponente]["marca"])
		if id == "estrela" and melhoria:
			_somar(oponente, "puro", int(float(dano) * 0.3))
			dano -= int(float(dano) * 0.3)
		_somar(oponente, "dano", dano)
	if cura > 0:
		var cura_efetiva: int = _cura_permitida(estado, cura)
		_somar(lado, "cura", cura_efetiva)
		if id == "coracao" and melhoria and cura_efetiva > 0 and indice >= 0:
			for vizinho: int in Grade.adjacentes(indice):
				_adiantar(lado, vizinho, 0.8)
	_somar(lado, "escudo", escudo)
	_somar(oponente, "sangramento", int(item.get("sangramento", 0)))
	_somar(oponente, "veneno", int(item.get("veneno", 0)))
	match id:
		"lamina":
			if melhoria:
				_somar(oponente, "sangramento", 2)
		"vela":
			var destino: int = Grade.vizinho(indice, "direita") if indice >= 0 else 0
			_adiantar(lado, destino, float(item["avanco"]))
			if melhoria and indice >= 0:
				_adiantar(lado, Grade.vizinho(indice, "abaixo"), float(item["avanco"]))
		"corrente":
			if melhoria and int(estado["escudo"]) > 0:
				_somar(oponente, "marca", 2)
		"estrela": estado["lentidao"] = 0.0
		"ampulheta":
			var alvo: int = -1
			var maior: float = -1.0
			var itens: Array = estado["itens"]
			for outro: int in range(itens.size()):
				var runtime: Dictionary = itens[outro]
				if outro == indice or runtime.is_empty():
					continue
				if float(runtime["restante"]) > maior:
					maior = float(runtime["restante"])
					alvo = outro
			_adiantar(lado, alvo, float(item["avanco"]))
			if melhoria:
				estado["lentidao"] = 0.0
		"frasco":
			var itens: Array = estado["itens"]
			for outro: int in range(itens.size()):
				var runtime: Dictionary = itens[outro]
				if outro == indice or runtime.is_empty():
					continue
				var outro_item: Dictionary = runtime["item"]
				if (outro_item["categorias"] as Array).has("Sombrio"):
					runtime["pressa"] = 5.0
					if melhoria:
						_adiantar(lado, outro, 1.0)
		"dentes":
			if int(lados[oponente]["sangramento"]) > 0:
				pendentes[lado]["pressa"] = maxf(float(pendentes[lado]["pressa"]), 2.0)
			if melhoria:
				_somar(lado, "escudo", int(item["sangramento"]))
		"chuva":
			if melhoria:
				pendentes[oponente]["lentidao"] = maxf(float(pendentes[oponente]["lentidao"]), 2.0)
		"sino":
			pendentes[oponente]["lentidao"] = maxf(float(pendentes[oponente]["lentidao"]), 4.0)
			if ativacoes % 3 == 0:
				_somar(oponente, "marca", 3)
			if melhoria and indice >= 0:
				_adiantar(lado, Grade.vizinho(indice, "acima"), 1.5)
	if not copia:
		var detalhes: Array[String] = []
		if dano > 0:
			detalhes.append("%d de dano" % dano)
		if escudo > 0:
			detalhes.append("%d de Escudo" % escudo)
		if cura > 0:
			detalhes.append("%d de Cura" % _cura_permitida(estado, cura))
		if detalhes.is_empty():
			detalhes.append("efeito ativado")
		_evento(lado, indice, "item", "%s · %s: %s." % [origem, str(item["nome"]), ", ".join(detalhes)])

func _cura_permitida(estado: Dictionary, quantidade: int) -> int:
	if str(estado["reliquia"]) == "lua_negra":
		return 0
	var multiplicador: float = 1.5 if str(estado["reliquia"]) == "coracao_santo" else 1.0
	var modificadores: Dictionary = estado["modificadores"]
	return int(round(float(quantidade) * multiplicador * float(modificadores.get("cura", 1.0))))

func _familiar(lado: int) -> void:
	var familiar: String = str(lados[lado]["familiar"])
	if familiar == "corvo":
		_somar(1 - lado, "marca", 2)
		_evento(lado, -1, "familiar", "Corvo de Carniça aplica 2 de Marca.")
	elif familiar == "rato":
		_somar(lado, "escudo", 7)
		_evento(lado, -1, "familiar", "Rato de Túmulo gera 7 de Escudo.")

func _resolver(lado: int) -> void:
	var estado: Dictionary = lados[lado]
	var efeitos: Dictionary = pendentes[lado]
	var escudo: int = int(estado["escudo"]) + int(efeitos["escudo"])
	var absorvido: int = mini(escudo, int(efeitos["dano"]))
	estado["escudo"] = escudo - absorvido
	var dano: int = int(efeitos["dano"]) - absorvido + int(efeitos["puro"])
	estado["vida"] = clampi(int(estado["vida"]) + int(efeitos["cura"]) - dano, 0, int(estado["vida_maxima"]))
	for status: String in ["sangramento", "veneno", "marca"]:
		estado[status] = int(estado[status]) + int(efeitos[status])
	for status: String in ["pressa", "lentidao"]:
		estado[status] = maxf(float(estado[status]), float(efeitos[status]))
	if int(estado["vida"]) <= 0 and not bool(estado["porta_usada"]):
		var possui_porta: bool = false
		for runtime: Dictionary in estado["itens"]:
			if not runtime.is_empty() and str((runtime["item"] as Dictionary)["id"]) == "porta":
				possui_porta = true
		if possui_porta:
			estado["porta_usada"] = true
			estado["vida"] = 1
			for runtime: Dictionary in estado["itens"]:
				if not runtime.is_empty():
					runtime["restante"] = 0.0
			_evento(lado, -1, "porta", "A Última Porta impede a morte e prepara todo o tabuleiro.")

func _evento(lado: int, indice: int, tipo: String, texto: String) -> void:
	eventos.append({"tempo": float(instante) * PASSO, "lado": lado, "indice": indice, "tipo": tipo, "texto": texto})

func _gravar_quadro() -> void:
	var estados: Array[Dictionary] = []
	for lado: Dictionary in lados:
		var recargas: Array[float] = []
		for runtime: Dictionary in lado["itens"]:
			if runtime.is_empty():
				recargas.append(-1.0)
			else:
				var item: Dictionary = runtime["item"]
				recargas.append(clampf(1.0 - float(runtime["restante"]) / float(item["recarga"]), 0.0, 1.0))
		estados.append({"vida": lado["vida"], "vida_maxima": lado["vida_maxima"], "escudo": lado["escudo"], "sangramento": lado["sangramento"], "veneno": lado["veneno"], "marca": lado["marca"], "pressa": lado["pressa"], "lentidao": lado["lentidao"], "recargas": recargas})
	quadros.append({"tempo": float(instante) * PASSO, "lados": estados})
