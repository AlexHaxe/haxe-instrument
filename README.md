# Coverage and Profiling instrumentation library

[![Haxelib Version](https://img.shields.io/github/tag/AlexHaxe/haxe-instrument.svg?label=haxelib)](http://lib.haxe.org/p/instrument)
[![Haxe-Instrument](https://github.com/AlexHaxe/haxe-instrument/workflows/Haxe-Instrument/badge.svg)](https://github.com/AlexHaxe/haxe-instrument/actions)
[![codecov](https://codecov.io/gh/AlexHaxe/haxe-instrument/branch/master/graph/badge.svg)](https://codecov.io/gh/AlexHaxe/haxe-instrument)

profiling and coverage will instrument your code to include calls to profile and coverage data collector logic.  

for that purpose instrument will disable all inlining of included types except for abstracts.
additionally it will switch off all null safety metadata on types and fields included for instrumentation.

for an example use of instrument run `haxe build.hxml` and play with different cli options (see commented out lines in `build.hxml`)

requires Haxe 4.1.x or higher

## Coverage

```hxml
-lib instrument
--macro instrument.Instrumentation.coverage([include packages] | fileName, [include folders] | fileName, [exclude packages] | fileName)
```

- include packages - takes an array of package and type names you want to collect coverage data on. names are matched against fully qualified type names ("`package name`.`type name`") using `StringTools.startsWith`
- include folders - array of folders containing code for coverage data collection. `Compiler.include` is used to make sure your types get included
- exclude packages - array of packages, types and fields to ignore, e.g. because they are for a different target. again using `StringTools.startsWith` to match fully qualified type name ("`package name`.`type name`") and field names ("`package name`.`type name`.`field name`") against list.

instead of passing an array each parameter will also take a filename pointing to a file containing package, type, field or folder names, allowing you to shorten the macro call. files should contain one entry per line with a `\n` as line break. there is no difference in behaviour between passing an array or using files for configuration.

make sure you include your source folder(s), otherwise you will only see coverage stats of types touched during run.

coverage instrumentation runs independently of a test framework. so you can create a coverage report from a "normal" run of your code if you like.  
confirmed to work with utest and munit.

coverage uses a resource named `coverageTypeInfo` to store type information it collects during compiletime so it's available for runtime coverage report generation.

### console coverage reporters

`-D coverage-console-summary-reporter` - prints a summary of coverage stats to your console

```text
=====================================
Coverage summary
=====================================
packages                 6/7 (85.71%)
types                  31/37 (83.78%)
fields               177/201 (88.05%)
branches             399/504 (79.16%)
expressions        1398/1451 (96.34%)
files                  31/33 (93.93%)
lines              1472/1540 (95.58%)
=====================================
Overall:                      91.55%
=====================================
```

overall coverage is `(covered fields + covered branches + covered expressions) / (total fields + total branches + total expressions)`

`-D coverage-console-package-summary-reporter` - prints a package summary of coverage stats to your console

```text
=========================================================================================================================================================
                              | Files          | Types          | Fields           | Branches         | Expression         | Lines              | Overall
Package                       | Rate       Num | Rate       Num | Rate         Num | Rate         Num | Rate           Num | Rate           Num |
=========================================================================================================================================================
demo                          |     0%     0/2 |     0%     0/4 |     0%      0/18 |     0%       0/0 |     0%         0/0 |     0%         0/0 |      0%
instrument                    |   100%     3/3 |   100%     3/3 | 85.71%       6/7 |    80%     40/50 | 96.96%       64/66 |  94.8%       73/77 |  89.43%
instrument.coverage           |   100%     9/9 |   100%     9/9 |   100%     34/34 |   100%     50/50 |   100%     235/235 |   100%     217/217 |    100%
instrument.coverage.reporter  |   100%     8/8 |    80%    8/10 | 98.52%     67/68 | 85.78%   175/204 | 98.59%     700/710 | 97.78%     793/811 |  95.92%
instrument.profiler           |   100%     1/1 |   100%     1/1 |   100%       7/7 | 58.92%     33/56 | 90.78%     128/141 | 88.96%     129/145 |  82.35%
instrument.profiler.reporter  |   100%     7/7 |   100%     7/7 | 97.91%     47/48 | 66.93%    83/124 | 88.23%     195/221 | 86.15%     168/195 |  82.69%
instrument.profiler.summary   |   100%     3/3 |   100%     3/3 | 84.21%     16/19 |    90%     18/20 | 97.43%       76/78 | 96.84%       92/95 |  94.01%
=========================================================================================================================================================
                       Total: | 93.93%   31/33 | 83.78%   31/37 | 88.05%   177/201 | 79.16%   399/504 | 96.34%   1398/1451 | 95.58%   1472/1540 |  91.55%
=========================================================================================================================================================
```

`-D coverage-console-file-summary-reporter` - prints a file by file summary of coverage stats to your console

```text
======================================================================================================================================================================
                                                            | Types          | Fields           | Branches         | Expression         | Lines              | Overall
FileName                                                    | Rate       Num | Rate         Num | Rate         Num | Rate           Num | Rate           Num |
======================================================================================================================================================================
[src/instrument/]
FileBaseReporter.hx                                         |   100%     1/1 |   100%       2/2 |    65%     13/20 |   100%       20/20 | 88.88%         8/9 |  83.33%
Instrumentation.hx                                          |   100%     1/1 | 66.66%       2/3 |    70%      7/10 | 88.23%       15/17 | 84.21%       16/19 |     80%
InstrumentationType.hx                                      |   100%     1/1 |   100%       2/2 |   100%     20/20 |   100%       29/29 |   100%       49/49 |    100%
coverage/BranchInfo.hx                                      |   100%     1/1 |   100%       4/4 |   100%       2/2 |   100%       10/10 |   100%         8/8 |    100%
coverage/BranchesInfo.hx                                    |   100%     1/1 |   100%       5/5 |   100%       4/4 |   100%       29/29 |   100%       30/30 |    100%
coverage/Coverage.hx                                        |   100%     1/1 |   100%       3/3 |     0%       0/0 |   100%       15/15 |   100%       16/16 |    100%
coverage/ExpressionInfo.hx                                  |   100%     1/1 |   100%       4/4 |   100%       2/2 |   100%       10/10 |   100%         8/8 |    100%
coverage/FieldInfo.hx                                       |   100%     1/1 |   100%       5/5 |   100%       4/4 |   100%       40/40 |   100%       45/45 |    100%
coverage/FileInfo.hx                                        |   100%     1/1 |   100%       3/3 |   100%       4/4 |   100%       27/27 |   100%       25/25 |    100%
coverage/LineCoverage.hx                                    |   100%     1/1 |   100%       3/3 |   100%     16/16 |   100%       32/32 |   100%       21/21 |    100%
coverage/PackageInfo.hx                                     |   100%     1/1 |   100%       3/3 |   100%       8/8 |   100%       35/35 |   100%       31/31 |    100%
coverage/TypeInfo.hx                                        |   100%     1/1 |   100%       4/4 |   100%     10/10 |   100%       37/37 |   100%       33/33 |    100%
coverage/reporter/CodecovCoverageReporter.hx                |   100%     1/1 |   100%       3/3 |   100%     12/12 |   100%       45/45 |   100%       47/47 |    100%
coverage/reporter/ConsoleCoverageFileSummaryReporter.hx     |   100%     1/1 |   100%     13/13 | 76.82%     63/82 | 97.07%     166/171 | 94.32%     183/194 |  90.97%
coverage/reporter/ConsoleCoveragePackageSummaryReporter.hx  |   100%     1/1 |   100%       9/9 |    80%     16/20 | 96.96%       64/66 | 97.56%     120/123 |  93.68%
coverage/reporter/ConsoleCoverageSummaryReporter.hx         |   100%     1/1 |   100%       4/4 |    50%       2/4 | 95.45%       21/22 | 95.45%       21/22 |     90%
coverage/reporter/ConsoleMissingCoverageReporter.hx         |   100%     1/1 |   100%     10/10 | 93.75%     30/32 |   100%       72/72 | 98.59%       70/71 |  98.24%
coverage/reporter/EMMACoverageReporter.hx                   |    50%     1/2 |   100%     10/10 |   100%       6/6 |   100%       81/81 |   100%       80/80 |    100%
coverage/reporter/JaCoCoXmlCoverageReporter.hx              |    50%     1/2 |   100%     12/12 |   100%     16/16 |   100%     118/118 |   100%     127/127 |    100%
coverage/reporter/LcovCoverageReporter.hx                   |   100%     1/1 | 85.71%       6/7 | 93.75%     30/32 | 98.51%     133/135 | 98.63%     145/147 |  97.12%
profiler/Profiler.hx                                        |   100%     1/1 |   100%       7/7 | 58.92%     33/56 | 90.78%     128/141 | 88.96%     129/145 |  82.35%
profiler/reporter/CPUProfileReporter.hx                     |   100%     1/1 |   100%       8/8 | 59.09%     26/44 | 87.14%       61/70 | 92.53%       62/67 |  77.86%
profiler/reporter/CSVSummaryReporter.hx                     |   100%     1/1 |   100%       7/7 |  62.5%     10/16 | 89.65%       26/29 | 81.81%       18/22 |  82.69%
profiler/reporter/ConsoleDetailReporter.hx                  |   100%     1/1 |   100%       6/6 |     0%       0/0 |   100%         6/6 |   100%         7/7 |    100%
profiler/reporter/ConsoleHierarchyReporter.hx               |   100%     1/1 |   100%       7/7 | 77.77%     14/18 | 96.42%       27/28 | 96.77%       30/31 |  90.56%
profiler/reporter/ConsoleMissedExitReporter.hx              |   100%     1/1 | 83.33%       5/6 |    50%       3/6 | 66.66%       18/27 | 53.84%       14/26 |  66.66%
profiler/reporter/ConsoleSummaryReporter.hx                 |   100%     1/1 |   100%       7/7 |  62.5%     10/16 | 89.65%       26/29 | 81.81%       18/22 |  82.69%
profiler/reporter/D3FlameHierarchyReporter.hx               |   100%     1/1 |   100%       7/7 | 83.33%     20/24 | 96.87%       31/32 |    95%       19/20 |  92.06%
profiler/summary/FlatSummary.hx                             |   100%     1/1 |    80%       4/5 |   100%       4/4 |   100%       13/13 |   100%       18/18 |  95.45%
profiler/summary/HierarchicalSummary.hx                     |   100%     1/1 |    80%       4/5 |     0%       0/0 |   100%       19/19 |   100%       29/29 |  95.83%
profiler/summary/HierarchyCallData.hx                       |   100%     1/1 | 88.88%       8/9 |  87.5%     14/16 | 95.65%       44/46 | 93.75%       45/48 |  92.95%

[srcDemo/demo/]
Hello.hx                                                    |     0%     0/1 |     0%       0/1 |     0%       0/0 |     0%         0/0 |     0%         0/0 |      0%
MyTestApp.hx                                                |     0%     0/3 |     0%      0/17 |     0%       0/0 |     0%         0/0 |     0%         0/0 |      0%
======================================================================================================================================================================
                                                     Total: | 83.78%   31/37 | 88.05%   177/201 | 79.16%   399/504 | 96.34%   1398/1451 | 95.58%   1472/1540 |  91.55%
======================================================================================================================================================================
```

`-D coverage-console-missing-reporter` - prints a line for every type, field, branch and expression with no coverage

```text
======================
== missing coverage ==
======================
srcDemo/demo/Hello.hx:3: type Hello not covered
srcDemo/demo/Hello.hx:4: field main not covered
srcDemo/demo/Hello.hx:5: expression not covered
srcDemo/demo/MyTestApp.hx:35: branch not covered
srcDemo/demo/MyTestApp.hx:36: expression not covered
srcDemo/demo/MyTestApp.hx:37: branch not covered
srcDemo/demo/MyTestApp.hx:38: expression not covered
srcDemo/demo/MyTestApp.hx:39: branch not covered
srcDemo/demo/MyTestApp.hx:40: expression not covered
srcDemo/demo/MyTestApp.hx:53: branch not covered
srcDemo/demo/MyTestApp.hx:54: expression not covered
srcDemo/demo/MyTestApp.hx:59: branch not covered
srcDemo/demo/MyTestApp.hx:60: expression not covered
srcDemo/demo/MyTestApp.hx:65: branch not covered
srcDemo/demo/MyTestApp.hx:66: expression not covered
srcDemo/demo/MyTestApp.hx:68: branch not covered
srcDemo/demo/MyTestApp.hx:74: branch not covered
srcDemo/demo/MyTestApp.hx:131: branch not covered
srcDemo/demo/MyTestApp.hx:134: expression not covered
srcDemo/demo/MyTestApp.hx:138: branch not covered
srcDemo/demo/MyTestApp.hx:151: field download not covered
srcDemo/demo/MyTestApp.hx:152: expression not covered
srcDemo/demo/MyTestApp.hx:154: type Role not covered
```

### lcov coverage reporter

writes coverage data using lcov format to a file. filename defaults to `lcov.info` in your workspace root. you can set a different name and folder. lcov reporter will try to create output folder. folder name is relative to your workspace root (or whereever you run Haxe from).
includes full coverage data down to lines and branches (visualisation of partially covered branches might depend on your tooling, some may show it, some won't).

```hxml
-D coverage-lcov-reporter
-D coverage-lcov-reporter=lcov.info
```

### Codecov coverage reporter (untested)

writes coverage data using Codecov's Json coverage foramt. filename defaults to `codecov.json` in your workspace root. you can set a different name and folder. Codecov reporter will try to create output folder. folder name is relative to your workspace root (or whereever you run Haxe from).
includes line coverage for each file, partial branches show up as "1/2" or "3/4".

```hxml
-D coverage-codecov-reporter
-D coverage-codecov-reporter=codecov.json
```

### emma coverage reporter (untested)

writes coverage data using emma xml format to a file. filename defaults to `emma-coverage.xml` in your workspace root. you can set a different name and folder. emma reporter will try to create output folder. folder name is relative to your workspace root (or whereever you run Haxe from).
only supports coverage down to method level (no branch and line coverage)

```hxml
-D coverage-emma-reporter
-D coverage-emma-reporter=emma-coverage.xml
```

### JaCoCo Xml coverage reporter (untested)

writes coverage data using JaCoCo xml format to a file. filename defaults to `jacoco-coverage.xml` in your workspace root. you can set a different name and folder. JaCoCo reporter will try to create output folder. folder name is relative to your workspace root (or whereever you run Haxe from).
includes line coverage for each file.

```hxml
-D coverage-jacocoxml-reporter or -D coverage-jacocoxml-reporter=jacoco-coverage.xml
```

## Profiling

```hxml
-lib instrument
--macro instrument.Instrumentation.profiling([include packages] | fileName, [include folders] | fileName, [exclude packages] | fileName)
```

- include packages - takes an array of package and type names you want to collect coverage data on. names are matched against fully qualified type names ("`package name`.`type name`") using `StringTools.startsWith`
- include folders - array of folders containing code for coverage data collection. `Compiler.include` is used to make sure your types get included
- exclude packages - array of packages, types and fields to ignore, e.g. because they are for a different target. again using `StringTools.startsWith` to match fully qualified type name ("`package name`.`type name`") and field names ("`package name`.`type name`.`field name`") against list.

instead of passing an array each parameter will also take a filename pointing to a file containing package, type, field or folder names, allowing you to shorten the macro call. files should contain one entry per line with a `\n` as line break. there is no difference in behaviour between passing an array or using files for configuration.

profiling was written with multithreading in mind, but's currently untested

### console profiling reporters

`-D profiler-console-detail-reporter` - prints entry and exit of every function as it happens including call id, location type and function name and duration of call

```text
>>> [2] srcDemo/demo/Hello.hx:4: Hello.main
srcDemo/demo/Hello.hx:5: Hello Haxe
<<< [2] srcDemo/demo/Hello.hx:4: Hello.main 0.080108642578125ms
```

`-D profiler-console-summary-reporter` - prints a summary listing all locations, fields, number of invocations and duration spent inside (includes duration of calls to other functions)

```text
==================
== Call Summary ==
==================
srcDemo/demo/MyTestApp.hx:143: MyTestApp.main 1 3.10015678405761719ms
srcDemo/demo/MyTestApp.hx:6: MyTestApp.new 1 1.54900550842285156ms
srcDemo/demo/MyTestApp.hx:117: MyTestApp.noBody4 1 0.174999237060546875ms
srcDemo/demo/MyTestApp.hx:148: MyTestApp_Fields_.moduleBody 7 0.14591217041015625ms
srcDemo/demo/MyTestApp.hx:71: MyTestApp.opBoolOr 3 0.145196914672851562ms
srcDemo/demo/MyTestApp.hx:89: MyTestApp.initTranslations 1 0.134944915771484375ms
srcDemo/demo/MyTestApp.hx:102: MyTestApp.noBody3 2 0.129222869873046875ms
srcDemo/demo/MyTestApp.hx:19: MyTestApp.<anon-1> 2 0.116825103759765625ms
srcDemo/demo/MyTestApp.hx:82: MyTestApp.sortColsFunc 1 0.0898838043212890625ms
srcDemo/demo/MyTestApp.hx:57: MyTestApp.switchVal 2 0.0722408294677734375ms
srcDemo/demo/MyTestApp.hx:111: MyTestApp.noBody2 3 0.051021575927734375ms
srcDemo/demo/MyTestApp.hx:122: MyTestApp.getInt 2 0.0469684600830078125ms
srcDemo/demo/MyTestApp.hx:99: MyTestApp.noBody 1 0.04482269287109375ms
srcDemo/demo/MyTestApp.hx:114: MyTestApp.noBody5 3 0.03910064697265625ms
srcDemo/demo/MyTestApp.hx:130: MyTestApp.noCover 1 0.0278949737548828125ms
srcDemo/demo/MyTestApp.hx:137: MyTestApp.whileLoop 1 0.0209808349609375ms
srcDemo/demo/MyTestApp.hx:43: MyTestApp.<anon-2> 1 0.0159740447998046875ms
srcDemo/demo/MyTestApp.hx:83: MyTestApp.<anon-3> 1 0.0140666961669921875ms
srcDemo/demo/MyTestApp.hx:4: MyTestApp.<anon-arrow-0> 1 0.011920928955078125ms
```

`-D profiler-console-missing-reporter` - prints a list of all calls that didn't exit properly. (might indicate an issue in instrument library)

`-D profiler-console-hierarchy-reporter` - prints a hierachical summary of calls showing which function was called from what function, again listing all locations, fields, number opf invocations and duration

```text
====================
== Call Hierarchy ==
====================
+ <root> 9.17577743530273438ms
---+ thread-0 9.17577743530273438ms
------+ srcDemo/demo/MyTestApp.hx:141: MyTestApp.main 1 4.44388389587402344ms
---------+ srcDemo/demo/MyTestApp.hx:6: MyTestApp.new 1 4.13799285888671875ms
------------+ srcDemo/demo/MyTestApp.hx:97: MyTestApp.noBody 1 0.030994415283203125ms
------------+ srcDemo/demo/MyTestApp.hx:109: MyTestApp.noBody2 1 0.0269412994384765625ms
------------+ srcDemo/demo/MyTestApp.hx:100: MyTestApp.noBody3 2 0.159025192260742188ms
---------------+ srcDemo/demo/MyTestApp.hx:146: MyTestApp_Fields_.moduleBody 2 0.0522136688232421875ms
------------+ srcDemo/demo/MyTestApp.hx:112: MyTestApp.noBody5 1 0.02193450927734375ms
------------+ srcDemo/demo/MyTestApp.hx:146: MyTestApp_Fields_.moduleBody 5 1.22761726379394531ms
------------+ srcDemo/demo/MyTestApp.hx:4: MyTestApp.<anon-arrow-0> 1 0.02288818359375ms
------------+ srcDemo/demo/MyTestApp.hx:115: MyTestApp.noBody4 1 0.294923782348632812ms
---------------+ srcDemo/demo/MyTestApp.hx:19: MyTestApp.<anon-1> 2 0.210046768188476562ms
------------------+ srcDemo/demo/MyTestApp.hx:112: MyTestApp.noBody5 2 0.03719329833984375ms
------------------+ srcDemo/demo/MyTestApp.hx:109: MyTestApp.noBody2 2 0.0393390655517578125ms
------------+ srcDemo/demo/MyTestApp.hx:87: MyTestApp.initTranslations 1 0.142812728881835938ms
------------+ srcDemo/demo/MyTestApp.hx:128: MyTestApp.noCover 1 0.031948089599609375ms
------------+ srcDemo/demo/MyTestApp.hx:120: MyTestApp.getInt 2 0.0612735748291015625ms
------------+ srcDemo/demo/MyTestApp.hx:135: MyTestApp.whileLoop 1 0.0259876251220703125ms
------------+ srcDemo/demo/MyTestApp.hx:41: MyTestApp.<anon-2> 1 0.0240802764892578125ms
------------+ srcDemo/demo/MyTestApp.hx:80: MyTestApp.sortColsFunc 1 0.072956085205078125ms
---------------+ srcDemo/demo/MyTestApp.hx:81: MyTestApp.<anon-3> 1 0.019073486328125ms
------------+ srcDemo/demo/MyTestApp.hx:55: MyTestApp.switchVal 2 0.118017196655273438ms
------------+ srcDemo/demo/MyTestApp.hx:69: MyTestApp.opBoolOr 3 0.70667266845703125ms
```

### CSV profiling reporter

writes profiling data to a CSV file using `thread;invocations;total time in ms;class;function;location` columns. filename defaults to `summary.csv` in your workspace root. you can set a different name and folder. csv reporter will try to create output folder. folder name is relative to your workspace root (or whereever you run Haxe from).

```hxml
-D profiler-csv-reporter
-D profiler-csv-reporter=summary.xml
```

### D3 Flamegraph profiling reporter

writes a json file compatible with d3-flame-graph javascript library.f ilename defaults to `flame.json` in your workspace root. you can set a different name and folder. d3 reporter will try to create output folder. folder name is relative to your workspace root (or whereever you run Haxe from).

```hxml
-D profiler-d3-reporter
-D profiler-d3-reporter=flame.json
```

### .cpuprofile profiling reporter (WIP)

work in progress - supposed to write a file in .cpuprofile format to be used in e.g. `vscode-js-profile-flame` VSCode extension.

```hxml
-D profiler-cpuprofile-reporter
-D profiler-cpuprofile-reporter=profiler.cpuprofile
```

## end instrumentation detection

instrument tries to find your `main` function and all calls to `Sys.exit` to set up automatic detection of program exit. however if you exit your program by any other means or if your main function is excluded from instrumentation, then you might have to add a call to instrument's `endProfiler` or `endCoverage` functions:

```hxml
#if instrument
instrument.coverage.Coverage.endCoverage(); // when measuring coverage
instrument.profiler.Profiler.endProfiler(); // when profiling
#end
```

you can invoke end instrumentation functions multiple times, results should include all data since start of application up to your end instrumentation call. file based reporters will overwrite their files with latest results.

## exclude types or fields from instrumentation

you can exclude types / fields from instrumentation by adding metadata:

- `@ignoreInstrument` or `@:ignoreInstrument` will ignore a type / field from all instrumentation
- `@ignoreCoverage` or `@:ignoreCoverage` will ignore a type / field  from coverage instrumentation
- `@ignoreProfiler` or `@:ignoreProfiler` will ignore a type / field  from profiler instrumentation

## quiet instrumentation

you can use `-D instrument-quiet` to suppress instrumentation output during compilation

## debugging

adding `-D debug-instrumentation` will make instrument print out each field's expression before and after instrumentation. so you can see what code instrument library adds to each of your fields.
