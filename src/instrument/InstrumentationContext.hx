package instrument;

import haxe.macro.Expr;
import instrument.coverage.FieldInfo;
import instrument.coverage.TypeInfo;

typedef InstrumentationContext = {
	var pack:String;
	var className:String;
	var pos:Position;
	var typeInfo:Null<TypeInfo>;
	var anonFuncCounter:Int;
	var isInline:Bool;
	var implicitReturn:Bool;
	var isAbstract:Bool;
	var allReturns:Bool;
	var missingBranches:Array<Expr>;
	var level:InstrumentationType;
	@:optional var fieldName:Null<String>;
	@:optional var field:Null<Field>;
	@:optional var fieldInfo:Null<FieldInfo>;
}
