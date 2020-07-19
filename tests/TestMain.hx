import sys.FileSystem;
import coverage.TestCoverage;
import utest.ITest;
import utest.Runner;
import utest.ui.Report;

class TestMain {
	public static function main() {
		var tests:Array<() -> ITest> = [TestCoverage.new];
		final runner:Runner = new Runner();
		runner.onComplete.add(_ -> {
			FileSystem.deleteFile("tests/.missing-data.json");
		});
		Report.create(runner);
		for (test in tests) {
			runner.addCase(test());
		}
		runner.run();
	}
}
