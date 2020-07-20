package instrument.coverage.reporter;

class ConsoleCoveragePackageSummaryReporter implements ICoverageReporter {
	final delimiter:String = " | ";

	public function new() {}

	public function generateReport(context:CoverageContext) {
		var lines:Array<PackageSummaryLine> = [];

		for (pack in context.packages) {
			var summary:PackageSummaryLine = {
				pack: pack.pack,
				fileCount: pack.files.length,
				filesCovered: pack.filesCovered,
				typeCount: pack.types.length,
				typesCovered: pack.typesCovered,
				fieldCount: pack.fieldCount,
				fieldsCovered: pack.fieldsCovered,
				branchCount: pack.branchCount,
				branchesCovered: pack.branchesCovered,
				expressionCount: pack.expressionCount,
				expressionsCovered: pack.expressionsCovered,
				lineCount: pack.lineCount,
				linesCovered: pack.linesCovered
			}
			lines.push(summary);
		}

		var packColumn:Int = longestPackageName(lines) + 1;
		var fileColumn:Int = summaryColumnLen(context.files.length, context.filesCovered);
		var typeColumn:Int = summaryColumnLen(context.types.length, context.typesCovered);
		var fieldColumn:Int = summaryColumnLen(context.fieldCount, context.fieldsCovered);
		var branchColumn:Int = summaryColumnLen(context.branchCount, context.branchesCovered);
		var expressionColumn:Int = summaryColumnLen(context.expressionCount, context.expressionsCovered);
		var lineColumn:Int = summaryColumnLen(context.lineCount, context.linesCovered);
		var overallColumn:Int = 7;
		var totalWidth:Int = packColumn
			+ fileColumn
			+ typeColumn
			+ fieldColumn
			+ branchColumn
			+ expressionColumn
			+ lineColumn
			+ overallColumn
			+ 7 * 3;

		output("");
		output("".rpad("=", totalWidth));
		var line:String = '${"".lpad(" ", packColumn)}' + delimiter + '${"Files".rpad(" ", fileColumn)}' + delimiter + '${"Types".rpad(" ", typeColumn)}'
			+ delimiter + '${"Fields".rpad(" ", fieldColumn)}' + delimiter + '${"Branches".rpad(" ", branchColumn)}' + delimiter
			+ '${"Expression".rpad(" ", expressionColumn)}' + delimiter + '${"Lines".rpad(" ", lineColumn)}' + delimiter
			+ '${"Overall".rpad(" ", overallColumn)}';
		output(line);
		line = '${"Package".rpad(" ", packColumn)}' + delimiter + '${"Rate".rpad(" ", fileColumn - 3)}Num' + delimiter
			+ '${"Rate".rpad(" ", typeColumn - 3)}Num' + delimiter + '${"Rate".rpad(" ", fieldColumn - 3)}Num' + delimiter
			+ '${"Rate".rpad(" ", branchColumn - 3)}Num' + delimiter + '${"Rate".rpad(" ", expressionColumn - 3)}Num' + delimiter
			+ '${"Rate".rpad(" ", lineColumn - 3)}Num' + delimiter + '${"".rpad(" ", overallColumn)}';
		output(line);
		output("".rpad("=", totalWidth));
		for (l in lines) {
			line = l.pack.rpad(" ", packColumn)
				+ delimiter
				+ summaryColumn(l.fileCount, l.filesCovered, fileColumn)
				+ delimiter
				+ summaryColumn(l.typeCount, l.typesCovered, typeColumn)
				+ delimiter
				+ summaryColumn(l.fieldCount, l.fieldsCovered, fieldColumn)
				+ delimiter
				+ summaryColumn(l.branchCount, l.branchesCovered, branchColumn)
				+ delimiter
				+ summaryColumn(l.expressionCount, l.expressionsCovered, expressionColumn)
				+ delimiter
				+ summaryColumn(l.lineCount, l.linesCovered, lineColumn)
				+ delimiter
				+ overallSumColumn(l.fieldCount + l.branchCount + l.expressionCount, l.fieldsCovered + l.branchesCovered + l.expressionsCovered,
					overallColumn);
			output(line);
		}
		output("".rpad("=", totalWidth));
		line = "Total:".lpad(" ", packColumn)
			+ delimiter
			+ summaryColumn(context.files.length, context.filesCovered, fileColumn)
			+ delimiter
			+ summaryColumn(context.types.length, context.typesCovered, typeColumn)
			+ delimiter
			+ summaryColumn(context.fieldCount, context.fieldsCovered, fieldColumn)
			+ delimiter
			+ summaryColumn(context.branchCount, context.branchesCovered, branchColumn)
			+ delimiter
			+ summaryColumn(context.expressionCount, context.expressionsCovered, expressionColumn)
			+ delimiter
			+ summaryColumn(context.lineCount, context.linesCovered, lineColumn)
			+ delimiter
			+ overallSumColumn(context.fieldCount
				+ context.branchCount
				+ context.expressionCount,
				context.fieldsCovered
				+ context.branchesCovered
				+ context.expressionsCovered, overallColumn);
		output(line);
		output("".rpad("=", totalWidth));
		output("");
	}

	function longestPackageName(lines:Array<PackageSummaryLine>):Int {
		var max:Int = 10;
		for (line in lines) {
			if (line.pack.length > max) {
				max = line.pack.length;
			}
		}
		return max;
	}

	function summaryColumn(count:Int, covered:Int, columnLen:Int):String {
		var nums:String = '$covered/$count';
		var percent:String = if (count <= 0) {
			"0%".lpad(" ", 6);
		} else {
			'${Math.floor(covered * 10000 / count) / 100}%'.lpad(" ", 6);
		}
		return percent.rpad(" ", columnLen - nums.length) + nums;
	}

	function overallSumColumn(count:Int, covered:Int, columnLen:Int):String {
		var percent:String = if (count <= 0) {
			"0%".lpad(" ", 6);
		} else {
			'${Math.floor(covered * 10000 / count) / 100}%'.lpad(" ", 6);
		}
		return percent.lpad(" ", columnLen);
	}

	function summaryColumnLen(count:Int, covered:Int):Int {
		return 6 + 3 + '${covered}/${count}'.length;
	}

	function sortPackageNames(a:PackageSummaryLine, b:PackageSummaryLine):Int {
		if (a.pack < b.pack) {
			return -1;
		}
		if (a.pack > b.pack) {
			return 1;
		}
		return 0;
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

typedef PackageSummaryLine = {
	var pack:String;
	var fileCount:Int;
	var filesCovered:Int;
	var typeCount:Int;
	var typesCovered:Int;
	var fieldCount:Int;
	var fieldsCovered:Int;
	var branchCount:Int;
	var branchesCovered:Int;
	var expressionCount:Int;
	var expressionsCovered:Int;
	var lineCount:Int;
	var linesCovered:Int;
}

typedef ExtractPackageSummaryLine = (l:PackageSummaryLine) -> Int
