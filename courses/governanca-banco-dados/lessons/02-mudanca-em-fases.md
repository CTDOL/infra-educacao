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

## Aprofundamento: os passos do padrão, segundo a fonte

O texto de Wellhausen descreve o padrão como uma sequência de passos com um estado inicial e um estado final. Em resumo:

1. **Estado inicial:** o código lê e grava na estrutura antiga.
2. **Introduzir a estrutura nova e gravar nas duas:** a aplicação passa a escrever nas duas estruturas. Os dados existentes são migrados em seguida, enquanto a escrita redundante continua.
3. **Trocar as leituras:** a partir daí, leituras e escritas passam a afetar só a estrutura nova.
4. **Remover a estrutura antiga:** só depois de a troca estar estável.

A fonte também avisa: "Each step needs to deployed separately and after each step, you need to make sure that the system is fully operational before you can apply the next step." (tradução livre: cada passo precisa ser implantado separadamente, e depois de cada um é preciso confirmar que o sistema está totalmente operacional antes de aplicar o próximo.)

Há um custo que precisa ser previsto: durante a escrita nas duas estruturas, "the number of write operations on the database increases during this period." (tradução livre: o número de operações de escrita no banco aumenta nesse período.) Esse aumento deve entrar no planejamento de capacidade.

O princípio que sustenta tudo está na própria fonte: implementar mudanças incompatíveis em vários passos, de modo que cada passo não quebre o sistema e possa ser revertido. A fonte também registra que a reversão dos passos é simples até um ponto, e que depois dele a reversão exige restauração de backup. Esse ponto é o que a Aula 04 trata como reversão.

**Fontes desta seção:** Tim Wellhausen, *Expand and Contract* (https://www.tim-wellhausen.de/papers/ExpandAndContract/ExpandAndContract.html) e Martin Fowler, *Parallel Change* (https://martinfowler.com/bliki/ParallelChange.html).

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
