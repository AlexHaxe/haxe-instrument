package demo;

@:ignoreInstrument
class Ignored {
	static function main() {
		trace("Hello Haxe");
	}
}

class FieldsIgnored {
	@:ignoreInstrument
	public function ignoreMe() {
		trace("invisible");
	}

	@:ignoreCoverage
	public function ignoreMeCoverage() {
		trace("invisible to coverage");
	}

	@:ignoreProfiler
	public function ignoreMeProfiler() {
		trace("invisible to profiler");
	}
}
