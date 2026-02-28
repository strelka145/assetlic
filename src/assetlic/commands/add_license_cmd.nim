import std/[os, strutils]
import ../domain/types
import ../render/yaml_render
import ../ui/prompt

proc slugify(s: string): string =
  s.toLowerAscii().replace(" ", "_")

proc addLicense*(
  db = "assetdb",
  id = "",
  name = "",
  url = "",
  attribution = false,
  notice = false,
  shareAlike = false,
  nonCommercial = false,
  noDerivatives = false,
  creditTemplate = "",
  nonInteractive = false,
  dryRun = false
) =
    ## Add a license (hybrid: flags + interactive prompts). 
  var lic = License()

  # --- NAME ---
  if name.len > 0:
    lic.name = name
  elif nonInteractive:
    quit("ERROR: --name is required in non-interactive mode")
  else:
    lic.name = askRequiredString("License name")

  # --- ID ---
  let defaultId = slugify(lic.name)
  if id.len > 0:
    lic.id = id
  elif nonInteractive:
    lic.id = defaultId
  else:
    lic.id = askString("License ID", defaultId)

  # --- URL ---
  if url.len > 0:
    lic.url = url
  elif not nonInteractive:
    lic.url = askString("URL (optional)")

  # --- REQUIRES ---
  if nonInteractive:
    lic.requires = LicenseReq(
      attribution: attribution,
      notice: notice,
      shareAlike: shareAlike,
      nonCommercial: nonCommercial,
      noDerivatives: noDerivatives
    )
  else:
    lic.requires = LicenseReq(
      attribution: askBool("Requires attribution?", true),
      notice: askBool("Requires notice?", false),
      shareAlike: askBool("Requires shareAlike?", false),
      nonCommercial: askBool("Non-commercial only?", false),
      noDerivatives: askBool("No derivatives allowed?", false)
    )

  # --- TEMPLATE ---
  if creditTemplate.len > 0:
    lic.defaultCreditTemplate = creditTemplate
  elif not nonInteractive:
    lic.defaultCreditTemplate = askString("Default credit template (optional)")

  let outDir = db / "licenses"
  let outPath = outDir / (lic.id & ".yml")

  if dryRun:
    echo renderLicenseYaml(lic)
    return

  createDir(outDir)
  writeFile(outPath, renderLicenseYaml(lic))
  echo "Created: " & outPath
