# Aula 03: Migrações versionadas e reexecutáveis (Nível N2)

## Objetivo
Escrever migrações que podem ser reexecutadas sem quebrar o banco.

## Versionamento
Cada migração tem um identificador e uma ordem. Uma migração aplicada nunca é editada. Se algo estiver errado, a correção é uma nova migração.

## Por que reexecutar acontece
Um pipeline falha no meio e é reexecutado. Alguém roda o script duas vezes por engano. Dois ambientes recebem a mesma mudança em momentos diferentes. Em qualquer desses casos, a migração pode rodar mais de uma vez.

## Idempotência
Uma operação é idempotente quando executá-la uma vez ou várias vezes produz o mesmo estado final. Na prática, isso se obtém de duas formas:
1. **Guarda de existência:** antes de criar, verifica-se se o objeto já existe. Por exemplo, `IF NOT EXISTS`, ou uma consulta ao catálogo do banco.
2. **Tabela de controle:** registra-se quais migrações já foram aplicadas, de forma que o registro não se duplique em uma nova execução.

## Um detalhe que depende do motor
Em alguns motores, uma instrução de mudança de esquema é confirmada sozinha. Se uma migração de várias etapas falha no meio, o banco fica pela metade, sem reversão automática. Por isso, a guarda precisa funcionar sem depender de rollback.

## Verificação rápida
- Por que editar uma migração já aplicada em produção é um erro?
- O que uma guarda de existência evita?
