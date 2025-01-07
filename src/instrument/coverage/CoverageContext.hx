package instrument.coverage;

import haxe.Json;
import instrument.coverage.TypeInfo.TypeInfoStruct;

@:ignoreCoverage
class CoverageContext {
	static var lock:Null<Mutex> = null;
	static var id:Int = 0;

	public static var covered:Null<Map<Int, Int>> = null;
	public static var coveredAttributable:Null<Map<Int, Int>> = null;

	public var types:Array<TypeInfo>;
	public var files:Array<FileInfo>;
	public var packages:Array<PackageInfo>;

	public var filesCovered:Int;
	public var packagesCovered:Int;
	public var typesCovered:Int;
	public var fieldCount:Int;
	public var fieldsCovered:Int;
	public var branchCount:Int;
	public var branchesCovered:Int;
	public var expressionCount:Int;
	public var expressionsCovered:Int;
	public var lineCount:Int;
	public var linesCovered:Int;

	public function new() {
		types = [];
		files = [];
		packages = [];
		filesCovered = 0;
		packagesCovered = 0;
		typesCovered = 0;
		fieldCount = 0;
		fieldsCovered = 0;
		branchCount = 0;
		branchesCovered = 0;
		expressionCount = 0;
		expressionsCovered = 0;
		lineCount = 0;
		linesCovered = 0;
	}

	public function addType(type:TypeInfo) {
		types.push(type);
	}

	public function nextId():Int {
		return id++;
	}

	#if macro
	public function findFileInfo(fileName:String):FileInfo {
		for (file in files) {
			if (fileName == file.file) {
				return file;
			}
		}
		var file = new FileInfo(fileName, fileName);
		files.push(file);
		return file;
	}

	public function findTypeInfo(fileName:String, startLine:Int, endLine:Int):TypeInfo {
		var fileInfo = findFileInfo(fileName);
		for (type in fileInfo.types) {
			if (type.location.startsWith(fileName)) {
				return type;
			}
		}
		var newType = new TypeInfo(nextId(), fileName, "SomeMacro", fileName + ":" + startLine, fileName, startLine, endLine);
		fileInfo.addType(newType);
		addType(newType);
		return newType;
	}

	public function findFieldInfo(fileName:String, startLine:Int, endLine:Int):FieldInfo {
		var typeInfo:Null<TypeInfo> = findTypeInfo(fileName, startLine, endLine);
		for (field in typeInfo.fields) {
			if (field.startLine <= startLine && field.endLine >= endLine) {
				return field;
			}
		}

		var newField = new FieldInfo(nextId(), fileName, fileName + ":" + startLine, startLine, endLine);
		typeInfo.addField(newField);
		return newField;
	}
	#end

	public static function contextFromJson():CoverageContext {
		var context:CoverageContext = new CoverageContext();
		var typesResource = haxe.Resource.getString(Coverage.RESOURCE_NAME);
		if (typesResource == null) {
			return context;
		}
		var jsonTypes:Array<TypeInfoStruct> = Json.parse(typesResource);
		for (type in jsonTypes) {
			context.addType(TypeInfo.fromJson(type));
		}
		return context;
	}

	public static function logBranch(logId:Int) {
		logExpression(logId);
	}

	public static function logExpression(logId:Int) {
		if (lock == null) {
			lock = new Mutex();
		}
		if (covered == null) {
			covered = new Map<Int, Int>();
		}
		if (coveredAttributable == null) {
			coveredAttributable = new Map<Int, Int>();
		}
		lock.sure().acquire();
		#if debug_log_expression
		Sys.println(findLogId(logId));
		#end
		if (covered.sure().exists(logId)) {
			covered.sure().set(logId, covered.sure().get(logId).sure() + 1);
		} else {
			covered.sure().set(logId, 1);
		}
		if (coveredAttributable.sure().exists(logId)) {
			coveredAttributable.sure().set(logId, coveredAttributable.sure().get(logId).sure() + 1);
		} else {
			coveredAttributable.sure().set(logId, 1);
		}
		lock.sure().release();
	}

	#if debug_log_expression
	static function findLogId(logId:Int) {
		static var context:CoverageContext = contextFromJson();

		for (type in context.types) {
			if (type.id == logId) {
				return '${type.location} [$logId - Type]';
			}
			for (field in type.fields) {
				if (field.id == logId) {
					return '${field.location} [$logId - Field]';
				}
				for (expr in field.expressions) {
					if (expr.id == logId) {
						return '${expr.location} ${expr.startLine}-${expr.endLine} [$logId - Expression]';
					}
				}
				for (branch in field.branches) {
					if (branch.id == logId) {
						return '${branch.location} ${branch.startLine}-${branch.endLine} [$logId - Branch]';
					}
					for (singleBranch in branch.branches) {
						if (singleBranch.id == logId) {
							return '${singleBranch.location} ${singleBranch.startLine}-${singleBranch.endLine} [$logId - Branch]';
						}
					}
				}
			}
		}
		return '[$logId - Unknown]';
	}
	#end

	public function calcStatistic(coveredData:Null<Map<Int, Int>>) {
		var coverageCallback = (id:Int) -> 0;

		if (coveredData != null) {
			final coveredIds:Map<Int, Int> = coveredData.sure();
			coverageCallback = function getCoverage(id:Int):Int {
				if (coveredIds.exists(id)) {
					return coveredIds.get(id).sure();
				}
				return 0;
			}
		}

		filesCovered = 0;
		packagesCovered = 0;
		typesCovered = 0;
		fieldCount = 0;
		fieldsCovered = 0;
		branchCount = 0;
		branchesCovered = 0;
		expressionCount = 0;
		expressionsCovered = 0;
		lineCount = 0;
		linesCovered = 0;

		for (type in types) {
			type.calcStatistic(coverageCallback);
			if (type.isCovered()) {
				typesCovered++;
			}

			fieldCount += type.fields.length;
			fieldsCovered += type.fieldsCovered;
			branchCount += type.branchCount;
			branchesCovered += type.branchesCovered;
			expressionCount += type.expressionCount;
			expressionsCovered += type.expressionsCovered;
			lineCount += type.lineCount;
			linesCovered += type.linesCovered;
		}
		calcFileStatistic();
		calcPackageStatistic(files);
	}

	function calcFileStatistic() {
		filesCovered = 0;
		var fileMap:Map<String, FileInfo> = new Map<String, FileInfo>();
		for (type in types) {
			var fileInfo:FileInfo;
			if (fileMap.exists(type.file)) {
				fileInfo = fileMap.get(type.file).sure();
			} else {
				fileInfo = new FileInfo(type.file, type.pack);
				fileMap.set(type.file, fileInfo);
			}
			fileInfo.addType(type);
		}
		files = [];
		for (_ => fileInfo in fileMap) {
			files.push(fileInfo);
			if (fileInfo.isCovered()) {
				filesCovered++;
			}
		}
	}

	function calcPackageStatistic(allFiles:Array<FileInfo>) {
		packagesCovered = 0;
		var packageMap:Map<String, PackageInfo> = new Map<String, PackageInfo>();
		for (type in types) {
			var packInfo:PackageInfo;
			if (packageMap.exists(type.pack)) {
				packInfo = packageMap.get(type.pack).sure();
			} else {
				packInfo = new PackageInfo(type.pack, allFiles);
				packageMap.set(type.pack, packInfo);
			}
			packInfo.addType(type);
		}
		packages = [];
		for (_ => packInfo in packageMap) {
			packages.push(packInfo);
			if (packInfo.isCovered()) {
				packagesCovered++;
			}
		}
	}

	public function sort() {
		types.sort(sortTypeInfo);
		for (type in types) {
			sortFields(type);
		}
	}

	public function sortFields(type:TypeInfo) {
		type.fields.sort(sortFieldInfo);
		for (field in type.fields) {
			sortExpressions(field);
			sortBranches(field);
		}
	}

	public function sortExpressions(field:FieldInfo) {
		field.expressions.sort(sortExpressionInfo);
	}

	public function sortBranches(field:FieldInfo) {
		field.branches.sort(sortBranchesInfo);
		for (branches in field.branches) {
			sortBranchs(branches);
		}
	}

	public function sortBranchs(branches:BranchesInfo) {
		branches.branches.sort(sortBranchInfo);
	}

	function sortTypeInfo(a:TypeInfo, b:TypeInfo):Int {
		if (a.file < b.file) {
			return -1;
		}
		if (a.file > b.file) {
			return 1;
		}
		if (a.name < b.name) {
			return -1;
		}
		if (a.name > b.name) {
			return 1;
		}
		return 0;
	}

	function sortFieldInfo(a:FieldInfo, b:FieldInfo):Int {
		if (a.name < b.name) {
			return -1;
		}
		if (a.name > b.name) {
			return 1;
		}
		return 0;
	}

	function sortExpressionInfo(a:ExpressionInfo, b:ExpressionInfo):Int {
		if (a.startLine < b.startLine) {
			return -1;
		}
		if (a.startLine > b.startLine) {
			return 1;
		}
		return 0;
	}

	function sortBranchesInfo(a:BranchesInfo, b:BranchesInfo):Int {
		if (a.location < b.location) {
			return -1;
		}
		if (a.location > b.location) {
			return 1;
		}
		return 0;
	}

	function sortBranchInfo(a:BranchInfo, b:BranchInfo):Int {
		if (a.location < b.location) {
			return -1;
		}
		if (a.location > b.location) {
			return 1;
		}
		return 0;
	}
}
