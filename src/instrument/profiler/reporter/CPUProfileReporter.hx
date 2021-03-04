package instrument.profiler.reporter;

import haxe.Json;
import haxe.io.Path;
import haxe.macro.Context;
import instrument.profiler.reporter.data.CPUProfile;
import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.HierarchicalData;

#if (sys || nodejs)
#end
// TODO fixme
class CPUProfileReporter extends FileBaseReporter implements IProfilerReporter {
	var scriptIds:Map<String, Int>;
	var nextScriptId:Int;

	public function new(?fileName:Null<String>) {
		scriptIds = new Map<String, Int>();
		nextScriptId = 1;
		#if macro
		super(fileName, Context.definedValue("profiler-cpuprofile-reporter"), "profiler.cpuprofile");
		#else
		super(fileName, haxe.macro.Compiler.getDefine("profiler-cpuprofile-reporter"), "profiler.cpuprofile");
		#end
	}

	public function startProfiler() {}

	public function endProfiler(summary:Array<CallSummaryData>, root:HierarchicalData) {
		if (root.childs.length <= 1) {
			var profile:Null<CPUProfileTwo> = buildCPUProfileTwo(root);
			if (profile != null) {
				outputProfileTwo(profile.sure());
			}
		} else {
			var name:String = fileName;
			var path:Path = new Path(fileName);
			for (child in root.childs) {
				fileName = Path.join([path.dir, path.file + '_${child.location}.${path.ext}']);
				var profile:Null<CPUProfileTwo> = buildCPUProfileTwo(child);
				if (profile != null) {
					outputProfileTwo(profile.sure());
				}
			}
			fileName = name;
		}
	}

	// function buildCPUProfileOne(tree:HierarchyCallData):Null<CPUProfileOne> {
	// 	if (tree == null) {
	// 		return null;
	// 	}
	// 	var name:String = tree.className;
	// 	if ((tree.parent != null) && (tree.functionName != null) && (tree.functionName.length > 0)) {
	// 		name += "." + tree.functionName;
	// 	}
	// 	var samples:Array<Int> = [tree.id];
	// 	var timeDeltas:Array<Float> = [tree.lastStartTime * 1000];
	// 	var profile:CPUProfileOne = {
	// 		head: makeHeadOne(Sys.programPath(), 0),
	// 		uid: 1,
	// 		title: "Haxe instrument root",
	// 		typeId: "Haxe instrument root",
	// 		startTime: tree.lastStartTime * 1000,
	// 		endTime: (tree.lastEndTime + 112),
	// 		samples: samples,
	// 		timeDeltas: timeDeltas
	// 	};
	// 	collectChildNodesOne(tree, profile.head, null, samples, timeDeltas);
	// 	return profile;
	// }
	// function makeHeadOne(name:String, id:Int):CPUProfileHeadOne {
	// 	return {
	// 		functionName: name,
	// 		url: "",
	// 		lineNumber: 0,
	// 		bailoutReason: "",
	// 		id: id,
	// 		scriptId: id,
	// 		hitCount: 0,
	// 		children: []
	// 	}
	// }
	// function makeNodeOne(name:String, lineNumber:Int, url:String, id:Int, scriptId:Int, hitCount:Int, stackFrame:String):CPUProfileNodeOne {
	// 	if (name == "") {
	// 		name = url;
	// 	}
	// 	return {
	// 		functionName: name,
	// 		url: url,
	// 		lineNumber: 0,
	// 		bailoutReason: "",
	// 		id: id,
	// 		scriptId: 0,
	// 		hitCount: hitCount,
	// 		children: [],
	// 		_stackFrame: stackFrame
	// 	}
	// }
	// function collectChildNodesOne(tree:HierarchyCallData, head:CPUProfileHeadOne, parent:Null<CPUProfileNodeOne>, samples:Array<Int>,
	// 		timeDeltas:Array<Float>) {
	// 	if (tree == null) {
	// 		return;
	// 	}
	// 	var index:Int = tree.location.lastIndexOf(":");
	// 	var url:String = tree.location;
	// 	var lineNum:Int = -1;
	// 	if (index > 0) {
	// 		url = tree.location.substr(0, index);
	// 		lineNum = Std.parseInt(tree.sure().location.substr(index + 1)).sure();
	// 	}
	// 	var cpuNode:CPUProfileNodeOne = makeNodeOne(tree.functionName, lineNum, url, tree.id, head.scriptId, tree.count, tree.functionName);
	// 	if (tree.childs != null) {
	// 		for (child in tree.childs.sure()) {
	// 			collectChildNodesOne(child, head, cpuNode, samples, timeDeltas);
	// 		}
	// 	}
	// 	if (parent == null) {
	// 		head.children.push(cpuNode);
	// 	} else {
	// 		parent.children.push(cpuNode);
	// 		// samples.push(tree.id);
	// 		// timeDeltas.push(tree.duration * 1000);
	// 	}
	// }

	function buildCPUProfileTwo(tree:HierarchicalData):Null<CPUProfileTwo> {
		if (tree == null) {
			return null;
		}

		var name:String = tree.className;
		if ((tree.parent != null) && (tree.functionName != null) && (tree.functionName.length > 0)) {
			name += "." + tree.functionName;
		}

		var samples:Array<Int> = [];
		var timeDeltas:Array<Int> = [];

		var deltaSamples:Array<CPUDeltaSample> = [];

		var startTime:Int = Math.floor(tree.firstStartTime * 1000);
		var endTime:Int = Math.floor(tree.lastEndTime * 1000);

		var totalHitCount:Int = tree.getTotalHitCount();
		var sampleFactor:Float = totalHitCount / (endTime - startTime);
		trace(totalHitCount);

		var profile:CPUProfileTwo = {
			nodes: [],
			startTime: startTime,
			endTime: endTime,
			samples: samples,
			timeDeltas: timeDeltas
		};
		collectChildNodesTwo(tree, profile, deltaSamples);
		deltaSamples.push({
			id: tree.id,
			sampleTime: tree.lastEndTime
		});

		deltaSamples.sort(sortDeltaSamples);
		var lastStartTime:Float = 0;
		for (sample in deltaSamples) {
			samples.push(sample.id);
			if (lastStartTime == 0) {
				lastStartTime = sample.sampleTime;
			}
			var delta:Float = sample.sampleTime - lastStartTime;
			lastStartTime = sample.sampleTime;
			timeDeltas.push(Math.floor(delta * 1000 * 1000));
		}
		return profile;
	}

	function collectChildNodesTwo(tree:HierarchicalData, profile:CPUProfileTwo, deltaSamples:Array<CPUDeltaSample>) {
		if (tree == null) {
			return;
		}
		var index:Int = tree.location.lastIndexOf(":");
		var name:String = tree.functionName;
		var url:String = "";
		var lineNum:Int = -1;
		var columnNum:Int = -1;
		var scriptId:String = "0";
		if (index > 0) {
			url = tree.location.substr(0, index);
			lineNum = Std.parseInt(tree.sure().location.substr(index + 1)).sure();
			columnNum = 0;
			scriptId = '${getScriptId(tree.className)}';
		} else {
			name = tree.location;
		}

		var callFrame:CPUCallFrameTwo = {
			functionName: name,
			scriptId: url,
			url: url,
			lineNumber: lineNum,
			columnNumber: columnNum
		}
		var cpuNode:CPUProfileNodeTwo = {
			id: tree.id,
			callFrame: callFrame,
			hitCount: tree.count,
			children: []
		}

		// if (tree.parent != null) {
		// 	cpuNode.parent = tree.parent.id;
		// }
		if (tree.childs != null) {
			cpuNode.children = tree.childs.map(c -> c.id);
		}
		profile.nodes.push(cpuNode);
		for (call in tree.calls) {
			trace(tree.id + " " + call.startTime + " " + call.endTime);
			deltaSamples.push({
				id: tree.id,
				sampleTime: call.startTime
			});
			deltaSamples.push({
				id: tree.parent.id,
				sampleTime: call.endTime
			});
		}
		// samples.push(tree.id);
		// timeDeltas.push(Math.floor((tree.lastStartTime) * 1000) - startTime);

		if (tree.childs != null) {
			for (child in tree.childs.sure()) {
				collectChildNodesTwo(child, profile, deltaSamples);
			}
		}
	}

	function sortDeltaSamples(a:CPUDeltaSample, b:CPUDeltaSample):Int {
		if (a.sampleTime < b.sampleTime) {
			return -1;
		}
		if (a.sampleTime > b.sampleTime) {
			return 1;
		}
		return 0;
	}

	function getScriptId(name:String):Int {
		if (scriptIds.exists(name)) {
			return scriptIds.get(name);
		}
		scriptIds.set(name, nextScriptId);
		return nextScriptId++;
	}

	public function enterFunction(data:CallData) {}

	public function exitFunction(data:CallData) {}

	function outputProfileOne(root:CPUProfileOne) {
		output(Json.stringify(root, "    "));
	}

	function outputProfileTwo(root:CPUProfileTwo) {
		output(Json.stringify(root, "    "));
	}
}
