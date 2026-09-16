# Black Oath v0.4 — Godot

Primeira migração oficial do protótipo para **Godot 4 + GDScript**, pensada para desenvolvimento e teste no Android.

## Já funciona neste protótipo
- menu principal;
- início de jornada;
- Ouro, Vida, Determinação e Corrupção;
- escolhas de evento;
- Caçada PvE;
- tabuleiro com 4 itens;
- reorganização tocando em dois itens;
- combate automático por recarga;
- dano e Escudo;
- sinergia da Vela Funerária;
- Ampulheta sem Areia;
- Segundo Coração;
- Duelo contra bot;
- progressão de Ciclos.

## Abrir no celular
1. Instale o **Godot Editor para Android**.
2. Extraia este projeto em uma pasta do aparelho.
3. No Godot, toque em **Importar** e selecione `project.godot`.
4. Abra o projeto e toque no botão de executar.

## Stack
- Godot 4.x
- GDScript
- Renderer: Compatibility
- Projeto base: 720 × 1280, orientação vertical

## Estrutura
- `scenes/` — cenas do jogo
- `scripts/game_state.gd` — estado da jornada
- `scripts/combat_simulator.gd` — simulador de combate separado da interface
- `scripts/main.gd` — fluxo e UI temporária do protótipo

A interface desta versão ainda é propositalmente simples. O objetivo é validar a migração e o núcleo jogável antes de substituir a UI pelos assets dark fantasy definitivos.
