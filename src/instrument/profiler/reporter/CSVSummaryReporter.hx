package instrument.profiler.reporter;

import haxe.io.Path;
import haxe.macro.Context;
import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.HierarchyCallData;
#if (sys || nodejs)
import sys.FileSystem;
import sys.io.File;
#end

class CSVSummaryReporter extends FileBaseReporter implements IProfilerReporter {
	public function new(?fileName:Null<String>) {
		super(fileName, Context.definedValue("profiler-csv-reporter"), "profiler.csv");
	}

	public function startProfiler() {}

	public function endProfiler(summary:Array<CallSummaryData>, root:HierarchyCallData) {
		var lines:Array<String> = [];
		lines.push("thread;invocations;total time in ms;class;function;location");
		summary.sort(sortSummary);
		for (data in summary) {
			lines.push('thread-${data.threadId};${data.count};${data.duration * 1000};${data.className};${data.functionName};${data.location}');
		}
		outputLines(lines);
	}

	function sortSummary(a:CallSummaryData, b:CallSummaryData):Int {
		if (a.threadId < b.threadId) {
			return -1;
		}
		if (a.threadId > b.threadId) {
			return 1;
		}
		if (a.duration < b.duration) {
			return 1;
		}
		if (a.duration > b.duration) {
			return -1;
		}
		return 0;
	}

	public function enterFunction(data:CallData) {}

	public function exitFunction(data:CallData) {}

	function outputLines(lines:Array<String>) {
		output(lines.join("\n"));
	}
}
