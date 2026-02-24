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

### From Nimble

```bash
nimble install assetlic
```

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

## Quick Start

### 1. Initialize database

```bash
assetlic init
```

This creates:

```
assetdb/
  assets/
  licenses/
  creators/
  projects/
```

### 2. Add a license (manual YAML)

Create a file like:

```
assetdb/licenses/cc_by_4.yml
```

```yaml
id: cc_by_4
name: "Creative Commons Attribution 4.0"
```

### 3. Add an asset (hybrid CLI)

```bash
assetlic add --file Assets/Audio/BGM/forest.ogg
```

The tool will:
- Suggest an ID
- Ask for name/type if missing
- Let you select a license (with search)
- Let you select creators (multi-select)
- Generate `assetdb/assets/<id>.yml`

Example output:

```yaml
id: forest_theme
name: "Forest Theme"
type: bgm
license_id: cc_by_4
creator_ids: ["john_doe"]
files:
  - "Assets/Audio/BGM/forest.ogg"
tags: ["release"]
```

## Linting

Validate your database:

```bash
assetlic lint
```

Checks include:
- Required fields
- Reference integrity (license/creator existence)
- Relative path enforcement
- Prevention of project root escape (`..`)
- File existence (warning by default)

Example output:

```
ERROR [REF_LICENSE_NOT_FOUND] license_id not found: unknown_license (asset:forest_theme)
WARN  [PATH_NOT_FOUND] file not found: Assets/Audio/BGM/test.ogg (asset:test)
Summary: errors=1, warnings=1
```

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
```

### Asset Schema (simplified)

```yaml
id: string
name: string
type: string
license_id: string
creator_ids: [string]
files:
  - relative/path
source:
  url: string
  vendor: string
tags: [string]
credit_text: string
modifications: string
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
- `add license` and `add creator`
- Template-based credit rendering
- CI integration mode
