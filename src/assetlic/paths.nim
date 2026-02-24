import std/[os, strutils, unicode]

proc normPathPosixish*(p: string): string =
  ## Accept forward slashes in YAML; normalize to current OS path.
  ## Also trims BOM/odd whitespace just in case.
  var s = p
  # trim common whitespace (including Unicode spaces)
  s = s.strip()
  # replace / with OS separator (works on Windows/Linux)
  s = s.replace('/', DirSep)
  result = s.normalizedPath()

proc ensureDbPath*(db: string): string =
  ## If db is empty: use ./assetdb; else use provided.
  let candidate = if db.len == 0: "assetdb" else: db
  result = candidate.normalizedPath()

proc isAbsoluteOrHomeLike*(p: string): bool =
  ## Reject absolute paths (Windows drive, UNC, POSIX absolute).
  ## Also reject "~/" because it is machine-specific.
  if p.len == 0: return false
  if p.startsWith("~"): return true
  # POSIX absolute
  if p[0] == '/' or p[0] == '\\': return true
  # Windows drive absolute: C:\...
  if p.len >= 2 and p[1] == ':': return true
  # UNC: \\server\share
  if p.len >= 2 and p[0] == '\\' and p[1] == '\\': return true
  return false
