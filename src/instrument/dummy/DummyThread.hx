package instrument.dummy;

@:ignoreInstrument
class DummyThread {
	static var INSTANCE:DummyThread = new DummyThread();

	public function new() {}

	public static function current():DummyThread {
		return INSTANCE;
	}
}
