# Aula 01: O banco como estado e a governança da mudança (Nível N0)

## Objetivo
Entender por que a mudança em banco de dados exige um tratamento diferente da mudança de código.

## O problema
Código pode ser reimplantado a partir de um commit. O banco não. Ele guarda dados, e cada mudança se acumula sobre a anterior. Por isso, um ajuste feito à mão em um ambiente e esquecido no roteiro de produção só aparece quando uma requisição falha.

## Três ideias centrais
1. **Versionar o esquema:** a estrutura do banco fica sob controle de versão, do mesmo modo que o código. Toda mudança entra por revisão antes de atingir qualquer banco.
2. **Mudança pequena e ordenada:** cada alteração é uma migração com identificador e ordem. Nenhuma migração já aplicada é reescrita.
3. **Mudança que não quebra quem já usa o banco:** a alteração acontece em fases que coexistem, de forma que a versão antiga continue funcionando até o último consumidor migrar.

## O que você deve levar desta aula
- Mudança de banco é mudança de estado. Reverter nem sempre é possível.
- A governança é a régua que define quando uma mudança pode seguir.

## Verificação rápida
- Por que um `ALTER` feito à mão em produção é um risco?
- Qual é a diferença entre reimplantar código e reimplantar um banco?
