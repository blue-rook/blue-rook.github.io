# blue-rook.github.io

Blog for [Blue Rook Technology](https://blue-rook.github.io/), built with [Hugo](https://gohugo.io/) and the [Nightfall](https://github.com/LordMathis/hugo-theme-nightfall) theme.

## Prerequisites

- [Git](https://git-scm.com/downloads)
- [Hugo](https://gohugo.io/installation/) (extended edition, v0.147+): `brew install hugo`
- [Go](https://go.dev/dl/) (1.23+, for Hugo modules): `brew install go`

## Local Development

```bash
make run              # Serve at http://localhost:1313 (live reload)
make run-drafts       # Same, but includes draft posts
```

## Creating Content

```bash
make new name=my-post-slug
# Edit content/blog/my-post-slug/index.md
# Set draft = false when ready to publish
```

Posts use TOML frontmatter (`+++`) and page bundle format.

## Build & Clean

```bash
make build            # Production build to public/
make clean            # Remove build artifacts
```

## Deploying to GitHub Pages

Deployment is fully automated via GitHub Actions. To set it up:

1. **Push this repo** to GitHub as `<username>.github.io`.

2. **Configure GitHub Pages source**:
   - Go to **Settings > Pages** in your repository.
   - Under **Build and deployment > Source**, select **GitHub Actions** (not "Deploy from a branch").

3. **Push to `master`** — the workflow at `.github/workflows/hugo.yaml` will automatically build and deploy the site.

That's it. Every push to `master` triggers a build and deploy. No build output is ever committed to the repo.

### Workflow details

The Actions workflow (`.github/workflows/hugo.yaml`):
- Installs Hugo extended and Dart Sass
- Runs `hugo --gc --minify`
- Uploads the `public/` directory as a GitHub Pages artifact
- Deploys to your `github.io` URL

### Custom domain (optional)

To use a custom domain:
1. Add a `CNAME` file to `static/` containing your domain (e.g., `blog.example.com`).
2. Configure DNS as described in [GitHub's custom domain docs](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site).
3. Update `baseURL` in `hugo.toml` to match.

## Project Structure

```
hugo.toml                       # Site configuration
content/blog/                   # Blog posts (page bundles)
archetypes/default.md           # New post template
static/                         # Static assets (favicon, images)
layouts/                        # Theme template overrides
.github/workflows/hugo.yaml     # CI/CD pipeline
Makefile                        # Build automation
```

## License

[MIT License](LICENSE)
