# Package

version       = "0.0.1"
author        = "Yoghaswara Hadi Nugroho"
description   = "A Database"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["falmesino"]
skipDirs = @["lib/entities"]


# Dependencies

requires "nim >= 1.6.8","https://github.com/xmonader/nim-redisparser"
