package instrument.profiler.reporter;

import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.HierarchyCallData;

class ConsoleSummaryReporter implements IProfilerReporter {
	public function new() {}

	public function startProfiler() {}

	public function endProfiler(summary:Array<CallSummaryData>, root:HierarchyCallData) {
		output("------------------");
		output("-- Call Summary --");
		output("------------------");
		summary.sort(sortSummary);
		for (data in summary) {
			output(data.location + ": " + data.className + "." + data.functionName + " " + data.count + " " + data.duration * 1000 + "ms");
		}
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

	function output(text:String) {
		#if (sys || nodejs)
		Sys.println(text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
	}
}
