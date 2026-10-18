# Aula 02: Mudança em fases: expandir, migrar e contrair (Nível N1)

## Objetivo
Aplicar o padrão Parallel Change, também chamado Expand and Contract, a uma mudança incompatível de esquema.

## O padrão
Uma mudança incompatível é quebrada em três fases:
- **Expandir:** a estrutura nova passa a existir ao lado da antiga. Nada é removido. O código atual continua funcionando.
- **Migrar:** os dados são copiados ou transformados, e os consumidores passam a usar a estrutura nova, aos poucos.
- **Contrair:** depois que nenhum consumidor usa a estrutura antiga, ela é removida.

## Exemplo: renomear uma coluna
Suponha que a coluna `nome_cliente` precise se chamar `nome_completo`.
1. **Expansão:** cria-se `nome_completo`. A aplicação passa a gravar nas duas colunas. As leituras continuam usando `nome_cliente`.
2. **Migração:** um processo copia os valores antigos para a coluna nova, em lotes. Quando a cópia termina, as leituras mudam para `nome_completo`.
3. **Contração:** após um período de observação, `nome_cliente` é removida.

Em cada passo, a aplicação continua funcionando. Se algo der errado antes da contração, é possível voltar sem perda.

## Por que funciona
Cada fase pode ser implantada sozinha. O risco fica fatiado, e a versão antiga continua disponível até a migração terminar.

## O ponto sem volta
A contração é o passo mais perigoso. Antes dela, reverter é apagar a estrutura nova. Depois, reverter exige restaurar um backup, com possível perda de dados. Por isso, a contração só acontece depois de um período em que nenhum consumidor usa a estrutura antiga. Um bom critério é esperar um ciclo completo do negócio, como um fechamento mensal, antes de remover.

## Glossário
- **Expansão:** a fase em que a estrutura nova convive com a antiga.
- **Migração de dados:** a fase em que os dados são copiados e as leituras mudam de lugar.
- **Contração:** a remoção da estrutura antiga. É o único passo sem volta fácil.
- **Consumidor:** qualquer parte do sistema ou outro sistema que lê ou grava na estrutura.

## Exercícios
1. Em qual fase a aplicação passa a gravar nas duas colunas? Por quê?
2. Descreva o que aconteceria se a contração fosse feita antes de todos os consumidores migrarem.
3. Quantos dias ou ciclos de negócio você esperaria antes de contrair uma coluna usada em relatório mensal? Justifique.

## Verificação rápida
- Em qual fase a estrutura antiga é removida?
- Por que a fase de expansão não pode remover nada?
