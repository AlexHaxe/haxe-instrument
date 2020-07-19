package instrument.profiler.summary;

typedef ThreadSummaryContext = {
	var threadId:Int;
	var itsMe:Bool;
	var flatSummary:FlatSummary;
	var hierarchicalSummary:HierarchicalSummary;
}
