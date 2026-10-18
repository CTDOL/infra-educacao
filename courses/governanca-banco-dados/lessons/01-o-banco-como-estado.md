# Aula 01: O banco como estado e a governança da mudança (Nível N0)

## Objetivo
Entender por que a mudança em banco de dados exige um tratamento diferente da mudança de código, e reconhecer os riscos de uma alteração feita fora de controle.

## O problema
Código pode ser reimplantado a partir de um commit. O banco não. Ele guarda dados, e cada mudança se acumula sobre a anterior. Um ajuste de estrutura feito à mão em um ambiente, e esquecido no roteiro de produção, aparece só quando uma requisição falha.

Imagine um sistema com tabelas de clientes e pedidos. A equipe adiciona uma coluna para o status do pedido. Em homologação, o comando é rodado. Em produção, ninguém roda. Na próxima versão do código, a aplicação lê a coluna, recebe um erro e para de funcionar. Nenhuma linha de código estava errada: o estado do banco é que não acompanhava o código.

## Três ideias centrais
1. **Versionar o esquema:** a estrutura do banco fica sob controle de versão, do mesmo jeito que o código. Toda mudança passa por revisão antes de atingir qualquer banco.
2. **Mudança pequena e ordenada:** cada alteração é uma migração, com identificador e ordem. Uma migração já aplicada não é reescrita.
3. **Mudança que não quebra quem usa o banco:** a alteração acontece em fases que coexistem, de forma que a versão antiga continue funcionando até o último consumidor migrar.

## Por que isso importa para a governança
A governança é a régua que decide quando uma mudança pode seguir. Ela responde a três perguntas: esta mudança é rastreável? Ela pode ser repetida sem dano? E, se der errado, até onde é possível voltar? As próximas aulas tratam cada uma dessas perguntas.

## Glossário
- **Esquema:** a estrutura do banco, com tabelas, colunas, chaves e restrições.
- **Migração:** uma alteração do esquema ou dos dados, com identificador e ordem.
- **Estado:** o conjunto de dados e de estrutura em um momento. Banco é estado; código é texto.
- **Governança de mudança:** o conjunto de regras que decide quando e como uma mudança entra.

## Exercícios
1. Liste três situações em que um `ALTER` feito à mão em produção causaria problema.
2. Explique, em duas frases, por que reimplantar código é mais simples do que reimplantar um banco.
3. Dê um exemplo de mudança de banco que você consideraria arriscada, e diga por quê.

## Verificação rápida
- Por que um `ALTER` feito à mão em produção é um risco?
- Qual é a diferença entre reimplantar código e reimplantar um banco?
