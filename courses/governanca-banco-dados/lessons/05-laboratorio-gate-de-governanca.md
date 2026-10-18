# Laboratório: aplicando o gate de governança de banco (Nível N3)

## Objetivo
Analisar uma mudança de banco com a mesma régua de oito critérios usada pelas equipes, e registrar a decisão com evidência.

## O cenário
A equipe quer renomear a coluna `telefone` da tabela `clientes` para `telefone_principal`, e remover a coluna antiga no mesmo passo. O plano é uma única migração, rodada em todos os ambientes na mesma semana.

## Tarefa
Leia o plano acima e responda, para cada critério, se ele está atendido, não atendido, ou não se aplica. Cite a evidência do próprio plano.

| Critério | O que exige | Sua resposta |
| :-: | :--- | :-: |
| G1 | Migração versionada, com identificador e ordem | |
| G2 | Reexecução segura, com guarda de existência | |
| G3 | Mudança destrutiva em fases: expandir, migrar, contrair | |
| G4 | Integridade referencial declarada no esquema | |
| G5 | Privilégio mínimo: a aplicação sem permissão de alterar o esquema | |
| G6 | Auditoria: quem aplicou, quando e com qual identificador | |
| G7 | Reversão declarada, com ponto sem volta identificado | |
| G8 | Mesma migração, mesma ordem, em todos os ambientes | |

## Veredito
Com base na tabela, escolha um dos três vereditos:
- **Aprovado:** todos os critérios aplicáveis, com evidência.
- **Aprovado com lacunas registradas:** G5, G6 ou G7 pendentes, com decisão do responsável anotada.
- **Bloqueado:** qualquer critério G1 a G4 ou G8 sem evidência. A mudança não avança.

## O que esperar
O plano tem um problema central: remover a coluna antiga no mesmo passo quebra a fase de contração. A aplicação que ainda lê `telefone` vai falhar. O veredito correto é **bloqueado**, com a recomendação de dividir o trabalho em três fases.

## Reescrevendo o plano
Refaça o plano em três migrações, uma por fase. Para cada uma, escreva:
1. o identificador;
2. a guarda de existência;
3. a condição para avançar à próxima fase;
4. o que fazer se a fase falhar.

## Glossário
- **Gate:** ponto de controle que impede a mudança de avançar sem evidência.
- **Veredito:** decisão final do gate, com base nos critérios.
- **Evidência:** trecho, arquivo ou registro que comprova um critério.

## Exercícios
1. Reescreva a análise supondo que a equipe tenha uma conta separada para migrações. Quais critérios mudam?
2. Explique por que o veredito "aprovado com lacunas" não serve quando o critério G1 está em aberto.
3. Escreva uma frase que a equipe possa usar para justificar o veredito "bloqueado" a um gerente de produto.

## Verificação rápida
- Qual critério o plano atende melhor, e qual atende pior?
- Em qual fase a coluna antiga deve ser removida?
