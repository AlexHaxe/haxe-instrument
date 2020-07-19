package instrument.coverage.reporter;

import haxe.io.Path;
import haxe.macro.Compiler;
#if (sys || nodejs)
import sys.FileSystem;
#end

class EMMACoverageReporter implements ICoverageReporter {
	public function new() {}

	public function generateReport(context:CoverageContext) {
		var root:Xml = Xml.createElement("report");
		root.addChild(buildGlobalStats(context));
		var data:Xml = Xml.createElement("data");
		root.addChild(data);
		var allClasses:Xml = Xml.createElement("all");
		allClasses.set("name", "all types");
		data.addChild(allClasses);
		allClasses.addChild(buildCoverageLine(CLASS, context.types.length, context.typesCovered));
		allClasses.addChild(buildCoverageLine(METHOD, context.fieldCount, context.fieldsCovered));
		allClasses.addChild(buildCoverageLine(BLOCK, context.branchCount, context.branchesCovered));
		allClasses.addChild(buildCoverageLine(LINE, context.lineCount, context.linesCovered));

		for (pack in context.packages) {
			allClasses.addChild(buildPackageCoverage(pack));
		}

		output(root.toString());
	}

	function buildPackageCoverage(pack:PackageInfo):Xml {
		var packXml:Xml = Xml.createElement("package");
		packXml.set("name", pack.pack);
		packXml.addChild(buildCoverageLine(CLASS, pack.types.length, pack.typesCovered));
		packXml.addChild(buildCoverageLine(METHOD, pack.fieldCount, pack.fieldsCovered));
		packXml.addChild(buildCoverageLine(BLOCK, pack.branchCount, pack.branchesCovered));
		packXml.addChild(buildCoverageLine(LINE, pack.lineCount, pack.linesCovered));
		var files:Array<FileInfo> = findFilesOfPackage(pack);
		for (file in files) {
			packXml.addChild(buildFileCoverage(file));
		}
		return packXml;
	}

	function buildFileCoverage(file:FileInfo):Xml {
		var fileXml:Xml = Xml.createElement("srcfile");
		fileXml.set("name", file.file);
		fileXml.addChild(buildCoverageLine(CLASS, file.types.length, file.typesCovered));
		fileXml.addChild(buildCoverageLine(METHOD, file.fieldCount, file.fieldsCovered));
		fileXml.addChild(buildCoverageLine(BLOCK, file.branchCount, file.branchesCovered));
		fileXml.addChild(buildCoverageLine(LINE, file.lineCount, file.linesCovered));
		for (type in file.types) {
			fileXml.addChild(buildTypeCoverage(type));
		}
		return fileXml;
	}

	function buildTypeCoverage(type:TypeInfo):Xml {
		var typeXml:Xml = Xml.createElement("class");
		typeXml.set("name", type.name);
		typeXml.addChild(buildCoverageLine(CLASS, 1, type.isCovered() ? 1 : 0));
		typeXml.addChild(buildCoverageLine(METHOD, type.fields.length, type.fieldsCovered));
		typeXml.addChild(buildCoverageLine(BLOCK, type.branchCount, type.branchesCovered));
		typeXml.addChild(buildCoverageLine(LINE, type.lineCount, type.linesCovered));
		for (field in type.fields) {
			typeXml.addChild(buildFieldCoverage(field));
		}
		return typeXml;
	}

	function buildFieldCoverage(field:FieldInfo):Xml {
		var fieldXml:Xml = Xml.createElement("method");
		fieldXml.set("name", field.name);
		fieldXml.addChild(buildCoverageLine(METHOD, 1, field.isCovered() ? 1 : 0));
		fieldXml.addChild(buildCoverageLine(BLOCK, field.branches.length, field.branchesCovered));
		fieldXml.addChild(buildCoverageLine(LINE, field.lineCount, field.linesCovered));
		return fieldXml;
	}

	function findFilesOfPackage(pack:PackageInfo):Array<FileInfo> {
		var fileMap:Map<String, FileInfo> = new Map<String, FileInfo>();
		for (type in pack.types) {
			var fileInfo:FileInfo;
			if (fileMap.exists(type.file)) {
				fileInfo = fileMap.get(type.file);
			} else {
				fileInfo = new FileInfo(type.file);
				fileMap.set(type.file, fileInfo);
			}
			fileInfo.addType(type);
		}
		return [for (_ => fileInfo in fileMap) fileInfo];
	}

	function buildCoverageLine(type:EMMACoverageType, count:Int, covered:Int):Xml {
		var coverageValue:String = '${Math.floor(covered * 10000 / count) / 100}% ($covered/$count)';
		var coverage:Xml = Xml.createElement("coverage");
		coverage.set("type", type);
		coverage.set("value", coverageValue);
		return coverage;
	}

	function buildGlobalStats(context:CoverageContext):Xml {
		var stats:Xml = Xml.createElement("stats");
		stats.addChild(makeGlobalStat("packages", context.packages.length));
		stats.addChild(makeGlobalStat("classes", context.types.length));
		stats.addChild(makeGlobalStat("methods", context.fieldCount));
		stats.addChild(makeGlobalStat("srcfiles", context.files.length));
		stats.addChild(makeGlobalStat("srclines", context.lineCount));
		return stats;
	}

	function makeGlobalStat(name:String, count:Int):Xml {
		var stat:Xml = Xml.createElement(name);
		stat.set("value", '$count');
		return stat;
	}

	function output(text:String) {
		#if (sys || nodejs)
		sys.io.File.saveContent(getEmmaFileName(), text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
	}

	#if (sys || nodejs)
	public static function getEmmaFileName():String {
		var fileName:String = Compiler.getDefine("coverage-emma-file");
		if ((fileName == null) || (fileName.length <= 0) || (fileName == "1")) {
			fileName = "coverage.xml";
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

enum abstract EMMACoverageType(String) to String {
	var CLASS = "class, %";
	var METHOD = "method, %";
	var BLOCK = "block, %";
	var LINE = "line, %";
}
