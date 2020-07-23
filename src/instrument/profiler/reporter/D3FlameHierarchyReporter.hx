package instrument.profiler.reporter;

import haxe.Json;
import haxe.macro.Context;
import instrument.profiler.reporter.data.D3FlameNode;
import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.HierarchyCallData;

#if (sys || nodejs)
#end
class D3FlameHierarchyReporter extends FileBaseReporter implements IProfilerReporter {
	public function new(?fileName:Null<String>) {
		#if macro
		super(fileName, Context.definedValue("profiler-d3-reporter"), "flame.json");
		#else
		super(fileName, haxe.macro.Compiler.getDefine("profiler-d3-reporter"), "flame.json");
		#end
	}

	public function startProfiler() {}

	public function endProfiler(summary:Array<CallSummaryData>, root:HierarchyCallData) {
		var d3Root:D3FlameNode = buildD3FlameData(root);
		outputFlame(d3Root);
	}

	function buildD3FlameData(tree:HierarchyCallData):D3FlameNode {
		if (tree == null) {
			return null;
		}

		var name:String = tree.className;
		if ((tree.parent != null) && (tree.functionName != null) && (tree.functionName.length > 0)) {
			name += "." + tree.functionName;
		}
		var node:D3FlameNode = {
			name: name,
			value: Math.floor(tree.duration * 1000 * 1000)
		}

		if (tree.childs == null) {
			return node;
		}
		node.children = tree.childs.map(c -> buildD3FlameData(c));
		return node;
	}

	public function enterFunction(data:CallData) {}

	public function exitFunction(data:CallData) {}

	function outputFlame(root:D3FlameNode) {
		output(Json.stringify(root, "    "));
	}
}
