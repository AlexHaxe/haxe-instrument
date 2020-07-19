package instrument.coverage;

class TypeInfo {
	public var id:Int;
	public var pack:String;
	public var name:String;
	public var location:String;
	public var file:String;
	public var startLine:Int;
	public var endLine:Int;

	public var fields:Array<FieldInfo>;

	public var fieldsCovered:Int;
	public var branchCount:Int;
	public var branchesCovered:Int;
	public var expressionCount:Int;
	public var expressionsCovered:Int;
	public var lineCount:Int;
	public var linesCovered:Int;

	public function new(id:Int, pack:String, name:String, location:String, file:String, startLine:Int, endLine:Int) {
		this.id = id;
		this.pack = pack;
		this.name = name;
		this.location = location;
		this.file = file;
		this.startLine = startLine;
		this.endLine = endLine;

		fields = [];
	}

	public function addField(field:FieldInfo) {
		fields.push(field);
	}

	public function calcStatistic(cb:GetCoverageCount) {
		fieldsCovered = 0;
		branchCount = 0;
		branchesCovered = 0;
		expressionCount = 0;
		expressionsCovered = 0;
		lineCount = 0;
		linesCovered = 0;

		for (field in fields) {
			field.calcStatistic(cb);
			if (field.isCovered()) {
				fieldsCovered++;
			}
			branchCount += field.branchCount;
			branchesCovered += field.branchesCovered;
			expressionCount += field.expressions.length;
			expressionsCovered += field.expressionsCovered;
			lineCount += field.lineCount;
			linesCovered += field.linesCovered;
		}
	}

	public function isCovered():Bool {
		return (fields.length > 0) && (fieldsCovered > 0);
	}

	public static function fromJson(ob:TypeInfoStruct):TypeInfo {
		var type:TypeInfo = new TypeInfo(ob.id, ob.pack, ob.name, ob.location, ob.file, ob.startLine, ob.endLine);
		for (field in ob.fields) {
			type.fields.push(FieldInfo.fromJson(field));
		}
		return type;
	}
}

typedef TypeInfoStruct = {
	id:Int,
	pack:String,
	name:String,
	location:String,
	file:String,
	startLine:Int,
	endLine:Int,
	fields:Array<FieldInfoStruct>
}

typedef FieldInfoStruct = {
	id:Int,
	name:String,
	location:String,
	startLine:Int,
	endLine:Int,
	expressions:Array<ExpressionInfoStruct>,
	branches:Array<BranchesInfoStruct>
}

typedef ExpressionInfoStruct = {
	id:Int,
	location:String,
	startLine:Int,
	endLine:Int
}

typedef BranchesInfoStruct = {
	id:Int,
	location:String,
	startLine:Int,
	endLine:Int,
	branches:Array<BranchInfoStruct>
}

typedef BranchInfoStruct = {
	id:Int,
	location:String,
	startLine:Int,
	endLine:Int
}
