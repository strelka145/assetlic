import cligen
from ./commands/init_cmd import init
from ./commands/lint_cmd import lint
from ./commands/add_cmd import addAsset
from ./commands/add_license_cmd import addLicense

proc runCli*() =
  dispatchMulti([init], [lint], [addAsset, cmdName = "add"], [addLicense, cmdName = "add-license"])
