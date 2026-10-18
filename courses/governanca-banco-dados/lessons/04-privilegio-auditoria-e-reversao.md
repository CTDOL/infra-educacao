# Aula 04: Privilégio mínimo, auditoria e reversão (Nível N3)

## Objetivo
Controlar quem pode mudar o banco, registrar quem mudou e saber até onde é possível voltar.

## Privilégio mínimo
Cada conta de banco recebe apenas as permissões que o sistema precisa para funcionar. Na prática, isso significa separar dois papéis: o que executa migrações e o que a aplicação usa no dia a dia. A aplicação não deve ter permissão de alterar o esquema. Assim, uma falha na aplicação não vira uma alteração destrutiva do banco.

Um exemplo: a aplicação lê e grava nos pedidos, mas não pode apagar tabelas. A migração roda com uma conta própria, usada só durante a implantação.

## Auditoria
A aplicação de cada mudança precisa ficar registrada, com autor, data e identificador. O registro também precisa ser protegido contra alteração:
- detectar se um registro foi modificado ou apagado;
- guardar cópias em mídia somente leitura, quando possível;
- restringir e revisar quem pode ler o registro.

Um registro que pode ser editado por quem ele audita perde o valor de prova.

## Reversão por tipo de mudança
- **Expansão:** reverter remove a estrutura nova. Só se perdem os dados gravados nela depois da expansão.
- **Migração de dados:** reverter limpa a estrutura nova e reinicia a migração. Não há perda enquanto a antiga continua viva.
- **Contração:** reverter exige restaurar um backup. Há perda de dados desde a contração.

## Em produção
A correção de um erro em produção normalmente é uma nova migração para frente, e não uma reversão. Reverter por migração em produção só com ordem explícita e backup verificado.

## Glossário
- **Privilégio mínimo:** princípio de dar a cada conta só as permissões necessárias.
- **Papel:** identidade de acesso no banco, com permissões próprias.
- **Trilha de auditoria:** registro protegido de quem mudou o quê e quando.
- **Ponto sem volta:** o passo a partir do qual reverter depende de backup.
- **Backup verificado:** cópia de segurança que foi restaurada e testada.

## Exercícios
1. Liste as permissões mínimas que uma aplicação de cadastro de clientes precisa.
2. Descreva o que um atacante ganharia se a aplicação tivesse permissão de criar e apagar tabelas.
3. Para uma contração já feita, descreva o plano de reversão, e diga em que momento ele deixa de ser possível sem backup.

## Verificação rápida
- Qual papel deve executar a migração, e qual deve ser o da aplicação?
- Por que a contração é o único passo sem volta fácil?
