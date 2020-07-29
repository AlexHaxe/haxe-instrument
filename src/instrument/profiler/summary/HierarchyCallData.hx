package instrument.profiler.summary;

class HierarchyCallData {
	public var id(default, null):Int;
	public var location(default, null):String;
	public var className(default, null):String;
	public var functionName(default, null):String;
	public var parent(default, null):Null<HierarchyCallData>;
	public var childs(default, null):Null<Array<HierarchyCallData>>;

	public var count(default, null):Int;
	public var duration(default, null):Float;

	public var lastStartTime(default, null):Float;
	public var lastEndTime(default, null):Float;

	public function new(data:Null<CallData>, parent:Null<HierarchyCallData>) {
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
		count++;
	}

	public function addDuration(data:CallData) {
		duration += data.endTime - data.startTime;
		lastEndTime = data.endTime;
	}

	public function setLastStartTime(startTime:Float) {
		lastStartTime = startTime;
	}

	public function setEndTime(endTime:Float) {
		duration += endTime - lastStartTime;
		lastEndTime = endTime;
	}

	public function setDuration(duration:Float) {
		this.duration = duration;
	}

	public function addChild(data:CallData):HierarchyCallData {
		if (childs == null) {
			var child:HierarchyCallData = new HierarchyCallData(data, this);
			childs = [child];
			return child;
		}
		for (child in childs.sure()) {
			if (child.location == data.location) {
				return child;
			}
		}
		var child:HierarchyCallData = new HierarchyCallData(data, this);
		childs.sure().push(child);
		return child;
	}

	public function addChildNode(node:HierarchyCallData) {
		node.parent = this;
		if (childs == null) {
			childs = [node];
			return;
		}
		childs.sure().push(node);
	}
}
