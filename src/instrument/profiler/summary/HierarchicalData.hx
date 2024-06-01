package instrument.profiler.summary;

class HierarchicalData {
	public var id(default, null):Int;
	public var location(default, null):String;
	public var className(default, null):String;
	public var functionName(default, null):String;
	public var parent(default, null):Null<HierarchicalData>;
	public var childs(default, null):Null<Array<HierarchicalData>>;
	public var calls(default, null):Array<HierarchyCallData>;

	public var count(default, null):Int;
	public var duration(default, null):Float;

	public var lastStartTime(default, null):Float;
	public var firstStartTime(get, null):Float;
	public var lastEndTime(get, null):Float;

	public function new(data:Null<CallData>, parent:Null<HierarchicalData>) {
		calls = [];
		this.parent = parent;
		if (data == null) {
			data = {
				id: Profiler.nextId(),
				threadId: -1,
				location: "<root>",
				className: "<root>",
				functionName: "",
				// args: [],
				startTime: 0,
				endTime: 0
			};
		}
		id = data.sure().id;
		location = data.sure().location;
		className = data.sure().className;
		functionName = data.sure().functionName;
		lastStartTime = data.sure().startTime;
		lastEndTime = data.sure().endTime;
		count = 0;
		duration = 0;
	}

	public function overrideClassName(name:String) {
		className = name;
	}

	public function increaseInvocations(data:CallData) {
		calls.push({
			startTime: data.startTime,
			endTime: data.endTime
		});
		count++;
	}

	public function addDuration(data:CallData) {
		calls[calls.length - 1].endTime = data.endTime;
		duration += data.endTime - data.startTime;
		lastEndTime = data.endTime;
	}

	public function setLastStartTime(startTime:Float) {
		lastStartTime = startTime;
	}

	public function setEndTime(endTime:Float) {
		duration += endTime - lastStartTime;
		var lastCall:Null<HierarchyCallData> = calls[calls.length - 1];
		if (lastCall != null) {
			lastCall.endTime = endTime;
		}
		lastEndTime = endTime;
	}

	public function get_firstStartTime():Float {
		if (calls.length <= 0) {
			if (childs == null) {
				return 0;
			}
			if (childs.length <= 0) {
				return 0;
			}
			return childs[0].firstStartTime;
		}
		return calls[0].startTime;
	}

	public function get_lastEndTime():Float {
		if (calls.length <= 0) {
			if (childs == null) {
				return 0;
			}
			if (childs.length <= 0) {
				return 0;
			}
			var val:Float = childs[childs.length - 1].lastEndTime;
			if (val < 0) {
				val = lastEndTime;
			}
			return val;
		}
		return calls[calls.length - 1].endTime;
	}

	public function setDuration(duration:Float) {
		this.duration = duration;
	}

	public function addChild(data:CallData):HierarchicalData {
		if (childs == null) {
			var child:HierarchicalData = new HierarchicalData(data, this);
			childs = [child];
			return child;
		}
		for (child in childs.sure()) {
			if (child.location == data.location) {
				return child;
			}
		}
		var child:HierarchicalData = new HierarchicalData(data, this);
		childs.sure().push(child);
		return child;
	}

	public function addChildNode(node:HierarchicalData) {
		node.parent = this;
		if (childs == null) {
			childs = [node];
			return;
		}
		childs.sure().push(node);
	}

	public function getTotalHitCount():Int {
		var hits:Int = count;
		if (childs == null) {
			return hits;
		}
		for (child in childs) {
			hits += child.getTotalHitCount();
		}
		return hits;
	}
}

typedef HierarchyCallData = {
	var startTime:Float;
	var endTime:Float;
}
