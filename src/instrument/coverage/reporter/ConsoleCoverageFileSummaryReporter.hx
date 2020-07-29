package instrument.coverage.reporter;

import haxe.io.Path;

class ConsoleCoverageFileSummaryReporter implements ICoverageReporter {
	final delimiter:String = " | ";

	public function new() {}

	public function generateReport(context:CoverageContext) {
		var lines:Array<SummaryLine> = [];

		for (file in context.files) {
			var summary:SummaryLine = {
				file: file.file,
				prefix: "",
				typeCount: file.types.length,
				typesCovered: file.typesCovered,
				fieldCount: file.fieldCount,
				fieldsCovered: file.fieldsCovered,
				branchCount: file.branchCount,
				branchesCovered: file.branchesCovered,
				expressionCount: file.expressionCount,
				expressionsCovered: file.expressionsCovered,
				lineCount: file.lineCount,
				linesCovered: file.linesCovered
			}
			lines.push(summary);
		}
		lines.sort(sortFileNames);
		buildFilePrefixes(lines);

		var fileColumn:Int = longestFileName(lines) + 1;
		var typeColumn:Int = summaryColumnLen(context.types.length, context.typesCovered);
		var fieldColumn:Int = summaryColumnLen(context.fieldCount, context.fieldsCovered);
		var branchColumn:Int = summaryColumnLen(context.branchCount, context.branchesCovered);
		var expressionColumn:Int = summaryColumnLen(context.expressionCount, context.expressionsCovered);
		var lineColumn:Int = summaryColumnLen(context.lineCount, context.linesCovered);
		var overallColumn:Int = 7;
		var totalWidth:Int = fileColumn + typeColumn + fieldColumn + branchColumn + expressionColumn + lineColumn + overallColumn + 6 * 3;

		output("");
		output("".rpad("=", totalWidth));
		var line:String = '${"".lpad(" ", fileColumn)}' + delimiter + '${"Types".rpad(" ", typeColumn)}' + delimiter + '${"Fields".rpad(" ", fieldColumn)}'
			+ delimiter + '${"Branches".rpad(" ", branchColumn)}' + delimiter + '${"Expression".rpad(" ", expressionColumn)}' + delimiter
			+ '${"Lines".rpad(" ", lineColumn)}' + delimiter + '${"Overall".rpad(" ", overallColumn)}';
		output(line);
		line = '${"FileName".rpad(" ", fileColumn)}' + delimiter + '${"Rate".rpad(" ", typeColumn - 3)}Num' + delimiter
			+ '${"Rate".rpad(" ", fieldColumn - 3)}Num' + delimiter + '${"Rate".rpad(" ", branchColumn - 3)}Num' + delimiter
			+ '${"Rate".rpad(" ", expressionColumn - 3)}Num' + delimiter + '${"Rate".rpad(" ", lineColumn - 3)}Num' + delimiter
			+ '${"".rpad(" ", overallColumn)}';
		output(line);
		output("".rpad("=", totalWidth));
		var lastPrefix:String = "";
		var first:Bool = true;
		for (l in lines) {
			if (first) {
				if (l.prefix.length > 0) {
					output('[${l.prefix}]');
					lastPrefix = l.prefix;
					first = false;
				}
			} else {
				if (lastPrefix != l.prefix) {
					output("");
					output('[${l.prefix}]');
					lastPrefix = l.prefix;
				}
			}
			line = l.file.rpad(" ", fileColumn)
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
		line = "Total:".lpad(" ", fileColumn)
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

	function longestFileName(lines:Array<SummaryLine>):Int {
		var max:Int = 10;
		for (line in lines) {
			if (line.file.length > max) {
				max = line.file.length;
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

	function sortFileNames(a:SummaryLine, b:SummaryLine):Int {
		if (a.prefix < b.prefix) {
			return -1;
		}
		if (a.prefix > b.prefix) {
			return 1;
		}
		if (a.file < b.file) {
			return -1;
		}
		if (a.file > b.file) {
			return 1;
		}
		return 0;
	}

	function buildFilePrefixes(lines:Array<SummaryLine>) {
		var prefixCandidateCounter:Map<String, Int> = new Map<String, Int>();
		for (l in lines) {
			addPrefixes(prefixCandidateCounter, l.file);
		}
		var prefixCandidates:Array<String> = [for (p => _ in prefixCandidateCounter) p];
		prefixCandidates.sort(sortPrefixes);

		var prefixes:Array<String> = [];
		var lastPrefix:String = "";
		var lastCount:Int = 0;
		for (prefix in prefixCandidates) {
			var count:Int = prefixCandidateCounter.get(prefix).sure();
			if (lastPrefix.length <= 0) {
				lastPrefix = prefix;
				lastCount = count;
				continue;
			}
			if (prefix.startsWith(lastPrefix)) {
				if ((count == lastCount) || (count > 30)) {
					lastPrefix = prefix;
					lastCount = count;
					continue;
				}
				if (!prefixes.contains(lastPrefix)) {
					prefixes.push(lastPrefix);
				}
			} else {
				lastPrefix = prefix;
				lastCount = count;
			}
		}
		if (!prefixes.contains(lastPrefix)) {
			prefixes.push(lastPrefix);
		}
		for (line in lines) {
			var matchedPrefix:String = "";
			for (prefix in prefixes) {
				if (line.file.startsWith(prefix)) {
					if (prefix.length > matchedPrefix.length) {
						matchedPrefix = prefix;
					}
				}
			}
			if (matchedPrefix.length > 0) {
				line.prefix = line.file.substr(0, matchedPrefix.length);
				line.file = line.file.substr(matchedPrefix.length);
			}
		}
	}

	function sortPrefixes(a:String, b:String):Int {
		if (a < b) {
			return -1;
		}
		if (a > b) {
			return 1;
		}
		return 0;
	}

	function addPrefixes(prefixCandidates:Map<String, Int>, fileName:String) {
		var folder:String = new Path(fileName).dir.sure();
		while (folder.length > 0) {
			addPrefix(prefixCandidates, folder + "/");
			folder = Path.directory(folder);
		}
	}

	function addPrefix(prefixCandidates:Map<String, Int>, prefix:String) {
		if (prefixCandidates.exists(prefix)) {
			prefixCandidates.set(prefix, prefixCandidates.get(prefix).sure() + 1);
		} else {
			prefixCandidates.set(prefix, 1);
		}
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

typedef SummaryLine = {
	var file:String;
	var prefix:String;
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

typedef ExtractSummaryValue = (l:SummaryLine) -> Int
