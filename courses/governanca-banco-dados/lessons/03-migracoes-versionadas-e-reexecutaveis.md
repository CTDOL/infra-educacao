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

## Aprofundamento: convergir para um estado, e não aplicar um delta

O texto de *Idempotent Script Design* apresenta a idempotência como uma propriedade do efeito: a execução deve chegar ao mesmo estado final, seja uma ou dez vezes. Segundo a fonte, a regra de projeto é fazer cada escrita de dados convergir para um alvo absoluto, e não aplicar uma variação relativa: "make every data write converge to an absolute target rather than apply a relative delta." (tradução livre: fazer cada escrita de dados convergir para um alvo absoluto, em vez de aplicar uma variação relativa.)

Exemplo ilustrativo, que não vem da fonte: uma migração que define `saldo = 100` pode ser repetida sem efeito. Uma que faz `saldo = saldo + 10` acumula o efeito a cada execução. A primeira converge; a segunda não.

A fonte descreve dois mecanismos complementares, e o que cada um cobre:
- a **guarda de existência**, que protege o DDL dentro da própria migração;
- a **tabela de controle**, que permite ao executor pular passos já concluídos.

Há um caso que só a guarda resolve: o intervalo entre a confirmação do DDL e a gravação na tabela de controle. Nesse intervalo, se a execução cair, a tabela ainda não registrou nada. A fonte resume: "The ledger can skip a completed step, but only the inline guard survives the gap." (tradução livre: a tabela de controle pode pular um passo concluído, mas só a guarda interna sobrevive a esse intervalo.)

A dependência do motor também aparece no texto. Segundo a fonte, em alguns motores uma migração de várias etapas pode ficar pela metade sem rollback automático. Por isso, "the guards and ledger must therefore be re-entrant on their own, because the engine offers no safety net." (tradução livre: a guarda e a tabela de controle precisam ser reexecutáveis por si mesmas, porque o motor não oferece rede de segurança.)

Um exemplo do próprio texto de *Writing Database Migrations That Won't Break When Run Twice*: a forma idempotente de adicionar uma coluna usa a cláusula de existência. Quem for escrever migrações deve conhecer essa cláusula no motor que usa, porque a sintaxe varia entre motores.

**Fontes desta seção:** *Idempotent Script Design for Safe, Re-runnable Migrations* (https://www.zero-downtime-schema.com/database-migration-fundamentals-tool-selection/idempotent-script-design/) e *Writing Database Migrations That Won't Break When Run Twice* (https://cicd.ariefw.com/articles/22-2-writing-database-migrations-that-wont-break-when-run-twice/). Sobre o versionamento do esquema, ver também *Why Version a Schema at All* (https://dbschema.com/blog/migrations/why-version-a-schema-at-all/).

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
