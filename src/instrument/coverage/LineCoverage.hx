package instrument.coverage;

class LineCoverage {
	public var coveredLines:Array<Int>;
	public var missedLines:Array<Int>;

	public function new() {
		coveredLines = [];
		missedLines = [];
	}

	public function addlines(start:Int, end:Int, covered:Bool) {
		for (i in start...end + 1) {
			if (!covered) {
				coveredLines.remove(i);
				if (!missedLines.contains(i)) {
					missedLines.push(i);
				}
				continue;
			}
			if (missedLines.contains(i)) {
				missedLines.remove(i);
			}
			if (coveredLines.contains(i)) {
				continue;
			}
			coveredLines.push(i);
		}
		coveredLines.sort((a, b) -> (a < b) ? -1 : 1);
		missedLines.sort((a, b) -> (a < b) ? -1 : 1);
	}

	public function lineCount():Int {
		return coveredLines.length + missedLines.length;
	}
}
