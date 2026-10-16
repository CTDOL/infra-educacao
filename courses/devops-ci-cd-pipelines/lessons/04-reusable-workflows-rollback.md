---
tags: [ "aula/devops/n3", "avancado", "ci-cd", "reusable-workflows", "crane-tag", "promotion-by-reference", "health-gated-release", "automated-rollback", "slc", "flashcards" ]
nivel: N3
modulo: "Avançado"
curso: "devops-ci-cd-pipelines"
titulo_aula: "Pipelines Reutilizáveis, Promoção Sem Rebuild, Quality Gates e Rollback Automático"
date: 2026-10-16
status: "Homologado"
obras_biblioteca: [ "[[Ficha_Obra_CICD_na_Pratica_CPINFO]]", "[[Fichamento_CICD_Pratica_Cap03_Deploy_HML_Passo_a_Passo]]" ]
autor_ia: "Gemini"
ultima_edicao_ia: "Gemini"
---

# 🧠 Aula 04: Reusable Workflows, Promoção por Referência e Rollback Automático (Nível N3)

> [!tldr] Resumo Executivo (Totem da Aula)
> - **Conceito Central:** A maturidade máxima em CI/CD é alcançada quando a esteira opera como código reutilizável centralizado (Reusable Workflows), imagens são promovidas entre ambientes via ponteiros OCI (`crane tag`) sem reconstrução de binários, e deploys executam checagens de integridade ativas com reversão automática de falhas (*Automated Rollback com Health-Gated Release*).
> - **Por quê:** Deploys manuais sem verificação de integridade geram tempo de indisponibilidade silencioso quando uma aplicação falha ao inicializar.
> - **Aplicação no CTDOL:** A esteira de deploy executa `docker compose up -d --wait`. Se o healthcheck (ex: rota `/up` do Laravel) não responder positivamente dentro da janela de tolerância, o runner automaticamente restaura os arquivos `.prev` e sobe a versão anterior sem intervenção humana.

---

## ⚡ Glossário de Termos Rápidos (Flashcards — Regra 10.1)

- **Reusable Workflow (Workflow Reutilizável):** Recurso do GitHub Actions (`workflow_call`) que permite centralizar toda a lógica complexa de compilação, validação de tags e deploy em um repositório mestre, mantendo os repositórios de produto extremamente leves.
- **Workflow Fino:** Arquivo YAML simples no repositório consumidor que não contém lógica operacional própria, servindo apenas como gatilho que invoca o Reusable Workflow central com `uses:`.
- **Promotion by Reference (Promoção por Referência):** Ação de apontar uma nova tag de versão (`v1.2.0`) diretamente para o digest criptográfico OCI da imagem construída no build, realizada em milissegundos sem download ou reprocessamento de camadas.
- **Google go-containerregistry (`crane`):** Utilitário de linha de comando de alta performance utilizado para manipular e inspecionar imagens diretamente no registry remoto sem necessidade do daemon do Docker Engine.
- **`crane tag`:** Comando que cria ou move uma tag de imagem no GHCR apontando para o mesmo hash SHA256 de forma atômica e idempotente.
- **Protected Environment (Ambiente Protegido):** Configuração no GitHub que exige aprovação formal de revisores designados (*Required Reviewers*) antes de permitir a execução de pipelines em produção.
- **Health-Gated Release (Lançamento Portado por Saúde):** Padrão de implantação em que o pipeline só declara sucesso após o container passar com êxito na verificação de saúde (*Healthcheck*).
- **Automated Rollback (Reversão Automática):** Mecanismo de defesa em que a esteira, ao detectar falha de healthcheck na nova versão, restaura os arquivos de configuração anteriores (`.prev`) e reativa os containers da versão estável precedente.
- **Idempotência de Pipeline:** Propriedade de uma esteira de execução pela qual rodar o mesmo comando múltiplas vezes gera exatamente o mesmo resultado estável, sem corrupção de estado.

---

## 🔄 1. O Ciclo da Imagem: Três Etapas e Zero Rebuild

O fluxo da imagem desde o commit do desenvolvedor até a tela do usuário final obedece à seguinte linha temporal:

```text
┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
│       01. BUILD      │     │      02. RELEASE     │     │      03. DEPLOY      │
│     app-build.yml    │ ──> │    app-release.yml   │ ──> │    app-deploy.yml    │
│  Build, Lint, Test   │     │   Promoção de Tag    │     │ Sobe no Servidor     │
│  Gera: sha-<sha7>    │     │ vX.Y.Z-rc.N / vX.Y.Z │     │ dev · hml · prd      │
└──────────────────────┘     └──────────────────────┘     └──────────────────────┘
```

### Por que usamos `crane tag` no Release?
Em vez de baixar a imagem, rodar `docker tag` e fazer upload de centenas de megabytes novamente, o utilitário `crane` conversa com a API do GitHub Container Registry (GHCR) e cria a nova tag diretamente no servidor de registros:
```bash
crane tag ghcr.io/cpinfo-sdp/escalas-api:sha-a1b2c3d v1.2.0
```
Isso garante **100% de certeza** de que a imagem em produção é rigorosamente idêntica em cada bit à que foi homologada.

---

## 🛡️ 2. Health-Gated Release e Rollback Automático na Prática

O que acontece nos bastidores quando o runner self-hosted executa o deploy?

```text
1. Validação: A tag existe no GHCR? O ambiente aceita essa tag?
      │
2. Backup de Segurança: Grava arquivos atuais em /opt/apps/<projeto>/.prev
      │
3. Pre-Deploy: Roda migrações (ex: php artisan migrate --force)
      │
4. Subida Controlada: docker compose up -d --wait
      │
      ├──> [Healthcheck OK em até 30s]:
      │    Deploy com SUCESSO! Aplicação no ar.
      │
      └──> [Healthcheck FALHOU / Timeout]:
           Aciona AUTOMATED ROLLBACK!
           Restaura arquivos .prev e sobe a imagem anterior.
           O job termina em erro no GitHub, mas o usuário NÃO sofre queda!
```

Esse mecanismo transforma o ato de fazer deploy em um evento sem risco de pânico: se houver um erro grave de inicialização, a esteira se recupera sozinha instantaneamente.

---

## 📋 3. Roteiro Passo a Passo: Deploy em Homologação (HML)

Para o desenvolvedor do dia a dia, a esteira foi desenhada para operar em **4 cliques**:

```text
Passo 1: Abrir a aba Actions no GitHub e rodar o workflow "Build" na branch atual.
Passo 2: No resumo do job Imagem, copiar a tag gerada (ex: sha-a1b2c3d).
Passo 3: Abrir o workflow "Deploy", selecionar o ambiente "hml", colar a tag e disparar.
Passo 4: Aguardar o job terminar verde e validar a URL do Traefik no navegador.
```

Se algo estiver errado no código e você precisar desfazer o deploy, o **Rollback Manual** consiste simplesmente em repetir o Passo 3 informando a tag `sha-<sha7>` da versão estável anterior.

---

## 🧠 4. Exercícios de Fixação Cognitiva

1. **Qual é a vantagem operacional de utilizar o `crane tag` para promover uma imagem de homologação para produção em vez de executar um novo build?**
   * *Resposta esperada:* Garante velocidade instantânea (segundos em vez de minutos) e certeza absoluta de paridade de binários (*Promotion by Reference*), eliminando riscos de desvios entre testes e produção.
2. **Como o comando `docker compose up -d --wait` viabiliza o Rollback Automático?**
   * *Resposta esperada:* O parâmetro `--wait` força o Docker Compose a aguardar que todos os containers atinjam o status de `healthy` antes de liberar o comando. Se o container falhar no teste de saúde, o pipeline captura o erro e restaura a versão anterior (`.prev`).
3. **Por que a regra de concorrência (`cancel-in-progress: false`) é mandatória nos workflows de deploy?**
   * *Resposta esperada:* Para garantir que um deploy em andamento nunca seja abortado pela metade por um novo disparo, evitando corrupção de containers ou estados intermediários de banco de dados.

---

## 🔗 Conexões & Grafo
- **Aula Anterior:** [[02_Modulo_N2_CICD_Edge_Routing_Traefik_Runners]]
- **Trilha de Aprendizagem:** [[Trilha_DevOps_CI_CD_GitHub_Actions]]
- **MOC Central do Curso:** [[00_MOC_Curso_DevOps_CICD_Pipelines]]
- **Ficha da BIBLION:** [[Fichamento_CICD_Pratica_Cap03_Deploy_HML_Passo_a_Passo]]
