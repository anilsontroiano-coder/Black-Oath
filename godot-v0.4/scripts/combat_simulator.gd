extends RefCounted
class_name CombatSimulator

const LIMITE := 30.0
const PASSO := 0.1

static func lutar(jogador_itens: Array[Dictionary], inimigo_itens: Array[Dictionary], vida_jogador := 100, vida_inimigo := 100) -> Dictionary:
    var j = _preparar_lado(jogador_itens, vida_jogador)
    var i = _preparar_lado(inimigo_itens, vida_inimigo)
    var tempo := 0.0
    var logs: Array[String] = []

    while tempo < LIMITE and j.vida > 0 and i.vida > 0:
        tempo += PASSO
        _tick_lado(j, i, PASSO, tempo, logs, true)
        if i.vida <= 0:
            break
        _tick_lado(i, j, PASSO, tempo, logs, false)

    if j.vida > 0 and i.vida > 0:
        var condenacao := 5
        while j.vida > 0 and i.vida > 0 and condenacao <= 100:
            tempo += 1.0
            _aplicar_dano(j, condenacao)
            _aplicar_dano(i, condenacao)
            logs.append("Condenação: ambos sofrem %d de dano." % condenacao)
            condenacao += 5

    var vitoria := j.vida > i.vida
    return {
        "vitoria": vitoria,
        "vida_jogador": max(j.vida, 0),
        "vida_inimigo": max(i.vida, 0),
        "tempo": tempo,
        "logs": logs
    }

static func _preparar_lado(itens: Array[Dictionary], vida: int) -> Dictionary:
    var runtime: Array[Dictionary] = []
    for item in itens:
        runtime.append({"item": item.duplicate(true), "restante": float(item.recarga)})
    return {"vida": vida, "escudo": 0, "itens": runtime}

static func _tick_lado(atacante: Dictionary, defensor: Dictionary, dt: float, tempo: float, logs: Array[String], jogador: bool) -> void:
    var itens: Array = atacante.itens
    for idx in range(itens.size()):
        var runtime: Dictionary = itens[idx]
        runtime.restante -= dt
        if runtime.restante <= 0.0:
            var item: Dictionary = runtime.item
            runtime.restante += float(item.recarga)
            var nome_lado := "Você" if jogador else "Inimigo"

            var dano := int(item.dano)
            if item.id == "segundo_coracao" and atacante.vida <= 50:
                dano = 18
            if dano > 0:
                _aplicar_dano(defensor, dano)
                logs.append("[%.1fs] %s ativa %s e causa %d de dano." % [tempo, nome_lado, item.nome, dano])

            var ganho_escudo := int(item.escudo)
            if ganho_escudo > 0:
                atacante.escudo += ganho_escudo
                logs.append("[%.1fs] %s ganha %d de Escudo com %s." % [tempo, nome_lado, ganho_escudo, item.nome])

            if item.id == "vela_funeraria" and idx + 1 < itens.size():
                itens[idx + 1].restante = max(0.0, float(itens[idx + 1].restante) - 1.2)
                logs.append("[%.1fs] Vela Funerária adianta o item à direita." % tempo)

            if item.id == "ampulheta_sem_areia" and itens.size() > 1:
                var alvo_idx := -1
                var maior_restante := -1.0
                for k in range(itens.size()):
                    if k == idx:
                        continue
                    if float(itens[k].restante) > maior_restante:
                        maior_restante = float(itens[k].restante)
                        alvo_idx = k
                if alvo_idx >= 0:
                    itens[alvo_idx].restante = max(0.0, float(itens[alvo_idx].restante) - 2.0)
                    logs.append("[%.1fs] Ampulheta sem Areia rouba tempo do item mais lento." % tempo)

static func _aplicar_dano(alvo: Dictionary, dano: int) -> void:
    var restante := dano
    if alvo.escudo > 0:
        var absorvido: int = min(alvo.escudo, restante)
        alvo.escudo -= absorvido
        restante -= absorvido
    if restante > 0:
        alvo.vida -= restante
