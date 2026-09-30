<?php
// Tema filho do Boost. NAO sobrescreve layouts de login: o fluxo SSO Keycloak
// (auth_oauth2, botao "Entrar com Conta CTDOL") permanece o do core.
defined('MOODLE_INTERNAL') || die();

$THEME->name = 'ctdol';
$THEME->sheets = [];
$THEME->editor_sheets = [];
$THEME->parents = ['boost'];
$THEME->enable_dock = false;
$THEME->yuicssmodules = [];
$THEME->rendererfactory = 'theme_overridden_renderer_factory';
$THEME->requiredblocks = '';
$THEME->addblockposition = BLOCK_ADDBLOCK_POSITION_FLATNAV;
$THEME->haseditswitch = true;
$THEME->usescourseindex = true;
$THEME->iconsystem = \core\output\icon_system::FONTAWESOME;

$THEME->scss = function ($theme) {
    return theme_ctdol_get_main_scss_content($theme);
};
$THEME->prescsscallback = 'theme_ctdol_get_pre_scss';
