# Aula 04: Privilégio mínimo, auditoria e reversão (Nível N3)

## Objetivo
Controlar quem pode mudar o banco, registrar quem mudou e saber até onde é possível voltar.

## Privilégio mínimo
Cada conta de banco recebe apenas as permissões que a aplicação precisa para funcionar. Isso significa separar o papel que executa migrações do papel que a aplicação usa. A aplicação não deve ter permissão de alteração de esquema. Uma falha na aplicação, assim, não vira uma alteração destrutiva do banco.

## Auditoria
A aplicação de cada mudança precisa ficar registrada, com autor, data e identificador. O registro precisa ser protegido contra alteração:
- detectar se um registro foi modificado ou apagado;
- guardar cópias em mídia somente leitura, quando possível;
- restringir e revisar quem pode ler o registro.

## Reversão por tipo de mudança
- **Expansão:** reverter remove a estrutura nova. Só se perdem os dados gravados nela depois da expansão.
- **Migração de dados:** reverter limpa a estrutura nova e reinicia a migração. Não há perda enquanto a antiga continua viva.
- **Contração:** reverter exige restaurar um backup. Há perda de dados.

## Em produção
A correção de um erro em produção normalmente é uma nova migração para frente, e não uma reversão. Reverter por migração em produção só com ordem explícita e backup verificado.

## Verificação rápida
- Qual papel deve executar a migração, e qual deve ser o da aplicação?
- Por que a contração é o único passo sem volta fácil?
