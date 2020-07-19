package instrument.coverage.reporter;

interface ICoverageReporter {
	function generateReport(context:CoverageContext):Void;
}
