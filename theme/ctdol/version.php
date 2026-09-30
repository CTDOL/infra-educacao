<?php
// Tema institucional CTDOL (Padrao BM / DTIC) - filho do Boost.
defined('MOODLE_INTERNAL') || die();

$plugin->component = 'theme_ctdol';
$plugin->version   = 2026093001;
$plugin->requires  = 2024100700;   // Moodle 4.5.
$plugin->maturity  = MATURITY_STABLE;
$plugin->release   = '1.0.0';
$plugin->dependencies = [
    'theme_boost' => 2024100700,
];
