import std/[strutils, sequtils]

proc slugify*(s: string): string =
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

proc titleize*(id: string): string =
  id.split('_').filterIt(it.len > 0).mapIt(it.capitalizeAscii()).join(" ")

proc askString*(prompt: string; default = ""): string =
  if default.len > 0:
    stdout.write(prompt & " [" & default & "]: ")
  else:
    stdout.write(prompt & ": ")

  let input = stdin.readLine().strip()
  if input.len == 0:
    return default
  input

proc askRequiredString*(prompt: string): string =
  while true:
    stdout.write(prompt & ": ")
    let input = stdin.readLine().strip()
    if input.len > 0:
      return input
    echo "This field is required."

proc askBool*(prompt: string; default: bool): bool =
  let suffix =
    if default: " [Y/n]: "
    else: " [y/N]: "

  stdout.write(prompt & suffix)
  let input = stdin.readLine().strip().toLowerAscii()

  if input.len == 0:
    return default

  input == "y" or input == "yes"
