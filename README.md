# 🎓 Infraestrutura Moodle LMS — CTDOL

Repositório central de infraestrutura como código (IaC), esteira de CI/CD e scripts de automação operacional para a plataforma de ensino **Moodle LMS** do CTDOL.

## 🔗 Links Oficiais
- **Plataforma de Ensino:** [https://edu.ctdol.com.br](https://edu.ctdol.com.br)
- **Tela de Acesso:** [https://edu.ctdol.com.br/login/index.php](https://edu.ctdol.com.br/login/index.php)
- **Provedor de Identidade (SSO):** [https://sso.ctdol.com.br](https://sso.ctdol.com.br)

---

## 🏗️ Topologia da Infraestrutura
O ambiente é executado de forma nativa e segura na VPS HostGator:
- **SO & Painel:** Linux cPanel/WHM (conta `ctdolc07`).
- **Moodle:** Versão 4.5 Stable sob Apache + LiteSpeed PHP 8.3 (`/usr/local/bin/ea-php83`).
- **Banco de Dados:** MySQL local (`ctdolc07_moodle`).
- **Diretórios na VPS:**
  - Aplicação Web: `/home/ctdolc07/edu.ctdol.com.br/`
  - Dados Protegidos: `/home/ctdolc07/moodledata/`
  - Repositório de Automação: `/home/ctdolc07/infra-educacao/`
  - Backups: `/home/ctdolc07/backups/moodle/`

---

## 🔐 Autenticação Centralizada (Keycloak SSO)
O Moodle CTDOL adota política **Zero Trust**:
- Contas locais manuais desativadas.
- Autenticação exclusiva via OpenID Connect (OIDC) através do botão **"Entrar com Conta CTDOL"** integrado ao realm `moodle` do Keycloak.
- Procedimento de emergência (Break-Glass) documentado em `CLAUDE.md`.

---

## 🚀 Esteira de CI/CD (GitHub Actions)
- **CI (`.github/workflows/ci.yml`):** Validação estática de scripts (`shellcheck`), linting de templates PHP e checagem anti-vazamento de segredos.
- **CD (`.github/workflows/deploy.yml`):** Deploy automatizado em push para `main` com aprovação manual no environment `production`, conectando via SSH com chave restrita (*forced command*).

---

## 🛠️ Scripts Operacionais (`scripts/`)
- `scripts/backup_moodle.sh`: Dump compactado do MySQL e snapshot de configurações com retenção de 7 dias.
- `scripts/status_moodle.sh`: Diagnóstico rápido de conectividade, HTTP 200, MySQL e armazenamento.
- `scripts/revisar_moodle_vps.sh`: Auditoria técnica aprofundada da VPS.
- `scripts/limpar_cache.sh`: Purge oficial de caches via CLI do Moodle.
- `scripts/deploy_ci.sh`: Executado pelo GitHub Actions via SSH restrito.
