package instrument.profiler.reporter;

import haxe.Json;
import haxe.io.Path;
import haxe.macro.Compiler;
import instrument.profiler.reporter.data.D3FlameNode;
import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.HierarchyCallData;
#if (sys || nodejs)
import sys.FileSystem;
import sys.io.File;
#end

class D3FlameHierarchyReporter implements IProfilerReporter {
	public function new() {}

	public function startProfiler() {}

	public function endProfiler(summary:Array<CallSummaryData>, root:HierarchyCallData) {
		var d3Root:D3FlameNode = buildD3FlameData(root);
		output(d3Root);
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

	function output(root:D3FlameNode) {
		var text:String = Json.stringify(root, "    ");
		#if (sys || nodejs)
		File.saveContent(getFlameFileName(), text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
	}

	#if (sys || nodejs)
	public static function getFlameFileName():String {
		var fileName:String = Compiler.getDefine("profiler-flame-file");
		if ((fileName == null) || (fileName.length <= 0) || (fileName == "1")) {
			fileName = "flame.json";
		}
		fileName = Path.join([Instrumentation.baseFolder(), fileName]);
		var folder:String = Path.directory(fileName);
		if (folder.trim().length > 0) {
			if (!FileSystem.exists(folder)) {
				FileSystem.createDirectory(folder);
			}
		}
		return fileName;
	}
	#end
}
