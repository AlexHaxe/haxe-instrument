package demo;

class NullSafety {
	public static function main() {
		func({field: 'hello'});
		func2({field: 'hello'});
	}

	static function func(o:{field:Null<String>}) {
		if (o.field != null) {
			trace(o.field.length);
		}
	}

	@:nullSafety(StrictThreaded)
	static function func2(o:{field:Null<String>}) {
		if (o.field != null) {
			trace(o.field.length);
		}
	}
}
