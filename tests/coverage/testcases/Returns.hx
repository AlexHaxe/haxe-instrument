package coverage.testcases;

import coverage.testee.ICoverageTestee;

class Returns implements ICoverageTestee {
	public function new() {}

	public static function tween(options:Dynamic) {
		if (options.onComplete != null) {
			options.onComplete();
		}
	}

	inline function intHelper(name:String, invalid:(String) -> Void, backup:Int):Int {
		tween({onComplete: (_) -> doNothing()});
		tween({onComplete: (_) -> doSomething()});
		invalid("test");
		return backup;
	}

	public function implicitReturn(name:String) {
		return intHelper(name, (msg) -> throw msg, 0);
	}

	function doSomething() {
		return 1;
	}

	function doNothing() {}

	public function run() {
		try {
			implicitReturn("");
		} catch (e:String) {}
	}
}
