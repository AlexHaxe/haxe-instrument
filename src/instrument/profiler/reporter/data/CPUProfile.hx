package instrument.profiler.reporter.data;

typedef CPUProfileOne = {
	var head:CPUProfileHeadOne;
	var uid:Int;
	var title:String;
	var typeId:String;
	var startTime:Float;
	var endTime:Float;
	var samples:Array<Int>;
	var timeDeltas:Array<Float>;
}

typedef CPUProfileHeadOne = {
	var functionName:String;
	var url:String;
	var lineNumber:Int;
	var bailoutReason:String;
	var id:Int;
	var scriptId:Int;
	var hitCount:Int;
	var children:Array<CPUProfileNodeOne>;
}

typedef CPUProfileNodeOne = {
	var functionName:String;
	var url:String;
	var lineNumber:Int;
	var bailoutReason:String;
	var id:Int;
	var scriptId:Int;
	var hitCount:Int;
	var children:Array<CPUProfileNodeOne>;
	var _stackFrame:String;
}

typedef CPUProfileTwo = {
	var nodes:Array<CPUProfileNodeTwo>;
	var startTime:Float;
	var endTime:Float;
	var samples:Array<Int>;
	var timeDeltas:Array<Int>;
}

typedef CPUProfileNodeTwo = {
	var id:Int;
	var callFrame:CPUCallFrameTwo;
	@:optional var parent:Int;
	@:optional var hitCount:Int;
	@:optional var children:Array<Int>;
	@:optional var deoptReason:String;
	@:optional var positionTicks:Array<CPUPositionTickInfoTwo>;
}

typedef CPUCallFrameTwo = {
	var functionName:String;
	var scriptId:String;
	var url:String;
	var lineNumber:Int;
	var columnNumber:Int;
}

typedef CPUPositionTickInfoTwo = {
	var line:Int;
	var ticks:Int;
}

typedef CPUDeltaSample = {
	var id:Int;
	var sampleTime:Float;
}
