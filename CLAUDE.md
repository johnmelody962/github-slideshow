# CLAUDE.md

Guide for AI assistants working with this repository.

## Project Overview

This is a **GitHub Learning Lab slideshow** — an interactive presentation built with **Jekyll** (Ruby static site generator) and **reveal.js** (v3.9.2). It teaches Git and GitHub fundamentals through a browser-based slideshow hosted on GitHub Pages.

## Tech Stack

- **Static Site Generator**: Jekyll (via `github-pages` gem >= 207)
- **Presentation Framework**: reveal.js 3.9.2 (installed via npm in `node_modules/`)
- **Language**: Ruby (Gemfile), HTML/Liquid templates, Markdown content
- **Markdown Engine**: kramdown with rouge syntax highlighting
- **Plugins**: jemoji (emoji support)

## Repository Structure

```
_posts/           # Slide content as Markdown files (each file = one slide)
_includes/        # Jekyll partial templates (head.html, script.html, slide.html)
_layouts/         # Page layouts (presentation.html, print.html, slide.html)
script/           # Shell scripts for build/dev workflows
node_modules/     # reveal.js dependency
index.html        # Main entry point — loops through _posts to build slides
_config.yml       # Jekyll + reveal.js configuration
Gemfile           # Ruby dependencies
```

## Build & Development Commands

```bash
# Initial setup (installs Ruby gems, initializes submodules)
script/setup

# Local development server (Jekyll watch mode, serves at localhost:4000)
script/server

# CI build (Jekyll build + HTML validation)
script/cibuild

# Staging deployment (builds and deploys to GitHub Pages staging)
script/stage
```

### What the CI build does

1. `bundle exec jekyll build --baseurl "."`
2. `htmlproofer _site/index.html --empty-alt-ignore`

There is no unit test suite. Validation is HTML-only via `html-proofer`.

## How Slides Work

1. Each `.md` file in `_posts/` is a slide, using Jekyll post naming: `YYYY-MM-DD-slug.md`
2. Front matter controls layout, title, CSS classes, and reveal.js data attributes
3. `index.html` iterates `_posts` (reversed) and renders each with `_includes/slide.html`
4. The presentation layout (`_layouts/presentation.html`) wraps everything in reveal.js markup
5. reveal.js initializes via `_includes/script.html` with plugins: markdown, highlight.js, speaker notes

### Adding a new slide

Create a new Markdown file in `_posts/` with front matter:

```markdown
---
layout: slide
title: "Slide Title"
---
Your slide content in Markdown
```

## Configuration

Key settings in `_config.yml`:

- **Theme**: dark (solarized)
- **Slide dimensions**: 1000x920
- **Transition**: linear (slide for backgrounds)
- **Slide numbering**: current/total format
- **Timezone**: Europe/Berlin

## Code Style

Per `.editorconfig`:

- Default: tabs (4-space width), LF line endings
- JSON/JS/CSS/SCSS/YML/HTML: 2-space indent
- Markdown: 4-space indent, trailing whitespace preserved

## Key Conventions

- Slide content is Markdown in `_posts/` — keep slides focused and concise
- Template changes go in `_includes/` (partials) or `_layouts/` (page wrappers)
- reveal.js configuration lives in both `_config.yml` (data) and `_includes/script.html` (initialization)
- The `_site/` directory is gitignored build output — never commit it
- No active CI/CD pipeline (CircleCI was removed); use `script/cibuild` locally to validate

## Dependencies

- **Ruby**: Managed via Bundler (`Gemfile.lock`). Run `bundle install` to install.
- **Node**: Only reveal.js. Committed in `node_modules/` (no `npm install` needed).

## License

MIT License (Copyright 2016 Thomas Friese)
