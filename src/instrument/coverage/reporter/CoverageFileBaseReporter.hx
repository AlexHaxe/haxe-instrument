package instrument.coverage.reporter;

import haxe.io.Path;
#if (sys || nodejs)
import sys.FileSystem;
#end

class CoverageFileBaseReporter {
	var fileName:String;

	public function new(fileName:Null<String>, defineFileName:Null<String>, defaultFileName:String) {
		if (fileName == null) {
			if ((defineFileName == null) || (defineFileName.length <= 0) || (defineFileName == "1")) {
				fileName = defaultFileName;
			} else {
				fileName = defineFileName;
			}
		}
		this.fileName = fileName;
	}

	function output(text:String) {
		#if (sys || nodejs)
		sys.io.File.saveContent(getCoverageFileName(fileName), text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
	}

	#if (sys || nodejs)
	static function getCoverageFileName(name:String):String {
		var filePath:String = Path.join([Instrumentation.baseFolder(), name]);
		var folder:String = Path.directory(filePath);
		if (folder.trim().length > 0) {
			if (!FileSystem.exists(folder)) {
				FileSystem.createDirectory(folder);
			}
		}
		return filePath;
	}
	#end
}
