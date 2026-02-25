# src/assetlic/commands/add_cmd.nim
import std/[os, strutils, sequtils, tables, algorithm]
import ../domain/types
import ../io/yaml_io
import ../paths
import ../ui/select
import ../render/yaml_render
import ../io/path_guard

proc slugify(s: string): string =
  var r = newStringOfCap(s.len)
  var prevUnd = false
  for ch in s.toLowerAscii():
    let ok = (ch in {'a'..'z'}) or (ch in {'0'..'9'})
    if ok:
      r.add(ch)
      prevUnd = false
    else:
      if not prevUnd:
        r.add('_')
        prevUnd = true
  r = r.strip(chars = {'_'})
  if r.len == 0: r = "asset"
  r

proc titleize(id: string): string =
  id.split('_').filterIt(it.len > 0).mapIt(it.capitalizeAscii()).join(" ")

proc assetPath(dbRoot, id: string): string =
  dbRoot / "assets" / (id & ".yml")

proc parseMultiOpt(xs: seq[string]): seq[string] =
  ## allow --creator=a --creator=b and also --creator="a,b"
  result = @[]
  for x in xs:
    for part in x.split(','):
      let t = part.strip()
      if t.len > 0: result.add(t)

proc ask(prompt: string; default = ""): string =
  if default.len > 0:
    stdout.write(prompt & " [" & default & "]: ")
  else:
    stdout.write(prompt & ": ")
  let s = stdin.readLine().strip()
  if s.len == 0: default else: s

proc confirm(prompt: string; defaultYes = true): bool =
  stdout.write(prompt & (if defaultYes: " [Y/n]: " else: " [y/N]: "))
  let s = stdin.readLine().strip().toLowerAscii()
  if s.len == 0: return defaultYes
  s in ["y", "yes"]

proc makeChoicesLic(db: Db): seq[Choice] =
  for id, l in db.licenses.pairs:
    result.add(Choice(id: id, label: l.name))
  result.sort(proc(a, b: Choice): int = system.cmp(a.id, b.id))

proc makeChoicesCre(db: Db): seq[Choice] =
  for id, c in db.creators.pairs:
    result.add(Choice(id: id, label: c.name))
  result.sort(proc(a, b: Choice): int = system.cmp(a.id, b.id))

proc addAsset*(
  db = "assetdb";
  root = ".";
  file = "";
  id = "";
  name = "";
  `type` = "";
  license = "";
  creator: seq[string] = @[];
  tag: seq[string] = @[];
  sourceUrl = "";
  sourceVendor = "";
  nonInteractive = false;
  dryRun = false
) =
  ## Add an asset (hybrid: flags + interactive prompts).
  let projectRoot = root.normalizedPath()
  let dbObj = loadDb(db) # uses ensureDbPath inside
  let dbRoot = dbObj.dbRoot

  var a: Asset
  a.creatorIds = @[]
  a.files = @[]
  a.tags = @[]

  # 1) file
  var rawFile = file
  if rawFile.len == 0:
    if nonInteractive:
      quit("ERROR: --file is required in --non-interactive mode")
    rawFile = ask("Asset file path (relative to project root)")

  if isAbsoluteOrHomeLike(rawFile):
    quit("ERROR: --file must be relative to project root: " & rawFile)

  let rel = normPathPosixish(rawFile)
  let absPath = (projectRoot / rel).normalizedPath()

  if not isInsideProject(root, file):
    quit("ERROR: files entry escapes project root: " & file)

  if not fileExists(absPath) and not dirExists(absPath):
    echo "WARN: file not found: " & rawFile & " (you can fix later; lint will warn)"

  a.files = @[rel]

  # 2) id
  var aid = id
  if aid.len == 0:
    let base = splitFile(rel).name
    aid = slugify(base)
    if not nonInteractive:
      echo "Suggested id: " & aid
      if not confirm("Use this id?", true):
        aid = slugify(ask("Enter id", aid))

  # ensure unique
  createDir(dbRoot / "assets")
  var finalId = aid
  var p = assetPath(dbRoot, finalId)
  if fileExists(p):
    if nonInteractive:
      quit("ERROR: asset already exists: " & finalId)
    var n = 2
    while fileExists(assetPath(dbRoot, finalId & "_" & $n)):
      inc n
    let suggested = finalId & "_" & $n
    echo "ID already exists. Suggested: " & suggested
    finalId = slugify(ask("Enter id", suggested))

  a.id = finalId

  # 3) name
  var aname = name
  if aname.len == 0:
    if nonInteractive:
      quit("ERROR: --name is required in --non-interactive mode")
    aname = ask("Name", titleize(a.id))
  a.name = aname

  # 4) type
  var atype = `type`
  if atype.len == 0:
    if nonInteractive:
      quit("ERROR: --type is required in --non-interactive mode")
    echo "Type examples: bgm, sfx, image, font, model, other"
    atype = ask("Type", "other").toLowerAscii()
  a.`type` = atype

  # 5) license_id (select)
  var lic = license
  if lic.len == 0:
    if nonInteractive:
      quit("ERROR: --license is required in --non-interactive mode")
    lic = selectOne(makeChoicesLic(dbObj), "License", allowEmpty = false)
  if not dbObj.licenses.hasKey(lic):
    quit("ERROR: license_id not found in db: " & lic)
  a.licenseId = lic

  # 6) creators (multi select)
  let creatorsOpt = parseMultiOpt(creator)
  if creatorsOpt.len > 0:
    for cid in creatorsOpt:
      if not dbObj.creators.hasKey(cid):
        quit("ERROR: creator_id not found in db: " & cid)
    a.creatorIds = creatorsOpt.deduplicate()
  else:
    if not nonInteractive:
      a.creatorIds = selectMany(makeChoicesCre(dbObj), "Creators")
    else:
      a.creatorIds = @[] # allowed

  # 7) tags
  let tagsOpt = parseMultiOpt(tag)
  a.tags = tagsOpt.deduplicate()

  # 8) source
  if sourceUrl.len > 0: a.source.url = sourceUrl
  if sourceVendor.len > 0: a.source.vendor = sourceVendor
  if (not nonInteractive) and (a.source.url.len == 0 and a.source.vendor.len == 0):
    if confirm("Add source info now?", false):
      a.source.url = ask("Source URL", "")
      a.source.vendor = ask("Source vendor", "")

  # render YAML
  let yml = renderAssetYaml(a)
  let outPath = assetPath(dbRoot, a.id)

  if not nonInteractive:
    echo "Will create: " & outPath
    if dryRun:
      echo "---"
      echo yml
      echo "---"
      return
    if not confirm("OK?", true):
      echo "Canceled."
      return

  if dryRun:
    echo yml
    return

  writeFile(outPath, yml)
  echo "OK: wrote " & outPath
