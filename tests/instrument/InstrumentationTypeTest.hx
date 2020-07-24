package instrument;

import utest.Assert;
import utest.ITest;

using instrument.InstrumentationType;

class InstrumentationTypeTest implements ITest {
	public function new() {}

	public function testAddType() {
		Assert.equals(None, None.add(None));
		Assert.equals(Coverage, None.add(Coverage));
		Assert.equals(Coverage, None.add(Coverage).add(Coverage));
		Assert.equals(Profiling, None.add(Profiling));
		Assert.equals(Profiling, None.add(Profiling).add(Profiling));
		Assert.equals(Both, None.add(Coverage).add(Profiling));
		Assert.equals(Both, None.add(Coverage).add(Profiling).add(Coverage).add(Profiling));
		Assert.equals(Both, None.add(Coverage).add(Both));
		Assert.equals(Both, None.add(Profiling).add(Both));

		Assert.equals(Coverage, Coverage.add(None));
		Assert.equals(Coverage, Coverage.add(Coverage).add(Coverage));

		Assert.equals(Profiling, Profiling.add(None));
		Assert.equals(Profiling, Profiling.add(Profiling).add(Profiling));

		Assert.equals(Both, Both.add(None));
		Assert.equals(Both, Both.add(Coverage).add(Profiling));
		Assert.equals(Both, None.add(Both));
		Assert.equals(Both, Coverage.add(Both));
		Assert.equals(Both, Profiling.add(Both));
		Assert.equals(Both, Both.add(Both));
	}

	public function testRemoveType() {
		Assert.equals(None, None.remove(None));
		Assert.equals(None, None.remove(Coverage));
		Assert.equals(None, None.remove(Profiling));
		Assert.equals(None, None.remove(None).remove(None));

		Assert.equals(Coverage, Coverage.remove(None));
		Assert.equals(None, Coverage.remove(Coverage));
		Assert.equals(Coverage, Coverage.remove(Profiling));
		Assert.equals(None, Coverage.remove(Both));
		Assert.equals(Coverage, Coverage.remove(None).remove(None));

		Assert.equals(Profiling, Profiling.remove(None));
		Assert.equals(Profiling, Profiling.remove(Coverage));
		Assert.equals(None, Profiling.remove(Profiling));
		Assert.equals(None, Profiling.remove(Both));
		Assert.equals(Profiling, Profiling.remove(None).remove(None));

		Assert.equals(Both, Both.remove(None));
		Assert.equals(Profiling, Both.remove(Coverage));
		Assert.equals(Coverage, Both.remove(Profiling));
		Assert.equals(None, Both.remove(Both));
		Assert.equals(Both, Both.remove(None).remove(None));
	}
}
