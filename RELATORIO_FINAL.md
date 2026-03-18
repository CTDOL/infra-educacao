# Relatório de Implementação: Moodle & ERPNext (CTDOL)

Este documento detalha as configurações realizadas para a estabilização das plataformas no servidor cPanel/Docker.

---

## 🏗️ 1. Moodle (edu.ctdol.com.br)
**Status:** Operacional e Segurado.

### Configurações Realizadas:
- **Versão:** Moodle 4.5+ Stable.
- **PHP:** 8.3 via LiteSpeed.
- **Correção Crítica:** O servidor exigia o manipulador `application/x-httpd-ea-php83___lsphp` para evitar erro 404 em arquivos PHP.
- **Moodledata:** Localizado em `/home/ctdolc07/moodledata` (fora da raiz pública para segurança).
- **Cron Job:** Configurado no Crontab do usuário para rodar de 1 em 1 minuto:
  ```bash
  /usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cron.php
  ```

### Próximos Passos (Moodle):
1.  **Configuração de E-mail:** Acessar *Administração do Site > Servidor > E-mail* e configurar os dados do SMTP da CTDOL.
2.  **Personalização de Tema:** O tema padrão (Boost) está ativo. Você pode instalar novos temas via painel.

---

## 🐳 2. ERPNext (erp.ctdol.com.br)
**Status:** Operacional em ambiente Docker Isolado.

### Configurações Realizadas:
- **Arquitetura:** Docker Compose (MariaDB 10.6, Redis Cache/Queue, Nginx Frontend, Gunicorn Backend).
- **Isolamento de Rede:** Rodando internamente na porta **8084** para evitar conflitos com processos Python do sistema.
- **Roteamento Proxy:** Configurado via `.htaccess` para repassar tráfego seguro do Apache para o Docker.
- **Volumes Unificados:** Os volumes `sites-data` e `apps-data` são compartilhados entre os contêineres para garantir que o Nginx consiga servir os arquivos estáticos (CSS/JS).
- **Estabilização de Setup:** 
  - Timeout aumentado para **600s** (10 min).
  - Conexão com Redis injetada manualmente no `common_site_config.json`.

### Próximos Passos (ERPNext):
1.  **Backup Automático:** Recomenda-se configurar um script `bench backup` periódico nos volumes Docker.
2.  **SSL:** O SSL está sendo gerenciado pelo Apache (cPanel AutoSSL). Não altere o `.htaccess` para manter o proxy ativo.

---

## 🔐 Dados de Acesso

### Moodle
- **URL:** [https://edu.ctdol.com.br](https://edu.ctdol.com.br)
- **Admin:** `ctdol_admin`
- **Senha:** `AdminMoodle2026@`

### ERPNext
- **URL:** [https://erp.ctdol.com.br](https://erp.ctdol.com.br)
- **Admin:** `Administrator`
- **Senha:** `AdminERP2026@`

### Banco de Dados (MariaDB Docker)
- **Usuário Root:** `root`
- **Senha:** `senha_forte_erp_ctdol_2024`

---

## 🛠️ Comandos de Manutenção (~/infra-educacao)
- **Ver status:** `docker-compose ps`
- **Reiniciar tudo:** `docker-compose restart`
- **Ver erros em tempo real:** `docker-compose logs -f backend`

🚀 **Projeto Finalizado com Sucesso.**
