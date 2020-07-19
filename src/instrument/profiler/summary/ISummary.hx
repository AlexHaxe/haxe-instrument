package instrument.profiler.summary;

interface ISummary {
	function startProfiler():Void;
	function endProfiler():Void;

	function enterFunction(data:CallData):Void;
	function exitFunction(data:CallData):Void;
}
