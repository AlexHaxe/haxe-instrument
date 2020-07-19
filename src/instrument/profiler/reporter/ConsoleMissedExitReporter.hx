package instrument.profiler.reporter;

import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.HierarchyCallData;

class ConsoleMissedExitReporter implements IProfilerReporter {
	var lock:Mutex;
	var pendingCalls:Map<Int, CallData>;
	var count:Int;

	public function new() {
		lock = new Mutex();
		pendingCalls = new Map<Int, CallData>();
		count = 0;
	}

	public function startProfiler() {}

	public function endProfiler(summary:Array<CallSummaryData>, root:HierarchyCallData) {
		if (count <= 0) {
			return;
		}
		output("------------------------");
		output("-- missing exit calls --");
		output("------------------------");
		for (data in pendingCalls) {
			output("[" + data.id + "] " + data.location + ": " + data.className + "." + data.functionName);
		}
	}

	public function enterFunction(data:CallData) {
		lock.acquire();
		pendingCalls.set(data.id, data);
		count++;
		lock.release();
	}

	public function exitFunction(data:CallData) {
		lock.acquire();
		if (pendingCalls.exists(data.id)) {
			count--;
			pendingCalls.remove(data.id);
		}
		lock.release();
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
