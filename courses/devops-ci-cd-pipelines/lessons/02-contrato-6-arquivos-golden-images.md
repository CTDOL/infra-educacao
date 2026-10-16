---
tags: [ "aula/devops/n1", "iniciante", "ci-cd", "makefile", "docker-multistage", "laravel", "vite", "slc", "flashcards" ]
nivel: N1
modulo: "Iniciante"
curso: "devops-ci-cd-pipelines"
titulo_aula: "O Contrato Universal dos 6 Arquivos, Golden Images e Empacotamento Multi-Stage"
date: 2026-10-16
status: "Homologado"
obras_biblioteca: [ "[[Ficha_Obra_CICD_na_Pratica_CPINFO]]", "[[Fichamento_CICD_Pratica_Cap02_Implementacao_Repositorios]]" ]
autor_ia: "Gemini"
ultima_edicao_ia: "Gemini"
---

# 🐣 Aula 02: O Contrato Universal dos 6 Arquivos e Golden Images (Nível N1)

> [!tldr] Resumo Executivo (Totem da Aula)
> - **Conceito Central:** A padronização de esteiras de CI/CD para iniciantes se baseia em um contrato desacoplado: a esteira central não precisa saber se o código é Laravel, React, Vue ou Go. Ela apenas interage com 6 arquivos universais na raiz do projeto.
> - **Por quê:** Sem esse contrato, cada novo repositório exigiria reinventar o pipeline do zero com centenas de linhas de scripts frágeis.
> - **Aplicação no CTDOL:** Todo repositório consumidor implementa: 1 Makefile (com 4 alvos previsíveis), 1 Dockerfile (baseado nas Golden Images institucionais), 1 Docker Compose (sem portas expostas) e 3 workflows enxutos (`build.yml`, `release.yml`, `deploy.yml`) que chamam a esteira reutilizável.

---

## ⚡ Glossário de Termos Rápidos (Flashcards — Regra 10.1)

- **Contrato Universal dos 6 Arquivos:** Conjunto mínimo padronizado de arquivos presentes em todo repositório de software (`Makefile`, `Dockerfile`, `docker-compose.yml`, `.github/workflows/build.yml`, `release.yml`, `deploy.yml`) que permite à esteira automatizada compilar, testar e publicar a aplicação.
- **Makefile:** Arquivo de automação de comandos Unix que expõe alvos universais previsíveis (`install`, `build`, `lint`, `test`), abstraindo as peculiaridades de cada linguagem de programação para a esteira.
- **Golden Image (Imagem Dourada):** Imagem base corporativa pré-construída, otimizada e com patches de segurança semanais contínuos (`laravel-base` e `spa-nginx-base`), que serve de alicerce para todas as aplicações da instituição.
- **Multi-Stage Build (Construção em Múltiplos Estágios):** Técnica do Dockerfile que divide a montagem do contêiner em etapas (ex: `base`, `test`, `prod`), permitindo descartar compiladores e dependências de desenvolvimento antes de gerar a imagem enxuta de produção.
- **Runtime Injection (Injeção em Tempo de Execução):** Técnica usada em SPAs estáticos em que as variáveis de ambiente (como a URL da API) são substituídas dentro do navegador no exato instante em que o contêiner inicia, sem necessidade de reconstruir o JavaScript.
- **`envsubst`:** Utilitário Unix leve que lê um arquivo template contendo variáveis (como `${VITE_API_URL}`) e gera o arquivo final substituindo-as pelos valores reais vindos do ambiente.
- **Âncora YAML (`&app` e `<<: *app`):** Recurso nativo do formato YAML que permite definir uma configuração uma única vez e reutilizá-la em múltiplos serviços do Docker Compose sem repetição de código.
- **Pre-Deploy Command:** Comando opcional disparado pela esteira antes da subida dos contêineres principais para executar tarefas atômicas preparatórias, como migrações de banco de dados (`php artisan migrate --force`).

---

## 📜 1. O Mapa dos 6 Arquivos Universais

Para qualquer projeto que entra na nossa governança de software, a raiz do repositório deve conter rigorosamente estes arquivos:

```text
meu-projeto/
├── Makefile                               # 1. Comandos que a esteira executa
├── Dockerfile                             # 2. Como a aplicação se empacota
├── docker-compose.yml                     # 3. Como a aplicação roda no servidor
└── .github/
    └── workflows/
        ├── build.yml                      # 4. Disparo do build e testes no GHCR
        ├── release.yml                    # 5. Promoção de versão semântica
        └── deploy.yml                     # 6. Disparo do deploy nos ambientes
```

---

## 🛠️ 2. O Makefile: A Interface Amigável da Esteira

O pipeline do GitHub Actions nunca chama diretamente comandos de linguagem como `npm run test` ou `vendor/bin/pint`. Ele interage com 4 alvos padronizados:

```makefile
# Exemplo canônico de Makefile para Backend (PHP/Laravel)
install:
	composer install --no-interaction

build:
	@echo "Aplicação de backend: sem build estático separado"

lint: install
	vendor/bin/pint --test

test:
	docker compose -f docker-compose.test.yml up --abort-on-container-exit
```

*Por que isso é genial para quem está aprendendo?*
Se amanhã você trocar o Laravel por Python ou Node.js, a esteira de CI continuará rodando os mesmos comandos: `make lint` e `make test`. Você apenas ajusta o que cada alvo faz dentro do seu próprio Makefile.

---

## 🎨 3. Frontend SPA Estático: A Mágica da Configuração em Runtime

Um dos maiores desafios de um iniciante em DevOps é entender por que um frontend (React/Vite) compila de forma estática:
- Se você embutir a URL `http://api-dev.ctdol.com.br` no build, essa mesma imagem Docker não conseguirá falar com `http://api.ctdol.com.br` em produção.
- **A Solução CTDOL:** A imagem base `spa-nginx-base` resolve isso em 3 passos simples:

```text
1. O Template (docker/env-config.template.js):
   window.__ENV__ = { VITE_API_URL: "${VITE_API_URL}" };

2. A Invocação no index.html:
   <head>
       <script src="/env-config.js"></script>
   </head>

3. O Hook de Inicialização do Container (40-env-config.sh):
   Na subida, o Nginx roda "envsubst" e grava o "/env-config.js" dinâmico!
```

O seu código no frontend simplesmente consome `window.__ENV__.VITE_API_URL`. A mesma imagem roda em `dev`, `hml` e `prd` sem jamais precisar ser recompilada.

---

## 🐘 4. Backend Laravel: Multi-Stage e Múltiplos Serviços

No backend corporativo, o Dockerfile aproveita o **Multi-Stage Build** a partir da Golden Image `laravel-base:8.3`:

```dockerfile
# Estágio Base (Código e dependências limpas)
FROM ghcr.io/cpinfo-sdp/laravel-base:8.3 AS base
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction
COPY . .
RUN composer dump-autoload --optimize

# Estágio de Testes (Com ferramentas de lint e teste)
FROM base AS test
RUN composer install --no-interaction

# Estágio Final Enxuto de Produção
FROM base AS prod
```

E no `docker-compose.yml`, utilizamos **Âncoras YAML** para rodar múltiplos processos reaproveitando a mesma imagem:

```yaml
x-app: &app
  image: ${IMAGE_NAME}:${IMAGE_TAG}
  env_file: ./app.env

services:
  app:
    <<: *app
    container_name: meu-projeto-${ENVIRONMENT}
    networks: [proxy-net]
    # Labels do Traefik são colocados exclusivamente no serviço HTTP
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://127.0.0.1:8000/up"]

  queue:
    <<: *app
    command: [artisan, queue:work, --tries=3]

  scheduler:
    <<: *app
    command: [artisan, schedule:work]
```

---

## 🧠 5. Exercícios de Fixação Cognitiva

1. **Quais são os 4 alvos obrigatórios que todo Makefile de projeto deve implementar?**
   * *Resposta esperada:* `install`, `build`, `lint` e `test`.
2. **Por que utilizamos o hook `40-env-config.sh` com `envsubst` nas aplicações frontend SPA (Vite/React)?**
   * *Resposta esperada:* Para permitir que as variáveis de ambiente (como a URL da API) sejam injetadas dinamicamente no navegador no momento em que o contêiner inicia, preservando o princípio *Build Once, Deploy Many*.
3. **Qual é a vantagem de utilizar âncoras YAML (`&app` e `<<: *app`) no Docker Compose de uma aplicação Laravel?**
   * *Resposta esperada:* Evitar a repetição de configurações comuns (como nome da imagem e arquivo de variáveis `app.env`) entre o serviço HTTP principal, o worker de filas e o agendador de tarefas.

---

## 🔗 Conexões & Grafo
- **Aula Anterior:** [[00_Modulo_N0_CICD_Filosofia_e_12Factor]]
- **Próxima Aula:** [[02_Modulo_N2_CICD_Edge_Routing_Traefik_Runners]]
- **Trilha de Aprendizagem:** [[Trilha_DevOps_CI_CD_GitHub_Actions]]
- **MOC Central do Curso:** [[00_MOC_Curso_DevOps_CICD_Pipelines]]
- **Ficha da BIBLION:** [[Fichamento_CICD_Pratica_Cap02_Implementacao_Repositorios]]
