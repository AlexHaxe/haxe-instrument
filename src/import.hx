#if (cs || neko || cpp || macro || eval || java || hl)
import sys.thread.Mutex;
import sys.thread.Thread;
#else
import instrument.dummy.DummyMutex as Mutex;
import instrument.dummy.DummyThread as Thread;
#end

using StringTools;
using instrument.profiler.LocationTools;
