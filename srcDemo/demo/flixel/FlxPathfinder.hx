package demo.flixel;

class FlxTypedPathfinder<Tilemap> {
	public var spacing:Any = {};

	public function new() {}

	public function findPath(map:Tilemap, start:FlxPoint, end:FlxPoint):Null<Array<FlxPoint>> {
		var data = new Map<String, String>();

		var path = findPathIndicesHelper(data);

		path[0].copyFrom(start);
		path[path.length - 1].copyFrom(end);

		path = simplifyPath(data, path);

		return path;
	}

	public static function tween(Options:TweenOptions) {}

	inline function intHelper(name:String, invalid:(String) -> Void, backup:Int):Int {
		invalid("test");

		function complete() {}

		tween({onComplete: (_) -> complete()});

		return backup;
	}

	public function int(name:String) {
		return intHelper(name, (msg) -> throw msg, 0);
	}

	function findPathIndicesHelper(data:Any):Array<FlxPoint> {
		return [];
	}

	function simplifyPath(data:Any, points:Array<FlxPoint>):Array<FlxPoint> {
		return points;
	}
}

typedef TweenOptions = {
	@:optional var onComplete:TweenCallback;
}

typedef TweenCallback = FlxPoint->Void;
