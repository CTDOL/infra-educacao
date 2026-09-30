<?php
namespace theme_ctdol\privacy;

defined('MOODLE_INTERNAL') || die();

/** O tema nao armazena dados pessoais. */
class provider implements \core_privacy\local\metadata\null_provider {
    public static function get_reason(): string {
        return 'privacy:metadata';
    }
}
