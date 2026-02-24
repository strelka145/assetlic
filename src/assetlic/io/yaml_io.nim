import std/[os, tables, strutils, sequtils, algorithm]
import yaml
import ../domain/types
import ../paths

type
  YErr = object of CatchableError

proc loadYamlFile(path: string): YamlNode =
  try:
    result = loadAs[YamlNode](readFile(path))
  except CatchableError as e:
    raise newException(YErr, "YAML parse failed: " & path & " :: " & e.msg)

proc listYml(dir: string): seq[string] =
  if not dirExists(dir): return @[]
  for kind, path in walkDir(dir):
    if kind == pcFile and (path.endsWith(".yml") or path.endsWith(".yaml")):
      result.add(path)
  result.sort()

proc mapTryGet(node: YamlNode; key: string; outNode: var YamlNode): bool =
  ## Robust mapping lookup that doesn't rely on hasKey/node[key] API.
  if node.kind != yMapping: return false
  for k, v in node.pairs:
    # keys are typically scalar nodes; $k makes a string representation
    if k.kind == yScalar and k.content == key:
      outNode = v
      return true
    # fallback in case of non-scalar keys (rare)
    if $k == key:
      outNode = v
      return true
  return false

proc getStr(node: YamlNode; key: string; default = ""): string =
  var v: YamlNode
  if not mapTryGet(node, key, v): return default
  if v.kind == yScalar: return v.content
  return default

proc getBool(node: YamlNode; key: string; default = false): bool =
  var v: YamlNode
  if not mapTryGet(node, key, v): return default
  if v.kind == yScalar:
    let s = v.content.toLowerAscii()
    if s in ["true", "yes", "on", "1"]: return true
    if s in ["false", "no", "off", "0"]: return false
  return default

proc getStrSeq(node: YamlNode; key: string): seq[string] =
  result = @[]
  var v: YamlNode
  if not mapTryGet(node, key, v): return
  if v.kind == ySequence:
    for it in v.elems:
      if it.kind == yScalar:
        result.add(it.content)
  elif v.kind == yScalar:
    result.add(v.content)

proc loadAssets(dbRoot: string): Table[string, Asset] =
  result = initTable[string, Asset]()
  let dir = dbRoot / "assets"
  for f in listYml(dir):
    let node = loadYamlFile(f)
    var a: Asset
    a.id = node.getStr("id")
    a.name = node.getStr("name")
    a.`type` = node.getStr("type")
    a.licenseId = node.getStr("license_id")
    a.creatorIds = node.getStrSeq("creator_ids")
    a.files = node.getStrSeq("files")
    a.creditText = node.getStr("credit_text")
    a.modifications = node.getStr("modifications")
    a.tags = node.getStrSeq("tags")

    # source:
    var sNode: YamlNode
    if mapTryGet(node, "source", sNode) and sNode.kind == yMapping:
      a.source.url = sNode.getStr("url")
      a.source.vendor = sNode.getStr("vendor")

    if a.id.len > 0:
      result[a.id] = a

proc loadLicenses(dbRoot: string): Table[string, License] =
  result = initTable[string, License]()
  let dir = dbRoot / "licenses"
  for f in listYml(dir):
    let node = loadYamlFile(f)
    var l: License
    l.id = node.getStr("id")
    l.name = node.getStr("name")
    l.url = node.getStr("url")
    l.defaultCreditTemplate = node.getStr("default_credit_template")

    # requires:
    var rNode: YamlNode
    if mapTryGet(node, "requires", rNode) and rNode.kind == yMapping:
      l.requires.attribution = rNode.getBool("attribution")
      l.requires.notice = rNode.getBool("notice")
      l.requires.shareAlike = rNode.getBool("share_alike")
      l.requires.nonCommercial = rNode.getBool("non_commercial")
      l.requires.noDerivatives = rNode.getBool("no_derivatives")

    if l.id.len > 0:
      result[l.id] = l

proc loadCreators(dbRoot: string): Table[string, Creator] =
  result = initTable[string, Creator]()
  let dir = dbRoot / "creators"
  for f in listYml(dir):
    let node = loadYamlFile(f)
    var c: Creator
    c.id = node.getStr("id")
    c.name = node.getStr("name")
    c.url = node.getStr("url")
    if c.id.len > 0:
      result[c.id] = c

proc loadProjects(dbRoot: string): Table[string, Project] =
  result = initTable[string, Project]()
  let dir = dbRoot / "projects"
  for f in listYml(dir):
    let node = loadYamlFile(f)
    var p: Project
    p.id = node.getStr("id")
    p.name = node.getStr("name")
    p.includeTags = node.getStrSeq("include_tags")
    p.includeAssets = node.getStrSeq("include_assets")
    p.excludeAssets = node.getStrSeq("exclude_assets")
    p.rollGroups = node.getStrSeq("roll_groups")

    # type_to_group mapping
    p.typeToGroup = initTable[string, string]()
    var mNode: YamlNode
    if mapTryGet(node, "type_to_group", mNode) and mNode.kind == yMapping:
      for k, v in mNode.pairs:
        if v.kind == yScalar:
          # key node should be scalar usually
          if k.kind == yScalar:
            p.typeToGroup[k.content] = v.content
          else:
            p.typeToGroup[$k] = v.content

    if p.id.len > 0:
      result[p.id] = p

proc loadDb*(dbPath: string): Db =
  let root = ensureDbPath(dbPath).normalizedPath()
  if not dirExists(root):
    raise newException(YErr, "DB directory not found: " & root & " (run `assetlic init`?)")

  result.dbRoot = root
  result.assets = loadAssets(root)
  result.licenses = loadLicenses(root)
  result.creators = loadCreators(root)
  result.projects = loadProjects(root)
