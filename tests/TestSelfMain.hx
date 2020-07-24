import demo.MyTestApp;
import instrument.coverage.Coverage;

class TestSelfMain {
	public static function main() {
		new MyTestApp(100, true);
		Coverage.endCoverage();
		Coverage.endCoverage();
	}
}
