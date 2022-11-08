import cache
    , strutils

type
    Version* = tuple
        mayor: int
        minor: int
        patch: int
        stage: string
        build: string

    Packer* = object
        falmesinoVersion*: Version
        database*: CacheTableLock


proc toVersionString*(v: Version, short = true): string =
    var build = "+" & v.build
    if short:
        build = ""

    if v.stage == "":
        return "$1.$2.$3$4".format(v.mayor,v.minor,v.patch,build)

    return "$1.$2.$3-$4$5".format(v.mayor,v.minor,v.patch,v.stage,build)

proc newPacker*(ctl: CacheTableLock,v: Version) : Packer = Packer(falmesinoVersion: v,database: ctl)