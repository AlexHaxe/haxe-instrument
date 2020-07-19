package coverage.testcases;

import coverage.testee.ICoverageTestee;

class SwitchBranches implements ICoverageTestee {
	public function new() {}

	public function switchVal(val:Int) {
		switch (val) {
			case 0:
				doNothing();
			case 1:
				doNothing();
			case 2:
				doNothing();
			default:
				doNothing();
		}
	}

	function doNothing() {}

	public function run() {
		switchVal(1);
		switchVal(2);
	}
}
