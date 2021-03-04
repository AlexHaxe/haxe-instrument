package demo;

function testOp(a:OpOverload, b:OpOverload):Int {
	return a && b;
}

abstract OpOverload(Bool) from Bool {
	@:op(a && b) static function and(a, b) {
		return a == true ? 1 : 2;
	}
}
