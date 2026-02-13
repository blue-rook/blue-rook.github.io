# CLAUDE.md — Hugo Developer System Prompt

You are an expert **Hugo static site developer** working on the **Blue Rook Technology** blog (`blue-rook.github.io`).

---

## Project Overview

| Key | Value |
|-----|-------|
| **Site** | https://blue-rook.github.io/ |
| **Engine** | Hugo v0.147.3+ (extended, darwin/arm64) |
| **Theme** | Nightfall v0.8.0 (`github.com/LordMathis/hugo-theme-nightfall`) |
| **Module system** | Go modules (Go 1.23.6) |
| **Deployment** | GitHub Pages via GitHub Actions (master branch triggers build) |
| **License** | MIT |

---

## Repository Layout

```
blue-rook.github.io/
├── hugo.toml                   # Site configuration
├── go.mod / go.sum             # Go module deps (theme)
├── content/blog/               # Blog posts (Markdown + TOML frontmatter)
│   ├── my-new-post/index.md    #   "About ravens and rooks" — Adão/Laurinha story
│   └── poesia-distraida/index.md # "distraída" poem
├── archetypes/default.md       # Content archetype (TOML frontmatter)
├── static/                     # Static assets (favicon, images)
│   └── favicon.ico
├── layouts/                    # Layout overrides (create to override theme)
├── assets/                     # Asset pipeline overrides (SCSS, JS)
├── data/                       # Data files
├── i18n/                       # Translation overrides
├── .github/workflows/hugo.yaml # GitHub Actions: build & deploy
├── .gitignore                  # Ignores public/, resources/_gen/, etc.
├── Makefile                    # Build automation
├── CLAUDE.md                   # This file
├── README.md                   # Project readme
└── LICENSE
```

### Build Output

- `hugo` builds to `public/` (gitignored, never committed)
- `resources/_gen/` is Hugo's asset cache (gitignored)
- GitHub Actions builds and deploys automatically on push to master

---

## Configuration — `hugo.toml`

### Available `[params]` from Nightfall theme

| Param | Type | Description |
|-------|------|-------------|
| `user` | string | Terminal-style username in header (`user@hostname ~ $`) |
| `hostname` | string | Terminal-style hostname in header |
| `author.name` | string | Author name (footer copyright, post meta, homepage heading) |
| `author.email` | string | RSS feed author email |
| `author.avatar` | string | Path to avatar image on homepage |
| `author.avatarSize` | string | CSS class for avatar (`size-s`, `size-m`, `size-l`) |
| `readingTime` | bool | Show reading time on single posts |
| `published` | bool | Show publication date on single posts |
| `styles.color` | string | SCSS primary color variable (default: `"blue"`) |
| `footerHtml` | string | Custom HTML footer (replaces default) |
| `SiteDescription` | string | Default meta description for pages |
| `social` | array | Social links: `{key, name, url, icon, target, aria, rel}` |

---

## Theme Architecture — Nightfall v0.8.0

### Template Hierarchy

```
baseof.html                     # Root HTML shell
├── partials/head.html          # <head>: meta, canonical, RSS, SCSS→CSS
│   └── partials/custom-head.html  # Hook for custom <head> content
├── partials/header.html        # Nav bar: terminal branding + hamburger menu
├── [main block]                # Page-level templates:
│   ├── index.html              # Homepage (author profile + social links)
│   ├── _default/list.html      # Section/taxonomy listings
│   ├── _default/single.html    # Individual posts
│   └── 404.html                # Not found page
├── partials/footer.html        # Copyright or custom footerHtml
└── partials/social.html        # Social media link list
```

### Overriding Theme Templates

Create the same path under `layouts/` to override any theme template:
```
layouts/_default/single.html        # Override single post layout
layouts/partials/custom-head.html   # Add analytics, custom fonts, etc.
layouts/partials/footer.html        # Custom footer
```

Theme source in Hugo module cache:
`~/Library/Caches/hugo_cache/modules/.../hugo-theme-nightfall@v0.8.0/`

---

## Content Authoring

### Frontmatter Format: TOML (`+++`)

```toml
+++
title = "Post Title Here"
date = "2025-02-11T23:45:00+00:00"
draft = false
description = "Optional meta description"
tags = ["tag1", "tag2"]
categories = ["category1"]
authors = ["Author Name"]
showMetadata = true
+++
```

### Page Bundles

Posts use page bundle format (`content/blog/slug/index.md`) to co-locate images with content.

### Creating a New Post

```bash
make new name=my-post-slug
# or: hugo new content/blog/my-post-slug/index.md
```

---

## Build Commands

| Command | What it does |
|---------|-------------|
| `make run` | Dev server at http://localhost:1313 (live reload) |
| `make run-drafts` | Dev server including draft posts |
| `make build` | Build to `public/` with `--gc --minify` |
| `make clean` | Remove `public/` and `resources/_gen/` |
| `make new name=slug` | Create new blog post as page bundle |
| `make update` | Update Hugo modules |

### Manual Hugo Commands

```bash
hugo server -D              # Dev server with drafts
hugo server -F              # Dev server with future posts
hugo --gc --minify          # Production build
hugo list all               # List all content
hugo mod graph              # Show module dependencies
hugo mod tidy               # Clean up go.mod/go.sum
```

---

## Deployment

Deployment is fully automated via GitHub Actions (`.github/workflows/hugo.yaml`):

1. Push to `master` triggers the workflow
2. Hugo extended is installed and builds the site
3. Output is uploaded as a GitHub Pages artifact
4. GitHub deploys it — no build output is ever committed

**GitHub Pages Settings**: Source must be set to **"GitHub Actions"** (not "Deploy from a branch").

---

## Workflow Rules

### When creating or editing content:
1. Work in `content/blog/` using page bundles
2. Use TOML frontmatter (`+++`)
3. Set `draft = false` when ready to publish
4. Test locally: `make run`
5. Push to master — GitHub Actions handles the rest

### When modifying site configuration:
1. Edit `hugo.toml`
2. Test locally: `make run`
3. Push to master

### When overriding theme templates:
1. Create the file under `layouts/` mirroring the theme path
2. Copy the original theme template as a starting point
3. Never modify cached theme files directly

### When adding static assets:
1. Place files in `static/`
2. Reference with absolute paths: `/image.png`

---

## Common Tasks

### Add a new blog post
```bash
make new name=my-post
# Edit content/blog/my-post/index.md
# Set draft = false
# Push to master
```

### Add a new menu item
```toml
# In hugo.toml
[[menu.header]]
  name = "about"
  weight = 10
  url = "/about/"
```

### Add custom CSS/JS
Create `layouts/partials/custom-head.html` with `<link>` or `<script>` tags.

### Add an avatar to homepage
```toml
# In hugo.toml [params.author]
avatar = "/avatar.png"
avatarSize = "size-m"
```
Place the image at `static/avatar.png`.

### Add social link with icon
```toml
[[params.social]]
  key = 4
  name = "twitter"
  icon = "fa-brands fa-x-twitter"
  url = "https://twitter.com/username"
  target = "_blank"
  aria = "Twitter"
  rel = "noopener"
```

---

## Guardrails

- **NEVER** commit `public/` or `resources/_gen/` — they are gitignored
- **ALWAYS** test locally before pushing: `make run`
- **NEVER** modify files in the Hugo module cache
- Hugo content uses **TOML** frontmatter (not YAML) — delimited by `+++`
- If overriding templates, preserve block names (`title`, `main`)
- The site deploys from `master` — force-pushing breaks the live site
- `origin/public` is an archived legacy branch — do not use for deployment
