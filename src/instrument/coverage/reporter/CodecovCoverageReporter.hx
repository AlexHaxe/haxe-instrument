package instrument.coverage.reporter;

import haxe.macro.Compiler;

class CodecovCoverageReporter extends FileBaseReporter implements ICoverageReporter {
	public function new(?fileName:Null<String>) {
		super(fileName, Compiler.getDefine("coverage-codecov-reporter"), "codecov.json");
	}

	public function generateReport(context:CoverageContext) {
		var text:StringBuf = new StringBuf();
		text.add('{"coverage": {');
		var first:Bool = true;
		for (file in context.files) {
			if (!first) {
				text.add(", ");
			}
			first = false;
			text.add('\n"${file.file}": {');

			var lineCov:Map<Int, String> = makeLineCoverage(file);
			var lineNumbers:Array<Int> = [for (line => _ in lineCov) line];
			lineNumbers.sort((a, b) -> (a < b) ? -1 : 1);
			var firstLine:Bool = true;
			for (line in lineNumbers) {
				if (!firstLine) {
					text.add(", ");
				}
				firstLine = false;
				text.add('"$line": ${lineCov.get(line)}');
			}

			text.add("}");
		}

		text.add("\n}}");
		output(text.toString());
	}

	function makeLineCoverage(file:FileInfo):Map<Int, String> {
		var coverage:Map<Int, String> = new Map<Int, String>();
		var fileName = file.file;

		for (type in file.types) {
			for (field in type.fields) {
				for (branches in field.branches) {
					if (!branches.location.startsWith(fileName)) {
						continue;
					}
					if (branches.isCovered()) {
						continue;
					}
					coverage.set(branches.startLine, '"${branches.branchesCovered}/${branches.branchCount}"');
				}
				for (expression in field.expressions) {
					if (!expression.location.startsWith(fileName)) {
						continue;
					}
					for (line in expression.startLine...expression.endLine + 1) {
						if (coverage.exists(line)) {
							continue;
						}
						coverage.set(line, '${expression.count}');
					}
				}
			}
		}
		return coverage;
	}
}
