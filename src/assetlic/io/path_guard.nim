import std/[os, strutils]

proc isInsideProject*(projectRoot, relPath: string): bool =
  ## Returns true if relPath stays inside projectRoot
  let rootAbs = absolutePath(projectRoot).normalizedPath()

  # absolute path is not allowed
  if isAbsolute(relPath):
    return false

  let absPath = absolutePath(rootAbs / relPath).normalizedPath()
  let relCheck = relativePath(absPath, rootAbs)

  # outside project root if it begins with ..
  if relCheck == "..": return false
  if relCheck.startsWith(".." & DirSep): return false
  if relCheck.startsWith("../"): return false

  true