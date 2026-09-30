#!/usr/local/bin/ea-php83
<?php
// ============================================================================
// provisionar_cursos.php — Provisiona cursos Docs-as-Code (courses/) no Moodle 4.5
//
// Aditivo e idempotente: cria categoria/curso/secoes/paginas/quiz que faltam e
// atualiza metadados e conteudo das aulas. NUNCA restaura .mbz, nunca apaga
// curso, matricula, nota ou tentativa. Quiz ja existente NAO e alterado.
// Nao toca em autenticacao (auth_oauth2 / Keycloak).
//
// Uso (na VPS, como ctdolc07):
//   /usr/local/bin/ea-php83 scripts/provisionar_cursos.php                  # dry-run (padrao)
//   /usr/local/bin/ea-php83 scripts/provisionar_cursos.php --apply          # grava
//   ... --course=containers-docker   # apenas um curso
//   ... --moodle-dir=/caminho --courses-dir=/caminho
// ============================================================================

if (PHP_SAPI !== 'cli') {
    exit("Somente CLI.\n");
}

$opts = getopt('', ['apply', 'help', 'course:', 'courses-dir:', 'moodle-dir:']);
if (isset($opts['help'])) {
    echo "Uso: provisionar_cursos.php [--apply] [--course=shortname] [--courses-dir=DIR] [--moodle-dir=DIR]\n";
    exit(0);
}
$apply = isset($opts['apply']);
$only = $opts['course'] ?? '';
$moodledir = rtrim($opts['moodle-dir'] ?? (getenv('MOODLE_DIR') ?: '/home/ctdolc07/edu.ctdol.com.br'), '/');
$coursesdir = rtrim($opts['courses-dir'] ?? dirname(__DIR__) . '/courses', '/');

define('CLI_SCRIPT', true);
require($moodledir . '/config.php');
require_once($CFG->libdir . '/clilib.php');
require_once($CFG->libdir . '/questionlib.php');
require_once($CFG->libdir . '/resourcelib.php');
require_once($CFG->dirroot . '/enrol/locallib.php');
require_once($CFG->dirroot . '/course/lib.php');
require_once($CFG->dirroot . '/course/modlib.php');
require_once($CFG->dirroot . '/mod/quiz/locallib.php');
require_once($CFG->dirroot . '/question/format.php');
require_once($CFG->dirroot . '/question/format/aiken/format.php');

\core\session\manager::set_user(get_admin());

$falhas = 0;

function logmsg(string $nivel, string $msg): void {
    cli_writeln(sprintf('[%-5s] %s', $nivel, $msg));
}

/** Le e valida (basico) os manifestos. */
function carregar_manifestos(string $dir, string $only): array {
    $out = [];
    foreach (glob($dir . '/*/course.json') ?: [] as $arquivo) {
        $m = json_decode(file_get_contents($arquivo), false);
        if (!$m || empty($m->shortname) || empty($m->idnumber) || empty($m->fullname) || empty($m->sections)) {
            logmsg('ERRO', "Manifesto invalido: $arquivo");
            continue;
        }
        if (basename(dirname($arquivo)) !== $m->shortname) {
            logmsg('ERRO', "shortname difere da pasta em $arquivo");
            continue;
        }
        if ($only !== '' && $m->shortname !== $only) {
            continue;
        }
        $m->_dir = dirname($arquivo);
        $out[] = $m;
    }
    return $out;
}

function garantir_categoria(string $nome, bool $apply): ?int {
    global $DB;
    if ($cat = $DB->get_record('course_categories', ['name' => $nome, 'parent' => 0], 'id', IGNORE_MULTIPLE)) {
        return (int) $cat->id;
    }
    logmsg($apply ? 'CRIA' : 'DRY', "categoria '$nome'");
    if (!$apply) {
        return null;
    }
    // Categorias de homologacao (prefixo "_") nascem ocultas.
    $nova = \core_course_category::create(['name' => $nome, 'parent' => 0, 'visible' => strpos($nome, '_') === 0 ? 0 : 1]);
    return (int) $nova->id;
}

function md_para_html(string $arquivo): string {
    $md = file_get_contents($arquivo);
    if ($md === false) {
        throw new RuntimeException("Nao foi possivel ler $arquivo");
    }
    return markdown_to_html($md);
}

function garantir_curso(stdClass $m, ?int $catid, bool $apply): ?stdClass {
    global $DB;
    $existente = $DB->get_record('course', ['shortname' => $m->shortname]);
    if ($existente) {
        if ($existente->idnumber !== $m->idnumber) {
            throw new RuntimeException("Curso '{$m->shortname}' existe com idnumber diferente ('{$existente->idnumber}'); abortando.");
        }
        // Atualiza somente metadados textuais; nao mexe em categoria, visibilidade, datas ou matriculas.
        if ($existente->fullname !== $m->fullname || $existente->summary !== ($m->summary ?? '')) {
            logmsg($apply ? 'ATUAL' : 'DRY', "metadados do curso {$m->shortname}");
            if ($apply) {
                $upd = clone $existente;
                $upd->fullname = $m->fullname;
                $upd->summary = $m->summary ?? '';
                $upd->summaryformat = FORMAT_HTML;
                if (isset($m->visible)) { $upd->visible = (int)$m->visible; }
                update_course($upd);
                $existente = $DB->get_record('course', ['id' => $existente->id]);
            }
        }
        return $existente;
    }
    if ($DB->record_exists('course', ['idnumber' => $m->idnumber])) {
        throw new RuntimeException("idnumber '{$m->idnumber}' ja usado por outro curso.");
    }
    logmsg($apply ? 'CRIA' : 'DRY', "curso {$m->shortname} ({$m->idnumber})");
    if (!$apply) {
        return null;
    }
    return create_course((object) [
        'fullname' => $m->fullname,
        'shortname' => $m->shortname,
        'idnumber' => $m->idnumber,
        'category' => $catid,
        'summary' => $m->summary ?? '',
        'summaryformat' => FORMAT_HTML,
        'format' => $m->format ?? 'topics',
        'visible' => (int) ($m->visible ?? 0),
        'numsections' => count($m->sections),
        'newsitems' => 0,
        'startdate' => usergetmidnight(time()),
    ]);
}

function garantir_secao(stdClass $course, int $numero, string $nome): void {
    global $DB;
    course_create_sections_if_missing($course, [$numero]);
    $sec = $DB->get_record('course_sections', ['course' => $course->id, 'section' => $numero], '*', MUST_EXIST);
    if ($sec->name !== $nome) {
        course_update_section($course, $sec, ['name' => $nome]);
    }
}


function anexar_imagem_curso(stdClass $course, string $arquivo_imagem, bool $apply): void {
    if (!file_exists($arquivo_imagem)) {
        logmsg('WARN', "imagem referenciada nao existe: $arquivo_imagem");
        return;
    }
    logmsg($apply ? 'IMAGEM' : 'DRY', "imagem de capa: " . basename($arquivo_imagem));
    if (!$apply) {
        return;
    }
    $context = context_course::instance($course->id);
    $fs = get_file_storage();
    
    $arquivos_atuais = $fs->get_area_files($context->id, 'course', 'overviewfiles', 0, 'itemid, filepath, filename', false);
    $novohash = sha1_file($arquivo_imagem);
    foreach ($arquivos_atuais as $arq) {
        if ($arq->get_contenthash() === $novohash) {
            logmsg('OK', "imagem de capa inalterada");
            return;
        }
    }
    
    $fs->delete_area_files($context->id, 'course', 'overviewfiles');
    
    $filerecord = [
        'contextid' => $context->id,
        'component' => 'course',
        'filearea' => 'overviewfiles',
        'itemid' => 0,
        'filepath' => '/',
        'filename' => basename($arquivo_imagem),
        'timecreated' => time(),
        'timemodified' => time(),
    ];
    $fs->create_file_from_pathname($filerecord, $arquivo_imagem);
    logmsg('OK', "imagem de capa anexada ao curso ({$filerecord['filename']})");
}


function configurar_matricula(stdClass $course, stdClass $m, bool $apply): void {
    global $DB;
    $tipo = $m->enrolment->type ?? 'manual';
    $senha = $m->enrolment->password ?? '';

    logmsg($apply ? 'MATRIC' : 'DRY', "politica de inscricao: $tipo");
    if (!$apply) {
        return;
    }

    $instances = enrol_get_instances($course->id, false);
    $self_instance = null;
    foreach ($instances as $ins) {
        if ($ins->enrol === 'self') {
            $self_instance = $ins;
            break;
        }
    }

    $plugin = enrol_get_plugin('self');
    if ($tipo === 'self') {
        if (!$self_instance) {
            $plugin->add_instance($course, ['status' => ENROL_INSTANCE_ENABLED, 'password' => $senha]);
            logmsg('OK', "auto-inscricao (self) criada e ativada");
        } else {
            $plugin->update_status($self_instance, ENROL_INSTANCE_ENABLED);
            if (!empty($senha)) {
                $DB->set_field('enrol', 'password', $senha, ['id' => $self_instance->id]);
            }
            logmsg('OK', "auto-inscricao (self) ativada");
        }
    } else { // 'manual' ou 'fee'
        if ($self_instance && (int)$self_instance->status !== ENROL_INSTANCE_DISABLED) {
            $plugin->update_status($self_instance, ENROL_INSTANCE_DISABLED);
            logmsg('OK', "auto-inscricao (self) desativada (curso fechado/corporativo)");
        } else {
            logmsg('OK', "inscricao manual/fechada mantida");
        }
    }
}

function publicar_pagina(stdClass $course, int $secao, string $titulo, string $html): void {
    global $DB;
    if ($p = $DB->get_record('page', ['course' => $course->id, 'name' => $titulo], '*', IGNORE_MULTIPLE)) {
        if ($p->content !== $html) {
            $DB->update_record('page', (object) [
                'id' => $p->id, 'content' => $html, 'contentformat' => FORMAT_HTML,
                'revision' => $p->revision + 1, 'timemodified' => time(),
            ]);
            rebuild_course_cache($course->id, true);
            logmsg('ATUAL', "aula '$titulo'");
        } else {
            logmsg('OK', "aula '$titulo' inalterada");
        }
        return;
    }
    logmsg('CRIA', "aula '$titulo' (secao $secao)");
    add_moduleinfo((object) [
        'modulename' => 'page',
        'module' => $DB->get_field('modules', 'id', ['name' => 'page'], MUST_EXIST),
        'section' => $secao,
        'visible' => 1,
        'visibleoncoursepage' => 1,
        'name' => $titulo,
        'intro' => '',
        'introformat' => FORMAT_HTML,
        'content' => $html,
        'contentformat' => FORMAT_HTML,
        'display' => RESOURCELIB_DISPLAY_OPEN,
        'printintro' => 0,
        'printlastmodified' => 1,
    ], $course);
}

function criar_quiz(stdClass $course, int $secao, stdClass $q, string $arquivo): void {
    global $DB;
    if ($DB->record_exists('quiz', ['course' => $course->id, 'name' => $q->name])) {
        logmsg('OK', "quiz '{$q->name}' ja existe; nao alterado (preserva tentativas/notas)");
        return;
    }
    logmsg('CRIA', "quiz '{$q->name}' (secao $secao)");

    $cfg = [
        'timeopen' => 0, 'timeclose' => 0, 'timelimit' => 0, 'preferredbehaviour' => 'deferredfeedback',
        'attempts' => (int) ($q->attempts ?? 0), 'attemptonlast' => 0, 'grademethod' => QUIZ_GRADEHIGHEST,
        'decimalpoints' => 2, 'questiondecimalpoints' => -1, 'questionsperpage' => 1, 'shuffleanswers' => 1,
        'sumgrades' => 0, 'grade' => (float) ($q->grade ?? 10), 'overduehandling' => 'autosubmit', 'graceperiod' => 86400,
        'quizpassword' => '', 'subnet' => '', 'browsersecurity' => '', 'delay1' => 0, 'delay2' => 0,
        'showuserpicture' => 0, 'showblocks' => 0, 'navmethod' => QUIZ_NAVMETHOD_FREE,
    ];
    // Opcoes de revisao (mesmos padroes do gerador de testes do Moodle).
    foreach (['attempt', 'correctness', 'maxmarks', 'marks', 'specificfeedback', 'generalfeedback', 'rightanswer', 'overallfeedback'] as $o) {
        foreach (['during', 'immediately', 'open', 'closed'] as $quando) {
            $cfg[$o . $quando] = ($o === 'overallfeedback' && $quando === 'during') ? 0 : 1;
        }
    }

    $mi = (object) ($cfg + [
        'modulename' => 'quiz',
        'module' => $DB->get_field('modules', 'id', ['name' => 'quiz'], MUST_EXIST),
        'section' => $secao,
        'visible' => 1,
        'visibleoncoursepage' => 1,
        'name' => $q->name,
        'intro' => '',
        'introformat' => FORMAT_HTML,
        // Requerido por quiz_after_add_or_update(): uma faixa de feedback vazia.
        'feedbacktext' => [['text' => '', 'format' => FORMAT_HTML, 'itemid' => IGNORE_FILE_MERGE]],
    ]);
    $mi = add_moduleinfo($mi, $course);
    $quiz = $DB->get_record('quiz', ['id' => $mi->instance], '*', MUST_EXIST);
    $quiz->cmid = $mi->coursemodule;

    // Importa o banco Aiken para a categoria padrao do contexto do quiz.
    $context = context_module::instance($quiz->cmid);
    $categoria = question_make_default_categories([$context]);
    $formato = new qformat_aiken();
    $formato->setCategory($categoria);
    $formato->setContexts([$context]);
    $formato->setCourse($course);
    $formato->setFilename($arquivo);
    $formato->setRealfilename(basename($arquivo));
    $formato->setMatchgrades('error');
    $formato->setCatfromfile(false);
    $formato->setContextfromfile(false);
    $formato->setStoponerror(true);
    $formato->set_display_progress(false);
    if (!$formato->importpreprocess() || !$formato->importprocess() || !$formato->importpostprocess()) {
        throw new RuntimeException("Falha ao importar Aiken: $arquivo");
    }
    foreach ($formato->questionids as $qid) {
        quiz_add_quiz_question($qid, $quiz, 0, 1);
    }
    \mod_quiz\quiz_settings::create($quiz->id)->get_grade_calculator()->recompute_quiz_sumgrades();
    logmsg('OK', count($formato->questionids) . " questoes importadas em '{$q->name}'");
}

// ----------------------------------------------------------------------------
logmsg('INFO', ($apply ? 'MODO APPLY (grava no Moodle)' : 'MODO DRY-RUN (nada sera gravado)') . " | $coursesdir");
$manifestos = carregar_manifestos($coursesdir, $only);
if (!$manifestos) {
    logmsg('ERRO', 'Nenhum curso encontrado.');
    exit(1);
}

foreach ($manifestos as $m) {
    logmsg('INFO', "== {$m->shortname} ==");
    try {
        $catid = garantir_categoria($m->category ?? '_HOMOLOGACAO_SANDBOX', $apply);
        $course = garantir_curso($m, $catid, $apply);
        if (!$course) {
            continue; // dry-run de curso novo: nao ha o que detalhar.
        }
        if (!empty($m->image)) {
            anexar_imagem_curso($course, $m->_dir . '/' . $m->image, $apply);
        }
        configurar_matricula($course, $m, $apply);
        foreach ($m->sections as $i => $sec) {
            $numero = $i + 1;
            if ($apply) {
                garantir_secao($course, $numero, $sec->name);
            }
            foreach ($sec->lessons ?? [] as $aula) {
                $html = md_para_html($m->_dir . '/' . $aula->file);
                if ($apply) {
                    publicar_pagina($course, $numero, $aula->title, $html);
                } else {
                    logmsg('DRY', "aula '{$aula->title}'");
                }
            }
            foreach ($sec->quizzes ?? [] as $q) {
                if ($apply) {
                    criar_quiz($course, $numero, $q, $m->_dir . '/' . $q->file);
                } else {
                    logmsg('DRY', "quiz '{$q->name}'");
                }
            }
        }
        if ($apply) {
            rebuild_course_cache($course->id, true);
        }
    } catch (Throwable $e) {
        $falhas++;
        logmsg('ERRO', "{$m->shortname}: " . $e->getMessage());
    }
}

logmsg($falhas ? 'ERRO' : 'INFO', "Concluido com $falhas falha(s).");
exit($falhas ? 1 : 0);
