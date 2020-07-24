package instrument.dummy;

@:ignoreInstrument
class DummyMutex {
	public function new() {}

	public function acquire() {}

	public function tryAcquire():Bool {
		return true;
	}

	public function release() {}
}
