package coverage.testcases;

import coverage.testee.ICoverageTestee;

class WhileBranches implements ICoverageTestee {
	public function new() {}

	public function whileLoopTrue() {
		while (true) {
			doNothing();
			return;
		}
		doNothing();
	}

	public function whileLoopFalse() {
		while (false) {
			doNothing();
			return;
		}
		doNothing();
	}

	public function whileLoopCount() {
		var i:Int = 0;
		while (i++ < 10) {
			if (i < 5) {
				doNothing();
			}
			doNothing();
			if (i > 10) {
				doNothing();
			}
			doNothing();
		}
		doNothing();
	}

	public function whileLoopCount2() {
		var i:Int = 0;
		while (i++ < 10) {
			if (i > 10) {
				continue;
			}
			if (i > 0) {
				doNothing();
			}
			doNothing();
		}
		doNothing();
	}

	function doNothing() {}

	public function run() {
		whileLoopTrue();
		whileLoopFalse();
		whileLoopCount();
		whileLoopCount2();
	}
}
