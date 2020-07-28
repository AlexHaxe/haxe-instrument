package instrument;

import haxe.io.Path;
import sys.FileSystem;
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
		Sys.print("Instrumenting ");
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
			default:
				return null;
		}

		switch (context.level) {
			case None:
				return null;
			case Coverage | Profiling | Both:
		}
		Sys.print(".");

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
				if (!field.access.contains(AExtern) && !context.isAbstract) {
					field.access.remove(AInline);
					context.isInline = false;
				}
				initFieldContext(field);
				context.allReturns = hasAllReturns(fun.expr);
				#if debug_instrumentation
				trace(BEFORE + fun.expr.toString());
				#end
				fun.expr = instrumentExpr(ensureBlockExpr(fun.expr));
				fun.expr = instrumentFieldExpr(fun.expr, true, isMain);
				#if debug_instrumentation
				trace(AFTER + fun.expr.toString());
				#end
			case FVar(type, expr) if (expr != null):
				if (context.isAbstract || context.isInline) {
					return;
				}
				initFieldContext(field);
				#if debug_instrumentation
				trace(BEFORE + expr.toString());
				#end
				expr = instrumentExpr(ensureBlockValueExpr(expr));
				expr = instrumentFieldExpr(expr, false, false);
				#if debug_instrumentation
				trace(AFTER + expr.toString());
				#end
				field.kind = FVar(type, expr);
			case FProp(get, set, type, expr) if (expr != null):
				if (context.isAbstract || context.isInline) {
					return;
				}
				initFieldContext(field);
				#if debug_instrumentation
				trace(BEFORE + expr.toString());
				#end
				expr = instrumentExpr(ensureBlockValueExpr(expr));
				expr = instrumentFieldExpr(expr, false, false);
				#if debug_instrumentation
				trace(AFTER + expr.toString());
				#end
				field.kind = FProp(get, set, type, expr);
			default:
		}
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

	static function initFieldContext(field:Field) {
		var location:Location = PositionTools.toLocation(field.pos);
		var fieldInfo:FieldInfo = new FieldInfo(coverageContext.nextId(), field.name, location.locationToString(), location.range.start.line,
			location.range.end.line);
		switch (context.level) {
			case None | Profiling:
			case Coverage | Both:
				context.typeInfo.addField(fieldInfo);
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

		var entry:Expr = macro var __profiler__id__:Int = instrument.profiler.Profiler.enterFunction($v{location.locationToString()}, $v{context.className},
			$v{context.fieldName}, null);
		var exit:Expr = macro instrument.profiler.Profiler.exitFunction(__profiler__id__);
		var covExpr:Expr = macro instrument.coverage.CoverageContext.logExpression($v{context.fieldInfo.id});
		if (withCoverage) {
			exprs.unshift(covExpr);
		}
		if (withProfiler) {
			exprs.unshift(entry);
			if (!context.allReturns) {
				exprs.push(exit);
			}
		}
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
					instrumentedExprs.push(instrumentExpr(e));

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
				econd = coverCondition(instrumentExpr(ensureBlockExpr(econd)), branchesInfo);
				e = instrumentExpr(ensureBlockExpr(e));
				return {expr: EWhile(econd, e, normal), pos: expr.pos};

			case EIf(cond, eif, eelse):
				var branchesInfo:BranchesInfo = makeBranchesInfo(expr);
				cond = coverBoolCondition(cond, branchesInfo);
				eif = instrumentExpr(ensureBlockExpr(eif));
				if (eelse != null) {
					eelse = instrumentExpr(ensureBlockExpr(eelse));
				}
				{expr: EIf(cond, eif, eelse), pos: expr.pos};

			case ETernary(cond, eif, eelse):
				var branchesInfo:BranchesInfo = makeBranchesInfo(expr);
				cond = coverBoolCondition(cond, branchesInfo);
				eif = instrumentExpr(ensureBlockExpr(eif));
				eelse = instrumentExpr(ensureBlockExpr(eelse));
				{expr: ETernary(cond, eif, eelse), pos: expr.pos};

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
				if (context.isInline) {
					if (e != null) {
						// e = instrumentExpr(ensureBlockExpr(e));
					}
					return {expr: EReturn(e), pos: Context.currentPos()};
				}
				replaceReturn(e);

			case EThrow(e):
				if (context.isInline) {
					if (e != null) {
						e = instrumentExpr(ensureBlockExpr(e));
					}
					return {expr: EThrow(e), pos: expr.pos};
				}
				replaceThrow(e);

			case ECall(e, params):
				var instumentedExpr:Expr = expr.map(instrumentExpr);
				switch (e.expr) {
					case EField(e, field):
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

				e = instrumentExpr(ensureBlockExpr(e));
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
						return {expr: EBinop(op, e1, e2), pos: expr.pos};
					case OpEq | OpNotEq | OpGt | OpGte | OpLt | OpLte:
						var branchesInfo:BranchesInfo = makeBranchesInfo(expr);
						e1 = instrumentExpr(ensureBlockExpr(e1));
						e2 = instrumentExpr(ensureBlockExpr(e2));
						return coverCondition({expr: EBinop(op, e1, e2), pos: expr.pos}, branchesInfo);
					default:
				}
				expr.map(instrumentExpr);

			default:
				expr.map(instrumentExpr);
		}
	}

	static function instrumentFunctionExpr(expr:Expr, name:String, allReturn:Bool):Expr {
		var exprs:Array<Expr> = exprsFromBlock(expr);
		switch (context.level) {
			case None | Coverage:
			case Profiling | Both:
				var location:Location = PositionTools.toLocation(expr.pos);
				var entry:Expr = macro var __profiler__id__:Int = instrument.profiler.Profiler.enterFunction($v{location.locationToString()},
					$v{context.className}, $v{name}, null);
				exprs.unshift(entry);
				if (!allReturn) {
					var exit:Expr = macro instrument.profiler.Profiler.exitFunction(__profiler__id__);
					exprs.push(exit);
				}
		}
		return {expr: EBlock(exprs), pos: expr.pos};
	}

	static function logExpression(expr:Expr):Expr {
		var location:Location = PositionTools.toLocation(expr.pos);
		var expressionInfo:ExpressionInfo = new ExpressionInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line,
			location.range.end.line);
		context.fieldInfo.addExpression(expressionInfo);
		return macro instrument.coverage.CoverageContext.logExpression($v{expressionInfo.id});
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
				makeBlock(expr); // this is not an "empty block", it's a empty object declaration.
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
		var location:Location = PositionTools.toLocation(expr.pos);
		var branchesInfo:BranchesInfo = new BranchesInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line,
			location.range.end.line);

		context.fieldInfo.addBranches(branchesInfo);
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
			new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		}
		branchesInfo.addBranch(branchInfo);
		var covExpr:Expr = macro instrument.coverage.CoverageContext.logExpression($v{branchInfo.id});

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
		var branchInfo1:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		var branchInfo2:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		branchesInfo.addBranch(branchInfo1);
		branchesInfo.addBranch(branchInfo2);

		var covExpr1:Expr = macro {instrument.coverage.CoverageContext.logExpression($v{branchInfo1.id}); true;}
		var covExpr2:Expr = macro {instrument.coverage.CoverageContext.logExpression($v{branchInfo2.id}); false;}
		expr = instrumentExpr(ensureBlockExpr(expr));

		return {expr: EIf(expr, covExpr1, covExpr2), pos: expr.pos}
	}

	static function coverCondition(expr:Expr, branchesInfo:BranchesInfo):Expr {
		switch (context.level) {
			case None | Profiling:
				return expr;
			case Coverage:
			case Both:
		}
		var location:Location = PositionTools.toLocation(expr.pos);
		var branchInfo1:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		var branchInfo2:BranchInfo = new BranchInfo(coverageContext.nextId(), location.locationToString(), location.range.start.line, location.range.end.line);
		branchesInfo.addBranch(branchInfo1);
		branchesInfo.addBranch(branchInfo2);

		var covExpr1:Expr = macro {instrument.coverage.CoverageContext.logExpression($v{branchInfo1.id}); true;}
		var covExpr2:Expr = macro {instrument.coverage.CoverageContext.logExpression($v{branchInfo2.id}); false;}

		return {expr: EIf(expr, covExpr1, covExpr2), pos: expr.pos};
	}

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
			return (macro {
				instrument.profiler.Profiler.exitFunction(__profiler__id__);
				return;
			});
		}
		return (macro {
			var result = ${instrumentExpr(expr)};
			instrument.profiler.Profiler.exitFunction(__profiler__id__);
			return cast result;
		});
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

	static function onGenerate(types:Array<Type>) {
		var typeData:String = haxe.Json.stringify(Instrumentation.coverageContext.types);
		Context.addResource(instrument.coverage.Coverage.RESOURCE_NAME, haxe.io.Bytes.ofString(typeData));
		Sys.println("");
		Sys.println("");
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
