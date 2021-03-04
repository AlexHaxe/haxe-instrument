package instrument.profiler.summary;

import haxe.Timer;

class HierarchicalSummary implements ISummary {
	var lock:Mutex;

	var stack:Array<HierarchicalData>;
	var startTime:Float;

	public var root(default, null):HierarchicalData;

	public function new(threadId:Int) {
		lock = new Mutex();
		root = new HierarchicalData({
			id: Profiler.nextId(),
			threadId: threadId,
			location: 'thread-$threadId',
			className: 'thread-$threadId',
			functionName: "",
			// args: [],
			startTime: 0,
			endTime: 0
		}, null);
		// root.overrideClassName('thread-$threadId');
		stack = [root];
		startTime = Timer.stamp();
		root.setLastStartTime(startTime);
	}

	public function startProfiler() {}

	public function endProfiler() {
		var endTime:Float = Timer.stamp();
		root.setEndTime(endTime);
		for (call in stack) {
			call.setEndTime(endTime);
		}
	}

	public function enterFunction(data:CallData) {
		lock.acquire();
		var parent:HierarchicalData = stack[stack.length - 1];
		var child:HierarchicalData = parent.addChild(data);
		stack.push(child);
		child.increaseInvocations(data);
		lock.release();
	}

	public function exitFunction(data:CallData) {
		lock.acquire();
		var current:HierarchicalData = stack.pop().sure();
		current.addDuration(data);
		lock.release();
	}
}
