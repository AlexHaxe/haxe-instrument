# Coverage and Profiling instrumentation library

profiling and coverage will instrument your code to include calls to profile and coverage data collector logic.  
for that purpose all inlining of included types will be disabled.

for an example use of instrument run `haxe build.hxml` and play with different cli options (see commented out lines in `build.hxml`)

requires Haxe 4.1.x or higher

## Coverage

```hxml
-lib instrument
--macro instrument.Instrumentation.coverage([include packages], [include folders], [exclude packages])
```

- include packages - takes an array of package names you want to collect coverage data on. names are matched against fully qualified type names using `StringTools.startsWith`
- include folders - array of folders containing code for coverage data collection. `Compiler.include` is used to make sure your types get included
- exclude packages - array of packages to ignore, e.g. because they are for a different target. again using `StringTools.startsWith` to match fully qualified type names against list

coverage instrumentation runs independently of a test framework. so you can create a coverage report from a "normal" run of your code if you like.  
confirmed to work with utest and munit.

### console coverage reporters

`-D coverage-console-summary-reporter` - prints a summary of coverage stats to your console

```text
=====================================
Coverage summary
=====================================
packages                 2/2   (100%)
types                    2/3 (66.66%)
fields                 16/18 (88.88%)
branches               34/42 (80.95%)
expressions           96/102 (94.11%)
files                    1/2    (50%)
lines                  81/92 (88.04%)
=====================================
Overall:                      90.12%
=====================================
```

overall coverage is `(covered fields + covered branches + covered expressions) / (total fields + total branches + total expressions)`

`-D coverage-console-package-summary-reporter` - prints a package summary of coverage stats to your console

```text
=============================================================================================================================
                 | Files        | Types        | Fields         | Branches       | Expression      | Lines          | Overall
Package          | Rate     Num | Rate     Num | Rate       Num | Rate       Num | Rate        Num | Rate       Num |
=============================================================================================================================
demo._MyTestApp  |     0%   0/0 |   100%   1/1 |    50%     1/2 |     0%     0/0 |    50%      1/2 |    50%     1/2 |     50%
demo             |    50%   1/2 |    50%   1/2 | 93.75%   15/16 | 80.95%   34/42 |    95%   95/100 | 88.88%   80/90 |  91.13%
=============================================================================================================================
          Total: |    50%   1/2 | 66.66%   2/3 | 88.88%   16/18 | 80.95%   34/42 | 94.11%   96/102 | 88.04%   81/92 |  90.12%
=============================================================================================================================
```

`-D coverage-console-file-summary-reporter` - prints a file by file summary of coverage stats to your console

```text
===========================================================================================================
              | Types        | Fields         | Branches       | Expression      | Lines          | Overall
FileName      | Rate     Num | Rate       Num | Rate       Num | Rate        Num | Rate       Num |
===========================================================================================================
[srcDemo/demo/]
Hello.hx      |     0%   0/1 |     0%     0/1 |     0%     0/0 |     0%      0/1 |     0%     0/1 |      0%
MyTestApp.hx  |   100%   2/2 | 94.11%   16/17 | 80.95%   34/42 | 95.04%   96/101 | 89.01%   81/91 |  91.25%
===========================================================================================================
       Total: | 66.66%   2/3 | 88.88%   16/18 | 80.95%   34/42 | 94.11%   96/102 | 88.04%   81/92 |  90.12%
===========================================================================================================
```

`-D coverage-console-missing-reporter` - prints a line for every type, field, branch and expression with no coverage

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
--macro instrument.Instrumentation.profiling([include packages], [include folders], [exclude packages])
```

- include packages - takes an array of package names you want to collect coverage data on. names are matched against fully qualified type names using `StringTools.startsWith`
- include folders - array of folders containing code for coverage data collection. `Compiler.include` is used to make sure your types get included
- exclude packages - array of packages to ignore, e.g. because they are for a different target. again using `StringTools.startsWith` to match fully qualified type names against list

profiling was written with multithreading in mind, but's currently untested

### console profiling reporters

`-D profiler-console-summary-reporter` - prints a summary listing all locations, fields, number of invocations and duration spent inside (includes duration of calls to other functions)

```text
>>> [2] srcDemo/demo/Hello.hx:4: Hello.main
srcDemo/demo/Hello.hx:5: Hello Haxe
<<< [2] srcDemo/demo/Hello.hx:4: Hello.main 0.080108642578125ms
```

`-D profiler-console-detail-reporter` - prints entry and exit of every function as it happens including call id, location type and function name and duration of call

```text
------------------
-- Call Summary --
------------------
srcDemo/demo/Hello.hx:4: Hello.main 1 1.59811973571777344ms
```

`-D profiler-console-missing-reporter` - prints a list of all calls that didn't exit properly. (might indicate an issue in instrument library)

```text
srcDemo/demo/Hello.hx:3: type Hello not covered
srcDemo/demo/Hello.hx:4: field main not covered
srcDemo/demo/Hello.hx:5: expression not covered
srcDemo/demo/MyTestApp.hx:40: branch not covered
srcDemo/demo/MyTestApp.hx:41: expression not covered
srcDemo/demo/MyTestApp.hx:46: branch not covered
srcDemo/demo/MyTestApp.hx:47: expression not covered
srcDemo/demo/MyTestApp.hx:52: branch not covered
srcDemo/demo/MyTestApp.hx:53: expression not covered
srcDemo/demo/MyTestApp.hx:55: branch not covered
srcDemo/demo/MyTestApp.hx:61: branch not covered
srcDemo/demo/MyTestApp.hx:118: branch not covered
srcDemo/demo/MyTestApp.hx:121: expression not covered
srcDemo/demo/MyTestApp.hx:125: branch not covered
srcDemo/demo/MyTestApp.hx:138: field download not covered
srcDemo/demo/MyTestApp.hx:139: expression not covered
```

`-D profiler-console-hierarchy-reporter` - prints a hierachical summary of calls showing which function was called from what function, again listing all locations, fields, number opf invocations and duration

```text
--------------------
-- Call Hierarchy --
--------------------
+ <root> 8.11815261840820312ms
---+ thread-0 8.11815261840820312ms
------+ srcDemo/demo/MyTestApp.hx:116: MyTestApp.main 1 3.99184226989746094ms
---------+ srcDemo/demo/MyTestApp.hx:6: MyTestApp.new 1 3.75390052795410156ms
------------+ srcDemo/demo/MyTestApp.hx:72: MyTestApp.noBody 1 0.090122222900390625ms
------------+ srcDemo/demo/MyTestApp.hx:84: MyTestApp.noBody2 1 0.0708103179931640625ms
------------+ srcDemo/demo/MyTestApp.hx:75: MyTestApp.noBody3 2 0.228166580200195312ms
---------------+ srcDemo/demo/MyTestApp.hx:121: MyTestApp_Fields_.moduleBody 2 0.072956085205078125ms
------------+ srcDemo/demo/MyTestApp.hx:87: MyTestApp.noBody5 1 0.030040740966796875ms
------------+ srcDemo/demo/MyTestApp.hx:121: MyTestApp_Fields_.moduleBody 5 0.137090682983398438ms
------------+ srcDemo/demo/MyTestApp.hx:4: MyTestApp.<anon-arrow-0> 1 0.031948089599609375ms
------------+ srcDemo/demo/MyTestApp.hx:90: MyTestApp.noBody4 1 0.273942947387695312ms
---------------+ srcDemo/demo/MyTestApp.hx:19: MyTestApp.<anon-1> 2 0.196218490600585938ms
------------------+ srcDemo/demo/MyTestApp.hx:87: MyTestApp.noBody5 2 0.041961669921875ms
------------------+ srcDemo/demo/MyTestApp.hx:84: MyTestApp.noBody2 2 0.04482269287109375ms
------------+ srcDemo/demo/MyTestApp.hx:62: MyTestApp.initTranslations 1 0.0598430633544921875ms
------------+ srcDemo/demo/MyTestApp.hx:103: MyTestApp.noCover 1 0.0441074371337890625ms
------------+ srcDemo/demo/MyTestApp.hx:95: MyTestApp.getInt 2 0.069141387939453125ms
------------+ srcDemo/demo/MyTestApp.hx:110: MyTestApp.whileLoop 1 0.0400543212890625ms
------------+ srcDemo/demo/MyTestApp.hx:30: MyTestApp.<anon-2> 1 0.0369548797607421875ms
------------+ srcDemo/demo/MyTestApp.hx:55: MyTestApp.sortColsFunc 1 0.08392333984375ms
---------------+ srcDemo/demo/MyTestApp.hx:56: MyTestApp.<anon-3> 1 0.02288818359375ms
------------+ srcDemo/demo/MyTestApp.hx:42: MyTestApp.switchVal 2 0.0870227813720703125ms
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

```haxe
#if instrument
instrument.coverage.Coverage.endCoverage(); // when measuring coverage
instrument.profiler.Profiler.endProfiler(); // when profiling
#end
```

## exclude types from instrumentation

you can exclude types from instrumentation by adding metadata to a type:

- `@ignoreInstrument` or `@:ignoreInstrument` will ignore a type from all instrumentation
- `@ignoreCoverage` or `@:ignoreCoverage` will ignore a type from coverage instrumentation
- `@ignoreProfiler` or `@:ignoreProfiler` will ignore a type from profiler instrumentation
