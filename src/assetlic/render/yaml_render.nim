import std/[strutils, sequtils]
import ../domain/types

proc yq(s: string): string =
  ## YAML double-quote with minimal escaping
  result = s
  result = result.replace("\\", "\\\\")
  result = result.replace("\"", "\\\"")
  result = "\"" & result & "\""

proc yListStr(xs: seq[string]): string =
  if xs.len == 0:
    return "[]"
  result = "[" & xs.mapIt(yq(it)).join(", ") & "]"

proc renderAssetYaml*(a: Asset): string =
  var lines: seq[string] = @[]
  lines.add("id: " & a.id)
  lines.add("name: " & yq(a.name))
  lines.add("type: " & a.`type`)
  lines.add("license_id: " & a.licenseId)

  if a.creatorIds.len > 0:
    lines.add("creator_ids: " & yListStr(a.creatorIds))
  else:
    lines.add("creator_ids: []")

  lines.add("files:")
  for f in a.files:
    lines.add("  - " & yq(f))

  # optional source block
  if a.source.url.len > 0 or a.source.vendor.len > 0:
    lines.add("source:")
    if a.source.url.len > 0:
      lines.add("  url: " & yq(a.source.url))
    if a.source.vendor.len > 0:
      lines.add("  vendor: " & yq(a.source.vendor))

  if a.tags.len > 0:
    lines.add("tags: " & yListStr(a.tags))

  if a.creditText.len > 0:
    lines.add("credit_text: " & yq(a.creditText))

  if a.modifications.len > 0:
    lines.add("modifications: " & yq(a.modifications))

  result = lines.join("\n") & "\n"
