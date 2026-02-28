import std/[strutils]

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
