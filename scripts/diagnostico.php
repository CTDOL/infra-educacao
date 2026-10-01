<?php
// ==============================================================================
// diagnostico.php — Diagnostico SOMENTE LEITURA do Moodle (pagamento, saude, erros, seguranca)
// Uso: /usr/local/bin/ea-php83 scripts/diagnostico.php [pagamento|saude|erros|seguranca|tudo]
// Nunca imprime segredos (config de gateways, client secrets, senhas) e nunca escreve no banco.
// ==============================================================================
define('CLI_SCRIPT', true);
require '/home/ctdolc07/edu.ctdol.com.br/config.php';
require_once $CFG->libdir . '/clilib.php';

$secao = $argv[1] ?? 'tudo';
$quer = fn(string $s): bool => $secao === 'tudo' || $secao === $s;
$ok = fn($c) => $c ? 'OK' : 'ATENCAO';

function titulo(string $t): void { echo PHP_EOL . "=== $t ===" . PHP_EOL; }
function lin(string $k, $v): void { echo sprintf('  %-34s %s', $k . ':', is_bool($v) ? ($v ? 'sim' : 'nao') : (string)$v) . PHP_EOL; }
function tentar(callable $f): void {
    try { $f(); } catch (Throwable $e) { echo '  (indisponivel: ' . get_class($e) . ': ' . substr($e->getMessage(), 0, 120) . ')' . PHP_EOL; }
}

// ------------------------------------------------------------------ PAGAMENTO
if ($quer('pagamento')) {
    titulo('PAGAMENTO');
    tentar(function () use ($DB) {
        $enrol = explode(',', (string)get_config('core', 'enrol_plugins_enabled'));
        lin('Metodos de matricula ativos', implode(', ', $enrol));
        lin('enrol_fee ativo', in_array('fee', $enrol, true));

        $pm = core_plugin_manager::instance();
        $paygw = $pm->get_plugins_of_type('paygw');
        $habil = \core\plugininfo\paygw::get_enabled_plugins() ?: [];
        lin('Gateways instalados (paygw)', $paygw ? implode(', ', array_keys($paygw)) : 'nenhum');
        lin('Gateways habilitados (global)', $habil ? implode(', ', $habil) : 'nenhum');

        echo '  Contas de pagamento:' . PHP_EOL;
        $contas = $DB->get_records('payment_accounts');
        if (!$contas) { echo '    nenhuma conta cadastrada' . PHP_EOL; }
        foreach ($contas as $c) {
            echo "    - #{$c->id} {$c->name} | conta ativa: " . ($c->enabled ? 'sim' : 'nao') . PHP_EOL;
            // Somente gateway/estado — NUNCA o campo "config" (guarda credenciais).
            $gws = $DB->get_records('payment_gateways', ['accountid' => $c->id], '', 'id,gateway,enabled');
            foreach ($gws as $g) { echo "        gateway {$g->gateway}: " . ($g->enabled ? 'habilitado' : 'desabilitado') . PHP_EOL; }
            if (!$gws) { echo '        sem gateways configurados' . PHP_EOL; }
        }

        echo '  Instancias de matricula paga (enrol_fee):' . PHP_EOL;
        $inst = $DB->get_records_sql("SELECT e.id, e.courseid, c.shortname, e.status, e.cost, e.currency, e.customint1 AS accountid
                                        FROM {enrol} e JOIN {course} c ON c.id = e.courseid WHERE e.enrol = 'fee'");
        if (!$inst) { echo '    nenhuma' . PHP_EOL; }
        foreach ($inst as $i) {
            echo "    - {$i->shortname}: " . ($i->status == 0 ? 'ativa' : 'desativada') . " | {$i->cost} {$i->currency} | conta #{$i->accountid}" . PHP_EOL;
        }

        $n = $DB->count_records('payments');
        lin('Pagamentos registrados', $n);
        if ($n) {
            $r = $DB->get_record_sql('SELECT COUNT(*) n, SUM(amount) total, MAX(timecreated) ultimo FROM {payments}');
            lin('Ultimo pagamento', userdate((int)$r->ultimo));
        }
    });
}

// ----------------------------------------------------------------------- SAUDE
if ($quer('saude')) {
    titulo('SAUDE GERAL');
    tentar(function () use ($DB, $CFG, $ok) {
        require $CFG->dirroot . '/version.php';
        lin('Moodle', "$release ($version)");
        lin('PHP', PHP_VERSION);
        lin('Modo manutencao', (bool)get_config('core', 'maintenance_enabled'));
        lin('Tema ativo', $CFG->theme);
        $cron = (int)get_config('tool_task', 'lastcronstart');
        $cron = $cron ?: (int)get_config('core', 'lastcronstart');
        lin('Ultimo cron', $cron ? userdate($cron) . ' (' . round((time() - $cron) / 60) . ' min atras) ' . $ok(time() - $cron < 900) : 'nunca');
        lin('Tarefas ad hoc na fila', $DB->count_records('task_adhoc'));
        lin('Tarefas agendadas com falha', $DB->count_records_select('task_scheduled', 'faildelay > 0'));
        lin('Cursos', $DB->count_records('course') - 1);
        lin('Usuarios ativos', $DB->count_records('user', ['deleted' => 0, 'suspended' => 0]));
        lin('Matriculas ativas', $DB->count_records('user_enrolments', ['status' => 0]));
        $ult = $DB->get_field_sql('SELECT MAX(timecreated) FROM {logstore_standard_log}');
        lin('Ultima atividade registrada', $ult ? userdate((int)$ult) : 'sem logs');
        $plug = core_plugin_manager::instance()->get_plugins_requiring_dependencies();
        lin('Plugins com dependencias pendentes', count($plug));
    });
}

// ----------------------------------------------------------------------- ERROS
if ($quer('erros')) {
    titulo('ERROS (ultimos 7 dias)');
    tentar(function () use ($DB) {
        $desde = time() - 7 * 86400;
        $f = $DB->get_records_sql("SELECT classname, COUNT(*) n, MAX(timestart) ultimo
                                     FROM {task_log} WHERE result = 1 AND timestart > ?
                                 GROUP BY classname ORDER BY n DESC", [$desde], 0, 15);
        echo '  Tarefas do cron que falharam:' . PHP_EOL;
        if (!$f) { echo '    nenhuma' . PHP_EOL; }
        foreach ($f as $x) { echo "    - {$x->classname}: {$x->n}x (ultima " . userdate((int)$x->ultimo) . ')' . PHP_EOL; }
    });
    tentar(function () use ($CFG) {
        foreach ([$CFG->dirroot . '/error_log', $CFG->dirroot . '/admin/error_log', '/home/ctdolc07/logs/edu.ctdol.com.br.error.log'] as $arq) {
            if (is_readable($arq) && filesize($arq) > 0) {
                echo "  Ultimas linhas de $arq (" . round(filesize($arq) / 1024) . ' KB):' . PHP_EOL;
                $l = array_slice(file($arq, FILE_IGNORE_NEW_LINES) ?: [], -15);
                foreach ($l as $x) { echo '    ' . substr($x, 0, 220) . PHP_EOL; }
            }
        }
    });
}

// ------------------------------------------------------------------ SEGURANCA
if ($quer('seguranca')) {
    titulo('SEGURANCA');
    tentar(function () use ($DB, $CFG, $ok) {
        $auth = (string)get_config('core', 'auth');
        lin('Metodos de autenticacao', $auth);
        lin('SSO oauth2 ativo', in_array('oauth2', explode(',', $auth), true));
        lin('Login manual escondido (showloginform=0)', empty($CFG->showloginform));
        foreach ($DB->get_records('oauth2_issuer', null, '', 'id,name,baseurl,enabled') as $i) {
            lin("Issuer {$i->name}", ($i->enabled ? 'ativo' : 'INATIVO') . " | {$i->baseurl}");
        }
        lin('Auto-cadastro (registerauth)', (string)($CFG->registerauth ?: 'desativado'));
        lin('Botao visitante (guestloginbutton)', !empty($CFG->guestloginbutton));
        lin('Forcar login em perfis', !empty($CFG->forceloginforprofiles));
        lin('Cookies seguros (cookiesecure)', !empty($CFG->cookiesecure));
        lin('Politica de senha', !empty($CFG->passwordpolicy));
        lin('Permitir iframe (allowframembedding)', !empty($CFG->allowframembedding));

        $admins = $DB->get_records_list('user', 'id', explode(',', (string)$CFG->siteadmins), '', 'id,username,suspended,lastaccess');
        echo '  Administradores do site:' . PHP_EOL;
        foreach ($admins as $a) {
            echo "    - {$a->username} | " . ($a->suspended ? 'suspenso' : 'ativo') . ' | ultimo acesso ' . ($a->lastaccess ? userdate((int)$a->lastaccess) : 'nunca') . PHP_EOL;
        }

        $desde = time() - 86400;
        lin('Logins falhos (24h)', $DB->count_records_select('logstore_standard_log', "eventname = ? AND timecreated > ?", ['\core\event\user_login_failed', $desde]));
        $top = $DB->get_records_sql("SELECT ip, COUNT(*) n FROM {logstore_standard_log}
                                      WHERE eventname = ? AND timecreated > ? GROUP BY ip ORDER BY n DESC", ['\core\event\user_login_failed', $desde], 0, 5);
        foreach ($top as $t) { echo "    IP {$t->ip}: {$t->n} falhas" . PHP_EOL; }

        $cfg = $CFG->dirroot . '/config.php';
        lin('Permissao do config.php', substr(sprintf('%o', fileperms($cfg)), -4) . ' ' . $ok((fileperms($cfg) & 0007) === 0));
        lin('Permissao do moodledata', substr(sprintf('%o', fileperms($CFG->dataroot)), -4));
    });
}
echo PHP_EOL;
