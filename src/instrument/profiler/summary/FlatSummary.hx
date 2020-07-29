package instrument.profiler.summary;

class FlatSummary implements ISummary {
	var lock:Mutex;

	public var summary(default, null):Map<String, CallSummaryData>;

	public function new() {
		lock = new Mutex();
		summary = new Map<String, CallSummaryData>();
	}

	public function startProfiler() {}

	public function endProfiler() {}

	public function enterFunction(data:CallData) {}

	public function exitFunction(data:CallData) {
		lock.acquire();
		var callSummary:Null<CallSummaryData> = summary.get(data.location);
		if (callSummary == null) {
			callSummary = {
				threadId: data.threadId,
				location: data.location,
				className: data.className,
				functionName: data.functionName,
				count: 0,
				duration: 0
			};
			summary.set(data.location, callSummary);
		}
		callSummary.sure().count++;
		callSummary.sure().duration += data.endTime - data.startTime;
		lock.release();
	}
}
