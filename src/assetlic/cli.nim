import cligen
from ./commands/init_cmd import init
from ./commands/lint_cmd import lint
from ./commands/add_cmd import addAsset

proc runCli*() =
  dispatchMulti([init], [lint], [addAsset])
