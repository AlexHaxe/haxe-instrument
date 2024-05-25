package instrument;

import haxe.io.Path;
#if (sys || nodejs)
import sys.FileSystem;
#end
#if macro
import haxe.display.Position.Location;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.macro.Type;
import instrument.coverage.BranchInfo;
import instrument.coverage.BranchesInfo;
import instrument.coverage.CoverageContext;
import instrument.coverage.ExpressionInfo;
import instrument.coverage.FieldInfo;
import instrument.coverage.TypeInfo;

using haxe.macro.ExprTools;
using instrument.InstrumentationType;
#end

@:ignoreProfiler
class Instrumentation {
	static inline final NULLSAFETY_META = ":nullSafety";
	static inline final AFTER = "after ";
	static inline final BEFORE = "before ";
	static inline final DISPLAY = "display";

	#if macro
	static var includePackProfiling:Array<String> = [];
	static var includeFolderProfiling:Array<String> = [];
	static var excludePackProfiling:Array<String> = [];

	static var includePackCoverage:Array<String> = [];
	static var includeFolderCoverage:Array<String> = [];
	static var excludePackCoverage:Array<String> = [];

	static var coverageContext:instrument.coverage.CoverageContext;

	static var context:InstrumentationContext;
	static var level:InstrumentationType = None;

	public static function profiling(includes:Null<Array<String>> = null, folders:Null<Array<String>> = null, excludes:Null<Array<String>> = null) {
		if (Context.defined(DISPLAY)) {
			return;
		}
		if (includes != null) {
			includePackProfiling = includes;
		}
		if (folders != null) {
			includeFolderProfiling = folders;
		}
		if (excludes != null) {
			excludePackProfiling = excludes;
		}
		for (pack in includePackProfiling) {
			if (excludePackProfiling.length <= 0) {
				Compiler.include(pack, true, null, includePackProfiling);
			} else {
				Compiler.include(pack, true, excludePackProfiling, includePackProfiling);
			}
		}

		switch (level) {
			case None:
				installMetadata();
				level = Profiling;
			case Coverage:
				level = Both;
			case Profiling | Both:
		}
		for (pack in includePackCoverage) {
			Compiler.include(pack, true, excludePackCoverage, includeFolderCoverage);
		}
	}

	public static function coverage(includes:Null<Array<String>> = null, folders:Null<Array<String>> = null, excludes:Null<Array<String>> = null) {
		if (Context.defined(DISPLAY)) {
			return;
		}
		if (includes != null) {
			includePackCoverage = includes;
		}
		if (folders != null) {
			includeFolderCoverage = folders;
		}
		if (excludes != null) {
			excludePackCoverage = excludes;
		}

		switch (level) {
			case None:
				installMetadata();
				level = Coverage;
			case Profiling:
				level = Both;
			case Coverage | Both:
				return;
		}
		for (pack in includePackCoverage) {
			Compiler.include(pack, true, excludePackCoverage, includeFolderCoverage);
		}

		Context.onGenerate(onGenerate);
	}

	static function installMetadata() {
		Compiler.addGlobalMetadata("", "@:build(instrument.Instrumentation.instrumentFields())", true, true, false);
		Compiler.addGlobalMetadata("Sys", "@:build(instrument.Instrumentation.sysExitField())", true, true, false);
		Compiler.addGlobalMetadata("haxe.EntryPoint", "@:build(instrument.Instrumentation.entrypointRunField())", true, true, false);
		coverageContext = new CoverageContext();
		#if (!instrument_quiet)
		Sys.print("Instrumenting ");
		#end
	}

	static function filterType(pack:String, location:Location):InstrumentationType {
		var excludedProfiling:Bool = false;
		var excludedCoverage:Bool = false;
		for (excl in excludePackProfiling) {
			if (pack.startsWith(excl)) {
				excludedProfiling = true;
				break;
			}
		}
		for (excl in excludePackCoverage) {
			if (pack.startsWith(excl)) {
				excludedCoverage = true;
				break;
			}
		}
		if (excludedCoverage && excludedProfiling) {
			return None;
		}

		var includedProfiling:Bool = includePackProfiling.length == 0;
		var includedCoverage:Bool = includePackCoverage.length == 0;
		for (incl in includePackProfiling) {
			if (pack.startsWith(incl)) {
				includedProfiling = true;
				break;
			}
		}
		for (incl in includePackCoverage) {
			if (pack.startsWith(incl)) {
				includedCoverage = true;
				break;
			}
		}

		var includedLocationProfiling:Bool = includeFolderProfiling.length == 0;
		var includedLocationCoverage:Bool = includeFolderCoverage.length == 0;
		var folderLocation:String = location.file.toString();
		for (folder in includeFolderProfiling) {
			if (folderLocation.startsWith(folder)) {
				includedLocationProfiling = true;
				break;
			}
		}
		for (folder in includeFolderCoverage) {
			if (folderLocation.startsWith(folder)) {
				includedLocationCoverage = true;
				break;
			}
		}

		var newLevel:InstrumentationType = level;
		if (excludedCoverage) {
			newLevel = newLevel.remove(Coverage);
		}
		if (excludedProfiling) {
			newLevel = newLevel.remove(Profiling);
		}
		if (!includedCoverage) {
			newLevel = newLevel.remove(Coverage);
		}
		if (!includedProfiling) {
			newLevel = newLevel.remove(Profiling);
		}
		if (!includedLocationCoverage) {
			newLevel = newLevel.remove(Coverage);
		}
		if (!includedLocationProfiling) {
			newLevel = newLevel.remove(Profiling);
		}
		return newLevel;
	}

	static function filterTypeMeta(meta:MetaAccess, type:InstrumentationType):InstrumentationType {
		return filterFieldMeta(meta.get(), type);
	}

	static function filterFieldMeta(metadata:Null<Metadata>, type:InstrumentationType):InstrumentationType {
		if (metadata == null) {
			return type;
		}
		for (meta in metadata) {
			switch (meta.name) {
				case "ignoreInstrument" | ":ignoreInstrument" | "ignoreInstrumentation" | ":ignoreInstrumentation":
					return None;
				case "ignoreCoverage" | ":ignoreCoverage":
					type = type.remove(Coverage);
				case "ignoreProfiler" | ":ignoreProfiler":
					type = type.remove(Profiling);
			}
			if (type == None) {
				return None;
			}
		}
		return type;
	}

	static function instrumentFields():Null<Array<Field>> {
		if (Context.defined(DISPLAY)) {
			return null;
		}

		switch (Context.getLocalType()) {
			case TInst(_.get() => type, _):
				if (type.name == null || type.isExtern || type.isInterface) {
					return null;
				}
				context = makeInstrumentContext(type);
				switch (type.kind) {
					case KAbstractImpl(ref):
						context.isAbstract = true;
					default:
				}
				if (type.meta.has(NULLSAFETY_META)) {
					type.meta.remove(NULLSAFETY_META);
					type.meta.add(NULLSAFETY_META, [macro Off], type.pos);
				}
			default:
				return null;
		}

		switch (context.level) {
			case None:
				return null;
			case Coverage | Profiling | Both:
		}
		#if (!instrument_quiet)
		Sys.print(String.fromCharCode(0x8));
		Sys.print(". ");
		#end

		var fields:Array<Field> = Context.getBuildFields();
		var typeLevel:InstrumentationType = context.level;
		for (field in fields) {
			context.level = filterFieldMeta(field.meta, typeLevel);
			switch (context.level) {
				case None:
					continue;
				case Coverage | Profiling | Both:
			}
			instrumentField(field);
		}
		return fields;
	}

	static function makeInstrumentContext(type:ClassType):InstrumentationContext {
		var packParts:Array<String> = type.pack.copy();
		if (type.isPrivate) {
			packParts.pop();
		}
		var pack:String = packParts.join(".");

		var fullTypeName:String = if (packParts.length <= 0) {
			type.name;
		} else {
			pack + '.${type.name}';
		};

		var location:Location = PositionTools.toLocation(type.pos);
		var typeLevel:InstrumentationType = filterType(fullTypeName, location);
		typeLevel = filterTypeMeta(type.meta, typeLevel);

		var typeInfo:TypeInfo = new TypeInfo(coverageContext.nextId(), pack, type.name, location.locationToString(), location.file.toString(),
			location.range.start.line, location.range.end.line);
		switch (typeLevel) {
			case None | Profiling:
			case Coverage | Both:
				coverageContext.addType(typeInfo);
		}
		return {
			pack: pack,
			className: type.name,
			pos: type.pos,
			typeInfo: typeInfo,
			anonFuncCounter: 0,
			isInline: false,
			isAbstract: false,
			allReturns: false,
			level: typeLevel,
			missingBranches: []
		};
	}

	static function instrumentField(field:Field) {
		var funcName:String = field.name;
		if (funcName == "detectableInstances") {
			return;
		}
		initContext(field);

		switch (field.kind) {
			case FFun(fun) if (fun.expr != null):
				var isMain:Bool = (funcName == "main") && field.access.contains(AStatic);
				if (!field.access.contains(AExtern) && canRemoveInline(fun.expr)) {
					field.access.remove(AInline);
					context.isInline = false;
				}
				initFieldContext(field);
				removeNullSafety(field);
				context.allReturns = hasAllReturns(fun.expr);
				#if debug_instrumentation
				Sys.println(debugPosition(field.pos) + BEFORE + fun.expr.toString());
				#end
				fun.expr = instrumentExpr(ensureBlockExpr(fun.expr));
				fun.expr = instrumentFieldExpr(fun.expr, true, isMain);
				#if debug_instrumentation
				Sys.println(debugPosition(field.pos) + AFTER + fun.expr.toString());
				#end
			case FVar(type, expr) if (expr != null):
				if (context.isAbstract || context.isInline) {
					return;
				}
				initFieldContext(field);
				removeNullSafety(field);
				#if debug_instrumentation
				Sys.println(debugPosition(field.pos) + BEFORE + expr.toString());
				#end
				expr = instrumentExpr(ensureBlockValueExpr(expr));
				expr = instrumentFieldExpr(expr, false, false);
				#if debug_instrumentation
				Sys.println(debugPosition(field.pos) + AFTER + expr.toString());
				#end
				field.kind = FVar(type, expr);
			case FProp(get, set, type, expr) if (expr != null):
				if (context.isAbstract || context.isInline) {
					return;
				}
				initFieldContext(field);
				removeNullSafety(field);
				#if debug_instrumentation
				Sys.println(debugPosition(field.pos) + BEFORE + expr.toString());
				#end
				expr = instrumentExpr(ensureBlockValueExpr(expr));
				expr = instrumentFieldExpr(expr, false, false);
				#if debug_instrumentation
				Sys.println(debugPosition(field.pos) + AFTER + expr.toString());
				#end
				field.kind = FProp(get, set, type, expr);
			default:
		}
	}

	static function debugPosition(p:Position):String {
		var loc = PositionTools.toLocation(p);
		return '${loc.file}:${loc.range.start.line}: ';
	}

	static function canRemoveInline(expr:Expr):Bool {
		if (!context.isAbstract) {
			return true;
		}
		if (!context.isInline) {
			return true;
		}
		return false;
	}

	static function initContext(field:Field) {
		context.fieldInfo = null;
		context.field = field;
		context.pos = field.pos;
		context.fieldName = field.name;
		context.isInline = field.access.contains(AInline);
		context.allReturns = false;
		context.missingBranches = [];
	}

	static function removeNullSafety(field:Field) {
		if (field.meta == null) {
			return;
		}
		for (meta in field.meta) {
			switch (meta.name) {
				case NULLSAFETY_META:
					meta.params = [macro Off];
				default:
			}
		}
	}

	static function initFieldContext(field:Field) {
		var typeFileName = context.typeInfo.location.substring(0, context.typeInfo.location.indexOf(":"));

		var location:Location = PositionTools.toLocation(field.pos);
		var fieldInfo:FieldInfo = new FieldInfo(coverageContext.nextId(), field.name, location.locationToString(), location.range.start.line,
			location.range.end.line);
		switch (context.level) {
			case None | Profiling:
			case Coverage | Both:
				if (fieldInfo.location.startsWith(typeFileName)) {
					context.typeInfo.addField(fieldInfo);
				} else {
					var typeInfo = coverageContext.findTypeInfo(location.file.toString(), location.range.start.line, location.range.end.line);
					if (typeInfo != null) {
						typeInfo.addField(fieldInfo);
					}
				}
		}
		context.fieldInfo = fieldInfo;
	}

	static function instrumentFieldExpr(expr:Expr, withProfiler:Bool, isMain:Bool):Expr {
		var withCoverage:Bool = true;
		var hadWithProfiler:Bool = withProfiler;
		switch (context.level) {
			case None:
				withProfiler = false;
				withCoverage = false;
			case Coverage:
				withProfiler = false;
			case Profiling:
				withCoverage = false;
			case Both:
		}
		var exprs:Array<Expr> = exprsFromBlock(expr);
		var location:Location = PositionTools.toLocation(context.pos);

		var addNullReturn:Bool = !context.allReturns;
		switch (context.field.kind) {
			case FVar(t, e):
			case FFun(f):
				switch (f.ret) {
					case null:
						addNullReturn = false;
					case TPath(p):
						if (p.name == "Void") {
							addNullReturn = false;
						}
					default:
				}
			case FProp(get, set, t, e):
		}
		if (withCoverage) {
			var covExpr:Expr = macro instrument.coverage.CoverageContext.logExpression($v{context.fieldInfo.id});
			exprs.unshift(covExpr);
		}
		if (withProfiler) {
			var exit:Expr = macro instrument.profiler.Profiler.exitFunction(__profiler__id__);
			var entry:Expr = macro var __profiler__id__:Int = instrument.profiler.Profiler.enterFunction($v{location.locationToString()},
				$v{context.className}, $v{context.fieldName}, null);
			exprs.unshift(entry);
			if (!context.allReturns) {
				exprs.push(exit);
			}
		}
		if (hadWithProfiler && addNullReturn) {
			var nullReturn:Expr = macro return cast null;
			exprs.push(nullReturn);
		}
		if (isMain) {
			exprs.push(macro instrument.Instrumentation.endInstrumentation(cast $v{instrument.Instrumentation.level}));
		}
		return {expr: EBlock(exprs), pos: expr.pos};
	}

	static function instrumentExpr(expr:Expr):Expr {
		return switch (expr.expr) {
			case EBlock(exprs):
				var instrumentedExprs = [];
				for (e in exprs) {
					switch (context.level) {
						case None | Profiling:
						case Coverage | Both:
							instrumentedExprs.push(logExpression(e));
					}
					instrumentedExprs = addExprOrBlock(instrumentExpr(e), instrumentedExprs);
					for (e in context.missingBranches) {
						instrumentedExprs.push(e);
					}
					context.missingBranches = [];
				}
				{expr: EBlock(instrumentedExprs), pos: expr.pos};

			case EFor(it, e):
				it = instrumentExpr(it);
				e = instrumentExpr(ensureBlockExpr(e));
				{expr: EFor(it, e), pos: expr.pos};

			case EWhile(econd, e, normal):
				var branchesInfo:BranchesInfo = makeBranchesInfo(econd);
				coverWhileCondition(econd, e, normal, branchesInfo);

			case EIf(cond, eif, eelse):
				var branchesInfo:BranchesInfo = makeBranchesInfo(expr);
				coverIfCondition(cond, eif, eelse, branchesInfo);

			case ETernary(cond, eif, eelse):
				var branchesInfo:BranchesInfo = makeBranchesInfo(expr);
				coverTernaryCondition(cond, eif, eelse, branchesInfo);

			case EFunction(kind, f):
				if (f.expr == null) {
					return expr;
				}
				switch (kind) {
					case null:
						return null;
					case FAnonymous:
						var allReturn:Bool = hasAllReturns(f.expr);
						f.expr = instrumentFunctionExpr(instrumentExpr(ensureBlockExpr(f.expr)), '<anon-${context.anonFuncCounter++}>', allReturn);
					case FNamed(name, inlined):
						var allReturn:Bool = hasAllReturns(f.expr);
						f.expr = instrumentFunctionExpr(instrumentExpr(ensureBlockExpr(f.expr)), name, allReturn);
					case FArrow:
						var allReturn:Bool = hasAllReturns(f.expr);
						f.expr = instrumentFunctionExpr(instrumentExpr(ensureBlockExpr(f.expr)), '<anon-arrow-${context.anonFuncCounter++}>', allReturn);
				}
				{expr: EFunction(kind, f), pos: expr.pos};

			case EReturn(e):
				replaceReturn(e);
			case ETry(e, catches):
				e = instrumentExpr(ensureBlockExpr(e));
				for (c in catches) {
					c.expr = instrumentExpr(ensureBlockExpr(c.expr));
				}

				{expr: ETry(e, catches), pos: expr.pos};

			case EThrow(e):
				replaceThrow(e);

			case ECall(e, params):
				var instumentedExpr:Expr = expr.map(instrumentExpr);
				switch (e.expr) {
					case #if (haxe >= version("4.3.0")) EField(e, field, kind) #else EField(e, field) #end:
						if (field == "exit") {
							switch (e.expr) {
								case EConst(CIdent(s)):
									if (s == "Sys") {
										instumentedExpr = replaceSysExit(params[0]);
									}
								case _:
							}
						}
					case _:
				}
				instumentedExpr;

			case ESwitch(e, cases, edef):
				var branchesInfo:BranchesInfo = makeBranchesInfo(expr);

				e = instrumentExpr(e);
				if ((edef != null) && (edef.expr != null)) {
					edef = coverBranch(instrumentExpr(ensureBlockExpr(edef)), expr.pos, branchesInfo);
				}

				for (c in cases) {
					if (c.expr == null) {
						c.expr = coverBranch(null, expr.pos, branchesInfo);
						continue;
					}
					c.expr = coverBranch(instrumentExpr(ensureBlockExpr(c.expr)), expr.pos, branchesInfo);
				}
				{expr: ESwitch(e, cases, edef), pos: expr.pos};

			case EUntyped(e):
				e = instrumentExpr(ensureBlockExpr(e));
				{expr: EUntyped(e), pos: expr.pos};

			case EMeta(s, e):
				if (s.name == ":inline") {
					return e;
				}
				expr.map(instrumentExpr);

			case EVars(vars):
				expr.map(instrumentExpr);

			case EBinop(op, e1, e2):
				switch (op) {
					case OpBoolOr | OpBoolAnd:
						var branchesInfo:BranchesInfo = makeBranchesInfo(expr);
						e1 = coverBoolCondition(e1, branchesInfo);
						e2 = coverBoolCondition(e2, branchesInfo);
						{expr: EBinop(op, e1, e2), pos: expr.pos};
					case OpEq | OpNotEq | OpGt | OpGte | OpLt | OpLte:
						var branchesInfo:BranchesInfo = makeBranchesInfo(expr);
						e1 = instrumentExpr(ensureBlockExpr(e1));
						e2 = instrumentExpr(ensureBlockExpr(e2));
						coverCondition({expr: EBinop(op, e1, e2), pos: expr.pos}, branchesInfo);
					#if (haxe >= version("4.3.0"))
					case OpNullCoal:
						var branchesInfo:BranchesInfo = makeBranchesInfo(expr);
						coverNullCoal(e1, e2, branchesInfo);
					#end
					default:
						expr.map(instrumentExpr);
				}
			#if (haxe >= version("4.3.0"))
			case EField(e, field, Safe) if (haxe.macro.Context.defined("js")):
				e = instrumentExpr(ensureBlockExpr(e));
				{expr: EField(e, field, Safe), pos: expr.pos};
			case EField(e, field, Safe):
				var branchesInfo:BranchesInfo = makeBranchesInfo(expr);
				coverSafeField(e, field, branchesInfo);
			#end
			default:
				expr.map(instrumentExpr);
		}
	}

	static function addExprOrBlock(expr:Expr, exprs:Array<Expr>):Array<Expr> {
		switch (expr.expr) {
			case EBlock(blkExprs):
				exprs = exprs.concat(blkExprs);
			case _:
				exprs.push(expr);
		}
		return exprs;
	}

	static function instrumentFunctionExpr(expr:Expr, name:String, allReturn:Bool):Expr {
		var exprs:Array<Expr> = exprsFromBlock(expr);
		switch (context.level) {
			case None | Coverage:
			case Profiling | Both:
				var location:Location = PositionTools.toLocation(expr.pos);
				var entry:Expr = macro var __profiler__id__:Int = instrument.profiler.Profiler.enterFunction($v{location.locationToString()},
					$v{context.className}, $v{name}, null);
				exprs.unshift(relocateExpr(entry, expr.pos));
				if (!allReturn) {
					var exit:Expr = macro instrument.profiler.Profiler.exitFunction(__profiler__id__);
					exprs.push(relocateExpr(exit, expr.pos));
				}
		}
		return {expr: EBlock(exprs), pos: expr.pos};
	}

	static function logExpression(expr:Expr):Expr {
		var fieldFileName = context.fieldInfo.location.substring(0, context.fieldInfo.location.indexOf(":"));

		var location:Location = PositionTools.toLocation(expr.pos);
		var expressionInfo:ExpressionInfo = new ExpressionInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line,
			location.range.end.line);

		if (location.file.toString() == fieldFileName) {
			context.fieldInfo.addExpression(expressionInfo);
		} else {
			var fieldInfo = coverageContext.findFieldInfo(location.file.toString(), location.range.start.line, location.range.end.line);
			fieldInfo.addExpression(expressionInfo);
		}
		return relocateExpr(macro instrument.coverage.CoverageContext.logExpression($v{expressionInfo.id}), expr.pos);
	}

	static function makeBlock(expr:Expr):Expr {
		return {expr: EBlock([expr]), pos: expr.pos};
	}

	static function ensureBlockExpr(expr:Expr):Expr {
		return switch (expr.expr) {
			case EBlock(_):
				expr;
			default:
				makeBlock(expr);
		}
	}

	static function ensureBlockValueExpr(expr:Expr):Expr {
		return switch (expr.expr) {
			case EBlock([]):
				makeBlock(expr); // this is not an "empty block", it's an empty object declaration.
			case EBlock(_):
				expr;
			default:
				makeBlock(expr);
		}
	}

	static function exprsFromBlock(expr:Expr):Array<Expr> {
		return switch (expr.expr) {
			case EBlock(exprs):
				exprs;
			default:
				[expr];
		}
	}

	static function makeBranchesInfo(expr:Expr):BranchesInfo {
		var fieldFileName = context.fieldInfo.location.substring(0, context.fieldInfo.location.indexOf(":"));

		var location:Location = PositionTools.toLocation(expr.pos);
		var branchesInfo:BranchesInfo = new BranchesInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line,
			location.range.end.line);

		if (location.file.toString() == fieldFileName) {
			context.fieldInfo.addBranches(branchesInfo);
		} else {
			var fieldInfo = coverageContext.findFieldInfo(location.file.toString(), location.range.start.line, location.range.end.line);
			fieldInfo.addBranches(branchesInfo);
		}
		return branchesInfo;
	}

	static function coverBranch(expr:Null<Expr>, pos:Position, branchesInfo:BranchesInfo):Expr {
		switch (context.level) {
			case None | Profiling:
				if (expr == null) {
					return {expr: EBlock([]), pos: Context.currentPos()};
				}
				var exprs:Array<Expr> = exprsFromBlock(expr);
				return {expr: EBlock(exprs), pos: expr.pos};
			case Coverage:
			case Both:
		}
		var branchInfo:BranchInfo = if (expr == null) {
			new BranchInfo(coverageContext.nextId(), branchesInfo.location, branchesInfo.startLine, branchesInfo.endLine);
		} else {
			var location:Location = PositionTools.toLocation(expr.pos);
			new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.start.line);
		}
		branchesInfo.addBranch(branchInfo);
		var covExpr:Expr = macro instrument.coverage.CoverageContext.logBranch($v{branchInfo.id});

		if (expr == null) {
			return covExpr;
		}
		var exprs:Array<Expr> = exprsFromBlock(expr);
		exprs.unshift(covExpr);

		return {expr: EBlock(exprs), pos: expr.pos};
	}

	static function coverBoolCondition(expr:Expr, branchesInfo:BranchesInfo):Expr {
		switch (context.level) {
			case None | Profiling:
				var exprs:Array<Expr> = exprsFromBlock(expr);
				return {expr: EBlock(exprs), pos: expr.pos};
			case Coverage:
			case Both:
		}
		var location:Location = PositionTools.toLocation(expr.pos);
		var branchTrue:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		var branchFalse:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		branchesInfo.addBranch(branchTrue);
		branchesInfo.addBranch(branchFalse);

		var varExpr:Expr = {
			expr: EVars([
				{name: "_instrumentValue", type: null, expr: instrumentExpr(ensureBlockExpr(expr))}
			]),
			pos: expr.pos
		};
		var trueExpr:Expr = macro {instrument.coverage.CoverageContext.logBranch($v{branchTrue.id}); _instrumentValue;}
		var falseExpr:Expr = macro {instrument.coverage.CoverageContext.logBranch($v{branchFalse.id}); cast false;}

		var ifExpr:Expr = {expr: EIf(macro cast _instrumentValue, trueExpr, falseExpr), pos: expr.pos};
		return {expr: EBlock([varExpr, ifExpr]), pos: expr.pos};
	}

	static function coverWhileCondition(cond:Expr, bodyExpr:Expr, normalWhile:Bool, branchesInfo:BranchesInfo):Expr {
		switch (context.level) {
			case None | Profiling:
				cond = {expr: EBlock(exprsFromBlock(cond)), pos: cond.pos};
				bodyExpr = {expr: EBlock(exprsFromBlock(bodyExpr)), pos: bodyExpr.pos};
				return {expr: EWhile(cond, bodyExpr, normalWhile), pos: cond.pos};
			case Coverage:
			case Both:
		}
		var location:Location = PositionTools.toLocation(cond.pos);
		var branchTrue:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		var branchFalse:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		branchesInfo.addBranch(branchTrue);
		branchesInfo.addBranch(branchFalse);

		bodyExpr = instrumentExpr(ensureBlockExpr(bodyExpr));

		var varExpr:Expr = {
			expr: EVars([
				{name: "_instrumentValue", type: null, expr: instrumentExpr(ensureBlockExpr(cond))}
			]),
			pos: cond.pos
		};
		var trueExpr:Expr = {
			expr: EBlock([
				macro {
					instrument.coverage.CoverageContext.logBranch($v{branchTrue.id});
				},
				macro true
			]),
			pos: cond.pos
		}
		var falseExpr:Expr = {
			expr: EBlock([
				macro {
					instrument.coverage.CoverageContext.logBranch($v{branchFalse.id});
				},
				macro false
			]),
			pos: cond.pos
		}
		var ifExpr:Expr = {expr: EIf(macro cast _instrumentValue, trueExpr, falseExpr), pos: cond.pos};
		var condBlock = {expr: EBlock([varExpr, ifExpr]), pos: cond.pos};
		return {expr: EWhile(condBlock, bodyExpr, normalWhile), pos: cond.pos};
	}

	static function coverIfCondition(cond:Expr, ifExpr:Expr, elseExpr:Null<Expr>, branchesInfo:BranchesInfo):Expr {
		switch (context.level) {
			case None | Profiling:
				cond = {expr: EBlock(exprsFromBlock(cond)), pos: cond.pos};
				ifExpr = {expr: EBlock(exprsFromBlock(ifExpr)), pos: ifExpr.pos};
				if (elseExpr != null) {
					elseExpr = {expr: EBlock(exprsFromBlock(elseExpr)), pos: elseExpr.pos};
				}

				return {expr: EIf(cond, ifExpr, elseExpr), pos: cond.pos};
			case Coverage:
			case Both:
		}
		var location:Location = PositionTools.toLocation(cond.pos);
		var branchTrue:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		var branchFalse:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		branchesInfo.addBranch(branchTrue);
		branchesInfo.addBranch(branchFalse);

		var ifReturnNoElse:Bool = false;
		if (elseExpr == null) {
			if (hasAllReturns(ifExpr)) {
				ifReturnNoElse = true;
			}
			elseExpr = {expr: EConst(CIdent("null")), pos: cond.pos};
		} else {
			elseExpr = instrumentExpr(ensureBlockExpr(elseExpr));
		}
		ifExpr = instrumentExpr(ensureBlockExpr(ifExpr));
		var varExpr:Expr = {
			expr: EVars([
				{name: "_instrumentValue", type: null, expr: instrumentExpr(ensureBlockExpr(cond))}
			]),
			pos: cond.pos
		};
		var trueExpr:Expr = {
			expr: EBlock(addExprOrBlock(ifExpr, [
				macro instrument.coverage.CoverageContext.logBranch($v{branchTrue.id}),
				logExpression(ifExpr)
			])),
			pos: ifExpr.pos
		};
		var falseExpr:Expr = if (ifReturnNoElse) null else {
			expr: EBlock(addExprOrBlock(elseExpr, [
				macro instrument.coverage.CoverageContext.logBranch($v{branchFalse.id}),
				logExpression(elseExpr)
			])),
			pos: elseExpr.pos
		};
		var ifExpr:Expr = {expr: EIf(macro cast _instrumentValue, trueExpr, falseExpr), pos: cond.pos};
		var exprs:Array<Expr> = [varExpr, ifExpr];
		if (ifReturnNoElse) {
			exprs.push(macro instrument.coverage.CoverageContext.logBranch($v{branchFalse.id}));
		}
		return {expr: EBlock(exprs), pos: cond.pos};
	}

	static function coverTernaryCondition(cond:Expr, ifExpr:Expr, elseExpr:Expr, branchesInfo:BranchesInfo):Expr {
		switch (context.level) {
			case None | Profiling:
				cond = {expr: EBlock(exprsFromBlock(cond)), pos: cond.pos};
				ifExpr = {expr: EBlock(exprsFromBlock(ifExpr)), pos: ifExpr.pos};
				elseExpr = {expr: EBlock(exprsFromBlock(elseExpr)), pos: elseExpr.pos};

				return {expr: ETernary(cond, ifExpr, elseExpr), pos: cond.pos};
			case Coverage:
			case Both:
		}
		var location:Location = PositionTools.toLocation(cond.pos);
		var branchTrue:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		var branchFalse:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		branchesInfo.addBranch(branchTrue);
		branchesInfo.addBranch(branchFalse);

		var varExpr:Expr = {
			expr: EVars([
				{name: "_instrumentValue", type: null, expr: instrumentExpr(ensureBlockExpr(cond))}
			]),
			pos: cond.pos
		};
		var trueExpr:Expr = {
			expr: EBlock([
				macro {
					instrument.coverage.CoverageContext.logBranch($v{branchTrue.id});
				},
				ifExpr
			]),
			pos: ifExpr.pos
		}
		var falseExpr:Expr = {
			expr: EBlock([
				macro {
					instrument.coverage.CoverageContext.logBranch($v{branchFalse.id});
				},
				elseExpr
			]),
			pos: elseExpr.pos
		}

		var ternaryExpr:Expr = {expr: ETernary(macro cast _instrumentValue, trueExpr, falseExpr), pos: cond.pos};
		return {expr: EBlock([varExpr, ternaryExpr]), pos: cond.pos};
	}

	static function coverCondition(expr:Expr, branchesInfo:BranchesInfo):Expr {
		switch (context.level) {
			case None | Profiling:
				return expr;
			case Coverage:
			case Both:
		}
		var location:Location = PositionTools.toLocation(expr.pos);
		var branchTrue:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		var branchFalse:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		branchesInfo.addBranch(branchTrue);
		branchesInfo.addBranch(branchFalse);

		var trueExpr:Expr = macro {instrument.coverage.CoverageContext.logBranch($v{branchTrue.id}); true;}
		var falseExpr:Expr = macro {instrument.coverage.CoverageContext.logBranch($v{branchFalse.id}); false;}

		return {expr: EIf(expr, trueExpr, falseExpr), pos: expr.pos};
	}

	#if (haxe >= version("4.3.0"))
	static function coverNullCoal(exprLeft:Expr, exprRight:Expr, branchesInfo:BranchesInfo):Expr {
		switch (context.level) {
			case None | Profiling:
				exprLeft = {expr: EBlock(exprsFromBlock(exprLeft)), pos: exprLeft.pos};
				exprRight = {expr: EBlock(exprsFromBlock(exprRight)), pos: exprRight.pos};
				return {expr: EBinop(OpNullCoal, exprLeft, exprRight), pos: exprLeft.pos};
			case Coverage:
			case Both:
		}
		var location:Location = PositionTools.toLocation(exprLeft.pos);
		var branchTrue:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		var branchFalse:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		branchesInfo.addBranch(branchTrue);
		branchesInfo.addBranch(branchFalse);

		var varExpr:Expr = {
			expr: EVars([
				{
					name: "_instrumentValue",
					type: null,
					expr: instrumentExpr(ensureBlockExpr(exprLeft))
				},
			]),
			pos: exprLeft.pos
		};
		var condExpr:Expr = {
			expr: EBinop(OpNotEq, {expr: EConst(CIdent("_instrumentValue")), pos: exprLeft.pos}, {expr: EConst(CIdent("null")), pos: exprLeft.pos}),
			pos: exprLeft.pos
		};

		var trueExpr:Expr = macro {
			instrument.coverage.CoverageContext.logBranch($v{branchTrue.id});
			_instrumentValue;
		}
		var falseExpr:Expr = {
			expr: EBlock([
				macro {instrument.coverage.CoverageContext.logBranch($v{branchFalse.id});},
				logExpression(exprRight),
				macro cast null
			]),
			pos: exprLeft.pos
		}
		var ifExpr:Expr = {expr: EIf(condExpr, trueExpr, falseExpr), pos: exprLeft.pos};
		var block:Expr = {expr: EBlock([varExpr, ifExpr]), pos: exprLeft.pos};
		return {expr: EBinop(OpNullCoal, {expr: ECast(block, null), pos: exprLeft.pos}, exprRight), pos: exprLeft.pos};
	}

	static function coverSafeField(expr:Expr, field:String, branchesInfo:BranchesInfo):Expr {
		switch (context.level) {
			case None | Profiling:
				expr = {expr: EBlock(exprsFromBlock(expr)), pos: expr.pos};
				return {expr: EField(expr, field, Safe), pos: expr.pos};
			case Coverage:
			case Both:
		}

		var location:Location = PositionTools.toLocation(expr.pos);
		var branchTrue:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		var branchFalse:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		branchesInfo.addBranch(branchTrue);
		branchesInfo.addBranch(branchFalse);

		// var fieldAccess = instrumentExpr(ensureBlockExpr(expr));
		// expr = instrumentExpr(ensureBlockExpr(expr));

		var varExpr:Expr = {
			expr: EVars([
				{
					name: "_instrumentValue",
					expr: {expr: EField(expr, field, Safe), pos: expr.pos}
				}
			]),
			pos: expr.pos
		};
		//
		// 		var varExpr:Expr = {
		// 			expr: EVars([{name: "_instrumentValue", type: null, expr: fieldAccess}]),
		// 			pos: expr.pos
		// 		};
		var condExpr:Expr = {
			expr: EBinop(OpNotEq, {expr: EConst(CIdent("_instrumentValue")), pos: expr.pos}, {expr: EConst(CIdent("null")), pos: expr.pos}),
			pos: expr.pos
		};

		var trueExpr:Expr = {
			expr: EBlock([
				macro {instrument.coverage.CoverageContext.logBranch($v{branchTrue.id});},
				macro _instrumentValue // {expr: EConst(CIdent("_instrumentValue")), pos: expr.pos}
				// {expr: EField(expr, field, Safe), pos: expr.pos}
				// {expr: EField({expr: EConst(CIdent("_instrumentValue")), pos: expr.pos}, field, Normal), pos: expr.pos}
			]),
			pos: expr.pos
		};
		var falseExpr:Expr = macro {
			instrument.coverage.CoverageContext.logBranch($v{branchFalse.id});
			null;
		};

		var ifExpr:Expr = {
			// expr: ECast({expr: EIf(condExpr, trueExpr, falseExpr), pos: expr.pos}, null),
			expr: EIf(condExpr, trueExpr, falseExpr),
			pos: expr.pos
		};

		var func:Expr = {
			expr: EFunction(FNamed("_safeNav", false), {
				args: [],
				expr: {
					expr: EBlock([varExpr, {expr: EReturn(ifExpr), pos: expr.pos}]),
					pos: expr.pos
				}
			}),
			pos: expr.pos
		};

		return {
			expr: EBlock([
				func,
				{expr: ECall({expr: EConst(CIdent("_safeNav")), pos: expr.pos}, []), pos: expr.pos}
			]),
			pos: expr.pos
		};
		// return {
		// 	// expr: EField({
		// 	expr: EBlock([varExpr, ifExpr]),
		// 	// pos: expr.pos
		// 	// }, field, Safe),
		// 	pos: expr.pos
		// };
	}
	#end

	static function hasAllReturns(expr:Expr):Bool {
		if ((expr == null) || (expr.expr == null)) {
			return false;
		}
		return switch (expr.expr) {
			case EBlock(exprs):
				for (e in exprs) {
					if (hasAllReturns(e)) {
						return true;
					}
				}
				false;
			case EIf(econd, eif, eelse):
				var result:Bool = hasAllReturns(eif);
				if (eelse != null) {
					result = result && hasAllReturns(eelse);
				} else {
					return false;
				}
				result;
			case ESwitch(e, cases, edef):
				var result:Bool = true;
				if (edef != null) {
					result = hasAllReturns(edef);
				}
				for (c in cases) {
					result = result && hasAllReturns(c.expr);
				}
				result;
			case ETry(e, catches):
				var result:Bool = hasAllReturns(e);
				for (c in catches) {
					result = result && hasAllReturns(c.expr);
				}
				result;
			case EUntyped(e):
				hasAllReturns(e);
			case EReturn(e):
				true;
			case EThrow(e):
				true;
			case EMeta(s, e):
				hasAllReturns(e);
			default:
				false;
		}
	}

	static function replaceReturn(expr:Expr):Expr {
		switch (context.level) {
			case None | Coverage:
				if (expr == null) {
					return {expr: EReturn(null), pos: Context.currentPos()};
				}
				return {expr: EReturn(instrumentExpr(expr)), pos: expr.pos};
			case Profiling:
			case Both:
		}
		if (expr == null) {
			return relocateExpr(macro {
				instrument.profiler.Profiler.exitFunction(__profiler__id__);
				return;
			}, Context.currentPos());
		}
		if ((context.fieldName == "new") || (context.fieldName == "_new")) {
			return relocateExpr(macro {
				instrument.profiler.Profiler.exitFunction(__profiler__id__);
				return $expr;
			}, expr.pos);
		}
		return relocateExpr(macro {
			var result = ${instrumentExpr(expr)};
			instrument.profiler.Profiler.exitFunction(__profiler__id__);
			return cast result;
		}, expr.pos);
	}

	static function replaceThrow(expr:Expr):Expr {
		switch (context.level) {
			case None | Coverage:
				return {expr: EThrow(instrumentExpr(expr)), pos: expr.pos};
			case Profiling:
			case Both:
		}
		return (macro {
			var result = ${instrumentExpr(expr)};
			instrument.profiler.Profiler.exitFunction(__profiler__id__);
			throw result;
		});
	}

	static function replaceSysExit(expr:Expr):Expr {
		return (macro {
			instrument.Instrumentation.endInstrumentation(cast $v{instrument.Instrumentation.level});
			Sys.exit(${expr});
		});
	}

	static function sysExitField():Null<Array<Field>> {
		if (Context.defined(DISPLAY)) {
			return null;
		}
		var ref:Ref<ClassType> = Context.getLocalClass();
		if (ref == null) {
			return null;
		}
		var cls:ClassType = ref.get();
		if (cls.isInterface || cls.name == null) {
			return null;
		}
		var fields:Array<Field> = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "exit":
					hookExit(field);
				case _:
			}
		}
		return fields;
	}

	static function hookExit(field:Field) {
		var endProfiler:Expr = macro instrument.Instrumentation.endInstrumentation(cast $v{instrument.Instrumentation.level});

		switch (field.kind) {
			case FVar(t, e):
			case FFun(f):
				if (f.expr == null) {
					return;
				}
				switch (f.expr.expr) {
					case EBlock(exprs):
						exprs.unshift(endProfiler);
					case _:
				}
			case FProp(get, set, t, e):
		}
	}

	static function entrypointRunField():Null<Array<Field>> {
		if (Context.defined(DISPLAY)) {
			return null;
		}
		var ref:Ref<ClassType> = Context.getLocalClass();
		if (ref == null) {
			return null;
		}
		var cls:ClassType = ref.get();
		if (cls.isInterface || cls.name == null) {
			return null;
		}
		var fields:Array<Field> = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "run":
					hookEntrypointRun(field);
				case _:
			}
		}
		return fields;
	}

	static function hookEntrypointRun(field:Field) {
		var endProfiler:Expr = macro instrument.Instrumentation.endInstrumentation(cast $v{instrument.Instrumentation.level});

		switch (field.kind) {
			case FVar(t, e):
			case FFun(f):
				if (f.expr == null) {
					return;
				}
				switch (f.expr.expr) {
					case EBlock(exprs):
						exprs.push(endProfiler);
					case _:
				}
			case FProp(get, set, t, e):
		}
	}

	static function relocateExpr(expr:Expr, pos:Position):Expr {
		expr.pos = pos;
		return expr.map((e) -> relocateExpr(e, pos));
	}

	static function onGenerate(types:Array<Type>) {
		var typeData:String = haxe.Json.stringify(Instrumentation.coverageContext.types);
		Context.addResource(instrument.coverage.Coverage.RESOURCE_NAME, haxe.io.Bytes.ofString(typeData));
		// trace(typeData);
		#if (!instrument_quiet)
		Sys.println("");
		Sys.println("");
		#end
	}
	#end

	macro public static function workspaceFolder():ExprOf<String> {
		return macro $v{Sys.getCwd()};
	}

	public static function endInstrumentation(instrumentLevel:InstrumentationType) {
		switch (instrumentLevel) {
			case None:
			case Coverage:
				instrument.coverage.Coverage.endCoverage();
			case Profiling:
				instrument.profiler.Profiler.endProfiler();
			case Both:
				instrument.profiler.Profiler.endProfiler();
				instrument.coverage.Coverage.endCoverage();
		}
	}

	#if (sys || nodejs)
	public static function workspaceFileName(name:String):String {
		var filePath:String = Path.join([workspaceFolder(), name]);
		var folder:String = Path.directory(filePath);
		if (folder.length > 0) {
			if (!FileSystem.exists(folder)) {
				FileSystem.createDirectory(folder);
			}
		}
		return filePath;
	}
	#end
}
