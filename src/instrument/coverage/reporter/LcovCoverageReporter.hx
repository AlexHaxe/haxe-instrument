package instrument.coverage.reporter;

import haxe.io.Path;
import haxe.macro.Compiler;
#if (sys || nodejs)
import sys.FileSystem;
import sys.io.FileOutput;
#end

class LcovCoverageReporter extends CoverageFileBaseReporter implements ICoverageReporter {
	public function new(?fileName:Null<String>) {
		super(fileName, Compiler.getDefine("coverage-lcov-reporter"), "lcov.info");
	}

	public function generateReport(context:CoverageContext) {
		#if (sys || nodejs)
		sys.io.File.saveContent(CoverageFileBaseReporter.getCoverageFileName(fileName), "\n");
		#end

		var fileTypeMap:Map<String, Array<TypeInfo>> = new Map<String, Array<TypeInfo>>();
		for (type in context.types) {
			if (fileTypeMap.exists(type.file)) {
				fileTypeMap.get(type.file).push(type);
				continue;
			}
			fileTypeMap.set(type.file, [type]);
		}
		for (file in fileTypeMap.keys()) {
			reportFile(file, fileTypeMap.get(file));
		}
	}

	function reportFile(file:String, types:Array<TypeInfo>) {
		var text:StringBuf = new StringBuf();

		text.add(makeLine("TN", types[0].name));
		text.add(makeLine("SF", file));
		text.add("\n");

		var maxLineNumber:Int = 0;

		var num:Int = 0;
		for (type in types) {
			for (field in type.fields) {
				text.add(makeLine("FN", '${field.startLine},${field.name}'));
			}
		}
		text.add("\n");

		for (type in types) {
			for (field in type.fields) {
				text.add(makeLine("FNDA", '${field.count},${field.name}'));
			}
		}

		text.add("\n");
		var countF:Int = 0;
		var countH:Int = 0;
		for (type in types) {
			countF += type.fields.length;
			countH += type.fieldsCovered;
		}
		text.add(makeLine("FNF", '$countF'));
		text.add(makeLine("FNH", '$countH'));
		text.add("\n");

		text.add(makeBranchCoverage(types));

		text.add("\n");

		text.add("\n");
		countF = 0;
		countH = 0;
		for (type in types) {
			countF += type.branchCount;
			countH += type.branchesCovered;
		}
		text.add(makeLine("BRF", '$countF'));
		text.add(makeLine("BRH", '$countH'));
		text.add("\n");

		maxLineNumber = 0;
		var lineCov:Map<Int, Int> = new Map<Int, Int>();
		for (type in types) {
			for (field in type.fields) {
				for (expr in field.expressions) {
					for (line in expr.startLine...expr.endLine + 1) {
						var count:Int = 0;
						if (!lineCov.exists(line)) {
							lineCov.set(line, expr.count);
							continue;
						}
						count = lineCov.get(line);
						if (count <= expr.count) {
							continue;
						}
						lineCov.set(line, expr.count);
					}
					if (maxLineNumber < expr.endLine) {
						maxLineNumber = expr.endLine;
					}
				}
			}
		}
		for (type in types) {
			for (field in type.fields) {
				for (branches in field.branches) {
					for (branch in branches.branches) {
						for (line in branch.startLine...branch.endLine + 1) {
							lineCov.set(line, branch.count);
						}
						if (maxLineNumber < branch.endLine) {
							maxLineNumber = branch.endLine;
						}
					}
				}
			}
		}
		for (line in 0...maxLineNumber + 1) {
			if (!lineCov.exists(line)) {
				continue;
			}
			var count:Int = lineCov.get(line);
			text.add(makeLine("DA", '${line},${count}'));
		}
		text.add("\n");

		countF = 0;
		countH = 0;
		for (type in types) {
			countF += type.lineCount;
			countH += type.linesCovered;
		}
		text.add(makeLine("LF", '$countF'));
		text.add(makeLine("LH", '$countH'));
		text.add("\n");

		text.add("end_of_record\n\n");
		appendCoverageFile(text.toString());
	}

	function makeBranchCoverage(types:Array<TypeInfo>):String {
		var text:StringBuf = new StringBuf();
		var lineCov:Map<Int, {block:Int, branch:Int, count:Int}> = new Map<Int, {block:Int, branch:Int, count:Int}>();
		for (type in types) {
			for (field in type.fields) {
				for (branches in field.branches) {
					for (branch in branches.branches) {
						var cov:{block:Int, branch:Int, count:Int} = {
							block: branches.id,
							branch: branch.id,
							count: branch.count
						};
						if (!lineCov.exists(branch.startLine)) {
							lineCov.set(branch.startLine, cov);
							continue;
						}
						var oldCov:{block:Int, branch:Int, count:Int} = lineCov.get(branch.startLine);
						if (oldCov.count > cov.count) {
							lineCov.set(branch.startLine, cov);
						}
					}
				}
			}
		}
		var lines:Array<Int> = [for (line => _ in lineCov) line];
		lines.sort((a, b) -> (a < b) ? -1 : 1);
		for (line in lines) {
			var cov:{block:Int, branch:Int, count:Int} = lineCov.get(line);
			if (cov.count <= 0) {
				text.add(makeLine("BRDA", '${line},${cov.block},${cov.branch},-'));
			} else {
				text.add(makeLine("BRDA", '${line},${cov.block},${cov.branch},${cov.count}'));
			}
		}
		return text.toString();
	}

	function appendCoverageFile(text:String) {
		#if nodejs
		js.node.Fs.appendFileSync(CoverageFileBaseReporter.getCoverageFileName(fileName), text);
		#elseif sys
		var file:FileOutput = sys.io.File.append(CoverageFileBaseReporter.getCoverageFileName(fileName));
		file.writeString(text.toString());
		file.close();
		#end
	}

	inline function makeLine(key:String, value:String):String {
		return '$key:$value\n';
	}

	override function output(text:String) {
		#if (sys || nodejs)
		appendCoverageFile(text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
	}
}
