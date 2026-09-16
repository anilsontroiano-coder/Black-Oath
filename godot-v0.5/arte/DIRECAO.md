# Direção de arte — v0.5

Os três atlas/cenários foram gerados para esta versão com a ferramenta integrada de geração de imagens e incorporados ao projeto. Não dependem de arquivos externos ao repositório.

## Cenário — `caminho.png`

Arte vertical para fundo de jogo 2D: posto de passagem gótico em ruínas sob uma lua fria; caminho estreito até um castelo distante; árvores retorcidas nas laterais; Errante encapuzado visto de costas; uma lanterna pequena de luz laranja. Reservar espaço negativo na área superior para a interface. Aparência deliberada de captura de jogo de PS2: geometria poligonal, texturas difusas pequenas e borradas, sombras duras, luz azul simples, discreto pontilhado e poucos detalhes. Azul-marinho, preto, ferro, prata gasta, vermelho escuro e brasa. Sem texto, marca, elementos modernos, anime, desenho infantil ou realismo fotográfico.

## Itens — `itens.png`

Atlas quadrado com quatro linhas e quatro colunas iguais; objetos centralizados em células individuais, com margem, sobre azul-marinho quase preto. Estética igual ao cenário, silhuetas claras em 56 pixels, objetos de inventário poligonais com textura gasta e iluminação dura. Ordem usada no código:

| Linha | Coluna 1 | Coluna 2 | Coluna 3 | Coluna 4 |
|---|---|---|---|---|
| 1 | Lâmina Desgastada | Vela Funerária | Corrente de Ferro | Estrela Adormecida |
| 2 | Segundo Coração | Ampulheta sem Areia | Frasco da Meia-Noite | Dentes da Lua |
| 3 | Chuva no Frasco | Garganta do Sino | Fragmento do Sol Morto | A Última Porta |
| 4 | Lua Negra | Coração do Santo | Corvo de Carniça | Rato de Túmulo |

Sem rótulos, molduras, números ou texto incorporado. A interface recorta cada célula com `AtlasTexture`; o original permanece preservado.

## Retratos — `retratos.png`

Atlas horizontal com quatro colunas e duas linhas de bustos quadrados; silhuetas diferentes, rostos facetados, texturas simples e luz lunar lateral. Ordem: Errante de capuz; Sangrador de tecidos carmesins; Alquimista de máscara medieval; Guardião de elmo de ferro; Ocultista velado com luz lunar; Cavaleiro sem Rosto; Santo Oco de pedra e auréola quebrada; Rei sem Sombra de coroa de ferro. Mesma paleta, margens internas e ausência de textos.

## Interface e áudio

Molduras simples de ferro, cantos discretos, prata e ouro gasto; textos editáveis nativos do Godot. O filtro visual afeta somente o cenário. Cinzel é usado nos títulos e DejaVu Sans nos textos; as licenças estão em `fontes/`.

A música e os três efeitos são sintetizados originalmente por `ferramentas/gerar_audio.py`. A música usa frases espaçadas e acordes menores, sem copiar uma faixa existente. Os controles permitem desligar música, efeitos e movimento.
