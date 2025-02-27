package demo;

import haxe.Exception;
import demo.flixel.FlxColor;
import demo.flixel.FlxPathfinder.FlxTypedPathfinder;
import demo.flixel.FlxPoint;
#if (haxe >= version("4.2.0"))
import demo.OpOverload.testOp;
#end

class MyTestApp {
	var arrow = (a) -> a + 1;

	public function new(val:Int, b:Bool) {
		trace("hello app");
		noBody();
		trace('${noBody2(val)}');
		noBody3(true);
		noBody3(false);
		noBody5(11);
		#if (haxe >= version("4.2.0"))
		moduleBody();
		moduleBody();
		moduleBody();
		moduleBody();
		moduleBody();
		#end
		var image:ImageName = "test";

		trace(arrow(val));
		noBody4(function(val) {
			noBody5(11);
			return '${noBody2(val)}';
		});
		initTranslations();
		noCover();
		getInt(null);
		getInt("100");
		whileLoop();
		var sortCols = ["xxx"];

		var role:Role = RoleAdmin;

		switch (role) {
			case RoleAdmin:
				trace("admin");
			case RoleEditor:
				trace("editor");
			case RoleSales:
				trace("sales");
			case RoleCustomer:
				trace("customer");
		}

		var orderBy:String = sortCols.map(function(value:String):String {
			return value;
		}).join(", ");
		trace(orderBy);
		sortColsFunc(sortCols);
		switchVal(1);
		switchVal(2);
		opBoolOr(1);
		opBoolOr(2);
		opBoolOr(4);
		tryMissedCatch();
		tryCatched();

		if (false)
			Sys.exit(0);

		#if (haxe >= version("4.2.0"))
		testOp(true, false);
		#end

		flx();
	}

	function flx() {
		var pathfinder = new FlxTypedPathfinder();
		pathfinder.findPath(null, new FlxBasePoint(), new FlxBasePoint());
		try {
			pathfinder.int("");
		} catch (e:Exception) {}

		var color:FlxColor = 0xff0000;
		color.red += 100;
		color.redFloat += 1.6;
	}

	public function switchVal(val:Int) {
		switch (val) {
			case 0:
				trace("000");
			case 1:
				trace("111");
			case 2:
				trace("222");
			default:
				trace("???");
		}
		return (true == false);
	}

	public function opBoolOr(val:Int) {
		if ((val == 1) // first condition
			|| (val == 2) // second condition
			|| (val == 3)) // third condition
		{
			trace(true);
			return;
		}
		trace(false);
	}

	public static inline function sortColsFunc(sortCols):String {
		var orderBy:String = sortCols.map(function(value:String):String {
			return value;
		}).join(", ");
		return orderBy;
	}

	public static function initTranslations():Void {
		var count = 0;
		while (count++ < 10) {
			if (count < 5) {
				continue;
			}
		}
		count = 11;
	}

	function noBody()
		trace("nobody");

	inline function noBody3(val:Bool) {
		if (val) {
			#if (haxe >= version("4.2.0"))
			moduleBody();
			moduleBody();
			#end
			return;
		}
		trace("nobody");
	}

	function noBody2(val:Int):Int
		return val * 2;

	inline function noBody5(val:Int)
		return val * 2;

	function noBody4(cb:(val:Int) -> String) {
		trace(cb(1));
		trace(cb(2));
	}

	public function getInt(field:Null<String>):Null<Int> {
		var value:Null<Int> = 10;
		if (field == null) {
			return null;
		}
		return value;
	}

	public function noCover() {
		if (true) {
			return;
		}
		trace("unreachable");
	}

	public function whileLoop():Null<Int> {
		while (true) {
			return null;
		}
	}

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

	static function main() {
		new MyTestApp(123, true);
		ArrayTest.main();
		NullSafety.main();
	}
}

#if (haxe >= version("4.2.0"))
function moduleBody()
	trace("module level no body block");

function download():String
	return "download";
#end

enum abstract Role(String) to String {
	public var RoleAdmin = "admin";
	public var RoleEditor = "editor";
	public var RoleSales = "sales";
	public var RoleCustomer = "customer";
}

abstract Distance(Int) from Int {
	@:op(A += B)
	public inline function assignPlus(val:Int):Distance {
		this = this + val * 100;
		return this;
	}
}

#if (haxe >= version("4.2.0"))
function testMe(a:Int, b:String):String {
	return switch [a, b] {
		case [_, "a"]: "A";
		case [1, _]: "B";
		case _: "C";
	}
}
#end
