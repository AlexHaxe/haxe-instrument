package coverage.testee;

import haxe.macro.Context;
import instrument.coverage.Coverage;
import instrument.coverage.reporter.LcovCoverageReporter;
import coverage.testcases.IfBranches;
import coverage.testcases.IgnoredCoverage;
import coverage.testcases.MissingFields;
import coverage.testcases.Returns;
import coverage.testcases.SwitchBranches;
import coverage.testcases.TryCatch;
import coverage.testcases.WhileBranches;
import coverage.testcases.WithMacroPositions;
#if (haxe >= version("4.3.0"))
import coverage.testcases.TernaryBranches;
#end

class CoverageTestMain {
	final includeTestCases:Array<() -> ICoverageTestee> = [
		IfBranches.new,
		IgnoredCoverage.new,
		MissingFields.new,
		Returns.new,
		SwitchBranches.new,
		#if (haxe >= version("4.3.0"))
		TernaryBranches.new,
		#end
		TryCatch.new,
		WithMacroPositions.new,
		WhileBranches.new
	];

	public static function main() {
		var testClassName:String = Context.definedValue("test-class");

		var reporter:CoverageTestReporter = new CoverageTestReporter();
		var lcovReporter:LcovCoverageReporter = new LcovCoverageReporter('lcov.${testClassName}.test.info');
		var clazz:Null<Class<Dynamic>> = Type.resolveClass(testClassName);
		if (clazz == null) {
			Coverage.endCustomCoverage([lcovReporter, reporter]);
			return;
		}
		var instance:ICoverageTestee = Type.createInstance(clazz, []);
		instance.run();
		Coverage.endCustomCoverage([lcovReporter, reporter]);
	}
}
