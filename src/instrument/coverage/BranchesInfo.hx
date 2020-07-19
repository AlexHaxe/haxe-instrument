package instrument.coverage;

import instrument.coverage.TypeInfo.BranchesInfoStruct;

class BranchesInfo {
	public var id:Int;
	public var location:String;
	public var startLine:Int;
	public var endLine:Int;

	public var branches:Array<BranchInfo>;

	public var count:Int;
	public var branchCount:Int;
	public var branchesCovered:Int;
	public var lineCount:Int;
	public var linesCovered:Int;

	public function new(id:Int, location:String, startLine:Int, endLine:Int) {
		this.id = id;
		this.location = location;
		this.startLine = startLine;
		this.endLine = endLine;
		branches = [];
	}

	public function addBranch(branch:BranchInfo) {
		branches.push(branch);
	}

	public function calcStatistic(cb:GetCoverageCount) {
		count = 0;
		branchCount = branches.length;
		branchesCovered = 0;
		lineCount = 0;
		linesCovered = 0;
		for (branch in branches) {
			branch.calcStatistic(cb);
			if (branch.isCovered()) {
				branchesCovered++;
			}
			count += branch.count;
		}
		calcLineCoverage();
	}

	function calcLineCoverage() {
		var lineCov:LineCoverage = new LineCoverage();
		for (branch in branches) {
			lineCov.addlines(branch.startLine, branch.endLine, branch.isCovered());
		}
		lineCount = lineCov.lineCount();
		linesCovered = lineCov.coveredLines.length;
	}

	public function isCovered():Bool {
		return (branches.length == branchesCovered);
	}

	public static function fromJson(ob:BranchesInfoStruct):BranchesInfo {
		var branchesInfo:BranchesInfo = new BranchesInfo(ob.id, ob.location, ob.startLine, ob.endLine);
		for (branch in ob.branches) {
			branchesInfo.branches.push(BranchInfo.fromJson(branch));
		}
		return branchesInfo;
	}
}
