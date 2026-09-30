# O que são containers

Um **container** é um processo (ou grupo de processos) isolado do restante do sistema, que carrega junto tudo o que a aplicação precisa para rodar: código, bibliotecas e configuração.

## Container não é máquina virtual

| | Máquina virtual | Container |
|---|---|---|
| Isolamento | Sistema operacional completo por VM | Processos isolados que **compartilham o kernel** do host |
| Tamanho | Gigabytes | Megabytes |
| Inicialização | Minutos | Segundos ou menos |

O isolamento vem de recursos do kernel Linux: *namespaces* (o que o processo enxerga) e *cgroups* (quanto de CPU e memória ele pode usar).

## Por que usar

- **Reprodutibilidade:** o mesmo ambiente em desenvolvimento, teste e produção.
- **Portabilidade:** roda em qualquer host com um runtime de containers.
- **Isolamento:** duas aplicações com dependências conflitantes convivem no mesmo servidor.

## Conceitos-chave

- **Docker:** plataforma popular para criar e executar containers.
- **Runtime:** componente que de fato executa o container.
- **Registry:** repositório de imagens (por exemplo, o Docker Hub).
