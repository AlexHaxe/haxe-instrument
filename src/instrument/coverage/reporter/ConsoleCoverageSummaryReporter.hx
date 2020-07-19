package instrument.coverage.reporter;

class ConsoleCoverageSummaryReporter implements ICoverageReporter {
	public function new() {}

	public function generateReport(context:CoverageContext) {
		output("".rpad("=", 37));
		output("Coverage summary");
		output("".rpad("=", 37));
		output('packages     ${results(context.packagesCovered, context.packages.length)}');
		output('types        ${results(context.typesCovered, context.types.length)}');
		output('fields       ${results(context.fieldsCovered, context.fieldCount)}');
		output('branches     ${results(context.branchesCovered, context.branchCount)}');
		output('expressions  ${results(context.expressionsCovered, context.expressionCount)}');
		output('files        ${results(context.filesCovered, context.files.length)}');
		output('lines        ${results(context.linesCovered, context.lineCount)}');
		output("".rpad("=", 37));
		var totalCoverage:Float = Math.floor((context.fieldsCovered + context.branchesCovered + context.expressionsCovered) * 10000 / (context.fieldCount
			+ context.branchCount + context.expressionCount)) / 100;
		output("Overall:     " + '$totalCoverage% '.lpad(" ", 24));
		output("".rpad("=", 37));
	}

	function results(covered:Int, count:Int):String {
		var percent:Float = if (count <= 0) {
			0;
		} else {
			Math.floor(covered * 10000 / count) / 100;
		}
		return '$covered/$count'.lpad(" ", 15) + ' ($percent%)'.lpad(" ", 9);
	}

	function output(text:String) {
		#if (sys || nodejs)
		Sys.println(text);
		#elseif js
		js.Browser.console.log(text);
		#else
		trace(text);
		#end
	}
}
