package instrument.profiler.reporter.data;

typedef CPUProfile = {
	var nodes:Array<CPUProfileNode>;
	var startTime:Float;
	var endTime:Float;
	@:optional var samples:Array<Int>;
	@:optional var timeDeltas:Array<Int>;
}

typedef CPUProfileNode = {
	var id:Int;
	var callFrame:CPUCallFrame;
	@:optional var hitCount:Int;
	@:optional var children:Array<Int>;
	@:optional var deoptReason:String;
	@:optional var positionTicks:Array<CPUPositionTickInfo>;
}

typedef CPUCallFrame = {
	var functionName:String;
	var scriptId:String;
	var url:String;
	var lineNumber:Int;
	var columnNumber:Int;
}

typedef CPUPositionTickInfo = {
	var line:Int;
	var ticks:Int;
}
