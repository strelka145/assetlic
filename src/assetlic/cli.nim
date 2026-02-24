import cligen
from ./commands/init_cmd import init
from ./commands/lint_cmd import lint

proc runCli*() =
  dispatchMulti([init], [lint])
