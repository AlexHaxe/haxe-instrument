package demo.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class BuildMacro {
	public static function build():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		for (field in fields) {
			if (field.name == "appendMacroCode") {
				appendCode(field, macro {
					doNothing();
				});
			}
		}

		fields.unshift(buildMacroFieldCovered());
		fields.unshift(buildMacroFieldNotCovered());

		return fields;
	}

	private static function buildMacroFieldCovered():Field {
		return (macro class {
			private function macroFieldCovered():Void {
				doNothing();
			}
		}).fields[0];
	}

	private static function buildMacroFieldNotCovered():Field {
		return (macro class {
			private function macroFieldNotCovered():Void {
				doNothing();
			}
		}).fields[0];
	}

	public static function appendCode(field:Field, expr:Expr) {
		switch (field.kind) {
			case FFun(f):
				switch (f.expr.expr) {
					case EBlock(exprs):
						exprs.push(expr);
					case _:
				}
			case _:
		}
	}
}
#end

@:autoBuild(demo.macro.BuildMacro.build())
interface IBuildMacro {}
