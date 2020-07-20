package instrument.coverage;

class FileInfo {
	public var file:String;
	public var pack:String;

	public var types:Array<TypeInfo>;

	public var typesCovered:Int;
	public var fieldCount:Int;
	public var fieldsCovered:Int;
	public var branchCount:Int;
	public var branchesCovered:Int;
	public var expressionCount:Int;
	public var expressionsCovered:Int;
	public var lineCount:Int;
	public var linesCovered:Int;

	public function new(file:String, pack:String) {
		this.file = file;
		this.pack = pack;

		typesCovered = 0;
		fieldCount = 0;
		fieldsCovered = 0;
		branchCount = 0;
		branchesCovered = 0;
		expressionCount = 0;
		expressionsCovered = 0;
		lineCount = 0;
		linesCovered = 0;
		types = [];
	}

	public function addType(type:TypeInfo) {
		types.push(type);
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

	public function isCovered():Bool {
		return typesCovered > 0;
	}
}
