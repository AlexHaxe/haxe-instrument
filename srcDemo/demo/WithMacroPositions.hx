package demo;

import demo.macro.BuildMacro.IBuildMacro;

class WithMacroPositions implements IBuildMacro {
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

	static function main() {
		new WithMacroPositions().run();
	}
}
