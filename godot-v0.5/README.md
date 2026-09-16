# BLACK OATH v0.5 — O preço da promessa

Jogo estratégico de fantasia sombria, **nativo em Godot 4.4.1 + GDScript**, 2D, vertical e voltado a Android. Esta versão foi construída em uma pasta nova; `godot-v0.4` permanece intacta.

## Jogar no celular

O APK é produzido pelo processo **BLACK OATH v0.5 · Testes e APK Godot**, na aba **Actions** do repositório. Abra uma execução concluída, baixe o artefato **BLACK-OATH-v0.5-Android**, extraia o ZIP e abra `BLACK-OATH-v0.5.apk`. É uma instalação de teste assinada com chave de depuração, não uma publicação na loja.

Também é possível abrir o código no **Godot Editor para Android 4.4.1 ou superior**: extraia o ZIP, importe `godot-v0.5/project.godot` e execute a cena principal. Use o renderizador **Compatibilidade**. O código foi verificado em Godot 4.4.1.

## O que está jogável

- Menu, seleção do Errante, configurações e retomada da jornada salva.
- Juramento → duas Escolhas → Caçada → duas Escolhas → O Corvo → Preparação → Duelo.
- Meta de **quatro vitórias**, seguida de Caçada Final e Rei sem Sombra. Derrotas podem exigir mais de quatro ciclos.
- Vida, Ouro, Determinação, Corrupção e Improviso com limite de uma recompensa por ciclo.
- Oito espaços em duas linhas, troca por dois toques, arraste entre espaços e reserva de doze itens.
- Doze itens, quatro raridades, venda e melhorias no Ferreiro.
- Escudo, Sangramento, Veneno, Pressa, Lentidão e Marca.
- Três juramentos com benefícios e sacrifícios cumulativos; Preço de Sangue com pagamentos alternativos.
- Uma Relíquia e um Familiar em espaços próprios: duas opções de cada.
- Quatro arquétipos de adversários, construídos dentro de um orçamento. Sua Vida não cresce a cada ciclo.
- O Corvo revela duas pistas do mesmo adversário que será enfrentado; a composição completa só aparece no combate.
- Corrupção altera acesso a itens, equipamento dos inimigos, recompensa das Caçadas e acolhimento na Capela. Em 100, abre um pacto perigoso.
- Batalhas reproduzidas com barras de recarga, efeitos, registro e velocidades 1×/2×/4×. É possível pular a animação.
- Cenário, ícones e retratos próprios; tipografia Cinzel; tratamento de época apenas no cenário.
- Música original, impactos, sino e toque. Música, efeitos, movimento e filtro podem ser desligados.
- Salvamento automático após ações e antes da reprodução do combate, preservando resultado e sorteios ao fechar o aplicativo.

## Regras que exigiam decisões no protótipo

1. **Ações simultâneas:** todos os itens prontos nos dois lados são coletados antes de aplicar dano, Cura e Escudo. Duas mortes no mesmo instante são empate. Não há desempate oculto a favor do jogador.
2. **Condenação:** começa exatamente aos 31 s, com 5 de dano; aumenta 5 por segundo, atravessa Escudo e não interrompe os itens.
3. **Vida da jornada:** ferimentos de Caçadas vencidas permanecem. Uma Caçada perdida causa retirada com até 12 de Vida perdida, sem recompensa. O próximo ciclo restaura a Vida; isso é reinício de ciclo, não Cura.
4. **Determinação:** derrota em Duelo custa 2; empate custa 1. A Sentinela Final custa 2 em derrota ou empate. O confronto com o Rei encerra a jornada.
5. **Improviso:** concede 2 de Ouro na primeira aquisição de uma categoria ainda não possuída naquele ciclo. Considera tabuleiro e reserva e não é reativado por venda e recompra no mesmo ciclo.
6. **Espaço cheio:** a compra falha sem cobrar; a recompensa de item da Caçada difícil é convertida em seu valor de Ouro quando tabuleiro e reserva estão cheios. Nunca há substituição aleatória.
7. **Rei sem Sombra:** copia toda terceira ativação de cada item do jogador. A cópia aplica as regras do item pelo lado do Rei e não desencadeia novas cópias. A Última Porta impede a morte uma vez por combate.
8. **Relíquias e familiares:** adquirir outro substitui o vínculo daquele tipo, como informado antes da compra. Não ocupam espaços comuns.

## Arquitetura

| Pasta | Responsabilidade |
|---|---|
| `dados/` | Itens, juramentos, vínculos e inimigos |
| `nucleo/jornada.gd` | Transições, economia, aquisição e progressão |
| `nucleo/simulador_combate.gd` | Simulação determinística sem dependência gráfica |
| `nucleo/bots.gd` | Arquétipos, orçamento e pistas |
| `nucleo/tabuleiro.gd` | Espaços e adjacências sem atravessar linhas |
| `nucleo/corrupcao.gd` | Faixas e descrição de consequências |
| `nucleo/salvamento.gd` | Arquivo versionado, escrita temporária e leitura sem objetos |
| `interface/` | Telas, tema, inspeção e interação por toque |
| `arte/`, `efeitos/` | Texturas, retratos, ícones e tratamento visual |
| `audio/` | Reprodução de música e efeitos |
| `testes/`, `ferramentas/` | Verificação, simulação em lote e geração do áudio |

Não há HTML, navegador incorporado, serviços remotos ou dependência de rede durante o jogo. Os arquivos de itens são definições imutáveis; cada instância guarda somente identidade e raridade. A interface reproduz quadros gerados pelo simulador, sem controlar suas regras.

## Verificar

Na pasta `godot-v0.5`, com o executável `godot` disponível:

```sh
godot --headless --editor --quit
godot --headless --script testes/verificar.gd
godot --headless --script testes/interface.gd
godot --headless --script ferramentas/simular.gd -- 1000
```

Os testes da interface usam uma jornada de teste e escrevem o salvamento. Execute em um perfil separado se houver uma jornada pessoal a preservar. O processo automatizado executa tudo em um ambiente descartável.

Para capturas reais do renderizador, em um computador com ambiente gráfico:

```sh
godot --audio-driver Dummy -- --captura
```

Esse modo é restrito a versões de depuração. As imagens são gravadas em `user://capturas/`. Avisos de GDScript são tratados como erros nas configurações do projeto.

## Exportação Android

O arquivo `export_presets.cfg` inclui o perfil `Android`, para ARMv7 e ARM64. O processo `.github/workflows/godot-v05.yml` importa, testa, captura a interface e só então exporta o APK. Usa Godot oficial 4.4.1, Java 17 e SDK Android 34. Referência: [documentação oficial do Godot 4.4](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html).

## Próximas etapas, ainda não implementadas

Itens que ocupam dois ou três espaços; heróis adicionais; todas as ideias de itens do documento de direção; composições gravadas de jogadores reais; partidas em rede; cosméticos; sete vitórias; publicação na Play Store. Esta versão valida um recorte completo, não promete todo o conteúdo futuro.

O equilíbrio ainda precisa de partidas humanas. Simulação e validação visual em computador não substituem testes de toque, desempenho e retomada em aparelhos Android reais.
