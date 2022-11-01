import 
    redisparser 
    , strutils

type
    DbAction* = enum
        daGet, daSet, daSetx, daDel

    DbExpiry* = enum
        deNeverExpire, deExpireAt

    DbExpiryD* = object 
        case mode: DbExpiry
        of deExpireAt : sec: int
        of deNeverExpire: discard

    # DbActionSet Description
    DaSetD* = object
        key: string
        value: RedisValue
        expiry: DbExpiryD

    DbActionD* = object
        case action: DbAction
        of daDel, daGet : key: string
        of daSet, daSetx: desc: DaSetD

# This basicly parsing token into semantic tree.
proc newDbActionDFromRedisValue*(protocolValue: RedisValue) : DbActionD =
    if protocolValue.isNil:
        raise newException(ValueError, "protocol value is nil")
    if protocolValue.isArray():
        var data = protocolValue.getItems()
        let header = data[0]
        if header.isString():
            case header.getStr():
            # GET [KEY]
            of "GET":
                var key = data[1]
                if not key.isString():
                    raise newException(TypeError,"Invalid data type key for GET command, it should be string")

                result = DbActionD(
                    action:daGet
                    , key: key.getStr()
                )
            # DEL [KEY]
            of "DEL":
                var key = data[1]
                if not key.isString():
                    raise newException(TypeError,"Invalid data type key for DEL command, it should be string")

                result = DbActionD(
                    action:daDel
                    , key: key.getStr()
                )
            # SET [KEY] [DATA]
            of "SET":
                var key = data[1]
                if not key.isString():
                    raise newException(TypeError,"Invalid data type key for SET command, it should be string")

                result = DbActionD(
                    action:daSet
                    , desc: DaSetD(
                        key: key.getStr()
                        , value: data[2]
                        , expiry: DbExpiryD(
                            mode: deNeverExpire
                        )
                    )                    
                )
            # SETX [KEY] [EXPIRY] [DATA]
            of "SETX":
                var key = data[1]
                if not key.isString():
                    raise newException(TypeError,"Invalid data type key for SETX command, it should be string")

                var expiry = data[2]
                if not expiry.isInteger():
                    raise newException(TypeError,"Invalid data type expiry for SETX command, it should be int")

                result = DbActionD(
                    action:daSet
                    , desc: DaSetD(
                        key: key.getStr()
                        , value: data[3]
                        , expiry: DbExpiryD(
                            mode: deExpireAt
                            , sec: expiry.getInt()
                        )
                    )                    
                )
            
proc debugDbActionD*(action: DbActionD): string =
    return "Order: $1".format(action.action)