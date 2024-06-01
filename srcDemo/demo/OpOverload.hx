package demo;

#if (haxe >= version("4.2.0"))
function testOp(a:OpOverload, b:OpOverload):Int {
	return a && b;
}
#end

abstract OpOverload(Bool) from Bool {
	@:op(a && b) static function and(a, b) {
		return a == true ? 1 : 2;
	}
}
