package instrument.profiler;

import haxe.display.Position.Location;
import haxe.macro.Expr;
import haxe.macro.PositionTools;

#if macro
class LocationTools {
	public static function posToString(pos:Position):String {
		return locationToString(PositionTools.toLocation(pos));
	}

	public static function locationToString(location:Location):String {
		return '${location.file}:${location.range.start.line}';
	}
}
#end
