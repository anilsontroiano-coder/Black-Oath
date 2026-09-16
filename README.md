# Black Oath — Protótipo v0.2

Protótipo mobile estratégico dark fantasy inspirado no loop de runs e auto-battler, com regras e identidade próprias.

## Stack
- TypeScript
- Phaser 3
- Vite
- UI HTML/CSS sobre o canvas
- Simulação de combate separada da renderização

## O que entrou na v0.2
- Run estruturada em: Escolha → Escolha → Caçada → Escolha → Duelo
- 12 itens, incluindo itens fantasiosos do universo
- 6 tipos de encontros
- Mercador com compra por Ouro
- Mercador de Sangue com compra por Vida Máxima
- Ferreiro com melhorias de item
- Capela para reduzir Corrupção
- Bosque com escolhas de itens
- Sistema de Corrupção influenciando raridade e dificuldade
- Caçadas PvE com risco e recompensas diferentes
- Duelo contra bots com arquétipos de build
- O Corvo revela informações parciais do próximo oponente
- Reorganização do tabuleiro antes do Duelo tocando em dois itens
- Mais efeitos de combate: banimento temporário, auto-sacrifício, aceleração adjacente, cargas e explosões
- Quatro cenários diferentes usados conforme a etapa da run
- Interface otimizada para tela vertical de celular

## Rodar
```bash
npm install
npm run dev
```

## Build
```bash
npm run build
```

## Próximo alvo
- Relíquias e Familiares
- O Juramento no início de cada Ciclo
- Chefe final da run
- Arrastar itens no tabuleiro
- Áudio e efeitos visuais de ativação
- Salvamento local

## Android / APK
O projeto também está preparado para empacotamento Android com Capacitor 8. Consulte `GERAR-APK-NO-CELULAR.md`. O workflow `.github/workflows/build-android-apk.yml` gera um APK instalável pelo GitHub Actions.
