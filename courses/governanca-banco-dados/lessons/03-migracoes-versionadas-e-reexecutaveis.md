# Aula 03: Migrações versionadas e reexecutáveis (Nível N2)

## Objetivo
Escrever migrações que podem ser reexecutadas sem quebrar o banco, e entender por que a reexecução acontece.

## Versionamento
Cada migração tem um identificador e uma ordem. Uma migração aplicada nunca é editada. Se algo estiver errado, a correção é uma nova migração que vem depois.

## Por que a reexecução acontece
- Um pipeline falha no meio e é reexecutado do início.
- Alguém roda o script duas vezes por engano.
- Dois ambientes recebem a mesma mudança em momentos diferentes.

Em qualquer desses casos, a migração pode rodar mais de uma vez. Se o segundo disparo falhar com "coluna já existe", um incidente pequeno vira uma implantação bloqueada.

## Idempotência
Uma operação é idempotente quando executá-la uma vez ou várias vezes produz o mesmo estado final. Na prática, há duas formas de obter isso:
1. **Guarda de existência:** antes de criar, verifica-se se o objeto já existe. Por exemplo, usando a cláusula `IF NOT EXISTS`, ou uma consulta ao catálogo do banco.
2. **Tabela de controle:** registra-se quais migrações já foram aplicadas, e o registro não se duplica numa nova execução.

## Exemplo
Uma migração que adiciona a coluna `ultimo_acesso`:
- Versão frágil: `ALTER TABLE usuarios ADD COLUMN ultimo_acesso TIMESTAMP;` falha na segunda execução.
- Versão reexecutável: primeiro verifica se a coluna existe; só então adiciona. A segunda execução não faz nada.

## Um detalhe que depende do motor
Em alguns motores, uma instrução de mudança de esquema é confirmada sozinha. Se uma migração de várias etapas falha no meio, o banco fica pela metade, sem reversão automática. Por isso, a guarda precisa funcionar sem depender de rollback. Antes de escrever a migração, vale saber como o motor trata a mudança de esquema dentro de uma transação.

## Glossário
- **Migração:** arquivo com uma mudança de esquema ou de dados, com identificador e ordem.
- **Idempotente:** que produz o mesmo resultado independentemente do número de execuções.
- **Guarda de existência:** verificação antes de criar ou remover um objeto.
- **Tabela de controle:** registro das migrações já aplicadas no banco.
- **Reexecução:** nova execução de uma migração, por retry ou por engano.

## Exercícios
1. Escreva, em pseudocódigo, uma migração que cria uma tabela `logs_acesso` de forma reexecutável.
2. Explique por que editar uma migração já aplicada em produção pode divergir os ambientes.
3. Dada uma migração que altera três colunas, descreva o que acontece se a execução parar após a segunda.

## Verificação rápida
- Por que editar uma migração já aplicada em produção é um erro?
- O que uma guarda de existência evita?
