import sys.FileSystem;
import sys.io.File;
import coverage.TestCoverage;
import utest.ITest;
import utest.Runner;
import utest.ui.text.DiagnosticsReport;

class TestMain {
	public static function main() {
		var tests:Array<() -> ITest> = [TestCoverage.new];
		final runner:Runner = new Runner();
		runner.onComplete.add(_ -> {
			FileSystem.deleteFile("tests/.missing-data.json");
			collectLcovData();
		});
		new DiagnosticsReport(runner);
		for (test in tests) {
			runner.addCase(test());
		}
		runner.run();
	}

	static function collectLcovData() {
		var lcovData:Array<String> = [];
		for (fileName in FileSystem.readDirectory(Sys.getCwd())) {
			if (!~/lcov.*\.test\.info/.match(fileName)) {
				continue;
			}
			lcovData.push(File.getContent(fileName));
			FileSystem.deleteFile(fileName);
		}
		File.saveContent("lcovTest.info", lcovData.join("\n"));
	}
}
