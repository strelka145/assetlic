import std/[os, strformat]
import cligen

const SeedCcBy4 = """id: cc_by_4
name: "CC BY 4.0"
url: "https://creativecommons.org/licenses/by/4.0/"
requires:
  attribution: true
  notice: false
  share_alike: false
  non_commercial: false
  no_derivatives: false
default_credit_template: "{title} — {creators} (CC BY 4.0)"
"""

const SeedCreator = """id: example_creator
name: "Example Creator"
url: "https://example.com"
"""

const SeedProject = """id: example_project
name: "Example Project"
include_tags: ["release"]
include_assets: []
exclude_assets: []
roll_groups: ["BGM", "SE", "Fonts"]
type_to_group:
  bgm: "BGM"
  se: "SE"
  font: "Fonts"
"""

const SeedAsset = """id: example_asset
name: "Example Asset"
type: bgm
source:
  url: "https://example.com/asset"
  vendor: "ExampleSite"
creator_ids: ["example_creator"]
license_id: cc_by_4
files: []
tags: ["example"]
"""

proc writeIfMissing(path, content: string) =
  if fileExists(path): return
  createDir(parentDir(path))
  writeFile(path, content)

proc init*(
  dir = "assetdb",
  withExamples = true
) =
  ## Create an assetdb skeleton.
  let root = dir.normalizedPath()
  createDir(root / "assets")
  createDir(root / "licenses")
  createDir(root / "creators")
  createDir(root / "projects")
  createDir(root / "templates")

  # Templates (minimal placeholders)
  writeIfMissing(root / "templates" / "credits.md.tpl", "# Credits\n\n{credits_body}\n")
  writeIfMissing(root / "templates" / "credits.txt.tpl", "CREDITS\n\n{credits_body}\n")
  writeIfMissing(root / "templates" / "endroll.txt.tpl", "{credits_body}\n")

  # Seed license(s)
  writeIfMissing(root / "licenses" / "cc_by_4.yml", SeedCcBy4)

  if withExamples:
    writeIfMissing(root / "creators" / "example_creator.yml", SeedCreator)
    writeIfMissing(root / "projects" / "example_project.yml", SeedProject)
    writeIfMissing(root / "assets" / "example_asset.yml", SeedAsset)

  echo &"Initialized assetdb at: {root}"
