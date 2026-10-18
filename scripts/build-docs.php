<?php

// Render a local, offline documentation preview without rewriting the source text.
// Run: C:\xampp\php\php.exe scripts/build-docs.php

declare(strict_types=1);

use League\CommonMark\GithubFlavoredMarkdownConverter;

$root = dirname(__DIR__);
$autoload = $root.'/backend/vendor/autoload.php';
if (!is_file($autoload)) {
    fwrite(STDERR, "Install backend Composer dependencies before building documentation.\n");
    exit(1);
}
require $autoload;

$documents = json_decode(<<<'JSON'
[{"file":"README.md","slug":"readme","label":"Overview","icon":"book","accent":"#137F78","soft":"#EAF8F5","index":"00"},{"file":"ARCHITECTURE.md","slug":"architecture","label":"Architecture","icon":"layers","accent":"#7C55C7","soft":"#F3EEFC","index":"01"},{"file":"DESIGNSYSTEM.md","slug":"designsystem","label":"Design System","icon":"palette","accent":"#CE4DA4","soft":"#FDEEF8","index":"02"},{"file":"PRD.md","slug":"prd","label":"Product Requirements","icon":"document","accent":"#7656CE","soft":"#F2EEFC","index":"03"},{"file":"WORKFLOW.md","slug":"workflow","label":"Clinic Workflows","icon":"flow","accent":"#397ABD","soft":"#EDF5FD","index":"04"}]
JSON, true, flags: JSON_THROW_ON_ERROR);
$icons = json_decode(<<<'JSON'
{"book":"<g fill=\"none\" stroke=\"#7C55C7\" stroke-width=\"2.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 6h8c3 0 4 2 4 4v19c0-3-2-4-5-4H4V6Zm24 0h-8c-3 0-4 2-4 4v19c0-3 2-4 5-4h7V6Z\"/></g>","layers":"<g fill=\"none\" stroke=\"#7C55C7\" stroke-width=\"2.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"m16 4 13 7-13 7L3 11 16 4Z\"/><path d=\"m3 17 13 7 13-7M3 23l13 7 13-7\"/></g>","palette":"<g fill=\"none\" stroke=\"#7C55C7\" stroke-width=\"2.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M17 4C9 4 3 9 3 17s6 12 12 12c4 0 5-2 3-4-2-3 0-5 3-5h3c5 0 7-4 5-8C27 7 23 4 17 4Z\"/><circle cx=\"10\" cy=\"13\" r=\"1\"/><circle cx=\"17\" cy=\"10\" r=\"1\"/><circle cx=\"24\" cy=\"13\" r=\"1\"/></g>","document":"<g fill=\"none\" stroke=\"#7C55C7\" stroke-width=\"2.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M7 3h12l7 7v20H7V3Z\"/><path d=\"M19 3v8h7M12 17h9M12 22h9\"/></g>","flow":"<g fill=\"none\" stroke=\"#7C55C7\" stroke-width=\"2.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><rect x=\"10\" y=\"3\" width=\"12\" height=\"7\" rx=\"2\"/><rect x=\"2\" y=\"22\" width=\"12\" height=\"7\" rx=\"2\"/><rect x=\"20\" y=\"22\" width=\"10\" height=\"7\" rx=\"2\"/><path d=\"M16 10v6H8v6m8-6h9v6\"/></g>"}
JSON, true, flags: JSON_THROW_ON_ERROR);
$escape = static fn (string $text): string => htmlspecialchars($text, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
$icon = static fn (string $kind): string => '<svg viewBox="0 0 32 32" aria-hidden="true">'.str_replace('#7C55C7', 'currentColor', $icons[$kind]).'</svg>';
$converter = new GithubFlavoredMarkdownConverter([
    'html_input' => 'allow',
    'allow_unsafe_links' => false,
]);
$docLinks = [];
foreach ($documents as $document) {
    $docLinks[$document['file']] = '#'.$document['slug'];
}
$diagramAssets = [
    'architecture' => ['architecture-flow.svg'],
    'workflow' => ['workflow-startup.svg', 'workflow-report.svg', 'workflow-planned.svg'],
];
$wideSections = [
    'architecture' => [1, 4, 5, 7, 9],
    'designsystem' => [1, 6, 9, 10],
    'prd' => [1, 3, 4, 5, 6, 8],
    'workflow' => [1, 3, 4, 6, 8, 10],
    'readme' => [1, 6, 7, 9],
];

$navigation = '';
$articles = '';
foreach ($documents as $document) {
    $slug = $document['slug'];
    $navigation .= '<a class="file-link" href="#'.$slug.'" style="--accent:'.$document['accent'].';--soft:'.$document['soft'].'">'.$icon($document['icon']).'<span>'.$escape($document['file']).'</span></a>';
    $markdown = file_get_contents($root.'/'.$document['file']);
    if ($markdown === false) {
        throw new RuntimeException('Cannot read '.$document['file']);
    }
    // Presentation wrappers are removable; the underlying document remains intact.
    $markdown = preg_replace('/<!-- presentation:start -->[\s\S]*?<!-- presentation:end -->\R?/', '', $markdown);
    $markdown = str_replace("\r\n", "\n", trim($markdown));
    $diagramIndex = 0;
    $render = function (string $part) use ($converter, $diagramAssets, $slug, &$diagramIndex, $escape, $docLinks): string {
        $part = preg_replace_callback('/```mermaid\s*([\s\S]*?)```/', function (array $match) use ($diagramAssets, $slug, &$diagramIndex, $escape): string {
            $asset = $diagramAssets[$slug][$diagramIndex++] ?? null;
            if ($asset === null) {
                throw new RuntimeException('Missing SVG diagram for '.$slug);
            }
            return "\n".'<figure class="diagram"><a href="assets/'.$asset.'" target="_blank" rel="noopener"><img src="assets/'.$asset.'" alt="'.$escape(ucfirst($slug).' diagram').'" /></a><figcaption><span>VERITAS / SYSTEM DIAGRAM</span><a href="assets/'.$asset.'" target="_blank" rel="noopener">Open diagram ↗</a></figcaption><details><summary>View Mermaid source</summary><pre><code>'.$escape(trim($match[1])).'</code></pre></details></figure>'."\n";
        }, $part);
        $html = $converter->convert($part)->getContent();
        $html = preg_replace_callback('/href="([^"]+)"/', static function (array $match) use ($docLinks, $escape): string {
            $href = html_entity_decode($match[1], ENT_QUOTES, 'UTF-8');
            if (isset($docLinks[$href])) {
                return 'href="'.$docLinks[$href].'"';
            }
            if (preg_match('~^(?:[a-z][a-z0-9+.-]*:|#|/|assets/)~i', $href)) {
                return $match[0];
            }
            return 'href="'.$escape('../'.$href).'"';
        }, $html);
        return preg_replace_callback('/<code>(#[A-Fa-f0-9]{6})<\/code>/', static fn (array $match): string =>
            '<span class="color-chip" aria-hidden="true" style="background:'.$match[1].'"></span>'.$match[0], $html);
    };
    $parts = preg_split('/(?=^## )/m', $markdown);
    $intro = $render(array_shift($parts));
    $sections = '';
    foreach ($parts as $index => $part) {
        $position = $index + 1;
        $html = $render($part);
        $sectionId = $slug.'-section-'.$position;
        $html = preg_replace('/<h2>/', '<h2 id="'.$sectionId.'">', $html, 1);
        $html = preg_replace('/(<h2[^>]*>)([0-9]{2})(\s*·\s*)/', '$1<span class="section-number">$2</span><span class="section-dot">$3</span>', $html, 1);
        $wide = in_array($position, $wideSections[$slug], true) || str_contains($html, 'class="diagram"');
        $sections .= '<section class="doc-section'.($wide ? ' wide' : '').'">'.$html.'</section>';
    }
    $articles .= '<article class="document" id="'.$slug.'" data-file="'.$escape($document['file']).'" data-title="'.$escape($document['label']).'" style="--accent:'.$document['accent'].';--soft:'.$document['soft'].'"'.($slug === 'readme' ? '' : ' hidden').'>'
        .'<div class="doc-eyebrow"><span class="doc-icon">'.$icon($document['icon']).'</span>'.$escape($document['file']).'<span class="doc-pill">VERITAS · PROTOTYPE 0.1</span></div>'
        .'<header class="intro">'.$intro.'</header><div class="sections">'.$sections.'</div>'
        .'<footer class="doc-end"><span>VERITAS / PROJECT DOCUMENTATION</span><span>'.$escape($document['file']).'</span></footer></article>';
}

$html = <<<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="description" content="Veritas project reference: architecture, design system, requirements, workflow, and setup.">
  <title>Veritas documentation</title>
  <link rel="stylesheet" href="assets/docs.css">
  <script src="assets/docs.js" defer></script>
</head>
<body>
  <a class="skip" href="#content">Skip to document</a>
  <header class="topbar">
    <span class="window-dots" aria-hidden="true"><i></i><i></i><i></i></span>
    <span class="topbar-brand">veritas</span><span class="topbar-slash">/</span><span class="topbar-label">Project documentation</span>
    <span class="topbar-spacer"></span><button class="print" id="print-document" type="button">Print / PDF</button>
  </header>
  <div class="layout">
    <aside class="sidebar">
      <div class="sidebar-brand"><span class="brand-mark" aria-hidden="true">v</span><div><strong>Veritas</strong><small>Prototype 0.1</small></div></div>
      <div class="nav-heading">PROJECT REFERENCE</div>
      <nav class="file-nav" aria-label="Documents">{$navigation}</nav>
      <div class="nav-heading">ON THIS PAGE</div>
      <nav class="toc" id="toc" aria-label="Current document sections"></nav>
      <div class="sidebar-foot">FLUTTER + LARAVEL<br>PROJECT DOCUMENTATION</div>
    </aside>
    <main id="content" tabindex="-1">
      <div class="breadcrumb"><span>docs</span><span>/</span><strong id="current-file">README.md</strong><a class="source-link" id="source-link" href="../README.md">View Markdown ↗</a></div>
      {$articles}
    </main>
  </div>
</body>
</html>
HTML;
$target = $root.'/docs/index.html';
if (!is_dir(dirname($target))) {
    mkdir(dirname($target), 0777, true);
}
file_put_contents($target, $html);
fwrite(STDOUT, "Built docs/index.html from five Markdown documents.\n");
