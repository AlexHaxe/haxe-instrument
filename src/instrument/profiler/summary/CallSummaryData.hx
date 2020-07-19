package instrument.profiler.summary;

typedef CallSummaryData = {
	var threadId:Int;
	var location:String;
	var className:String;
	var functionName:String;
	var count:Int;
	var duration:Float;
}
