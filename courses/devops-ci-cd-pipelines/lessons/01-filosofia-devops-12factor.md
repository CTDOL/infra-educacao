---
tags: [ "aula/devops/n0", "fundamentos", "ci-cd", "12-factor-app", "pull-based", "slc", "flashcards" ]
nivel: N0
modulo: "Onboarding"
curso: "devops-ci-cd-pipelines"
titulo_aula: "Filosofia DevOps, 12-Factor App, Ciclo de Imutabilidade e o Modelo Pull-Based"
date: 2026-10-16
status: "Homologado"
obras_biblioteca: [ "[[Ficha_Obra_CICD_na_Pratica_CPINFO]]", "[[Fichamento_Engenharia_Software_Moderna_Cap_10]]" ]
autor_ia: "Gemini"
ultima_edicao_ia: "Gemini"
---

# 🔰 Aula 01: Filosofia DevOps, 12-Factor App e o Modelo Pull-Based (Nível N0)

> [!tldr] Resumo Executivo (Totem da Aula)
> - **Conceito Central:** DevOps não é apenas um conjunto de ferramentas, mas uma cultura de engenharia que elimina o clássico "Muro da Confusão" entre quem cria código (Dev) e quem sustenta a operação (Ops). Essa cultura apoia-se em entregas automatizadas, imutabilidade de artefatos (*Build Once, Deploy Many*) e arquitetura desacoplada via 12-Factor App.
> - **Por quê:** O método antigo de copiar arquivos manualmente por FTP ou rodar `git pull` direto no servidor via SSH gera inconsistências ("na minha máquina funciona"), risco de indisponibilidade em massa e vazamento de segredos.
> - **Aplicação no CTDOL:** Adotamos pipelines que constroem a imagem Docker uma única vez com tag de commit imutável (`sha-<sha7>`). Os servidores executam agentes *pull-based* (Runners Self-Hosted) que buscam trabalho sem expor nenhuma porta SSH de entrada.

---

## ⚡ Glossário de Termos Rápidos (Flashcards — Regra 10.1)

- **Muro da Confusão:** Conflito histórico em que o time de desenvolvimento busca lançar novidades rapidamente (incentivo à mudança), enquanto o time de operações busca congelar o ambiente para evitar falhas (incentivo à estabilidade). O DevOps alinha ambos sob automação contínua.
- **CI (Continuous Integration / Integração Contínua):** Prática de mesclar o código no branch principal várias vezes ao dia, disparando testes e análises automáticas a cada commit para identificar bugs precocemente.
- **CD (Continuous Delivery / Entrega Contínua):** Extensão do CI onde cada alteração aprovada gera um artefato empacotado e testado, pronto para ser publicado em produção com um único clique de aprovação.
- **Continuous Deployment (Implantação Contínua):** Estágio avançado onde o deploy em produção ocorre de forma 100% autônoma, sem intervenção humana, imediatamente após o pipeline passar com sucesso.
- **12-Factor App (Metodologia dos Doze Fatores):** Conjunto de boas práticas de arquitetura para construção de aplicações modernas e escaláveis em nuvem e contêineres.
- **Factor III (Config):** Princípio do 12-Factor que exige que toda configuração que varie entre ambientes (URLs, senhas, portas) seja injetada em runtime, nunca embutida no código ou na imagem Docker.
- **Factor V (Build, Release, Run):** Princípio do 12-Factor que separa estritamente a fase de compilação da fase de lançamento e da fase de execução.
- **Build Once, Deploy Many (Construa uma vez, implante em muitos):** Padrão de engenharia onde a mesma imagem de software testada em desenvolvimento é promovida para homologação e produção sem passar por uma nova compilação.
- **Tag Imutável (`sha-<sha7>`):** Identificador exclusivo de uma imagem de container amarrado ao hash criptográfico SHA do commit Git exato que a originou.
- **Pull-Based Agent Model (Modelo de Agente Baseado em Puxada):** Arquitetura de segurança em que o servidor local consulta a nuvem periodicamente via HTTPS de saída em busca de tarefas pendentes, eliminando a necessidade de portas SSH abertas na entrada.
- **Runner Self-Hosted:** Computador ou servidor próprio da instituição configurado com um serviço leve que executa os passos dos workflows do GitHub Actions localmente dentro da sua rede interna.
- **Promotion by Reference (Promoção por Referência):** Ação de apontar uma nova tag semântica (ex: `v1.2.0`) para o mesmo hash/digest de uma imagem já compilada, sem recompilar uma única linha de código.

---

## 🧱 1. O Problema Histórico: O "Muro da Confusão"

Para um iniciante em tecnologia, entender o motivo de existir **CI/CD** começa ao observar a divisão arcaica da indústria de software:

```text
┌──────────────────────────────┐        M U R O        ┌──────────────────────────────┐
│       DESENVOLVIMENTO        │          D A          │          OPERAÇÃO            │
│  "Criei uma funcionalidade!  │  ═══════════════════  │  "O sistema caiu após o      │
│   Na minha máquina roda!"    │    C O N F U S Ã O    │   deploy. Não mexam em nada!"│
│  (Métrica: Novas Releases)   │                       │  (Métrica: 99.9% Uptime)     │
└──────────────────────────────┘                       └──────────────────────────────┘
```

Quando a entrega é manual (feita por SSH, FTP ou scripts caseiros), a equipe tem medo de fazer deploy. O intervalo entre versões aumenta de dias para meses. Quando o lançamento finalmente acontece, acumulam-se dezenas de alterações não testadas juntas, gerando incidentes graves de produção.

> [!quote] Axioma de Jez Humble & David Farley
> *"Se dói, faça com mais frequência. Automatize até que lançar software deixe de ser um evento traumático e passe a ser um ato banal de rotina."*

---

## 🎯 2. Os Três Estágios da Entrega de Software

```text
┌──────────────┐     Build & Teste Automático     ┌────────────────────────┐
│  Código Git  │ ───────────────────────────────> │ Integração Contínua    │
└──────────────┘                                  │ (CI - Lint e Testes)   │
                                                  └───────────┬────────────┘
                                                              │
                                            Artefato Pronto   ▼
                                                  ┌────────────────────────┐
                                                  │ Entrega Contínua       │
                                                  │ (CD - Pronto p/ Deploy)│
                                                  └───────────┬────────────┘
                                                              │
                                            Gate Manual (HML) ▼
                                                  ┌────────────────────────┐
                                                  │ Produção Segura        │
                                                  │ (Release Homologada)   │
                                                  └────────────────────────┘
```

1. **Integração Contínua (CI):** O código é testado contra suites unitárias e checado por linters de formatação a cada *Pull Request*. Se quebrar, o pipeline avisa na hora.
2. **Entrega Contínua (Continuous Delivery):** A imagem é gerada, rotulada e publicada no repositório de pacotes (GHCR). O ambiente aguarda apenas a autorização do responsável técnico para subir.
3. **Implantação Contínua (Continuous Deployment):** A aprovação humana é dispensada; se a bateria automatizada de testes for 100% verde, o código vai direto para o usuário final.

---

## 🏛️ 3. O 12-Factor App na Prática do CTDOL

Toda a arquitetura que você aprenderá neste curso é orientada pela metodologia internacional **12-Factor App**:

### Factor III: Configurações em Runtime (Zero Segredos na Imagem)
* **A regra:** O mesmo contêiner deve ser capaz de rodar na máquina do desenvolvedor (`dev`), no ambiente de testes (`hml`) e no datacenter corporativo (`prd`).
* **Como fazemos:** O arquivo `Dockerfile` nunca contém senhas, chaves de API ou nomes de domínio. Ele compila a aplicação de forma neutra. Na hora em que o contêiner sobe no servidor, o GitHub Actions injeta um arquivo de ambiente (`app.env`) com as variáveis específicas daquele servidor.

### Factor V: Build, Release e Run (Três Etapas Rígidas)
* **Build (Construção):** Transforma o código-fonte em um contêiner imutável rotulado com a tag `sha-<sha7>`. É aqui que rodam `composer install` ou `npm run build`.
* **Release (Lançamento):** Pega a imagem já construída no passo anterior e vincula a uma versão semântica (`v1.0.0`) ou de homologação (`v1.0.0-rc.1`). **Nenhum rebuild é permitido nesta fase.**
* **Run (Execução):** O servidor inicia o processo do contêiner associado à sua configuração de ambiente.

---

## 🔒 4. A Revolução do Modelo: Push via SSH vs Pull-Based com Runner

Tradicionalmente, pipelines tentavam conectar no servidor através de comandos remotos:

```text
Abordagem Antiga (Frágil / Insegura - Push SSH):
GitHub (Nuvem)  ──[ Conexão SSH de Entrada Porta 22 ]──>  Servidor de Produção
(Exige IP público fixo no servidor e chave root privada guardada na nuvem)

Abordagem Moderna CTDOL (Segura / Pull-Based Agent):
GitHub (Nuvem)  <──[ Consulta Ativa HTTPS Outbound Porta 443 ]──  Runner Self-Hosted
(Zero portas de entrada abertas; o servidor pergunta se há trabalho pendente)
```

### Por que o modelo Pull-Based é superior?
1. **Zero Exposição:** O servidor pode estar atrás de NAT, firewall corporativo ou VPN; não é necessário abrir portas no roteador para o GitHub.
2. **Sem Chaves SSH na Nuvem:** Se a conta do GitHub for comprometida, o invasor não ganha uma chave SSH com acesso direto de terminal ao seu sistema operacional.
3. **Princípio do Menor Privilégio:** O runner roda com um usuário restrito do sistema operacional (`ctdol`), pertencente apenas ao grupo `docker`. Ele não possui privilégios de `sudo`.

---

## 🧠 5. Exercícios de Fixação Cognitiva

1. **Por que é proibido compilar o código novamente ao promover uma aplicação de Homologação (HML) para Produção (PRD)?**
   * *Resposta esperada:* Porque uma nova compilação pode baixar uma dependência atualizada silenciosamente de última hora ou rodar em condições ligeiramente diferentes, violando a certeza de que o que foi testado em HML é exatamente o que vai rodar em PRD (*Build Once, Deploy Many*).
2. **Qual é a diferença de segurança entre um pipeline que faz deploy via SSH e um que utiliza Runner Self-Hosted?**
   * *Resposta esperada:* O deploy via SSH exige que o servidor exponha uma porta de entrada na internet e guarde credenciais de acesso na nuvem (push). O runner self-hosted opera em modo pull, consultando tarefas por HTTPS de saída sem abrir portas no servidor.
3. **De acordo com o Factor III do 12-Factor App, onde devem residir senhas de banco de dados e chaves de criptografia?**
   * *Resposta esperada:* Estritamente fora da base de código e da imagem Docker, sendo injetadas em tempo de execução através de variáveis de ambiente gerenciadas com segurança (GitHub Environments).

---

## 🔗 Conexões & Grafo
- **Próxima Aula:** [[01_Modulo_N1_CICD_Contrato_6_Arquivos_Makefile_Docker]]
- **Trilha de Aprendizagem:** [[Trilha_DevOps_CI_CD_GitHub_Actions]]
- **MOC Central do Curso:** [[00_MOC_Curso_DevOps_CICD_Pipelines]]
- **Ficha Mestra da BIBLION:** [[Ficha_Obra_CICD_na_Pratica_CPINFO]]
