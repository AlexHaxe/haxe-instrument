package instrument.coverage;

import instrument.coverage.TypeInfo.FieldInfoStruct;

class FieldInfo {
	public var id:Int;
	public var name:String;
	public var location:String;
	public var startLine:Int;
	public var endLine:Int;

	public var expressions:Array<ExpressionInfo>;
	public var branches:Array<BranchesInfo>;

	public var count:Int;
	public var branchCount:Int;
	public var branchesCovered:Int;
	public var expressionsCovered:Int;
	public var lineCount:Int;
	public var linesCovered:Int;

	public function new(id:Int, name:String, location:String, startLine:Int, endLine:Int) {
		this.id = id;
		this.name = name;
		this.location = location;
		this.startLine = startLine;
		this.endLine = endLine;
		expressions = [];
		branches = [];
		count = 0;
		branchCount = 0;
		branchesCovered = 0;
		expressionsCovered = 0;
		lineCount = 0;
		linesCovered = 0;
	}

	#if macro
	public function addExpression(expression:ExpressionInfo) {
		expressions.push(expression);
	}

	public function addBranches(branchesInfo:BranchesInfo) {
		branches.push(branchesInfo);
	}
	#end

	public function calcStatistic(cb:GetCoverageCount) {
		branchCount = 0;
		branchesCovered = 0;
		expressionsCovered = 0;
		lineCount = 0;
		linesCovered = 0;

		count = cb(id);
		for (branch in branches) {
			branch.calcStatistic(cb);
			branchCount += branch.branchCount;
			branchesCovered += branch.branchesCovered;
		}
		for (expression in expressions) {
			expression.calcStatistic(cb);
			if (expression.isCovered()) {
				expressionsCovered++;
			}
		}
		calcLineCoverage();
	}

	function calcLineCoverage() {
		var lineCov:LineCoverage = new LineCoverage();

		for (expression in expressions) {
			lineCov.addlines(expression.startLine, expression.endLine, expression.isCovered());
		}
		for (branch in branches) {
			for (b in branch.branches) {
				lineCov.addlines(b.startLine, b.endLine, b.isCovered());
			}
		}
		lineCount = lineCov.lineCount();
		linesCovered = lineCov.coveredLines.length;
	}

	public function isCovered():Bool {
		return count > 0;
	}

	public static function fromJson(ob:FieldInfoStruct):FieldInfo {
		var field:FieldInfo = new FieldInfo(ob.id, ob.name, ob.location, ob.startLine, ob.endLine);
		for (e in ob.expressions) {
			field.expressions.push(ExpressionInfo.fromJson(e));
		}
		for (b in ob.branches) {
			field.branches.push(BranchesInfo.fromJson(b));
		}
		return field;
	}
}
