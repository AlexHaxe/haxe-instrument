package demo;

import haxe.ds.ReadOnlyArray;

class ArrayTest {
	public static function main() {
		final array = ["hello", "world"];

		func(array);
	}

	static function func(_array:ReadOnlyArray<String>) {
		trace(_array.length);
	}
}
