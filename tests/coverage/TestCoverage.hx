package coverage;

import haxe.Exception;
import haxe.PosInfos;
import utest.Assert;
import utest.ITest;
import coverage.testee.ExpectedCoverageData;

class TestCoverage implements ITest {
	public function new() {}

	public function testIfBranches() {
		var data:ExpectedCoverageData = new ExpectedCoverageData();
		data.addMissing(9, Branch);

		data.addMissing(16, Branch);
		data.addMissing(17, Expression);

		data.addMissing(23, Branch);
		data.addMissing(27, Expression);

		data.addMissing(31, Expression);
		data.addMissing(31, Branch);
		data.addMissing(35, Expression);

		data.addMissing(39, Branch);
		data.addMissing(39, Expression);
		data.addMissing(43, Expression);

		data.addMissing(56, Branch);

		data.addMissing(66, Branch);
		data.addMissing(66, Expression);
		data.addMissing(70, Expression);

		data.addMissing(74, Branch);
		data.addMissing(74, Expression);
		data.addMissing(78, Expression);

		data.addMissing(82, Branch);
		data.addMissing(86, Expression);

		data.save();

		runTestee("coverage.testcases.IfBranches");
	}

	public function testIgnored() {
		var data:ExpectedCoverageData = new ExpectedCoverageData();
		data.save();
		runTestee("coverage.testcases.IgnoredCoverage");
	}

	public function testMissingFiels() {
		var data:ExpectedCoverageData = new ExpectedCoverageData();
		data.addMissing(8, Expression);
		data.addMissing(12, Field("doNothing"));
		data.addMissing(14, Field("doNothing2"));
		data.addMissing(16, Field("doNothing3"));
		data.save();
		runTestee("coverage.testcases.MissingFields");
	}

	public function testSwitchBranches() {
		var data:ExpectedCoverageData = new ExpectedCoverageData();
		data.addMissing(10, Branch);
		data.addMissing(11, Expression);

		data.addMissing(16, Branch);
		data.addMissing(17, Expression);
		data.save();
		runTestee("coverage.testcases.SwitchBranches");
	}

	public function testWhileBranches() {
		var data:ExpectedCoverageData = new ExpectedCoverageData();
		data.addMissing(9, Branch);
		data.addMissing(13, Expression);

		data.addMissing(17, Branch);
		data.addMissing(18, Expression);
		data.addMissing(19, Expression);

		data.addMissing(31, Branch);
		data.addMissing(32, Expression);
		data.save();
		runTestee("coverage.testcases.WhileBranches");
	}

	public function testTryCatch() {
		var data:ExpectedCoverageData = new ExpectedCoverageData();
		data.addMissing(13, Expression);
		data.addMissing(21, Expression);
		data.save();
		runTestee("coverage.testcases.TryCatch");
	}

	function runTestee(testeeClass:String, ?pos:PosInfos) {
		var params:Array<String> = [
			"haxe", "-cp", "src", "-cp", "tests", "-lib", "safety", "-D", "test-class=" + testeeClass, "--macro",
			'instrument.Instrumentation.coverage([\'$testeeClass\'],[\'tests\'],[])', "-main", "coverage.testee.CoverageTestMain", "--run",
			"coverage.testee.CoverageTestMain"
		];

		Sys.println(params.join(" "));
		try {
			var exitCode:Int = Sys.command("npx", params);
			Assert.equals(0, exitCode, pos);
		} catch (e:Exception) {
			Assert.fail(e.details());
		};
	}
}
