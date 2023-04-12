package instrument.coverage.reporter;

class ConsoleMissingCoverageReporter implements ICoverageReporter {
	var outputLines:Array<OutputLine> = [];
	var lineMap:Map<String, Bool>;

	public function new() {
		lineMap = new Map<String, Bool>();
	}

	public function generateReport(context:CoverageContext) {
		reportUncoveredTypes(context);
		outputLines.sort(sortOutput);
		if (outputLines.length > 0) {
			output("");
			output("======================");
			output("== missing coverage ==");
			output("======================");
		}
		for (o in outputLines) {
			output('${o.file}:${o.lineNumber}: ${o.text}');
		}
	}

	function addOutput(file:String, lineNumber:Int, text:String) {
		var line:String = '${file}:${lineNumber}: ${text}';
		if (lineMap.exists(line)) {
			return;
		}
		lineMap.set(line, true);
		outputLines.push({file: file, lineNumber: lineNumber, text: text});
	}

	function sortOutput(a:OutputLine, b:OutputLine):Int {
		if (a.file < b.file) {
			return -1;
		}
		if (a.file > b.file) {
			return 1;
		}
		if (a.lineNumber < b.lineNumber) {
			return -1;
		}
		if (a.lineNumber > b.lineNumber) {
			return 1;
		}
		return 0;
	}

	function reportUncoveredTypes(context:CoverageContext) {
		for (type in context.types) {
			if (type.isCovered()) {
				continue;
			}
			addOutput(type.file, type.startLine, "type " + type.name + " not covered");
		}
		for (type in context.types) {
			reportUncoveredFields(type, type.file);
		}
	}

	function reportUncoveredFields(type:TypeInfo, file:String) {
		for (field in type.fields) {
			if (field.isCovered()) {
				continue;
			}
			final fileName = field.location.substring(0, field.location.indexOf(":"));
			addOutput(file, field.startLine, "field " + field.name + " not covered");
		}

		for (field in type.fields) {
			reportUncoveredBranches(field, file);
		}
		for (field in type.fields) {
			reportUncoveredExpressions(field, file);
		}
	}

	function reportUncoveredBranches(field:FieldInfo, file:String) {
		for (branches in field.branches) {
			if (branches.isCovered()) {
				continue;
			}
			for (branch in branches.branches) {
				if (branch.isCovered()) {
					continue;
				}
				final fileName = branch.location.substring(0, branch.location.indexOf(":"));
				addOutput(fileName, branch.startLine, "branch not covered");
			}
		}
	}

	function reportUncoveredExpressions(field:FieldInfo, file:String) {
		for (expression in field.expressions) {
			if (expression.isCovered()) {
				continue;
			}
			final fileName = expression.location.substring(0, expression.location.indexOf(":"));
			addOutput(fileName, expression.startLine, "expression not covered");
		}
	}

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

typedef OutputLine = {
	var file:String;
	var lineNumber:Int;
	var text:String;
}
