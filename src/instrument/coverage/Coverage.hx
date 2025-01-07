package instrument.coverage;

import instrument.coverage.reporter.ICoverageReporter;

class Coverage {
	public static var RESOURCE_NAME:String = "coverageTypeInfo";

	static var context:Null<CoverageContext>;

	static function loadContext():CoverageContext {
		if (context == null) {
			context = CoverageContext.contextFromJson();
		}
		return context.sure();
	}

	/**
	 * reports coverage data using reporters provided by caller
	 *
	 * @param reporters each reporter can access all recorded coverage data
	 */
	public static function endCustomCoverage(reporters:Array<ICoverageReporter>) {
		final ctxt = loadContext();
		ctxt.calcStatistic(CoverageContext.covered);
		for (report in reporters) {
			report.generateReport(ctxt);
		}
	}

	/**
	 * resets attributable coverage data. 
	 * 
	 * use before running a new testcase to zero out coverage counters
	 *
	 */
	public static function resetAttributableCoverage() {
		if (CoverageContext.coveredAttributable != null) {
			CoverageContext.coveredAttributable.clear();
		}
	}

	/**
	 * reports attributable coverage data using reporters provided by caller
	 * 
	 * use in conjunction with `resetAttributableCoverage` to attribute coverage per individual testcase
	 *
	 * @param reporters each reporter can access all recorded coverage data
	 */
	public static function reportAttributableCoverage(reporters:Array<ICoverageReporter>) {
		final ctxt = loadContext();
		ctxt.calcStatistic(CoverageContext.coveredAttributable);
		for (report in reporters) {
			report.generateReport(ctxt);
		}
	}

	/**
	 * reports coverage through reporters defined with `-D` compile options
	 * used by internal `instrument.Instrumentation.endInstrumantation` function
	 */
	public static function endCoverage() {
		#if instrument_coverage
		var reporters:Array<ICoverageReporter> = [];

		#if coverage_console_missing_reporter
		reporters.push(new instrument.coverage.reporter.ConsoleMissingCoverageReporter());
		#end

		#if coverage_console_file_summary_reporter
		reporters.push(new instrument.coverage.reporter.ConsoleCoverageFileSummaryReporter());
		#end

		#if coverage_console_package_summary_reporter
		reporters.push(new instrument.coverage.reporter.ConsoleCoveragePackageSummaryReporter());
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

		#if coverage_jacocoxml_reporter
		reporters.push(new instrument.coverage.reporter.JaCoCoXmlCoverageReporter());
		#end

		endCustomCoverage(reporters);
		#end
	}
}
