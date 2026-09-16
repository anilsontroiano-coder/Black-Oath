# v0.5 — O preço da promessa

A v0.4 foi lida antes da implementação. Esta atualização cria uma base nova e independente na pasta `godot-v0.5`, atendendo ao pedido de reconstrução. Nenhum arquivo da v0.4 é modificado.

Principais problemas da base anterior tratados:

- Compras substituíam um item aleatório quando o tabuleiro estava cheio. Agora há reserva e validação anterior ao pagamento.
- O jogador agia primeiro e podia impedir a resposta de um item já carregado do adversário. Agora a resolução é simultânea.
- A Condenação interrompia os itens. Agora as recargas continuam, com dano crescente a partir de 31 segundos.
- O Corvo mostrava uma frase genérica e o adversário era criado novamente. Agora ele revela duas pistas reais de uma composição persistida.
- A jornada avançava indefinidamente. Agora há meta de quatro vitórias, Caçada Final, chefe e dois tipos de encerramento.
- Interface e dados estavam concentrados em poucos arquivos e havia inferência insegura de `Variant`. A nova arquitetura separa responsabilidades e passa pelo motor com avisos de GDScript tratados como erros.

Consulte o README para conteúdo implementado, decisões de regra e limites do protótipo.
