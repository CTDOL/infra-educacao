<?php
// ==============================================================================
// Moodle Configuration File Template (CTDOL SSoT)
// Copie este arquivo para config.php na raiz do Moodle e preencha as variáveis
// ==============================================================================

unset($CFG);
global $CFG;
$CFG = new stdClass();

// Configurações do Banco de Dados MySQL
$CFG->dbtype    = 'mysqli';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = 'ctdolc07_moodle';
$CFG->dbuser    = 'ctdolc07_moodle';
$CFG->dbpass    = 'SENHA_AQUI'; // Injetada localmente no servidor
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array(
    'dbpersist'     => 0,
    'dbport'        => '',
    'dbsocket'      => '',
    'dbcollation'   => 'utf8mb4_0900_ai_ci',
);

// Endereços e Caminhos do Sistema
$CFG->wwwroot   = 'https://edu.ctdol.com.br';
$CFG->sslproxy  = true; // Ativo por trás do proxy Cloudflare / Apache
$CFG->dataroot  = '/home/ctdolc07/moodledata';
$CFG->admin     = 'admin';

// Permissões de Diretório padrão WHM/cPanel
$CFG->directorypermissions = 02777;

// Carregamento do core do Moodle
require_once(__DIR__ . '/lib/setup.php');

// Não adicione tag de fechamento PHP
