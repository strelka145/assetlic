# src/assetlic/ui/select.nim
import std/[strutils, sequtils]

type
  Choice* = object
    id*: string
    label*: string # display name, etc.

proc icontains(a, b: string): bool =
  a.toLowerAscii().contains(b.toLowerAscii())

proc filterChoices*(choices: seq[Choice]; query: string): seq[Choice] =
  if query.len == 0: return choices
  for c in choices:
    if c.id.icontains(query) or c.label.icontains(query):
      result.add(c)

proc selectOne*(choices: seq[Choice]; prompt: string;
    allowEmpty = false): string =
  ## Returns selected choice.id (or "" if allowEmpty and user skips)
  if choices.len == 0:
    return ""

  while true:
    echo prompt
    echo "  (type to search; empty=all" & (
        if allowEmpty: ", 'skip'=none" else: "") & ")"
    stdout.write("> ")
    let q = stdin.readLine().strip()

    if allowEmpty and (q == "skip" or q == "none"):
      return ""

    let matches = filterChoices(choices, q)
    if matches.len == 0:
      echo "No matches."
      continue
    if matches.len == 1 and q.len > 0:
      echo "Selected: " & matches[0].id & " - " & matches[0].label
      return matches[0].id

    for i, c in matches:
      echo $(i+1) & ") " & c.id & " - " & c.label

    stdout.write("Select number: ")
    let s = stdin.readLine().strip()
    if s.len == 0: continue
    try:
      let idx = parseInt(s) - 1
      if idx >= 0 and idx < matches.len:
        return matches[idx].id
    except:
      discard
    echo "Invalid selection."

proc selectMany*(
  choices: seq[Choice];
  prompt: string;
  onCreate: proc(): Choice {.closure.} = nil
): seq[string] =
  ## Returns list of selected choice.id (deduped, preserves selection order)
  result = @[]
  if choices.len == 0 and onCreate.isNil:
    return

  var baseChoices = choices

  while true:
    echo prompt
    if onCreate.isNil:
      echo "  (type to search; empty=all, 'done'=finish, 'skip'=none)"
    else:
      echo "  (type to search; empty=all, 'new'=create, 'done'=finish, 'skip'=none)"
    stdout.write("> ")
    let q = stdin.readLine().strip()

    if q == "done":
      break
    if q == "skip" or q == "none":
      result.setLen(0)
      break

    if (not onCreate.isNil) and (q == "new"):
      let created = onCreate()
      baseChoices.add(created)
      echo "Added: " & created.id & " - " & created.label
      continue

    let matches = filterChoices(baseChoices, q)
    if matches.len == 0:
      echo "No matches."
      continue

    for i, c in matches:
      echo $(i+1) & ") " & c.id & " - " & c.label

    stdout.write("Select numbers (comma-separated), or Enter to search again: ")
    let s = stdin.readLine().strip()
    if s.len == 0:
      continue

    for part in s.split(','):
      let t = part.strip()
      if t.len == 0: continue
      try:
        let idx = parseInt(t) - 1
        if idx >= 0 and idx < matches.len:
          let picked = matches[idx].id
          if picked notin result:
            result.add(picked)
      except:
        discard

    echo "Selected so far: " & (if result.len == 0: "(none)" else: result.join(", "))
