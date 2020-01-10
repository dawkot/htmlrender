version       = "0.1.0"
author        = "dawkot"
description   = "Html rendering using macros"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.0.4"

task test, "run the tests":
  exec "nimble install -d"
  exec "nim c -r src/htmlrender"
  rmFile "src/htmlrender"
  echo "Done!"