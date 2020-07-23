package instrument;

#if (sys || nodejs)
#end
class FileBaseReporter {
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
		sys.io.File.saveContent(Instrumentation.workspaceFileName(fileName), text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
	}
}
