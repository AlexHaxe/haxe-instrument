package coverage.testcases;

import coverage.testee.ICoverageTestee;

@:ignoreCoverage
class IgnoredCoverage implements ICoverageTestee {
	public function new() {}

	public function ifBranchTrue() {
		if (true) {
			doNothing();
		}
		doNothing();
	}

	function doNothing() {}

	public function run() {
		ifBranchTrue();
	}
}
