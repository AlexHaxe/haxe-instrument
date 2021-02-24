import demo.MyTestApp;
import instrument.Instrumentation;
import instrument.InstrumentationTypeTest;
import utest.ITest;
import utest.Runner;
import utest.ui.Report;
import utest.ui.text.DiagnosticsReport;

class TestSelfMain {
	public static function main() {
		new MyTestApp(100, true);

		var tests:Array<() -> ITest> = [InstrumentationTypeTest.new];
		final runner:Runner = new Runner();
		runner.onComplete.add(_ -> {
			Instrumentation.endInstrumentation(None);
			Instrumentation.endInstrumentation(Coverage);
			Instrumentation.endInstrumentation(Profiling);
			Instrumentation.endInstrumentation(Both);
		});
		new DiagnosticsReport(runner);
		for (test in tests) {
			runner.addCase(test());
		}
		runner.run();
	}
}
