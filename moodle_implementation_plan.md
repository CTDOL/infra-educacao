# Objetivo
Instalar e configurar o Moodle na plataforma cPanel para o domínio `edu.ctdol.com.br`, salvando o histórico, scripts e planejamento na pasta `infra-educacao`. As configurações são nativas (PHP/Apache/MySQL via cPanel) sem modificar diretivas críticas do sistema que quebrem os padrões exigidos.

## Plano de Execução

1. **Configuração do Banco de Dados**
   - Criar banco de dados MySQL via UAPI do cPanel (`uapi Mysql create_database`).
   - Criar usuário do banco e senha associada (`uapi Mysql create_user`).
   - Atribuir privilégios completos do usuário no banco criado.

2. **Download e Descompactação do Moodle**
   - Baixar a última versão estável do pacote oficial (Moodle 4.x) a partir de `download.moodle.org`.
   - Extrair na raiz do domínio educacional: `~/edu.ctdol.com.br`.

3. **Configuração de Diretórios**
   - Criar e proteger o diretório base de dados do Moodle: `~/moodledata` (fora do `public_html` ou `edu.ctdol.com.br`).
   - Configurar permissões de arquivo/pasta adequadas (755 para pastas, 644 para arquivos via WHM/cPanel default).

4. **Instalação e Configuração (CLI)**
   - Criar e definir as regras no arquivo `config.php` baseado nas constantes mapeadas do ambiente e informações do banco de dados.
   - Instalar banco de dados e idioma inicial (pt_br) através do instalador em modo texto via `php admin/cli/install_database.php`.

5. **Ajustes de Infraestrutura cPanel**
   - Adicionar o cronjob para as rotinas do sistema do Moodle `php /home/ctdolc07/edu.ctdol.com.br/admin/cli/cron.php`.
   - Verificar configurações do PHP e uso correto do Apache e SSL sem quebrar proxy do Cloudflare.

6. **Relatório/Walkthrough Final**
   - Gerar o arquivo final detalhando os acessos e comprovando a funcionalidade da plataforma no arquivo `walkthrough.md`.

## User Review Required
> [!IMPORTANT]
> A instalação será feita nativamente no ambiente do sistema criando bancos de dados em tempo real se a conta possuir privilégios UAPI. Você deseja que as senhas e banco de dados sejam nomeados com prefixo nativo ou possuam algum padrão determinado? O procedimento seguirá executando os comandos em segundo plano (shell).

## Plano de Verificação
- **Automação/Testes:** O cronjob e os primeiros passos poderão ser testados rodando `php admin/cli/cron.php` da raiz do moodle. Acessar manualmente `https://edu.ctdol.com.br` e validar o carregamento da página principal.
- **Testes Manuais:** O usuário precisará entrar ativamente na URL de admin e fazer login com as credenciais iniciais que serão mostradas na execução final (ou salvas em `infra-educacao/moodle-credentials.txt`).
