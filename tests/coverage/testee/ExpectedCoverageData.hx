package coverage.testee;

import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import instrument.Instrumentation;

class ExpectedCoverageData {
	public var missedItems:Array<ExpectedCoverageItem>;

	public function new() {
		missedItems = [];
	}

	public function addMissing(line:Int, type:MissedCoverageType) {
		missedItems.push({
			line: line,
			missedType: missedTypeToString(type)
		});
	}

	public static function load():ExpectedCoverageData {
		var jsonData:String = File.getContent(getMissingDataFile());
		var data:ExpectedCoverageData = new ExpectedCoverageData();
		data.missedItems = Json.parse(jsonData);
		return data;
	}

	public function save() {
		File.saveContent(getMissingDataFile(), Json.stringify(missedItems));
	}

	public static function getMissingDataFile():String {
		var fileName:String = Path.join([Instrumentation.workspaceFolder(), "tests", ".missing-data.json"]);
		var folder:String = Path.directory(fileName);
		if (folder.trim().length > 0) {
			if (!FileSystem.exists(folder)) {
				FileSystem.createDirectory(folder);
			}
		}
		return fileName;
	}

	function missedTypeToString(type:MissedCoverageType):String {
		return switch (type) {
			case Type(name):
				'type $name';
			case Field(name):
				'field $name';
			case Branch:
				"branch";
			case Expression:
				"expression";
		}
	}
}

typedef ExpectedCoverageItem = {
	var line:Int;
	var missedType:String;
}

enum MissedCoverageType {
	Type(name:String);
	Field(name:String);
	Branch;
	Expression;
}
