package demo.flixel;

abstract FlxColor(Int) from Int from UInt to Int to UInt {
	public var red(get, set):Int;

	public var redFloat(get, set):Float;

	public function new(Value:Int = 0) {
		this = Value;
	}

	inline function get_red():Int {
		return this;
	}

	inline function get_redFloat():Float {
		return red;
	}

	inline function set_red(Value:Int):Int {
		this &= 0xff00ffff;
		this |= Value;
		return Value;
	}

	inline function set_redFloat(Value:Float):Float {
		red = Math.round(Value * 255);
		return Value;
	}
}
