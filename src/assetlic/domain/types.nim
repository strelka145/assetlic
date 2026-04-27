import std/tables

type
  SourceInfo* = object
    url*: string
    vendor*: string

  LicenseReq* = object
    attribution*: bool
    notice*: bool
    shareAlike*: bool
    nonCommercial*: bool
    noDerivatives*: bool

  License* = object
    id*: string
    name*: string
    url*: string
    requires*: LicenseReq
    prohibitions*: seq[string]
    defaultCreditTemplate*: string

  Creator* = object
    id*: string
    name*: string
    url*: string

  Asset* = object
    id*: string
    name*: string
    `type`*: string
    source*: SourceInfo
    creatorIds*: seq[string]
    licenseId*: string
    files*: seq[string]
    creditText*: string
    modifications*: string
    tags*: seq[string]

  Project* = object
    id*: string
    name*: string
    includeTags*: seq[string]
    includeAssets*: seq[string]
    excludeAssets*: seq[string]
    typeToGroup*: Table[string, string]
    rollGroups*: seq[string]

  Db* = object
    dbRoot*: string
    assets*: Table[string, Asset]
    licenses*: Table[string, License]
    creators*: Table[string, Creator]
    projects*: Table[string, Project]
