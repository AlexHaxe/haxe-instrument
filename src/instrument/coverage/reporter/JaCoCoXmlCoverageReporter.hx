package instrument.coverage.reporter;

import haxe.macro.Compiler;

class JaCoCoXmlCoverageReporter extends FileBaseReporter implements ICoverageReporter {
	public function new(?fileName:Null<String>) {
		super(fileName, Compiler.getDefine("coverage-jacocoxml-reporter"), "jacoco-coverage.xml");
	}

	public function generateReport(context:CoverageContext) {
		var root:Xml = Xml.createElement("report");
		root.set("name", "coverage report");
		addGlobalStats(context, root);

		for (pack in context.packages) {
			root.addChild(buildPackageCoverage(pack));
		}
		output(root.toString());
	}

	function buildPackageCoverage(pack:PackageInfo):Xml {
		var packXml:Xml = Xml.createElement("package");
		packXml.set("name", pack.pack);

		packXml.addChild(buildCoverageCounter(CLASS, pack.typesCovered, pack.types.length));
		packXml.addChild(buildCoverageCounter(METHOD, pack.fieldsCovered, pack.fieldCount));
		packXml.addChild(buildCoverageCounter(LINE, pack.linesCovered, pack.lineCount));
		packXml.addChild(buildCoverageCounter(BRANCH, pack.branchesCovered, pack.branchCount));
		packXml.addChild(buildCoverageCounter(INSTRUCTION, pack.expressionsCovered, pack.expressionCount));

		var files:Array<FileInfo> = findFilesOfPackage(pack);
		for (file in files) {
			packXml.addChild(buildFileCoverage(file));
		}

		for (type in pack.types) {
			packXml.addChild(buildTypeCoverage(type));
		}
		return packXml;
	}

	function buildFileCoverage(file:FileInfo):Xml {
		var fileXml:Xml = Xml.createElement("srcfile");
		fileXml.set("name", file.file);

		fileXml.addChild(buildCoverageCounter(CLASS, file.typesCovered, file.types.length));
		fileXml.addChild(buildCoverageCounter(METHOD, file.fieldsCovered, file.fieldCount));
		fileXml.addChild(buildCoverageCounter(LINE, file.linesCovered, file.lineCount));
		fileXml.addChild(buildCoverageCounter(BRANCH, file.branchesCovered, file.branchCount));
		fileXml.addChild(buildCoverageCounter(INSTRUCTION, file.expressionsCovered, file.expressionCount));

		addLineCoverage(file, fileXml);
		return fileXml;
	}

	function buildTypeCoverage(type:TypeInfo):Xml {
		var typeXml:Xml = Xml.createElement("class");
		typeXml.set("name", type.name);
		typeXml.set("sourcefilename", type.file);

		typeXml.addChild(buildCoverageCounter(CLASS, type.isCovered() ? 1 : 0, 1));
		typeXml.addChild(buildCoverageCounter(METHOD, type.fieldsCovered, type.fields.length));
		typeXml.addChild(buildCoverageCounter(LINE, type.linesCovered, type.lineCount));
		typeXml.addChild(buildCoverageCounter(BRANCH, type.branchesCovered, type.branchCount));
		typeXml.addChild(buildCoverageCounter(INSTRUCTION, type.expressionsCovered, type.expressionCount));

		for (field in type.fields) {
			typeXml.addChild(buildFieldCoverage(field));
		}
		return typeXml;
	}

	function buildFieldCoverage(field:FieldInfo):Xml {
		var fieldXml:Xml = Xml.createElement("method");
		fieldXml.set("name", field.name);
		fieldXml.set("descriptor", "<not recorded>");
		fieldXml.set("line", '${field.startLine}');

		fieldXml.addChild(buildCoverageCounter(METHOD, field.isCovered() ? 1 : 0, 1));
		fieldXml.addChild(buildCoverageCounter(LINE, field.linesCovered, field.lineCount));
		fieldXml.addChild(buildCoverageCounter(BRANCH, field.branchesCovered, field.branchCount));
		fieldXml.addChild(buildCoverageCounter(INSTRUCTION, field.expressionsCovered, field.expressions.length));

		return fieldXml;
	}

	function addLineCoverage(file:FileInfo, fileXml:Xml) {
		var lineInfo:Map<Int, JacocoLineCounters> = new Map<Int, JacocoLineCounters>();
		for (type in file.types) {
			for (field in type.fields) {
				for (expression in field.expressions) {
					for (line in expression.startLine...expression.endLine + 1) {
						setLineCounterInstructions(lineInfo, line, 1, expression.isCovered() ? 1 : 0);
					}
				}
				for (branches in field.branches) {
					setLineCounterBranches(lineInfo, branches.startLine, branches.branchCount, branches.branchesCovered);
				}
			}
		}
		var lineCounters:Array<JacocoLineCounters> = [for (_ => info in lineInfo) info];
		lineCounters.sort((a, b) -> (a.line < b.line) ? -1 : 1);
		for (counter in lineCounters) {
			var lineXml:Xml = Xml.createElement("line");
			lineXml.set("nr", '${counter.line}');
			lineXml.set("mi", '${counter.missedExpr}');
			lineXml.set("ci", '${counter.coveredExpr}');
			lineXml.set("mb", '${counter.missedBranches}');
			lineXml.set("cb", '${counter.coveredBranches}');
			fileXml.addChild(lineXml);
		}
	}

	function setLineCounterInstructions(lineInfo:Map<Int, JacocoLineCounters>, line:Int, count:Int, covered:Int) {
		if (lineInfo.exists(line)) {
			var info:JacocoLineCounters = lineInfo.get(line);
			info.coveredExpr += covered;
			info.missedExpr += (count - covered);
		} else {
			var info:JacocoLineCounters = {
				line: line,
				missedExpr: count - covered,
				coveredExpr: covered,
				missedBranches: 0,
				coveredBranches: 0
			}
			lineInfo.set(line, info);
		}
	}

	function setLineCounterBranches(lineInfo:Map<Int, JacocoLineCounters>, line:Int, count:Int, covered:Int) {
		if (lineInfo.exists(line)) {
			var info:JacocoLineCounters = lineInfo.get(line);
			info.coveredBranches += covered;
			info.missedBranches += (count - covered);
		} else {
			var info:JacocoLineCounters = {
				line: line,
				missedExpr: 0,
				coveredExpr: 0,
				missedBranches: count - covered,
				coveredBranches: covered
			}
			lineInfo.set(line, info);
		}
	}

	function findFilesOfPackage(pack:PackageInfo):Array<FileInfo> {
		var fileMap:Map<String, FileInfo> = new Map<String, FileInfo>();
		for (type in pack.types) {
			var fileInfo:FileInfo;
			if (fileMap.exists(type.file)) {
				fileInfo = fileMap.get(type.file);
			} else {
				fileInfo = new FileInfo(type.file, pack.pack);
				fileMap.set(type.file, fileInfo);
			}
			fileInfo.addType(type);
		}
		return [for (_ => fileInfo in fileMap) fileInfo];
	}

	function buildCoverageCounter(type:JaCoCoCoverageType, covered:Int, count:Int):Xml {
		var stat:Xml = Xml.createElement("counter");
		stat.set("type", type);
		stat.set("missed", '${count - covered}');
		stat.set("covered", '$covered');
		return stat;
	}

	function addGlobalStats(context:CoverageContext, root:Xml) {
		root.addChild(buildCoverageCounter(CLASS, context.typesCovered, context.types.length));
		root.addChild(buildCoverageCounter(METHOD, context.fieldsCovered, context.fieldCount));
		root.addChild(buildCoverageCounter(LINE, context.linesCovered, context.lineCount));
		root.addChild(buildCoverageCounter(BRANCH, context.branchesCovered, context.branchCount));
		root.addChild(buildCoverageCounter(INSTRUCTION, context.expressionsCovered, context.expressionCount));
	}
}

enum abstract JaCoCoCoverageType(String) to String {
	var INSTRUCTION = "INSTRUCTION";
	var BRANCH = "BRANCH";
	var LINE = "LINE";
	var COMPLEXITY = "COMPLEXITY";
	var METHOD = "METHOD";
	var CLASS = "CLASS";
}

typedef JacocoLineCounters = {
	var line:Int;
	var missedExpr:Int;
	var coveredExpr:Int;
	var missedBranches:Int;
	var coveredBranches:Int;
}
