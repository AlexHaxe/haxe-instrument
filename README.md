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
packages                 1/1   (100%)
types                    2/4    (50%)
fields                 16/18 (88.88%)
branches               35/46 (76.08%)
expressions          100/108 (92.59%)
files                    1/2    (50%)
lines                 84/102 (82.35%)
=====================================
Overall:                      87.79%
=====================================
```

overall coverage is `(covered fields + covered branches + covered expressions) / (total fields + total branches + total expressions)`

`-D coverage-console-package-summary-reporter` - prints a package summary of coverage stats to your console

```text
==========================================================================================================================
            | Files        | Types        | Fields         | Branches       | Expression       | Lines           | Overall
Package     | Rate     Num | Rate     Num | Rate       Num | Rate       Num | Rate         Num | Rate        Num |
==========================================================================================================================
demo        |    50%   1/2 |    50%   2/4 | 88.88%   16/18 | 76.08%   35/46 | 92.59%   100/108 | 82.35%   84/102 |  87.79%
==========================================================================================================================
     Total: |    50%   1/2 |    50%   2/4 | 88.88%   16/18 | 76.08%   35/46 | 92.59%   100/108 | 82.35%   84/102 |  87.79%
==========================================================================================================================
```

`-D coverage-console-file-summary-reporter` - prints a file by file summary of coverage stats to your console

```text
=============================================================================================================
              | Types        | Fields         | Branches       | Expression       | Lines           | Overall
FileName      | Rate     Num | Rate       Num | Rate       Num | Rate         Num | Rate        Num |
=============================================================================================================
[srcDemo/demo/]
Hello.hx      |     0%   0/1 |     0%     0/1 |     0%     0/0 |     0%       0/1 |     0%      0/1 |      0%
MyTestApp.hx  | 66.66%   2/3 | 94.11%   16/17 | 76.08%   35/46 | 93.45%   100/107 | 83.16%   84/101 |  88.82%
=============================================================================================================
       Total: |    50%   2/4 | 88.88%   16/18 | 76.08%   35/46 | 92.59%   100/108 | 82.35%   84/102 |  87.79%
=============================================================================================================
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
======================
== missing coverage ==
======================
srcDemo/demo/Hello.hx:3: type Hello not covered
srcDemo/demo/Hello.hx:4: field main not covered
srcDemo/demo/Hello.hx:5: expression not covered
srcDemo/demo/MyTestApp.hx:31: branch not covered
srcDemo/demo/MyTestApp.hx:35: branch not covered
srcDemo/demo/MyTestApp.hx:36: expression not covered
srcDemo/demo/MyTestApp.hx:37: branch not covered
srcDemo/demo/MyTestApp.hx:38: expression not covered
srcDemo/demo/MyTestApp.hx:51: branch not covered
srcDemo/demo/MyTestApp.hx:52: expression not covered
srcDemo/demo/MyTestApp.hx:57: branch not covered
srcDemo/demo/MyTestApp.hx:58: expression not covered
srcDemo/demo/MyTestApp.hx:63: branch not covered
srcDemo/demo/MyTestApp.hx:64: expression not covered
srcDemo/demo/MyTestApp.hx:66: branch not covered
srcDemo/demo/MyTestApp.hx:72: branch not covered
srcDemo/demo/MyTestApp.hx:129: branch not covered
srcDemo/demo/MyTestApp.hx:132: expression not covered
srcDemo/demo/MyTestApp.hx:136: branch not covered
srcDemo/demo/MyTestApp.hx:149: field download not covered
srcDemo/demo/MyTestApp.hx:150: expression not covered
srcDemo/demo/MyTestApp.hx:152: type Role not covered
```

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
