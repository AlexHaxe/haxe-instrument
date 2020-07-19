package instrument.profiler.reporter;

import haxe.io.Path;
import haxe.macro.Compiler;
import instrument.profiler.summary.CallData;
import instrument.profiler.summary.CallSummaryData;
import instrument.profiler.summary.HierarchyCallData;
#if (sys || nodejs)
import sys.FileSystem;
import sys.io.File;
#end

class CSVSummaryReporter implements IProfilerReporter {
	public function new() {}

	public function startProfiler() {}

	public function endProfiler(summary:Array<CallSummaryData>, root:HierarchyCallData) {
		var lines:Array<String> = [];
		lines.push("thread;invocations;total time in ms;class;function;location");
		summary.sort(sortSummary);
		for (data in summary) {
			lines.push('thread-${data.threadId};${data.count};${data.duration * 1000};${data.className};${data.functionName};${data.location}');
		}
		output(lines);
	}

	function sortSummary(a:CallSummaryData, b:CallSummaryData):Int {
		if (a.threadId < b.threadId) {
			return -1;
		}
		if (a.threadId > b.threadId) {
			return 1;
		}
		if (a.duration < b.duration) {
			return 1;
		}
		if (a.duration > b.duration) {
			return -1;
		}
		return 0;
	}

	public function enterFunction(data:CallData) {}

	public function exitFunction(data:CallData) {}

	function output(lines:Array<String>) {
		var text:String = lines.join("\n");
		#if (sys || nodejs)
		File.saveContent(getCsvFileName(), text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
	}

	#if (sys || nodejs)
	public static function getCsvFileName():String {
		var fileName:String = Compiler.getDefine("profiler-csv-file");
		if ((fileName == null) || (fileName.length <= 0) || (fileName == "1")) {
			fileName = "summary.xml";
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
