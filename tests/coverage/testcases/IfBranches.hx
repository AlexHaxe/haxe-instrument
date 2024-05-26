package coverage.testcases;

import coverage.testee.ICoverageTestee;

class IfBranches implements ICoverageTestee {
	public function new() {}

	public function ifBranchTrue() {
		if (true) {
			doNothing();
		}
		doNothing();
	}

	public function ifBranchFalse() {
		if (false) {
			doNothing();
		}
		doNothing();
	}

	public function ifBranchReturn() {
		if (true) {
			doNothing();
			return;
		}
		doNothing();
	}

	public function ifBranchOpBoolTrueFalse() {
		if (true || false) {
			doNothing();
			return;
		}
		doNothing();
	}

	public function ifBranchOpBoolTrueTrue() {
		if (true || true) {
			doNothing();
			return;
		}
		doNothing();
	}

	public function ifBranchOpBoolAll(val1:Bool, val2:Bool) {
		if (val1 || val2) {
			doNothing();
			return;
		}
		doNothing();
	}

	public function opBoolOr(val:Int) {
		if ((val == 1) // first condition
			|| (val == 2) // second condition
			|| (val == 3)) // third condition
		{
			doNothing();
			return;
		}
		doNothing();
	}

	public function ifBranchOpBool1(val1:Bool, val2:Bool) {
		if (val1 || val2) {
			doNothing();
			return;
		}
		doNothing();
	}

	public function ifBranchOpBool2(val1:Bool, val2:Bool) {
		if (val1 || val2) {
			doNothing();
			return;
		}
		doNothing();
	}

	public function ifBranchOpBool3(val1:Bool, val2:Bool) {
		if (val1 || val2) {
			doNothing();
			return;
		}
		doNothing();
	}

	public function ifBranchOpBool4(val1:Bool, val2:Bool) {
		if (val1 || val2) {
			doNothing();
			return;
		}
		doNothing();
	}

	function doNothing() {}

	public function ifBranchOpBoolTrueTrue2() {
		if (true) {
			doNothing();
			return;
		}
	}

	public function run() {
		ifBranchTrue();
		ifBranchFalse();
		ifBranchReturn();
		ifBranchOpBoolTrueFalse();
		ifBranchOpBoolTrueTrue();
		ifBranchOpBoolTrueTrue2();
		ifBranchOpBoolAll(false, false);
		ifBranchOpBoolAll(true, false);
		ifBranchOpBoolAll(false, true);
		ifBranchOpBoolAll(true, true);

		ifBranchOpBool1(true, true);

		ifBranchOpBool2(true, true);
		ifBranchOpBool2(true, false);

		ifBranchOpBool3(true, true);
		ifBranchOpBool3(true, false);
		ifBranchOpBool3(false, true);

		ifBranchOpBool4(true, true);
		ifBranchOpBool4(true, false);
		ifBranchOpBool4(false, true);
		ifBranchOpBool4(false, false);

		opBoolOr(1);
		opBoolOr(3);
		opBoolOr(4);
	}
}
