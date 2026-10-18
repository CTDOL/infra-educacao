# Aula 02: Mudança em fases: expandir, migrar e contrair (Nível N1)

## Objetivo
Aplicar o padrão Parallel Change, também chamado Expand and Contract, a uma mudança incompatível de esquema.

## O padrão
Uma mudança incompatível é quebrada em três fases:
- **Expandir:** a estrutura nova passa a existir ao lado da antiga. Nada é removido. O código atual continua funcionando.
- **Migrar:** os dados são copiados ou transformados, e os consumidores passam a usar a estrutura nova, aos poucos.
- **Contrair:** depois que nenhum consumidor usa a estrutura antiga, ela é removida.

## Exemplo em banco
Para renomear uma coluna, a fase de expansão cria a coluna nova e passa a gravar nas duas. A migração copia os dados antigos. Só então as leituras mudam para a coluna nova. A contração remove a coluna antiga.

## Por que funciona
Cada fase pode ser implantada sozinha. O risco fica fatiado, e a versão antiga continua disponível até a migração terminar.

## Cuidado com a contração
A contração é o ponto sem volta. Antes dela, reverter é limpar a estrutura nova. Depois, reverter exige restaurar dados de um backup, com possível perda. Por isso, a contração só acontece depois de um período em que nenhum consumidor usa a estrutura antiga.

## Verificação rápida
- Em qual fase a estrutura antiga é removida?
- Por que a fase de expansão não pode remover nada?
