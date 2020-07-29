package instrument.coverage;

import instrument.coverage.TypeInfo.BranchInfoStruct;

class BranchInfo {
	public var id:Int;
	public var location:String;
	public var startLine:Int;
	public var endLine:Int;

	public var count:Int;

	public function new(id:Int, location:String, startLine:Int, endLine:Int) {
		this.id = id;
		this.location = location;
		this.startLine = startLine;
		this.endLine = endLine;
		count = 0;
	}

	public function calcStatistic(cb:GetCoverageCount) {
		count = cb(id);
	}

	public function isCovered():Bool {
		return count > 0;
	}

	public static function fromJson(ob:BranchInfoStruct):BranchInfo {
		var branch:BranchInfo = new BranchInfo(ob.id, ob.location, ob.startLine, ob.endLine);
		return branch;
	}
}
