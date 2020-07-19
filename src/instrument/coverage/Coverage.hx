package instrument.coverage;

import instrument.coverage.reporter.ICoverageReporter;

class Coverage {
	/**
	 * reports coverage data using reporters provided by caller
	 *
	 * @param reporters each reporter can access all recorded coverage data
	 */
	public static function endCustomCoverage(reporters:Array<ICoverageReporter>) {
		var context:CoverageContext = CoverageContext.contextFromJson();
		context.calcStatistic();
		for (report in reporters) {
			report.generateReport(context);
		}
	}

	/**
	 * reports coverage through reporters defined with `-D` compile options
	 * used by internal `instrument.Instrumentation.endInstrumantation` function
	 */
	public static function endCoverage() {
		var reporters:Array<ICoverageReporter> = [];

		#if coverage_console_missing_reporter
		reporters.push(new instrument.coverage.reporter.ConsoleMissingCoverageReporter());
		#end

		#if coverage_console_file_summary_reporter
		reporters.push(new instrument.coverage.reporter.ConsoleCoverageFileSummaryReporter());
		#end

		#if coverage_console_summary_reporter
		reporters.push(new instrument.coverage.reporter.ConsoleCoverageSummaryReporter());
		#end

		#if coverage_lcov_reporter
		reporters.push(new instrument.coverage.reporter.LcovCoverageReporter());
		#end

		#if coverage_codecov_reporter
		reporters.push(new instrument.coverage.reporter.CodecovCoverageReporter());
		#end

		#if coverage_emma_reporter
		reporters.push(new instrument.coverage.reporter.EMMACoverageReporter());
		#end

		endCustomCoverage(reporters);
	}
}
