package instrument;

using haxe.macro.ExprTools;

enum abstract InstrumentationType(Int) {
	var None;
	var Coverage;
	var Profiling;
	var Both;

	public static function remove(level:InstrumentationType, removeLevel:InstrumentationType):InstrumentationType {
		return switch (level) {
			case None:
				None;
			case Coverage:
				switch (removeLevel) {
					case None | Profiling:
						Coverage;
					case Coverage | Both:
						None;
				}
			case Profiling:
				switch (removeLevel) {
					case None | Coverage:
						Profiling;
					case Profiling | Both:
						None;
				}
			case Both:
				switch (removeLevel) {
					case None:
						Both;
					case Coverage:
						Profiling;
					case Profiling:
						Coverage;
					case Both:
						None;
				}
		}
	}

	public static function add(level:InstrumentationType, addLevel:InstrumentationType):InstrumentationType {
		return switch (level) {
			case None:
				addLevel;
			case Coverage:
				switch (addLevel) {
					case None | Coverage:
						Coverage;
					case Profiling | Both:
						Both;
				}
			case Profiling:
				switch (addLevel) {
					case None | Profiling:
						Profiling;
					case Coverage | Both:
						Both;
				}
			case Both:
				Both;
		}
	}
}
