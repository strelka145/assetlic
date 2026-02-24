import std/[os, strutils, sequtils, tables]
import ../domain/types
import ../paths

type
  Severity* = enum
    sevError, sevWarn

  Issue* = object
    severity*: Severity
    code*: string
    msg*: string
    fileHint*: string

proc err(code, msg, hint: string): Issue =
  Issue(severity: sevError, code: code, msg: msg, fileHint: hint)

proc warn(code, msg, hint: string): Issue =
  Issue(severity: sevWarn, code: code, msg: msg, fileHint: hint)

proc validateRequiredFields(db: Db): seq[Issue] =
  result = @[]
  for id, a in db.assets.pairs:
    let hint = "asset:" & id
    if a.id.len == 0: result.add(err("ASSET_ID_MISSING", "asset.id is required", hint))
    if a.name.len == 0: result.add(err("ASSET_NAME_MISSING",
        "asset.name is required", hint))
    if a.`type`.len == 0: result.add(err("ASSET_TYPE_MISSING",
        "asset.type is required", hint))
    if a.licenseId.len == 0: result.add(err("ASSET_LICENSE_MISSING",
        "asset.license_id is required", hint))
    let isExample = a.tags.anyIt(it == "example")
    if a.files.len == 0 and not isExample: result.add(err("ASSET_FILES_MISSING",
        "asset.files must have at least one entry", hint))

  for id, l in db.licenses.pairs:
    let hint = "license:" & id
    if l.id.len == 0: result.add(err("LICENSE_ID_MISSING",
        "license.id is required", hint))
    if l.name.len == 0: result.add(err("LICENSE_NAME_MISSING",
        "license.name is required", hint))

  for id, c in db.creators.pairs:
    let hint = "creator:" & id
    if c.id.len == 0: result.add(err("CREATOR_ID_MISSING",
        "creator.id is required", hint))
    if c.name.len == 0: result.add(warn("CREATOR_NAME_MISSING",
        "creator.name is recommended", hint))

  for id, p in db.projects.pairs:
    let hint = "project:" & id
    if p.id.len == 0: result.add(err("PROJECT_ID_MISSING",
        "project.id is required", hint))
    if p.name.len == 0: result.add(warn("PROJECT_NAME_MISSING",
        "project.name is recommended", hint))

proc validateReferences(db: Db): seq[Issue] =
  result = @[]
  for id, a in db.assets.pairs:
    let hint = "asset:" & id
    if a.licenseId.len > 0 and not db.licenses.hasKey(a.licenseId):
      result.add(err("REF_LICENSE_NOT_FOUND", "license_id not found: " &
          a.licenseId, hint))
    for cid in a.creatorIds:
      if cid.len > 0 and not db.creators.hasKey(cid):
        result.add(err("REF_CREATOR_NOT_FOUND", "creator_id not found: " & cid, hint))

proc validatePaths(db: Db; projectRoot: string): seq[Issue] =
  result = @[]
  let root = projectRoot.normalizedPath()

  for id, a in db.assets.pairs:
    let hint = "asset:" & id
    for raw in a.files:
      if raw.len == 0: continue
      if isAbsoluteOrHomeLike(raw):
        result.add(err("PATH_ABSOLUTE", "files entry must be relative (project root): " &
            raw, hint))
        continue

      let rel = normPathPosixish(raw)
      let absPath = (root / rel).normalizedPath()

      # Prevent path escaping project root via ".."
      if not absPath.startsWith(root):
        result.add(err("PATH_ESCAPES_ROOT",
            "files entry escapes project root: " & raw, hint))
        continue

      if not fileExists(absPath) and not dirExists(absPath):
        # allow missing during early phases but flag as warn; can be error later if you want
        result.add(warn("PATH_NOT_FOUND", "file not found: " & raw, hint))

proc lintDb*(db: Db; projectRoot: string): seq[Issue] =
  result = @[]
  result.add validateRequiredFields(db)
  result.add validateReferences(db)
  result.add validatePaths(db, projectRoot)
