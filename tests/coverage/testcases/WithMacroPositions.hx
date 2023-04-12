package coverage.testcases;

import coverage.testcases.macro.BuildMacro.IBuildMacro;
import coverage.testee.ICoverageTestee;

class WithMacroPositions implements ICoverageTestee implements IBuildMacro {
	public function new() {}

	public function withoutMacro() {
		doNothing();
	}

	public function appendMacroCode() {
		doNothing();
	}

	function doNothing() {}

	public function run() {
		macroFieldCovered();
		withoutMacro();
	}
}
