package instrument.profiler;

import haxe.Timer;
import instrument.profiler.reporter.IProfilerReporter;
import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.FlatSummary;
import instrument.profiler.summary.HierarchicalData;
import instrument.profiler.summary.HierarchicalSummary;
import instrument.profiler.summary.ThreadSummaryContext;

@:ignoreProfiler
@:expose
class Profiler {
	static var profilerId:Null<Int>;
	static var pendingCalls:Null<Map<String, CallData>>;
	static var lock:Null<Mutex>;
	static var reporter:Null<Array<IProfilerReporter>>;
	static var completed:Bool = false;

	static var threads:Null<Array<Thread>>;
	static var threadContexts:Null<Map<Int, ThreadSummaryContext>>;

	static var lastExits:Null<Map<Int, CallData>>;

	static function getThreadContext():ThreadSummaryContext {
		var context:Null<ThreadSummaryContext> = null;

		if (lock == null) {
			lock = new Mutex();
		}
		lock.sure().acquire();

		var threadId:Int = determineThreadId();
		if (threadContexts == null) {
			threadContexts = new Map<Int, ThreadSummaryContext>();
		}
		if (!threadContexts.sure().exists(threadId)) {
			context = {
				threadId: threadId,
				itsMe: false,
				flatSummary: new FlatSummary(),
				hierarchicalSummary: new HierarchicalSummary(threadId)
			};
			threadContexts.sure().set(threadId, context);
		} else {
			context = threadContexts.sure().get(threadId);
		}

		lock.sure().release();

		return context.sure();
	}

	static function determineThreadId():Int {
		#if eval
		return eval.vm.NativeThread.self().id();
		#else
		var currentThread:Thread = Thread.current();
		if (threads == null) {
			threads = [];
		}
		var index:Int = 0;
		for (index in 0...threads.length) {
			var thread:Thread = threads[index];
			if (thread == currentThread) {
				return index;
			}
		}
		threads.push(currentThread);
		return threads.length - 1;
		#end
	}

	public static function enterFunction(location:String, className:String, functionName:String, argNames:Null<Array<String>>):Int {
		var context:ThreadSummaryContext = getThreadContext();
		if (context == null) {
			return -1;
		}
		if (context.itsMe) {
			return -1;
		}
		context.itsMe = true;

		if (completed) {
			return -1;
		}
		lock.sure().acquire();
		var newId:Int = nextId();
		var data:CallData = {
			id: newId,
			threadId: context.threadId,
			location: location,
			className: className,
			functionName: functionName,
			// args: argNames,
			startTime: Timer.stamp(),
			endTime: -1
		};

		if (pendingCalls == null) {
			pendingCalls = new Map<String, CallData>();
		}
		if (lastExits == null) {
			lastExits = new Map<Int, CallData>();
		}
		commitLastCallData(context);

		pendingCalls.sure().set('$newId', data);

		for (s in [context.flatSummary, context.hierarchicalSummary]) {
			s.enterFunction(data);
		}
		for (r in reporter.sure()) {
			r.enterFunction(data);
		}
		context.itsMe = false;
		lock.sure().release();

		return newId;
	}

	public static function exitFunction(id:Int) {
		var context:ThreadSummaryContext = getThreadContext();
		if (context == null) {
			return;
		}
		if (context.itsMe) {
			return;
		}
		if (completed) {
			return;
		}
		context.itsMe = true;
		lock.sure().acquire();
		var data:Null<CallData> = pendingCalls.sure().get('$id').sure();
		if (data == null) {
			context.itsMe = false;
			lock.sure().release();
			return;
		}
		data.endTime = Timer.stamp();
		commitLastCallData(context);
		lastExits.set(context.threadId, data);
		lock.sure().release();
		context.itsMe = false;
	}

	public static function cancelExitFunction(id:Int) {
		var context:ThreadSummaryContext = getThreadContext();
		if (context == null) {
			return;
		}
		if (context.itsMe) {
			return;
		}
		if (completed) {
			return;
		}
		context.itsMe = true;
		lock.sure().acquire();

		var lastCalldata:Null<CallData> = lastExits.get(context.threadId);
		if (lastCalldata == null) {
			lock.sure().release();
			context.itsMe = false;
			return;
		}
		if (lastCalldata.id == id) {
			lastExits.remove(context.threadId);
			context.itsMe = false;
			lock.sure().release();
			return;
		}
		commitLastCallData(context);
		lock.sure().release();
		context.itsMe = false;
	}

	public static function endProfiler() {
		var context:ThreadSummaryContext = getThreadContext();
		if (context == null) {
			return;
		}
		if (context.itsMe) {
			return;
		}
		context.itsMe = true;
		completed = true;

		for (threadId => ctx in threadContexts.sure()) {
			ctx.itsMe = true;
			commitLastCallData(ctx);
			for (s in [ctx.flatSummary, ctx.hierarchicalSummary]) {
				s.endProfiler();
			}
		}

		var summary:Array<CallSummaryData> = [];
		var root:HierarchicalData = new HierarchicalData(null, null);
		var duration:Float = 0;
		for (_ => ctx in threadContexts.sure()) {
			root.addChildNode(ctx.hierarchicalSummary.root);
			duration += ctx.hierarchicalSummary.root.duration;
			for (key => value in ctx.flatSummary.summary) {
				summary.push(value);
			}
		}
		root.setDuration(duration);

		for (r in reporter.sure()) {
			r.endProfiler(summary, root);
		}
		for (_ => ctx in threadContexts.sure()) {
			ctx.itsMe = false;
		}
		completed = false;
	}

	static function commitLastCallData(context:ThreadSummaryContext) {
		var lastCalldata:Null<CallData> = lastExits.get(context.threadId);
		if (lastCalldata == null) {
			return;
		}
		pendingCalls.sure().remove('$lastCalldata.id');
		for (s in [context.flatSummary, context.hierarchicalSummary]) {
			s.exitFunction(lastCalldata);
		}
		for (r in reporter.sure()) {
			r.exitFunction(lastCalldata);
		}
		lastExits.remove(context.threadId);
	}

	public static function nextId():Int {
		if (profilerId == null) {
			profilerId = 1;
		}
		var next:Int = @:nullSafety(Off) profilerId++;
		return next;
	}

	static function __init__() {
		completed = false;
		if (lock == null) {
			lock = new Mutex();
		}
		if (threadContexts == null) {
			threadContexts = new Map<Int, ThreadSummaryContext>();
		}

		reporter = [];

		#if profiler_console_detail_reporter
		reporter.sure().push(new instrument.profiler.reporter.ConsoleDetailReporter());
		#end

		#if profiler_console_missing_reporter
		reporter.sure().push(new instrument.profiler.reporter.ConsoleMissedExitReporter());
		#end

		#if profiler_console_summary_reporter
		reporter.sure().push(new instrument.profiler.reporter.ConsoleSummaryReporter());
		#end

		#if profiler_console_hierarchy_reporter
		reporter.sure().push(new instrument.profiler.reporter.ConsoleHierarchyReporter());
		#end

		#if profiler_csv_reporter
		reporter.sure().push(new instrument.profiler.reporter.CSVSummaryReporter());
		#end

		#if profiler_d3_reporter
		reporter.sure().push(new instrument.profiler.reporter.D3FlameHierarchyReporter());
		#end

		#if profiler_cpuprofile_reporter
		reporter.sure().push(new instrument.profiler.reporter.CPUProfileReporter());
		#end

		for (r in reporter.sure()) {
			r.startProfiler();
		}
	}
}
