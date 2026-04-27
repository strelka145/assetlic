# assetlic

**assetlic** is a command-line tool for managing third-party asset licenses in game development projects.

It helps you:

- Keep asset metadata in a structured database (`assetdb/`)
- Validate license and creator references
- Enforce safe, relative file paths
- Automatically prepare data for credit generation (coming soon)

Designed for Git-based workflows and minimal side effects.

## Philosophy

- 1 asset = 1 YAML file
- No modification outside `assetdb/`
- Relative paths only
- Git-friendly structure
- CLI-first workflow


## Installation

### From Source

```bash
git clone https://github.com/strelka145/assetlic.git
cd assetlic
nimble build -d:release
```

The executable will be created as:

```
assetlic.exe   (Windows)
assetlic       (Linux/macOS)
```

---

## Commands

### `init` — Initialize database

```bash
assetlic init [--dir=assetdb] [--with-examples=true]
```

Creates the `assetdb/` directory structure and seeds a CC BY 4.0 license entry.

```
assetdb/
  assets/
  licenses/
    cc_by_4.yml   ← seeded automatically
  creators/
  projects/
  templates/
    credits.md.tpl
    credits.txt.tpl
    endroll.txt.tpl
```

| Flag | Default | Description |
|------|---------|-------------|
| `--dir` | `assetdb` | Path to the database directory |
| `--with-examples` | `true` | Seed example asset, creator, and project files |

---

### `add` — Add an asset

```bash
assetlic add [options]
```

Registers an asset interactively (prompts for missing values) or fully via flags.

| Flag | Default | Description |
|------|---------|-------------|
| `--db` | `assetdb` | Path to the database directory |
| `--root` | `.` | Project root for path validation |
| `--file` | *(prompt)* | Asset file path (relative to project root) |
| `--id` | *(auto from filename)* | Asset ID |
| `--name` | *(prompt)* | Display name |
| `--type` | *(prompt)* | Type (e.g. `bgm`, `sfx`, `image`, `font`, `model`) |
| `--license` | *(select)* | License ID |
| `--creator` | *(multi-select)* | Creator ID(s); repeatable or comma-separated |
| `--tag` | | Tag(s); repeatable or comma-separated |
| `--source-url` | | Source URL |
| `--source-vendor` | | Source vendor name |
| `--non-interactive` | `false` | Disable all prompts (all required flags must be set) |
| `--dry-run` | `false` | Print generated YAML without writing |

Example:

```bash
assetlic add --file Assets/Audio/BGM/forest.ogg
```

The tool will suggest an ID from the filename, prompt for missing fields, and let you select a license and creators interactively. New creators can be registered inline during selection.

Example output:

```yaml
id: forest_theme
name: "Forest Theme"
type: bgm
license_id: cc_by_4
creator_ids: ["john_doe"]
files:
  - "Assets/Audio/BGM/forest.ogg"
source:
  url: "https://example.com"
  vendor: "ExampleSite"
tags: ["release"]
```

---

### `add-license` — Add a license

```bash
assetlic add-license [options]
```

Registers a license interactively or fully via flags.

| Flag | Default | Description |
|------|---------|-------------|
| `--db` | `assetdb` | Path to the database directory |
| `--name` | *(prompt)* | License name |
| `--id` | *(auto from name)* | License ID |
| `--url` | *(prompt)* | License URL |
| `--attribution` | `false` | Requires attribution |
| `--notice` | `false` | Requires notice |
| `--share-alike` | `false` | Requires share-alike |
| `--non-commercial` | `false` | Non-commercial use only |
| `--no-derivatives` | `false` | No derivatives allowed |
| `--prohibitions` | | Custom prohibition text; repeatable |
| `--credit-template` | *(prompt)* | Default credit template string |
| `--non-interactive` | `false` | Disable all prompts |
| `--dry-run` | `false` | Print generated YAML without writing |

Example:

```bash
assetlic add-license --name "My Custom License" --attribution --prohibitions:"No resale" --prohibitions:"No redistribution"
```

Example output:

```yaml
id: my_custom_license
name: "My Custom License"
requires:
  attribution: true
  notice: false
  share_alike: false
  non_commercial: false
  no_derivatives: false
prohibitions:
  - "No resale"
  - "No redistribution"
```

---

### `lint` — Validate database

```bash
assetlic lint [--db=assetdb] [--project-root=.] [--fail-on-warn=false]
```

Checks the integrity of the entire database.

| Flag | Default | Description |
|------|---------|-------------|
| `--db` | *(auto-detected)* | Path to the database directory |
| `--project-root` | `.` | Project root for file path validation |
| `--fail-on-warn` | `false` | Exit with code 3 if any warnings exist |

**Exit codes:** `0` = clean, `2` = errors found, `3` = warnings found (with `--fail-on-warn`)

Checks performed:

| Code | Severity | Description |
|------|----------|-------------|
| `ASSET_ID_MISSING` | ERROR | `id` field is empty |
| `ASSET_NAME_MISSING` | ERROR | `name` field is empty |
| `ASSET_TYPE_MISSING` | ERROR | `type` field is empty |
| `ASSET_LICENSE_MISSING` | ERROR | `license_id` field is empty |
| `ASSET_FILES_MISSING` | ERROR | `files` is empty (non-example assets) |
| `LICENSE_ID_MISSING` | ERROR | License `id` is empty |
| `LICENSE_NAME_MISSING` | ERROR | License `name` is empty |
| `CREATOR_ID_MISSING` | ERROR | Creator `id` is empty |
| `CREATOR_NAME_MISSING` | WARN | Creator `name` is missing |
| `PROJECT_ID_MISSING` | ERROR | Project `id` is empty |
| `PROJECT_NAME_MISSING` | WARN | Project `name` is missing |
| `REF_LICENSE_NOT_FOUND` | ERROR | `license_id` references a non-existent license |
| `REF_CREATOR_NOT_FOUND` | ERROR | `creator_id` references a non-existent creator |
| `PATH_ABSOLUTE` | ERROR | `files` entry is an absolute path |
| `PATH_ESCAPES_ROOT` | ERROR | `files` entry escapes project root via `..` |
| `PATH_NOT_FOUND` | WARN | `files` entry does not exist on disk |
| `FILENAME_ID_MISMATCH` | ERROR | Filename does not match the `id` field inside the file |

Example output:

```
ERROR [REF_LICENSE_NOT_FOUND] license_id not found: unknown_license (asset:forest_theme)
WARN  [PATH_NOT_FOUND] file not found: Assets/Audio/BGM/test.ogg (asset:test)
Summary: errors=1, warnings=1
```

---

## Database Structure

```
assetdb/
  assets/
    <asset_id>.yml
  licenses/
    <license_id>.yml
  creators/
    <creator_id>.yml
  projects/
    <project_id>.yml
  templates/
    credits.md.tpl
    credits.txt.tpl
    endroll.txt.tpl
```

### Asset Schema

```yaml
id: string
name: string
type: string              # bgm, sfx, image, font, model, other, ...
license_id: string
creator_ids: [string]
files:
  - relative/path/to/file
source:
  url: string             # optional
  vendor: string          # optional
tags: [string]            # optional
credit_text: string       # optional
modifications: string     # optional
```

### License Schema

```yaml
id: string
name: string
url: string               # optional
requires:
  attribution: bool
  notice: bool
  share_alike: bool
  non_commercial: bool
  no_derivatives: bool
prohibitions:             # optional
  - string
default_credit_template: string  # optional
```

### Creator Schema

```yaml
id: string
name: string
url: string               # optional
```

## Path Rules

- All `files` must be relative to project root
- Absolute paths are rejected
- `..` path escaping is rejected
- Missing files generate warnings

## Roadmap

Planned features:
- `credits` command (auto-generate credit text)
- `strict` lint mode
- `add creator` command
- Template-based credit rendering
- CI integration mode
