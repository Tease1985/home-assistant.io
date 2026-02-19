# CLAUDE.md — Home Assistant Website (home-assistant.io)

This document describes the codebase structure, development workflows, and conventions for AI assistants working on the [Home Assistant documentation website](https://home-assistant.io).

## Project Overview

This repository is the source for the **Home Assistant website and documentation**. It is a [Jekyll](https://jekyllrb.com/) static site. All user-facing content lives under `source/` and is compiled into `public/`.

- License: CC BY-NC-SA 4.0
- Live site: <https://www.home-assistant.io>
- Deployed via Netlify

---

## Tech Stack

| Layer | Tool |
|---|---|
| Static site generator | Jekyll 4.3.3 |
| CSS pre-processor | Sass/Compass |
| Ruby package manager | Bundler (Gemfile) |
| Build/task runner | Rake (Rakefile) |
| Markdown processor | CommonMark (`jekyll-commonmark`) |
| Markdown linting | remark (`npm run markdown:lint`) |
| Terminology linting | textlint (`npm run textlint`) |
| Ruby linting | RuboCop |

---

## Directory Structure

```
home-assistant.io/
├── source/                     # All site content
│   ├── _integrations/          # Integration documentation (1300+ .markdown files)
│   ├── _docs/                  # Core documentation pages
│   ├── _posts/                 # Blog posts (dated .markdown files)
│   ├── _includes/              # Reusable HTML partials/templates
│   ├── _layouts/               # Page layout templates
│   ├── _data/                  # YAML/JSON data files (glossary, fetched data)
│   ├── _examples/              # Code/config examples
│   ├── _faq/                   # FAQ pages
│   ├── _dashboards/            # Dashboard documentation
│   ├── assets/                 # Static assets
│   └── images/                 # Image files
├── plugins/                    # Custom Jekyll plugins (Ruby)
├── sass/                       # Sass/SCSS stylesheets
├── _config.yml                 # Jekyll site configuration
├── config.rb                   # Compass/Sass configuration
├── Gemfile                     # Ruby dependencies
├── Rakefile                    # Build and task definitions
└── package.json                # Node.js linting dependencies
```

### Jekyll Collections

The site uses these collections (defined in `_config.yml`):

| Collection | Source directory | Description |
|---|---|---|
| `integrations` | `source/_integrations/` | Integration-specific docs |
| `docs` | `source/_docs/` | General documentation |
| `examples` | `source/_examples/` | Configuration examples |
| `addons` | `source/addons/` | Add-on documentation |
| `faq` | `source/_faq/` | Frequently asked questions |
| `dashboards` | `source/_dashboards/` | Dashboard docs |

---

## Development Workflows

### Initial Setup

```bash
bundle install
npm install
```

### Local Preview

Start a local server at `http://127.0.0.1:4000`:

```bash
bundle exec rake preview
```

To serve on a specific IP (e.g., in a container):

```bash
bundle exec rake preview[192.168.0.123]
```

> In a Dev Container, the server automatically binds to `0.0.0.0`.

### Site Generation (production build)

```bash
bundle exec rake generate
```

This runs (in order):
1. `compass compile` — compiles Sass to CSS
2. `rake analytics_data` — fetches analytics from analytics.home-assistant.io
3. `rake alerts_data` — fetches alerts from alerts.home-assistant.io
4. `rake version_data` — fetches current version from version.home-assistant.io
5. `rake blueprint_exchange_data` — fetches blueprint exchange data
6. `jekyll build`

### Speeding Up Development (Blog Post Isolation)

The large number of blog posts slows down site generation. To exclude all but the post you are working on:

```bash
bundle exec rake isolate[filename-of-blogpost]
```

When finished, restore all posts:

```bash
bundle exec rake integrate
```

### Data Fetching Tasks (standalone)

```bash
bundle exec rake analytics_data
bundle exec rake version_data
bundle exec rake alerts_data
bundle exec rake blueprint_exchange_data
```

---

## Linting

Always run linters before committing. The CI pipeline enforces these.

### Markdown Lint (remark)

```bash
npm run markdown:lint
```

### Terminology Lint (textlint) — focused directories

```bash
npm run textlint
```

### Terminology Lint (textlint) — all source

```bash
npm run textlint:all
```

### Ruby Lint (RuboCop)

```bash
bundle exec rubocop
```

---

## Content Conventions

### File Extensions

All content files use `.markdown` extension (not `.md`).

### Front Matter — Integrations

Integration files (`source/_integrations/*.markdown`) require specific YAML front matter:

```yaml
---
title: Integration Name
description: One-line description of what this integration does.
ha_category:
  - Category1
  - Category2
ha_release: 0.XX           # or YYYY.MM for modern versions
ha_iot_class: Cloud Push   # or Local Push, Cloud Polling, Local Polling, etc.
ha_config_flow: true       # if UI-configurable
ha_codeowners:
  - '@github-username'
ha_domain: integration_domain
ha_homekit: true           # optional, if HomeKit compatible
ha_platforms:
  - sensor
  - switch
ha_integration_type: integration
---
```

**IoT class values**: `Cloud Push`, `Cloud Polling`, `Local Push`, `Local Polling`, `Calculated`, `Local`, `Cloud`

### Front Matter — Blog Posts

Blog posts (`source/_posts/YYYY-MM-DD-title.markdown`):

```yaml
---
layout: post
title: "Post Title"
description: "Short description for SEO and social sharing."
date: YYYY-MM-DD HH:MM:SS
date_formatted: "Month Day, Year"
author: Author Name
author_twitter: twitterhandle
comments: true
categories:
  - Release-Notes
  - Core
og_image: /images/blog/YYYY-MM/social.png
---
```

### Front Matter — Docs Pages

```yaml
---
title: "Page Title"
description: "Description of the page."
---
```

### Markdown Style

- **Headings**: Use ATX style (`#`, `##`, etc.) — no setext underlines
- **Heading levels**: Must increment sequentially (no skipping from `##` to `####`)
- **Unordered lists**: Use `-` as the bullet marker
- **Ordered lists**: Use `.` as the marker (e.g., `1.`, `2.`)
- **Fenced code blocks**: Always include a language identifier
- **Shell code blocks**: Do NOT prefix commands with `$`
- **Emphasis**: Use `_underscores_` for italic, `**asterisks**` for bold
- **Line length**: No enforced limit (MD013 is disabled)

### URLs and Links

- **Use relative URLs** for internal links — never absolute `https://www.home-assistant.io/...`
  - Correct: `/integrations/mqtt/`
  - Wrong: `https://www.home-assistant.io/integrations/mqtt/`
- Exception: When the URL appears in a quoted string context

### Terminology Rules

The following terms must be spelled/capitalized exactly as shown. The linter enforces these:

| Wrong | Correct |
|---|---|
| `home assistant`, `Hass`, `hass` | `Home Assistant` |
| `Github` | `GitHub` |
| `Websocket` | `WebSocket` |
| `addon`, `addons` | `add-on`, `add-ons` |
| `Speech-To-Text` | `Speech-to-text` |
| `Text-To-Speech` | `Text-to-speech` |
| `docs` | `documentation` |
| `repo` | `repository` |
| `analyse` | `analyze` |
| `behaviour` | `behavior` |
| `colour` | `color` |
| `grey` | `gray` |
| `licence` | `license` |
| `cancelled` | `canceled` |
| `recognise` | `recognize` |
| `he/she`, `he or she` | `they` |
| `an URL` | `a URL` |
| `e.g.` | `e.g.,` |
| `i.e.` | `i.e.,` |
| `ZWave` | `Z-Wave` |
| `Hass.io`, `HassOS` | `Home Assistant` |
| `hassio.local` | `homeassistant.local` |
| `HA` (standalone) | `Home Assistant` |
| `backwards compatible` | `backward compatible` |

Use American English spelling throughout.

### Liquid Tags and Terminology Tooltips

Use Liquid tags for Home Assistant terminology to generate tooltips:

```liquid
{% term integration %}
{% term device %}
{% term service %}
{% term automation %}
{% term sensor %}
```

Include standard snippets for config flow integrations:

```liquid
{% include integrations/config_flow.md %}
```

---

## Custom Jekyll Plugins

Located in `plugins/`. These are auto-loaded by Jekyll:

| Plugin | Purpose |
|---|---|
| `active_link.rb` | Marks navigation links as active |
| `cache_buster.rb` | Appends cache-busting hash to asset URLs |
| `category_generator.rb` | Generates category index pages for the blog |
| `configuration.rb` | Generates configuration variable documentation blocks |
| `configuration_basic.rb` | Simplified configuration docs |
| `details.rb` | Renders `<details>`/`<summary>` expandable blocks |
| `environment_variables.rb` | Exposes environment variables to Liquid templates |
| `filters.rb` | Custom Liquid filters (URL helpers, etc.) |
| `include_array.rb` | Includes a list of files as an array |
| `my.rb` | My Home Assistant deep-link helper |
| `output_modder.rb` | Post-processes Jekyll output |
| `tabbed_block.rb` | Renders tabbed content blocks |
| `terminology_tooltip.rb` | Renders tooltip markup for HA terminology |
| `titlecase.rb` | Title-case filter |

---

## Jekyll Configuration Highlights (`_config.yml`)

- **Markdown**: CommonMark with `SMART`, `FOOTNOTES`, `UNSAFE` options and `strikethrough`, `autolink`, `table` extensions
- **Liquid**: Strict error mode — Liquid errors fail the build
- **Table of contents**: Auto-generated for integrations (h2–h3), installation pages, and common tasks
- **Permalink**: `/blog/:year/:month/:day/:title/`
- **Pagination**: 10 posts per page at `blog/posts/:num`
- **Current release version**: Set via `current_major_version`, `current_minor_version`, `current_patch_version`

---

## Sass/CSS

- Source: `sass/` directory
- Output: `source/stylesheets/` (during dev) → `public/stylesheets/` (production)
- Configured via `config.rb` (Compass)
- Compiled with: `compass compile --css-dir source/stylesheets`
- Output style: `compressed`

---

## Coding Style (Ruby)

- Indent: 2 spaces (enforced by `.editorconfig` and RuboCop)
- Applies to: `*.rb`, `Rakefile`, `Gemfile*`, `config.ru`

---

## External Data Sources

The site fetches live data during build and stores it in `source/_data/`:

| Task | Source URL | Output file |
|---|---|---|
| `analytics_data` | `analytics.home-assistant.io/data.json` | `_data/analytics_data.json` |
| `alerts_data` | `alerts.home-assistant.io/alerts.json` | `_data/alerts_data.json` |
| `version_data` | `version.home-assistant.io/stable.json` | `_data/version_data.json` |
| `blueprint_exchange_data` | `community.home-assistant.io/c/blueprints-exchange/53/l/top.json` | `_data/blueprint_exchange_data.json` |

These files are not committed to the repository.

---

## Contributing Guidelines

- Sign the Contributor License Agreement (CLA) — required for all PRs
- Follow the Code of Conduct
- Documentation and process details: <https://developers.home-assistant.io/docs/documenting/>
- All contributions must be original work or properly attributed open-source content

---

## Key Conventions Summary for AI Assistants

1. **File extension**: Always `.markdown`, never `.md`
2. **Integration front matter**: Include all required fields (`title`, `description`, `ha_category`, `ha_release`, `ha_iot_class`, `ha_domain`, `ha_integration_type`)
3. **Terminology**: Use exact casing from the terminology list — the CI linter will catch violations
4. **Internal links**: Always use relative paths (no `https://www.home-assistant.io/` prefix)
5. **Code blocks**: Always tag the language; never prefix shell commands with `$`
6. **English variant**: American English throughout
7. **Liquid strict mode**: All Liquid tags must be valid — undefined variables cause build failures
8. **Heading increments**: Never skip heading levels
9. **List bullets**: Use `-` for unordered, `1.` / `2.` for ordered
10. **Run linters** before finishing: `npm run markdown:lint` and `npm run textlint`
