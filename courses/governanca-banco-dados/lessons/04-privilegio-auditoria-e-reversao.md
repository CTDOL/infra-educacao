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

## Aprofundamento: o que a OWASP recomenda

**Privilégio mínimo.** A folha de segurança de banco da OWASP recomenda o princípio do menor privilégio na atribuição de permissões às contas: elas devem ter apenas as permissões mínimas necessárias para a aplicação funcionar. Para a maioria das aplicações, a fonte observa que bastam as permissões de leitura, alteração e remoção de dados: "Most applications would only need SELECT , UPDATE and DELETE permissions." (tradução livre: a maioria das aplicações precisaria apenas de permissões de SELECT, UPDATE e DELETE.)

Duas recomendações diretas da mesma fonte:
- "The account should not be the owner of the database as this can lead to privilege escalation vulnerabilities." (tradução livre: a conta da aplicação não deve ser a dona do banco, porque isso pode levar a escalada de privilégio.)
- "Avoid using database links or linked servers." (tradução livre: evite usar links de banco ou servidores vinculados.)

**Auditoria.** A folha de logging da OWASP trata o registro de eventos. Entre os eventos que devem ser registrados, a fonte lista mudanças de configuração e a inicialização e parada de sistemas. Sobre a proteção do registro, o texto afirma: "The logging mechanisms and collected event data must be protected from mis-use such as tampering in transit, and unauthorized access, modification and deletion once stored." (tradução livre: os mecanismos de registro e os dados de eventos precisam ser protegidos contra uso indevido, como adulteração em trânsito e acesso, modificação ou exclusão não autorizados depois de armazenados.)

A fonte também recomenda, para o armazenamento, detectar alteração e copiar o registro para mídia somente leitura o quanto antes. E sobre quem lê o registro: "All access to the logs must be recorded and monitored" e "The privileges to read log data should be restricted and reviewed." (tradução livre: todo acesso aos registros deve ser registrado e monitorado; os privilégios de leitura dos registros devem ser restritos e revisados.)

**Reversão.** O paper de Wellhausen traz o alerta que dá sentido à Aula 04: a reversão de uma etapa de contração "cannot be easily done anymore other by restoring data from a backup" (tradução livre: não pode mais ser feita facilmente, a não ser restaurando dados de um backup). Por isso, antes de contrair, o backup precisa estar verificado.

**Fontes desta seção:** OWASP, *Database Security Cheat Sheet* (https://cheatsheetseries.owasp.org/cheatsheets/Database_Security_Cheat_Sheet.html), OWASP, *Logging Cheat Sheet* (https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html) e Tim Wellhausen, *Expand and Contract* (https://www.tim-wellhausen.de/papers/ExpandAndContract/ExpandAndContract.html).

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
