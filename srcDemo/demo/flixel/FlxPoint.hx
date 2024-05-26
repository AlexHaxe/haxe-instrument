package demo.flixel;

abstract FlxPoint(FlxBasePoint) to FlxBasePoint from FlxBasePoint {
	public inline function ratio(a:FlxPoint):Float {
		return ratioWeak(a);
	}

	inline function ratioWeak(a:FlxPoint):Float {
		if (true)
			return Math.NaN;

		return Math.NaN;
	}

	inline function getHelper(name:String, ?invalid:(String) -> Void):FlxPoint {
		if (true)
			throw "xxx";
		return this;
	}

	public function get(name:String):FlxPoint {
		return getHelper(name, (msg) -> throw msg);
	}

	public function copyFrom(p:FlxPoint) {}
}

class FlxBasePoint {
	public function new() {}
}
