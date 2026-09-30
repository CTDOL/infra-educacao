<?php
namespace local_ctdolog;

defined('MOODLE_INTERNAL') || die();

/**
 * Insere meta tags Open Graph / Twitter Card no <head> da pagina publica do curso
 * (/course/info.php?id=X), para gerar previa com titulo, resumo e imagem em
 * WhatsApp, LinkedIn, Facebook, Telegram, Slack etc.
 *
 * Somente le dados do curso. Nao altera autenticacao nem qualquer outra pagina.
 */
class hook_callbacks {
    /** Tamanho maximo da descricao na previa. */
    private const DESCRIPTION_MAX = 200;

    /**
     * @param \core\hook\output\before_standard_head_html_generation $hook
     */
    public static function before_standard_head_html_generation(
        \core\hook\output\before_standard_head_html_generation $hook
    ): void {
        global $PAGE, $SITE;

        if ($PAGE->pagetype !== 'course-info') {
            return;
        }
        $course = $PAGE->course;
        if (empty($course->id) || $course->id == SITEID) {
            return;
        }

        $context = \context_course::instance($course->id);
        $title = strip_tags(format_string($course->fullname, true, ['context' => $context]));
        $sitename = strip_tags(format_string($SITE->fullname, true));
        $url = (new \moodle_url('/course/info.php', ['id' => $course->id]))->out(false);

        $description = trim(preg_replace('/\s+/u', ' ', content_to_text($course->summary, $course->summaryformat)));
        $description = shorten_text($description, self::DESCRIPTION_MAX, true);

        $tags = [
            ['property', 'og:type', 'website'],
            ['property', 'og:site_name', $sitename],
            ['property', 'og:locale', 'pt_BR'],
            ['property', 'og:title', $title],
            ['property', 'og:url', $url],
            ['name', 'twitter:title', $title],
        ];
        if ($description !== '') {
            $tags[] = ['name', 'description', $description];
            $tags[] = ['property', 'og:description', $description];
            $tags[] = ['name', 'twitter:description', $description];
        }

        $image = self::course_image($course);
        if ($image) {
            $tags[] = ['property', 'og:image', $image['url']];
            $tags[] = ['property', 'og:image:secure_url', $image['url']];
            if (!empty($image['width']) && !empty($image['height'])) {
                $tags[] = ['property', 'og:image:width', (string) $image['width']];
                $tags[] = ['property', 'og:image:height', (string) $image['height']];
            }
            $tags[] = ['name', 'twitter:card', 'summary_large_image'];
            $tags[] = ['name', 'twitter:image', $image['url']];
        } else {
            $tags[] = ['name', 'twitter:card', 'summary'];
        }

        $html = '';
        foreach ($tags as [$attr, $name, $content]) {
            $html .= '<meta ' . $attr . '="' . s($name) . '" content="' . s($content) . '">' . "\n";
        }
        $hook->add_html($html);
    }

    /**
     * URL publica (pluginfile de overviewfiles) e dimensoes da imagem do curso.
     *
     * @param \stdClass $course
     * @return array|null ['url' => string, 'width' => int|null, 'height' => int|null]
     */
    private static function course_image(\stdClass $course): ?array {
        $element = new \core_course_list_element($course);
        foreach ($element->get_course_overviewfiles() as $file) {
            if (!$file->is_valid_image()) {
                continue;
            }
            $url = \moodle_url::make_pluginfile_url(
                $file->get_contextid(),
                $file->get_component(),
                $file->get_filearea(),
                null,
                $file->get_filepath(),
                $file->get_filename()
            )->out(false);
            $info = $file->get_imageinfo() ?: [];
            return ['url' => $url, 'width' => $info['width'] ?? null, 'height' => $info['height'] ?? null];
        }
        return null;
    }
}
