package instrument.profiler.reporter;

import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.HierarchicalData;

class ConsoleDetailReporter implements IProfilerReporter {
	var lock:Mutex;

	public function new() {
		lock = new Mutex();
	}

	public function startProfiler() {}

	public function endProfiler(summary:Array<CallSummaryData>, root:HierarchicalData) {}

	public function enterFunction(data:CallData) {
		output(">>> [" + data.id + "] " + data.location + ": " + data.className + "." + data.functionName);
		// + "("
		// + data.args.join(", ")
		// + ")");
	}

	public function exitFunction(data:CallData) {
		output("<<< [" + data.id + "] " + data.location + ": " + data.className + "." + data.functionName + " " + (data.endTime - data.startTime) * 1000 +
			"ms");
	}

	function output(text:String) {
		lock.acquire();
		#if (sys || nodejs)
		Sys.println(text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
		lock.release();
	}
}
