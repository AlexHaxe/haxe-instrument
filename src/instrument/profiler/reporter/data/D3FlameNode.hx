package instrument.profiler.reporter.data;

typedef D3FlameNode = {
	var name:String;
	var value:Int;
	@:optional var children:Array<D3FlameNode>;
}
