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

proc renderLicenseYaml*(l: License): string =
  var lines: seq[string] = @[]
  lines.add("id: " & l.id)
  lines.add("name: " & yq(l.name))
  if l.url.len > 0:
    lines.add("url: " & yq(l.url))

  # requires block (always present for stable schema)
  lines.add("requires:")
  lines.add("  attribution: " & $l.requires.attribution)
  lines.add("  notice: " & $l.requires.notice)
  lines.add("  share_alike: " & $l.requires.shareAlike)
  lines.add("  non_commercial: " & $l.requires.nonCommercial)
  lines.add("  no_derivatives: " & $l.requires.noDerivatives)

  if l.defaultCreditTemplate.len > 0:
    lines.add("default_credit_template: " & yq(l.defaultCreditTemplate))

  result = lines.join("\n") & "\n"

proc renderCreatorYaml*(c: Creator): string =
  var lines: seq[string] = @[]
  lines.add("id: " & c.id)
  lines.add("name: " & yq(c.name))
  if c.url.len > 0:
    lines.add("url: " & yq(c.url))
  result = lines.join("\n") & "\n"
