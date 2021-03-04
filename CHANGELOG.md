# Version History

## dev branch / next version (1.x.x)

- added canRemoveInline to detect `this` assignments
- added `-D instrument-quiet``conditional to skip printing dots during instrumentation
- fixed exception in calcStatistic with empty coverage data
- fixed handling of abstract constructors
- fixed branch coverage with abstract op overload, fixes [#11](https://github.com/AlexHaxe/haxe-instrument/issues/11)
- refactored call hierarchy data collection

## version 1.1.0 (2020-07-30)

- added support for field level exclusion metadata
- added safety lib dependency
- fixed handling of abstract types, fixes [#1](https://github.com/AlexHaxe/haxe-instrument/issues/1)
- fixed keeping inlining for abstract fields, fixes [#2](https://github.com/AlexHaxe/haxe-instrument/issues/2)
- fixed instrumentation of null safety enabled code, fixes [#4](https://github.com/AlexHaxe/haxe-instrument/issues/4)
- refactored code to be more null safe

## version 1.0.0 (2020-07-24)

- initial version
