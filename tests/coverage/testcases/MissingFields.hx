package coverage.testcases;

import coverage.testee.ICoverageTestee;

class MissingFields implements ICoverageTestee {
	var var1:Int;
	var var2:Int = 10;
	var var3 = (t) -> t * t;

	public function new() {}

	function doNothing() {}

	static function doNothing2() {}

	public inline function doNothing3() {}

	public function run() {}
}
