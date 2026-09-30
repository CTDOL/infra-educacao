<?php
defined('MOODLE_INTERNAL') || die();

$callbacks = [
    [
        'hook' => \core\hook\output\before_standard_head_html_generation::class,
        'callback' => \local_ctdolog\hook_callbacks::class . '::before_standard_head_html_generation',
    ],
];
