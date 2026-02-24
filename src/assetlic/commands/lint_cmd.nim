import std/[os, strformat, strutils]
import ../io/yaml_io
import ../validate/lint
import ../paths

proc fmtIssue(i: Issue): string =
  let sev = if i.severity == sevError: "ERROR" else: "WARN"
  result = &"{sev} [{i.code}] {i.msg} ({i.fileHint})"

proc lint*(
  db = "",
  projectRoot = ".",
  failOnWarn = false
) =
  ## Validate assetdb integrity.
  let dbRoot = ensureDbPath(db)
  let root = projectRoot.normalizedPath()
  let theDb = loadDb(dbRoot)
  let issues = lintDb(theDb, root)

  var errCount = 0
  var warnCount = 0
  for it in issues:
    echo fmtIssue(it)
    if it.severity == sevError: inc errCount
    else: inc warnCount

  echo &"Summary: errors={errCount}, warnings={warnCount}"

  if errCount > 0:
    quit(2)
  if failOnWarn and warnCount > 0:
    quit(3)
