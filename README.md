# Falmesino

An experimental key-value database compatible with Redis protocol but the fate are unknown.

### Post-mortem

Beware of:

- Async function and await keyword not work well inside try-except statement (this occure in nim 1.6.8), [details](https://github.com/nim-lang/Nim/issues/4170).
    - Instead, use `fail` method from Future.
- Compiler flag `nim:OldCaseObjects` for handle some limition on redisparser about type checking in cache type and moving semantic, do not delete.
- Note for me, 
    - do not use var parameter to async function.
    - do not forget put discard when there an async function that return void.

## Motivation

I learn make a database [just for fun. No, really.](https://justforfunnoreally.dev/)

## Maintainer

- [Lort Kegelaban](https://github.com/frederett)