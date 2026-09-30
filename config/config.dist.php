<?php
// Template SANITIZADO do config.php do Moodle 4.5 — CTDOL (edu.ctdol.com.br).
// Copie para /home/ctdolc07/edu.ctdol.com.br/config.php e preencha os valores
// marcados com <...>. NUNCA commite o config.php real (esta no .gitignore).
unset($CFG);
global $CFG;
$CFG = new stdClass();

// --- Banco de dados (MySQL local do cPanel) -------------------------------
$CFG->dbtype    = 'mysqli';               // ou 'mariadb' conforme o servidor
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = 'ctdolc07_moodle';
$CFG->dbuser    = '<USUARIO_DB>';         // prefixo cPanel: ctdolc07_...
$CFG->dbpass    = '<SENHA_DB>';           // definir so no servidor
$CFG->prefix    = 'mdl_';
$CFG->dboptions = [
    'dbpersist'   => 0,
    'dbport'      => '',
    'dbsocket'    => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
];

// --- URLs e caminhos -------------------------------------------------------
$CFG->wwwroot   = 'https://edu.ctdol.com.br';
$CFG->dirroot   = '/home/ctdolc07/edu.ctdol.com.br';
$CFG->dataroot  = '/home/ctdolc07/moodledata';   // FORA do web root, nunca exposto
$CFG->admin     = 'admin';
$CFG->directorypermissions = 0755;               // pastas 755 / arquivos 644
$CFG->filepermissions      = 0644;

// --- SSL atras do proxy Cloudflare (Full/Strict) --------------------------
// Cloudflare termina TLS e repassa ao Apache; sem isso o Moodle entra em loop de redirect.
$CFG->sslproxy = true;
// $CFG->reverseproxy = false;  // manter false: wwwroot ja e https publico

// --- Autenticacao Keycloak SSO --------------------------------------------
// O emissor OAuth2/OIDC (realm `moodle`, https://sso.ctdol.com.br/realms/moodle) e o
// client secret sao configurados na UI (Administracao > Servidor > OAuth 2) e guardados
// no banco. NAO colocar segredos aqui. Callback: https://edu.ctdol.com.br/admin/oauth2callback.php
// O metodo ativo `auth` (oauth2) e definido via CLI/UI; Break-Glass: ver CLAUDE.md.
// Descomente SOMENTE para forcar durante emergencia (prefira o comando CLI do CLAUDE.md):
// $CFG->auth = 'manual,oauth2';

// --- Seguranca / operacao --------------------------------------------------
$CFG->passwordsaltmain = '';        // preservar o valor original se existir na instalacao
$CFG->cookiesecure     = true;
$CFG->cookiehttponly   = true;
$CFG->preventexecpath  = true;      // impede alterar caminhos de binarios pela UI
$CFG->disableupdateautodeploy = true;
// $CFG->debug = 0; $CFG->debugdisplay = 0;   // producao: sem debug na tela

// --- Sessao / desempenho (opcional) ---------------------------------------
// $CFG->session_handler_class = '\core\session\file';
// $CFG->localcachedir = '/home/ctdolc07/moodle_localcache';

require_once(__DIR__ . '/lib/setup.php'); // NAO remover esta linha.
// NAO adicionar "?>" ao final do arquivo.
