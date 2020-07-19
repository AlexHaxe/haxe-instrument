package instrument.coverage.reporter;

import haxe.io.Path;
import haxe.macro.Compiler;
#if (sys || nodejs)
import sys.FileSystem;
#end

class CodecovCoverageReporter implements ICoverageReporter {
	public function new() {}

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

		for (type in file.types) {
			for (field in type.fields) {
				for (branches in field.branches) {
					if (branches.isCovered()) {
						continue;
					}
					coverage.set(branches.startLine, '"${branches.branchesCovered}/${branches.branchCount}"');
				}
				for (expression in field.expressions) {
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

	function output(text:String) {
		#if (sys || nodejs)
		sys.io.File.saveContent(getCodecovFileName(), text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
	}

	#if (sys || nodejs)
	public static function getCodecovFileName():String {
		var fileName:String = Compiler.getDefine("coverage-codecov-file");
		if ((fileName == null) || (fileName.length <= 0) || (fileName == "1")) {
			fileName = "coverage.json";
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
