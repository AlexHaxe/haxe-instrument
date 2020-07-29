package instrument.coverage;

import haxe.Json;
import instrument.coverage.TypeInfo.TypeInfoStruct;

@:ignoreCoverage
class CoverageContext {
	static var lock:Null<Mutex> = null;
	static var id:Int = 0;

	public static var covered:Null<Map<Int, Int>> = null;

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

	public static function contextFromJson():CoverageContext {
		var context:CoverageContext = new CoverageContext();
		var jsonTypes:Array<TypeInfoStruct> = Json.parse(haxe.Resource.getString(Coverage.RESOURCE_NAME));
		for (type in jsonTypes) {
			context.addType(TypeInfo.fromJson(type));
		}
		return context;
	}

	public static function logExpression(logId:Int) {
		if (lock == null) {
			lock = new Mutex();
		}
		if (covered == null) {
			covered = new Map<Int, Int>();
		}
		lock.sure().acquire();
		#if debug_log_expression
		trace("logExpression(" + logId + ")");
		#end
		if (covered.sure().exists(logId)) {
			covered.sure().set(logId, covered.sure().get(logId).sure() + 1);
		} else {
			covered.sure().set(logId, 1);
		}
		lock.sure().release();
	}

	public function calcStatistic() {
		function getCoverage(id:Int):Int {
			if (CoverageContext.covered.sure().exists(id)) {
				return CoverageContext.covered.sure().get(id).sure();
			}
			return 0;
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
			type.calcStatistic(getCoverage);
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
