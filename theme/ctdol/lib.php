<?php
defined('MOODLE_INTERNAL') || die();

/**
 * SCSS principal: preset padrao do Boost + estilos CTDOL (pos-Bootstrap).
 *
 * @param theme_config $theme
 * @return string
 */
function theme_ctdol_get_main_scss_content($theme) {
    global $CFG;
    $scss  = file_get_contents($CFG->dirroot . '/theme/boost/scss/preset/default.scss');
    $scss .= "\n" . file_get_contents($CFG->dirroot . '/theme/ctdol/scss/post.scss');
    return $scss;
}

/**
 * SCSS carregado ANTES do Bootstrap: tokens/variaveis da identidade CTDOL.
 *
 * @param theme_config $theme
 * @return string
 */
function theme_ctdol_get_pre_scss($theme) {
    global $CFG;
    return file_get_contents($CFG->dirroot . '/theme/ctdol/scss/pre.scss');
}
