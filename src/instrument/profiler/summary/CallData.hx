package instrument.profiler.summary;

typedef CallData = {
	var id:Int;
	var threadId:Int;
	var location:String;
	var className:String;
	var functionName:String;
	// var args:Array<String>;
	var startTime:Float;
	var endTime:Float;
}
