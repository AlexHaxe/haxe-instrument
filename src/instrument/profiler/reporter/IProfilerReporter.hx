package instrument.profiler.reporter;

import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.HierarchyCallData;

interface IProfilerReporter {
	function startProfiler():Void;
	function endProfiler(summary:Array<CallSummaryData>, root:HierarchyCallData):Void;

	function enterFunction(data:CallData):Void;
	function exitFunction(data:CallData):Void;
}
