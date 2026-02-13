# How Hugo Builds This Site — Under the Hood

This document traces every step Hugo takes when you run `hugo --gc --minify`,
from reading config to writing the final files in `public/`.

---

## Step 0: Resolve modules

Hugo reads `go.mod` and downloads (or locates in cache) the Nightfall theme:

```
go.mod  →  github.com/LordMathis/hugo-theme-nightfall v0.8.0
              ↓
~/Library/Caches/hugo_cache/modules/.../hugo-theme-nightfall@v0.8.0/
```

The theme provides layouts, assets (SCSS, fonts), and i18n strings.
Your site can override any of these by placing a file at the same path
under your own `layouts/`, `assets/`, or `i18n/` directories — site files
always win over theme files.

---

## Step 1: Load configuration

Hugo reads `hugo.toml` and builds an in-memory config object:

| Key | What it controls |
|-----|-----------------|
| `baseURL` | Every absolute URL in the generated HTML (`https://blue-rook.github.io/`) |
| `languageCode` | The `<html lang="en-us">` attribute |
| `[module.imports]` | Which theme to use |
| `[[menu.header]]` | Navigation links in the terminal-style header |
| `[params]` | Theme-specific settings: branding, author info, footer, social links |

---

## Step 2: Discover content

Hugo scans `content/` and builds a **content tree**. Each Markdown file
becomes a **Page** object:

```
content/
└── blog/
    ├── my-new-post/index.md      →  Page (section: blog, slug: my-new-post)
    └── poesia-distraida/index.md  →  Page (section: blog, slug: poesia-distraida)
```

For each `.md` file Hugo:

1. **Parses the TOML frontmatter** (`+++` delimiters) into page variables:
   `title`, `date`, `draft`, `tags`, `categories`, `authors`, etc.
2. **Converts Markdown to HTML** using the Goldmark renderer. Headings,
   lists, links, emphasis — all become HTML elements.
3. **Calculates derived fields**: `.ReadingTime` (words / 200), `.Summary`
   (first 70 words or up to `<!--more-->`), `.WordCount`, `.Permalink`.

Pages with `draft = true` are excluded unless you pass `-D`.

---

## Step 3: Build the taxonomy indexes

Hugo reads the frontmatter of every page and builds reverse indexes:

```
tags/
  "tag1" → [page-a, page-b]
  "tag2" → [page-c]

categories/
  "category1" → [page-a]

authors/
  "Author Name" → [page-a, page-b]
```

Each taxonomy term gets its own list page (e.g., `/tags/tag1/`).
This site currently has no tags or categories set, so these pages are
generated but empty.

---

## Step 4: Match templates to pages

Hugo selects a template for each output page using a
[lookup order](https://gohugo.io/templates/lookup-order/):

| Page kind | Template selected | What it renders |
|-----------|------------------|-----------------|
| **Homepage** | `index.html` | Author name, avatar, social links |
| **Blog listing** | `_default/list.html` | List of posts with dates and summaries |
| **Single post** | `_default/single.html` | Full post content with metadata |
| **Taxonomy list** | `_default/list.html` | Pages grouped by tag/category |
| **404 page** | `404.html` | "NOT FOUND" error message |
| **RSS feeds** | Hugo's built-in RSS template | XML feed of posts |
| **Sitemap** | Hugo's built-in sitemap template | XML sitemap for search engines |

Most templates extend `baseof.html`, which defines the shared HTML shell:

```
baseof.html
├── <head>
│   └── partial: head.html        ← meta tags, CSS pipeline
│       └── partial: custom-head.html  ← empty hook for your additions
├── partial: header.html          ← terminal-style nav bar
├── {{ block "main" }}            ← replaced by each page template
└── partial: footer.html          ← copyright line
```

The homepage (`index.html`) is an exception — it's a standalone template
that doesn't extend `baseof.html`.

---

## Step 5: Execute the SCSS pipeline

When `head.html` renders, it triggers the CSS build:

```
assets/sass/main.scss
    │
    ├── @use "global"               (base styles: body, links, headings)
    ├── @use "utils/variables"      (colors, fonts, breakpoints)
    ├── @use "utils/fonts"          (@font-face for Fira Mono, Open Sans)
    ├── @use "components/header"    (terminal nav, hamburger menu)
    ├── @use "components/footer"    (centered footer)
    ├── @use "components/post"      (post cards in list view)
    ├── @use "components/social"    (social link icons)
    ├── @use "pages/baseof"         (flexbox page structure)
    ├── @use "pages/index"          (homepage/avatar layout)
    ├── @use "pages/single"         (post content, metadata grid)
    └── @use "pages/list"           (list page alignment)
```

Hugo runs this through three **pipes**:

```
main.scss
  → toCSS          Dart Sass compiles SCSS to CSS.
  │                Hugo injects params.styles.color (default: "blue")
  │                as a Sass variable via @use "hugo:vars".
  │                The theme maps "blue" → #80AADD for links/accents.
  │
  → minify         Strips whitespace, comments, shortens values.
  │
  → fingerprint    Appends a SHA-256 hash to the filename:
                   /css/style.min.5c1fa9bb...c725.css
                   This busts browser caches on every change.
```

The result is a single CSS file with a content-addressed filename.

---

## Step 6: Render templates to HTML

Hugo executes each template with its page context. Here's what happens
for the key pages:

### Homepage (`/index.html`)

The template reads:
- `params.author.name` → rendered as `<h1>Blue rook technology</h1>`
- `params.author.avatar` → avatar image (not currently set)
- `params.social` → sorted by `key`, rendered as a link list:
  `github`, `linkedin`, `work with us`

### Blog listing (`/blog/index.html`)

The template:
1. Calls `{{ range .Pages }}` to iterate over all blog posts
2. For each post, renders: title (as link), date, and summary
3. Posts are sorted by date, newest first

### Single post (`/blog/my-new-post/index.html`)

The template:
1. Overrides the `<title>` block with the post title
2. Renders metadata (`<dl>` grid): tags, authors, date, reading time
3. Outputs `.Content` — the Markdown already converted to HTML in Step 2

### Footer (every page)

Because `params.footerHtml` is set in `hugo.toml`:
```toml
footerHtml = "&copy; 2026 Blue rook technology"
```
The footer renders this HTML directly instead of the theme's default
"Built with Hugo and Nightfall theme" message.

---

## Step 7: Copy static files

Hugo copies everything from `static/` (and the theme's `static/`) into
`public/` with the same directory structure:

```
static/favicon.ico                 →  public/favicon.ico
theme/static/fonts/FiraMono/*      →  public/fonts/FiraMono/*
theme/static/fonts/OpenSans/*      →  public/fonts/OpenSans/*
```

These files are served as-is, no processing.

---

## Step 8: Generate XML outputs

Hugo produces machine-readable files alongside the HTML:

| File | Purpose |
|------|---------|
| `public/sitemap.xml` | Lists all pages with last-modified dates. Submitted to search engines. |
| `public/index.xml` | RSS feed (Atom) of all site content. |
| `public/blog/index.xml` | RSS feed scoped to the blog section only. |
| `public/categories/index.xml` | RSS feed for categories taxonomy. |
| `public/tags/index.xml` | RSS feed for tags taxonomy. |

---

## Step 9: Garbage collection and minification

The `--gc` and `--minify` flags do final cleanup:

- **`--gc`** (garbage collect): Removes unused files from `resources/_gen/`,
  Hugo's asset cache. If you change your SCSS, the old compiled CSS is deleted.

- **`--minify`**: Minifies all HTML output — strips whitespace, removes
  unnecessary quotes, collapses empty attributes. CSS was already minified
  by the SCSS pipeline in Step 5.

---

## Final output

After all steps complete, `public/` contains the entire deployable site:

```
public/
├── index.html                          Homepage
├── 404.html                            Error page
├── index.xml                           Site RSS feed
├── sitemap.xml                         Sitemap for SEO
├── blog/
│   ├── index.html                      Blog listing
│   ├── index.xml                       Blog RSS feed
│   ├── my-new-post/index.html          "About ravens and rooks" story
│   └── poesia-distraida/index.html     "distraida" poem
├── categories/
│   ├── index.html                      Categories listing (empty)
│   └── index.xml                       Categories RSS
├── tags/
│   ├── index.html                      Tags listing (empty)
│   └── index.xml                       Tags RSS
├── css/
│   └── style.min.[hash].css            Compiled, minified, fingerprinted CSS
├── fonts/
│   ├── FiraMono/                       Fira Mono Medium (5 formats)
│   └── OpenSans/                       Open Sans Regular (3 formats)
└── favicon.ico                         Site icon
```

**12 HTML/XML pages, 1 CSS file, 9 static files. Built in ~80ms.**

---

## What happens on deploy

When you push to `master`, GitHub Actions (`.github/workflows/hugo.yaml`):

1. Installs Hugo extended + Dart Sass on an Ubuntu runner
2. Checks out the repo
3. Runs `hugo --gc --minify` (same steps as above)
4. Uploads `public/` as a GitHub Pages artifact
5. GitHub deploys the artifact to `https://blue-rook.github.io/`

Nothing in `public/` is ever committed to git — it's rebuilt from source
every time.
