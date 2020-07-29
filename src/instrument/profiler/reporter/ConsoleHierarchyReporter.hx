package instrument.profiler.reporter;

import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.HierarchyCallData;

class ConsoleHierarchyReporter implements IProfilerReporter {
	public function new() {}

	public function startProfiler() {}

	public function endProfiler(summary:Array<CallSummaryData>, root:HierarchyCallData) {
		output("");
		output("====================");
		output("== Call Hierarchy ==");
		output("====================");
		printTree(root, "");
	}

	function printTree(tree:HierarchyCallData, indent:String) {
		if (tree == null) {
			return;
		}
		if ((tree.functionName == null) || (tree.functionName.length <= 0)) {
			output(indent + "+ " + tree.className + " " + (tree.duration * 1000) + "ms");
		} else {
			output(indent
				+ "+ "
				+ tree.location
				+ ": "
				+ tree.className
				+ "."
				+ tree.functionName
				+ " "
				+ tree.count
				+ " "
				+ (tree.duration * 1000)
				+ "ms");
		}
		if (tree.childs == null) {
			return;
		}
		for (child in tree.childs.sure()) {
			printTree(child, indent + "---");
		}
	}

	public function enterFunction(data:CallData) {}

	public function exitFunction(data:CallData) {}

	function output(text:String) {
		#if (sys || nodejs)
		Sys.println(text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
	}
}
