<?php
// ==============================================================================
// diagnostico.php — Diagnostico SOMENTE LEITURA do Moodle (pagamento, saude, erros, seguranca)
// Uso: /usr/local/bin/ea-php83 scripts/diagnostico.php [pagamento|saude|erros|seguranca|tudo]
// Nunca imprime segredos (config de gateways, client secrets, senhas) e nunca escreve no banco.
// SAIDA PUBLICA: o repositorio e publico e o log do Actions tambem. Por isso so saem contagens e
// estados (OK/ATENCAO) — sem usuarios, IPs, URLs, versoes exatas, nomes de arquivo ou linhas de log.
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
            echo "    - conta #{$c->id} | ativa: " . ($c->enabled ? 'sim' : 'nao') . PHP_EOL;
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
        lin('Moodle (major.minor)', implode('.', array_slice(explode('.', preg_replace('/[^0-9.].*/', '', $release)), 0, 2)));
        lin('Modo manutencao', (bool)get_config('core', 'maintenance_enabled'));
        lin('Tema ativo e o esperado (ctdol)', $ok($CFG->theme === 'ctdol'));
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
        lin('Upgrade do Moodle pendente', $ok(!moodle_needs_upgrading()));
        $pm = core_plugin_manager::instance();
        if (method_exists($pm, 'plugins_need_upgrading')) {
            lin('Plugins aguardando upgrade', count($pm->plugins_need_upgrading()));
        }
    });
    tentar(function () use ($CFG) {
        // Patch do ramo: consulta direta a API publica de atualizacoes do Moodle (somente leitura;
        // nao usa \core\update\checker, que grava a resposta no banco). So o veredito sai no log.
        require $CFG->dirroot . '/version.php';
        require_once $CFG->libdir . '/filelib.php';
        $url = 'https://download.moodle.org/api/1.3/updates.php?format=json&version=' . urlencode((string)$version)
             . '&branch=' . urlencode((string)$branch);
        $resp = json_decode((string)download_file_content($url, null, null, false, 20, 10), true);
        if (($resp['status'] ?? '') !== 'OK') {
            lin('Patch do Moodle', 'indisponivel (API de atualizacoes nao respondeu)');
            return;
        }
        $ramo = intdiv((int)$branch, 100) . '.' . ((int)$branch % 100);   // '405' -> '4.5'
        $mesmo = $maior = 0;
        foreach ($resp['updates']['core'] ?? [] as $u) {
            if ((float)($u['version'] ?? 0) <= (float)$version) {
                continue;
            }
            (($u['branch'] ?? '') === $ramo) ? $mesmo++ : $maior++;
        }
        lin("Patch do ramo $ramo", $mesmo ? "ATRASADO ($mesmo atualizacao(oes) do mesmo ramo disponivel)" : 'atualizado');
        lin('Versao maior mais nova disponivel', $maior ? 'sim' : 'nao');
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
        // Somente tamanho/idade dos logs: o conteudo pode ter caminhos, usuarios e IPs.
        foreach (['error_log' => $CFG->dirroot . '/error_log', 'admin/error_log' => $CFG->dirroot . '/admin/error_log', 'logs/edu.error.log' => '/home/ctdolc07/logs/edu.ctdol.com.br.error.log'] as $rot => $arq) {
            if (is_readable($arq)) {
                lin("Log $rot", round(filesize($arq) / 1024) . ' KB, modificado ha ' . round((time() - filemtime($arq)) / 3600) . ' h');
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
        $iss = $DB->get_records('oauth2_issuer', null, '', 'id,enabled');
        lin('Emissores OAuth2 (ativos/total)', count(array_filter($iss, fn($i) => $i->enabled)) . '/' . count($iss));
        lin('Auto-cadastro (registerauth)', (string)($CFG->registerauth ?: 'desativado'));
        lin('Botao visitante (guestloginbutton)', !empty($CFG->guestloginbutton));
        lin('Forcar login em perfis', !empty($CFG->forceloginforprofiles));
        lin('Cookies seguros (cookiesecure)', !empty($CFG->cookiesecure));
        lin('Politica de senha', !empty($CFG->passwordpolicy));
        lin('Permitir iframe (allowframembedding)', !empty($CFG->allowframembedding));

        $admins = $DB->get_records_list('user', 'id', explode(',', (string)$CFG->siteadmins), '', 'id,suspended,lastaccess');
        lin('Administradores do site (ativos)', count(array_filter($admins, fn($a) => !$a->suspended)));
        lin('Admins sem acesso ha +90 dias', count(array_filter($admins, fn($a) => !$a->suspended && $a->lastaccess < time() - 90 * 86400)));

        $desde = time() - 86400;
        lin('Logins falhos (24h)', $DB->count_records_select('logstore_standard_log', "eventname = ? AND timecreated > ?", ['\core\event\user_login_failed', $desde]));
        $ips = $DB->get_field_sql("SELECT COUNT(DISTINCT ip) FROM {logstore_standard_log} WHERE eventname = ? AND timecreated > ?", ['\core\event\user_login_failed', $desde]);
        lin('IPs distintos com login falho (24h)', $ips);
        $topn = $DB->get_field_sql("SELECT MAX(n) FROM (SELECT COUNT(*) n FROM {logstore_standard_log} WHERE eventname = ? AND timecreated > ? GROUP BY ip) t", ['\core\event\user_login_failed', $desde]);
        lin('Maximo de falhas de um unico IP', $topn ?: 0);

        $cfg = $CFG->dirroot . '/config.php';
        lin('config.php sem acesso a "outros"', $ok((fileperms($cfg) & 0007) === 0));
        lin('moodledata sem acesso a "outros"', $ok((fileperms($CFG->dataroot) & 0007) === 0));
    });
}
echo PHP_EOL;
