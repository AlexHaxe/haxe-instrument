package instrument.profiler;

import haxe.Timer;
import instrument.profiler.reporter.IProfilerReporter;
import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.FlatSummary;
import instrument.profiler.summary.HierarchicalSummary;
import instrument.profiler.summary.HierarchyCallData;
import instrument.profiler.summary.ThreadSummaryContext;

@:ignoreProfiler
@:expose
class Profiler {
	static var profilerId:Null<Int>;
	static var pendingCalls:Map<String, CallData>;
	static var lock:Mutex;
	static var reporter:Array<IProfilerReporter>;
	static var completed:Bool;

	static var threads:Array<Thread>;
	static var threadContexts:Map<Int, ThreadSummaryContext>;

	static function getThreadContext():ThreadSummaryContext {
		var context:ThreadSummaryContext = null;

		if (lock == null) {
			lock = new Mutex();
		}
		lock.acquire();

		var threadId:Int = determineThreadId();
		if (threadContexts == null) {
			threadContexts = new Map<Int, ThreadSummaryContext>();
		}
		if (!threadContexts.exists(threadId)) {
			context = {
				threadId: threadId,
				itsMe: false,
				flatSummary: new FlatSummary(),
				hierarchicalSummary: new HierarchicalSummary(threadId)
			};
			threadContexts.set(threadId, context);
		} else {
			context = threadContexts.get(threadId);
		}

		lock.release();

		return context;
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

	public static function enterFunction(location:String, className:String, functionName:String, argNames:Array<String>):Int {
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
		lock.acquire();
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

		pendingCalls.set('$newId', data);
		for (s in [context.flatSummary, context.hierarchicalSummary]) {
			s.enterFunction(data);
		}
		for (r in reporter) {
			r.enterFunction(data);
		}
		context.itsMe = false;
		lock.release();

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
		lock.acquire();
		var data:CallData = pendingCalls.get('$id');
		if (data == null) {
			context.itsMe = false;
			lock.release();
			return;
		}
		if (data != null) {
			data.endTime = Timer.stamp();
		}
		pendingCalls.remove('$id');
		lock.release();
		for (s in [context.flatSummary, context.hierarchicalSummary]) {
			s.exitFunction(data);
		}
		for (r in reporter) {
			r.exitFunction(data);
		}
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

		for (threadId => ctx in threadContexts) {
			ctx.itsMe = true;
			for (s in [ctx.flatSummary, ctx.hierarchicalSummary]) {
				s.endProfiler();
			}
		}

		var summary:Array<CallSummaryData> = [];
		var root:HierarchyCallData = new HierarchyCallData(null, null);
		var duration:Float = 0;
		for (_ => ctx in threadContexts) {
			root.addChildNode(ctx.hierarchicalSummary.root);
			duration += ctx.hierarchicalSummary.root.duration;
			for (key => value in ctx.flatSummary.summary) {
				summary.push(value);
			}
		}
		root.setDuration(duration);

		for (r in reporter) {
			r.endProfiler(summary, root);
		}
		for (_ => ctx in threadContexts) {
			ctx.itsMe = false;
		}
		completed = false;
	}

	public static function nextId():Int {
		if (profilerId == null) {
			profilerId = 1;
		}
		var next:Int = profilerId++;
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
		reporter.push(new instrument.profiler.reporter.ConsoleDetailReporter());
		#end

		#if profiler_console_missing_reporter
		reporter.push(new instrument.profiler.reporter.ConsoleMissedExitReporter());
		#end

		#if profiler_console_summary_reporter
		reporter.push(new instrument.profiler.reporter.ConsoleSummaryReporter());
		#end

		#if profiler_console_hierarchy_reporter
		reporter.push(new instrument.profiler.reporter.ConsoleHierarchyReporter());
		#end

		#if profiler_csv_reporter
		reporter.push(new instrument.profiler.reporter.CSVSummaryReporter());
		#end

		#if profiler_d3_reporter
		reporter.push(new instrument.profiler.reporter.D3FlameHierarchyReporter());
		#end

		#if profiler_cpuprofile_reporter
		reporter.push(new instrument.profiler.reporter.CPUProfileReporter());
		#end

		for (r in reporter) {
			r.startProfiler();
		}
	}
}
