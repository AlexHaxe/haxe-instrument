package coverage.testcases;

import coverage.testee.ICoverageTestee;

typedef CacheOptions = {
	@:optional var defaultDuration:Int;
	@:optional var keyPrefix:String;
	@:optional var serializer:Serializer;
}

typedef Serializer = {
	var serialize:Int;
	var unserialize:Int;
}

class TernaryBranches implements ICoverageTestee {
	public function new() {}

	public function ternaryAllFalse(options:Null<CacheOptions>) {
		var tmp = options != null ? options : null;
		var tmp = options ?? null;

		var defaultDuration = options?.defaultDuration ?? 0;
		var keyPrefix = options?.keyPrefix ?? "";
		var serializer = options?.serializer ?? {
			serialize: 1,
			unserialize: 2
		};
	}

	public function ternaryAllTrue(options:Null<CacheOptions>) {
		var tmp = options != null ? options : null;
		var tmp = options ?? null;

		var defaultDuration = options?.defaultDuration ?? 0;
		var keyPrefix = options?.keyPrefix ?? "";
		var serializer = options?.serializer ?? {
			serialize: 1,
			unserialize: 2
		};
	}

	public function ternaryEmptyOptions(options:Null<CacheOptions>) {
		var tmp = options != null ? options : null;
		var tmp = options ?? null;

		var defaultDuration = options?.defaultDuration ?? 0;
		var keyPrefix = options?.keyPrefix ?? "";
		var serializer = options?.serializer ?? {
			serialize: 1,
			unserialize: 2
		};
	}

	public function ternaryAllCovered(options:Null<CacheOptions>) {
		var tmp = options != null ? options : null;
		var tmp = options ?? null;

		var defaultDuration = options?.defaultDuration ?? 0;
		var keyPrefix = options?.keyPrefix ?? "";
		var serializer = options?.serializer ?? {
			serialize: 1,
			unserialize: 2
		};
	}

	public function run() {
		ternaryAllFalse(null);

		ternaryAllTrue({defaultDuration: 10, keyPrefix: "prefix", serializer: {serialize: 100, unserialize: 200}});

		ternaryEmptyOptions(null);
		ternaryEmptyOptions({});

		ternaryAllCovered(null);
		ternaryAllCovered({defaultDuration: 10, keyPrefix: "prefix", serializer: {serialize: 100, unserialize: 200}});
	}
}
