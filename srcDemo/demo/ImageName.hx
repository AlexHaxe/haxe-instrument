package demo;

abstract ImageName(String) {
	public function new(name:String) {
		this = name;
	}

	@:from
	public static function fromString(name:String):ImageName {
		return new ImageName(name);
	}

	@:to
	public function toString():Null<String> {
		if (this == null) {
			return null;
		}
		var r:EReg = ~/[^_\-a-zA-Z0-9äöüßÄÖÜ]/g;
		var filename:String = r.replace('${this}', "_");
		filename = ~/ä/g.replace(filename, "ae");
		filename = ~/Ä/g.replace(filename, "Ae");
		filename = ~/ö/g.replace(filename, "oe");
		filename = ~/Ö/g.replace(filename, "Oe");
		filename = ~/ü/g.replace(filename, "ue");
		filename = ~/Ü/g.replace(filename, "Ue");
		filename = ~/ß/g.replace(filename, "ss");
		filename = ~/[_]+/g.replace(filename, "_");
		r = ~/^[^_a-zA-Z0-9]/;
		return r.replace(filename, "_");
	}
}
