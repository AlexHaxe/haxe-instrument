package coverage.testcases;

import haxe.Exception;
import coverage.testee.ICoverageTestee;

class TryCatch implements ICoverageTestee {
	public function new() {}

	public function tryMissedCatch() {
		try {
			doNothing();
		} catch (e:Exception) {
			doNothing();
		}
	}

	public function tryCatched() {
		try {
			doNothing();
			throwSomething();
			doNothing();
		} catch (e:Exception) {
			doNothing();
		}
	}

	function throwSomething() {
		throw "something";
	}

	function doNothing() {}

	public function tryCatched2() {
		try {
			doNothing();
			throwSomething();
			doNothing();
		} catch (e:String) {
			doNothing();
		} catch (e:Exception) {
			doNothing();
		}
	}

	public function tryCatched3() {
		try {
			doNothing();
			throwSomething();
			doNothing();
		} catch (e:String) {
			// doNothing();
		} catch (e:Exception) {
			// doNothing();
		}
	}

	public function tryCatched4() {
		try {
			doNothing();
			doNothing();
		} catch (e:String) {
			// doNothing();
		} catch (e:Exception) {
			// doNothing();
		}
	}

	public function run() {
		tryMissedCatch();
		tryCatched();
		tryCatched2();
		tryCatched3();
		tryCatched4();
	}
}
