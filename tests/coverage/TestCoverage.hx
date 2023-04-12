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
		data.addMissing(9, Expression);

		data.addMissing(16, Branch);
		data.addMissing(16, Expression);
		data.addMissing(17, Expression);

		data.addMissing(23, Branch);
		data.addMissing(23, Expression);
		data.addMissing(27, Expression);

		data.addMissing(31, Branch);
		data.addMissing(31, Expression);
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
		data.addMissing(82, Expression);
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
		data.addMissing(31, Expression);
		data.addMissing(32, Expression);

		data.addMissing(42, Branch);
		data.addMissing(42, Expression);
		data.addMissing(43, Expression);
		data.addMissing(45, Branch);
		data.addMissing(45, Expression);
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

	#if (haxe >= version("4.3.0"))
	public function testTernaryBranches() {
		var data:ExpectedCoverageData = new ExpectedCoverageData();
		data.addMissing(20, Branch);
		data.addMissing(21, Branch);
		data.addMissing(23, Branch);
		data.addMissing(24, Branch);
		data.addMissing(25, Branch);

		data.addMissing(32, Branch);
		data.addMissing(33, Branch);
		data.addMissing(33, Expression);
		data.addMissing(35, Branch);
		data.addMissing(35, Expression);
		data.addMissing(36, Branch);
		data.addMissing(36, Expression);
		data.addMissing(37, Branch);
		data.addMissing(37, Expression);

		data.addMissing(47, Branch);
		data.addMissing(48, Branch);
		data.addMissing(49, Branch);

		data.save();
		runTestee("coverage.testcases.TernaryBranches");
	}
	#end

	public function testWithMacroPositions() {
		var data:ExpectedCoverageData = new ExpectedCoverageData();
		data.addMissing(13, Field("appendMacroCode"));
		data.addMissing(14, Expression);
		data.addMissing("tests/coverage/testcases/macro/BuildMacro.hx", 12, Field("tests/coverage/testcases/macro/BuildMacro.hx"));
		data.addMissing("tests/coverage/testcases/macro/BuildMacro.hx", 12, Expression);
		data.addMissing("tests/coverage/testcases/macro/BuildMacro.hx", 13, Expression);
		data.addMissing("tests/coverage/testcases/macro/BuildMacro.hx", 34, Field("macroFieldNotCovered"));
		data.addMissing("tests/coverage/testcases/macro/BuildMacro.hx", 35, Expression);
		data.save();
		runTestee("coverage.testcases.WithMacroPositions");
	}

	function runTestee(testeeClass:String, ?pos:PosInfos) {
		var params:Array<String> = [
			"haxe",
			"-cp",
			"src",
			"-cp",
			"tests",
			"-lib",
			"safety",
			"-D",
			"test-class=" + testeeClass,
			"--macro",
			'instrument.Instrumentation.coverage([\'$testeeClass\'],[\'tests\'],[])',
			"-main",
			"coverage.testee.CoverageTestMain",
			"--run",
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
