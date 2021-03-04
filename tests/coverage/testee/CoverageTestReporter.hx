package coverage.testee;

import instrument.coverage.CoverageContext;
import instrument.coverage.reporter.ConsoleMissingCoverageReporter;

class CoverageTestReporter extends ConsoleMissingCoverageReporter {
	public function new() {
		super();
	}

	override public function generateReport(context:CoverageContext) {
		super.generateReport(context);
		var data:ExpectedCoverageData = ExpectedCoverageData.load();

		if (data.missedItems.length != outputLines.length) {
			trace("number of missed items mismatch: " + data.missedItems.length + " != " + outputLines.length);
			trace(outputLines.map(l -> '${l.lineNumber}: ${l.text}\n'));
			trace(data.missedItems.map(l -> '${l.line}: ${l.missedType}\n'));
			Sys.exit(-1);
		}
		for (item in data.missedItems) {
			var found:Bool = false;
			var text:String = '${item.missedType} not covered';
			for (out in outputLines) {
				if (out.lineNumber != item.line) {
					continue;
				}
				if (out.text != text) {
					continue;
				}
				found = true;
			}
			if (!found) {
				trace('should have a missing ${item.missedType} coverage on line ${item.line}');
				Sys.exit(1);
			}
		}
		Sys.exit(0);
	}

	override function output(text:String) {}
}
