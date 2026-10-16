---
tags: [ "aula/devops/n2", "intermediario", "ci-cd", "traefik", "edge-router", "service-discovery", "runners-self-hosted", "slc", "flashcards" ]
nivel: N2
modulo: "Intermediário"
curso: "devops-ci-cd-pipelines"
titulo_aula: "Edge Routing com Traefik, Descoberta Dinâmica de Serviços e Runners Self-Hosted"
date: 2026-10-16
status: "Homologado"
obras_biblioteca: [ "[[Ficha_Obra_CICD_na_Pratica_CPINFO]]", "[[Fichamento_CICD_Pratica_Cap01_Principios_e_Arquitetura]]" ]
autor_ia: "Gemini"
ultima_edicao_ia: "Gemini"
---

# 🚀 Aula 03: Edge Routing com Traefik e Runners Self-Hosted (Nível N2)

> [!tldr] Resumo Executivo (Totem da Aula)
> - **Conceito Central:** Aplicações conteinerizadas corporativas não devem expor portas diretamente para o sistema operacional host. O roteamento de tráfego de entrada é delegado integralmente ao Traefik (Edge Router dinâmico), enquanto a execução dos passos de deploy no servidor é conduzida por Runners Self-Hosted operando sob agendamento por capacidades (*Capability-based Scheduling*).
> - **Por quê:** Conflitos de portas locais (como dois projetos tentando usar a porta `80` ou `8080`) e abertura de portas SSH desnecessárias criam vulnerabilidades e inviabilizam servidores multi-tenant seguros.
> - **Aplicação no CTDOL:** O Traefik escuta em `80/443`, lê as labels do `docker.sock` em modo somente-leitura e encaminha requisições aos containers na rede interna `proxy-net`. O deploy é acionado por runners isolados por servidor e ambiente (`dev`, `hml`, `prd`).

---

## ⚡ Glossário de Termos Rápidos (Flashcards — Regra 10.1)

- **Edge Router (Roteador de Borda):** Componente de infraestrutura posicionado na fronteira da rede que recebe todo o tráfego HTTP/HTTPS externo e o encaminha para o serviço correto com base em regras de domínio e path.
- **Traefik Proxy:** Roteador moderno nativo para nuvem que se integra diretamente com o Docker, descobrindo novos serviços em tempo real sem exigir reinicializações manuais ou edições estáticas de arquivos de configuração.
- **Service Discovery (Descoberta Dinâmica de Serviços):** Capacidade do Traefik de detectar instantaneamente quando um novo contêiner sobe ou desce no host através de eventos emitidos pelo socket do Docker.
- **`docker.sock` (Socket Unix do Docker):** Ponto de comunicação IPC pelo qual clientes conversam com o daemon do Docker Engine; no Traefik, é montado estritamente como somente-leitura (`:ro`) para mitigar riscos de segurança.
- **Rede `proxy-net`:** Rede virtual do tipo bridge compartilhada entre o container do Traefik e os serviços web das aplicações, permitindo tráfego HTTP interno isolado da rede externa.
- **Labels do Docker:** Metadados chave-valor declarados no `docker-compose.yml` que instruem o Traefik sobre regras de roteamento (ex: `Host('api.ctdol.com.br')`), TLS e balanceamento de carga.
- **Capability-based Scheduling (Agendamento Baseado em Capacidades):** Estratégia de CI/CD em que os jobs de pipeline especificam rótulos no campo `runs-on` (ex: `[self-hosted, centauro, prd]`), garantindo que a tarefa rode no servidor correto e isolado.
- **Runner Group:** Agrupamento lógico de runners no GitHub que restringe quais repositórios e branches têm permissão para disparar execuções em servidores sensíveis de homologação ou produção.

---

## 🚦 1. O Problema da Exposição de Portas no Host

Quando um desenvolvedor novato cria um `docker-compose.yml`, o instinto comum é declarar:

```yaml
# A PRÁTICA ARCAICA (PERIGOSA E COM CONFLITOS):
services:
  app:
    ports:
      - "8080:8000"   # Se outro projeto usar 8080, o deploy quebra!
```

Em um ambiente corporativo com dezenas de microsserviços, essa abordagem causa colisões constantes de portas e expõe serviços internos diretamente à rede local.

### A Abordagem Moderna: Só o Traefik Publica Portas
No nosso padrão, **nenhum container de aplicação publica portas no host**. Todos entram na rede compartilhada `proxy-net`:

```text
INTERNET / USUÁRIOS
        │
        ▼ (Portas 80 e 443 expostas)
┌────────────────────────────────────────────────────────┐
│                    TRAEFIK (Edge Router)               │
│         Monitora o /var/run/docker.sock (:ro)          │
└──────────────────────────┬─────────────────────────────┘
                           │ (Rede Interna proxy-net)
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  App Escalas │   │  App Cargas  │   │   Keycloak   │
│ (Sem ports:) │   │ (Sem ports:) │   │ (Sem ports:) │
└──────────────┘   └──────────────┘   └──────────────┘
```

---

## 🏷️ 2. Como a Rota Nasce com o Label

Para que o Traefik saiba como rotear as chamadas para sua aplicação, você apenas declara **Labels** no `docker-compose.yml`:

```yaml
services:
  app:
    image: ${IMAGE_NAME}:${IMAGE_TAG}
    networks:
      - proxy-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.minhaapp.rule=Host(`${TRAEFIK_HOST}`)"
      - "traefik.http.routers.minhaapp.entrypoints=websecure"
      - "traefik.http.routers.minhaapp.tls=true"
      - "traefik.http.services.minhaapp.loadbalancer.server.port=8000"
```

Assim que o comando `docker compose up -d` termina, o Traefik lê essas labels em tempo real e passa a direcionar as requisições HTTPS do domínio `${TRAEFIK_HOST}` diretamente para a porta interna `8000` do contêiner. Zero paradas, zero reloads!

---

## 🖥️ 3. Arquitetura dos Runners Self-Hosted

Os agentes que executam o deploy dentro dos nossos servidores físicos são os **Runners Self-Hosted** do GitHub Actions:

```text
GitHub Actions Cloud                       Servidor Local AlmaLinux (Host)
┌─────────────────────┐                   ┌───────────────────────────────┐
│  Workflow de Deploy │                   │                               │
│  runs-on:           │                   │  Processo do Runner (Daemon)  │
│  [self-hosted,      │ <=== HTTPS ====>  │  Usuário: 'ctdol'             │
│   centauro, hml]    │                   │  Grupo: 'docker'              │
└─────────────────────┘                   │  Sem privilégios de root      │
                                          └───────────────┬───────────────┘
                                                          │ Executa
                                                          ▼
                                          ┌───────────────────────────────┐
                                          │      Docker Engine Local      │
                                          │  docker compose pull          │
                                          │  docker compose up -d --wait  │
                                          └───────────────────────────────┘
```

### Regras de Governança dos Runners:
1. **Um runner por servidor:** Cada máquina possui seu agente local isolado.
2. **Separação Rígida de Ambientes:** Um runner de `dev` jamais executa tarefas em servidores de `prd`.
3. **Capability-based Scheduling:** Os jobs casam os rótulos do runner com as necessidades do produto.
4. **Segurança de Egress:** O servidor de produção bloqueia conexões arbitrárias de saída, permitindo tráfego apenas para o GitHub e para o registry de imagens (GHCR).

---

## 🧠 4. Exercícios de Fixação Cognitiva

1. **Por que os contêineres de aplicação não devem utilizar a diretiva `ports:` no Docker Compose de produção?**
   * *Resposta esperada:* Para evitar conflitos de portas entre aplicações diferentes no mesmo servidor e garantir que todo o tráfego passe obrigatoriamente pela camada de borda segura e auditada do Traefik.
2. **Como o Traefik descobre que um novo contêiner subiu sem precisar que alguém reinicie o serviço?**
   * *Resposta esperada:* Através da leitura contínua de eventos no socket Unix do Docker (`/var/run/docker.sock`), identificando as labels declaradas pelo contêiner.
3. **Qual é o risco de segurança mitigado ao rodar o processo do Runner Self-Hosted com um usuário comum pertencente apenas ao grupo `docker`?**
   * *Resposta esperada:* Garante o Princípio do Menor Privilégio, impedindo que comandos arbitrários no pipeline obtenham privilégios de `sudo`/root no sistema operacional host.

---

## 🔗 Conexões & Grafo
- **Aula Anterior:** [[01_Modulo_N1_CICD_Contrato_6_Arquivos_Makefile_Docker]]
- **Próxima Aula:** [[03_Modulo_N3_CICD_Pipelines_Promocao_Rollback]]
- **Trilha de Aprendizagem:** [[Trilha_DevOps_CI_CD_GitHub_Actions]]
- **MOC Central do Curso:** [[00_MOC_Curso_DevOps_CICD_Pipelines]]
- **Ficha da BIBLION:** [[Fichamento_CICD_Pratica_Cap01_Principios_e_Arquitetura]]
