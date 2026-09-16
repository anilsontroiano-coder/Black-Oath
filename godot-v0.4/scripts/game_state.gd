extends Node

var ciclo := 1
var vida := 100
var vida_maxima := 100
var ouro := 10
var determinacao := 8
var corrupcao := 0
var vitorias := 0
var etapa := "escolha"
var escolhas_feitas := 0
var tabuleiro: Array[Dictionary] = []

const ITENS := {
    "lamina_desgastada": {
        "nome": "Lâmina Desgastada",
        "recarga": 6.0,
        "dano": 12,
        "escudo": 0,
        "descricao": "Causa 12 de dano a cada 6 segundos."
    },
    "vela_funeraria": {
        "nome": "Vela Funerária",
        "recarga": 8.0,
        "dano": 0,
        "escudo": 0,
        "descricao": "Ao ativar, adianta em 1,2 s o item à direita."
    },
    "corrente_ferro": {
        "nome": "Corrente de Ferro",
        "recarga": 7.0,
        "dano": 0,
        "escudo": 10,
        "descricao": "Ganha 10 de Escudo a cada 7 segundos."
    },
    "estrela_adormecida": {
        "nome": "Estrela Adormecida",
        "recarga": 18.0,
        "dano": 42,
        "escudo": 0,
        "descricao": "Lenta, mas causa 42 de dano ao despertar."
    },
    "segundo_coracao": {
        "nome": "Segundo Coração",
        "recarga": 9.0,
        "dano": 10,
        "escudo": 0,
        "descricao": "Abaixo de 50% de vida, passa a causar 18 de dano."
    },
    "ampulheta_sem_areia": {
        "nome": "Ampulheta sem Areia",
        "recarga": 10.0,
        "dano": 0,
        "escudo": 0,
        "descricao": "Ao ativar, adianta em 2 s o item mais lento."
    }
}

func nova_jornada() -> void:
    ciclo = 1
    vida = 100
    vida_maxima = 100
    ouro = 10
    determinacao = 8
    corrupcao = 0
    vitorias = 0
    etapa = "escolha"
    escolhas_feitas = 0
    tabuleiro = [
        criar_item("lamina_desgastada"),
        criar_item("vela_funeraria"),
        criar_item("corrente_ferro"),
        criar_item("estrela_adormecida")
    ]

func criar_item(id: String) -> Dictionary:
    var base: Dictionary = ITENS[id].duplicate(true)
    base["id"] = id
    base["nivel"] = 1
    return base

func proxima_etapa() -> void:
    if etapa == "escolha":
        escolhas_feitas += 1
        if escolhas_feitas >= 2:
            etapa = "cacada"
    elif etapa == "cacada":
        etapa = "preparacao"
    elif etapa == "preparacao":
        etapa = "duelo"

func concluir_duelo(vitoria: bool) -> void:
    if vitoria:
        vitorias += 1
        ouro += 5 + ciclo
    else:
        determinacao -= 2
    ciclo += 1
    escolhas_feitas = 0
    etapa = "escolha"
