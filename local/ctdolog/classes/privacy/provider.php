<?php
namespace local_ctdolog\privacy;

defined('MOODLE_INTERNAL') || die();

/** O plugin nao armazena dados pessoais. */
class provider implements \core_privacy\local\metadata\null_provider {
    public static function get_reason(): string {
        return 'privacy:metadata';
    }
}
