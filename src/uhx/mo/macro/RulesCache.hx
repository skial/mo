package uhx.mo.macro;

import hxparse.Pattern;
import hxparse.CharRange;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;
using haxe.macro.ExprTools;
using haxe.macro.TypedExprTools;
using tink.CoreApi;
using tink.MacroApi;

enum abstract Defines(String) {
    public var Debug = 'debug';
    public var Display = 'display';
    public var DisplayDetails = 'display-details';
    public var Disable = 'disable.rules.cache';

    @:to public inline function defined():Bool {
        return Context.defined(this);
    }

    @:op(!A) public static inline function boolNot(a:Defines):Bool {
        return !a.defined();
    }

    @:commutative
    @:op(A || B) public static inline function boolOr(a:Defines, b:Bool):Bool {
        return a.defined() || b;
    }

    @:commutative
    @:op(A && B) public static inline function boolAnd(a:Defines, b:Bool):Bool {
        return a.defined() && b;
    }

}

class RulesCache {

    private static final printer = new haxe.macro.Printer();

    /* Map<[Original Rule String], _> */
    /**
        Individual character ranges to be shared.
        ---
        `{ range:CharRange }` The min/max character range.
        `{ type:Type }` The original class that contained the `range`.
    **/
    @:persistent
    private static var ranges:Map<String, {range:CharRange, type:Type}> = [];

    /* Map<[Original Rule String], _> */
    /** 
        Patterns persist across different rule sets to be able to share values.
        --
        `{ pattern:Pattern }` The parsed rule into a `hxparse.Pattern` enum.
        `{ type:Type }` The original class that contained the `pattern`.
        `{ depth:Int }` Used to sort generated pattern static fields.
    **/
    @:persistent
    private static var patterns:Map<String, {pattern:Pattern, type:Type, depth:Int}> = [];

    public static function build():Array<Field> {
        var fields:Array<Field> = Context.getBuildFields();

        // There is no need to run in display mode.
        if (Disable || Display || DisplayDetails) return fields;

        var local:Type = Context.getLocalType();
        var localName:String = local.getID();
        var allImports = Context.getLocalImports();
        var typedImports = allImports.map( i -> Context.getType( i.path.map( p -> p.name ).join('.') ) );
        var returnFields = [];
        var reconstruct:Map<String, {field:Field, ctype:Null<ComplexType>, expr:Null<Expr>, keys:Array<String>, patterns:Array<String>}> = [];

        for (field in fields) {
            var isStatic = false;

            for (access in field.access) {
                if ((isStatic = (access == AStatic))) break;
            }

            if (isStatic) switch field.kind {
                case FVar(ct, e):
                    var keys = [];
                    var patternKeys = [];
                    var rules:Map<String, {field:Field, ctype:Null<ComplexType>, method:Expr}> = [];

                    switch e {
                        case macro Mo.rules( [$a{exprs}] ):
                            for (expr in exprs) switch expr {
                                case macro $key => $func:
                                    var value = extractRule(key, fields, typedImports);
                                    
                                    if (value == null) {
                                        Context.error('Unable to determine value for `${key.toString()}`.', key.pos);
                                    }

                                    if (keys.lastIndexOf(value) == -1) {
                                        keys.push(value);
                                    }

                                    if (!rules.exists(value)) {
                                        var pattern = hxparse.LexEngine.parse(value);
                                        var key = patternName(pattern);

                                        if (patternKeys.indexOf(key) == -1) {
                                            patternKeys.push(key);
                                        }

                                        cacheRanges(pattern, local);
                                        cachePatterns(pattern, local);

                                        rules.set( value, { field: field, ctype:ct, method: func } );

                                    }

                                case _:

                            }

                            if (!reconstruct.exists(field.name)) {
                                reconstruct.set(
                                    field.name, 
                                    {
                                        expr:e, 
                                        ctype:ct, 
                                        keys:keys,
                                        field:field, 
                                        patterns:patternKeys,
                                    }
                                );

                            }

                            // Move inline functions to class `static functons`.
                            for (key => value in rules) {
                                var lexerType = macro:hxparse.Lexer;

                                switch value.ctype {
                                    case TPath({params:params}):

                                        lexerType = switch params[0] {
                                            case TPType(ct): ct;
                                            case _: null;
                                        }

                                    case _:

                                }
                                
                                var methodName = value.field.name + '_' + methodName(localName + key);
                                var methodBody = switch value.method {
                                    case macro $lexer -> $body:
                                        macro return $body;

                                    case macro function($lexer) $body:
                                        body;

                                    case _:
                                        value.method;

                                }

                                var pos = value.field.pos;
                                var tmp = (macro class {
                                    @:pos(pos) public static function $methodName(lexer:$lexerType) $methodBody;
                                });

                                returnFields.push( tmp.fields[0] );

                            }

                            continue;

                        case _:

                    }

                case _:
                
            }

            // Add back original uneditted fields.
            returnFields.push( field );

        }

        for (_ => value in ranges) {
            var rangeName = rangeName(value.range);
            var rangeExpr = rangeExpr(value.range);

            var tmp = (macro class {
                @:noCompletion 
                public static final $rangeName:hxparse.CharRange = $rangeExpr;
            });

            returnFields.push( tmp.fields[0] );

        }

        var empty = [];
        var match = [];
        var single = [];
        var pair = [];

        // Split all enum ctors out into common groups to be ordered.
        for (_ => value in patterns) switch value.pattern {
            case Empty: empty.push(value);
            case Match(_): match.push(value);
            case Star(_), Plus(_), Group(_): single.push(value);
            case Next(_, _), Choice(_, _): pair.push(value);
        }

        var nested = single.concat(pair);
        nested.sort( (a, b) -> a.depth - b.depth );
        
        var ordered = empty.concat(match).concat(nested);
        for (value in ordered) {
            var patternName = patternName(value.pattern);
            var patternExpr = patternExpr(value);

            var tmp = (macro class {
                @:noCompletion 
                public static final $patternName:hxparse.Pattern = $patternExpr;
            });

            returnFields.push( tmp.fields[0] );

        }

        for (_ => value in reconstruct) {
            var name = value.field.name;
            var lexerType = macro:hxparse.Lexer;
            var returnType = null;

            switch value.ctype {
                case TPath({params:params}):

                    lexerType = switch params[0] {
                        case TPType(ct): ct;
                        case _: null;
                    }

                    returnType = switch params[1] {
                        case TPType(ct): ct;
                        case _: null;
                    }

                case _:

            }

            var eof = macro null;
            var methods = [];

            for (_key in value.keys) if (_key == '') {
                eof = macro $i{name + '_' + methodName(localName + _key)}
                
            } else {
                methods.push( macro $i{name + '_' + methodName(localName + _key)} );
            };

            var cases = [for (_key in value.patterns) {
                var value = patterns.get(_key);
                var access = value.type.getID() + '.' + _key;
                macro $e{access.resolve()}
            }];

            var pos = value.field.pos;
            var tmp = (macro class {
                @:pos(pos) public static final $name = new hxparse.Ruleset<$lexerType, $returnType>(
                    new hxparse.LexEngine([$a{cases}]).firstState(),
                    [$a{methods}], $eof, $v{localName + '.' + name}
                );
            });

            returnFields.push( tmp.fields[0] );
        }

        if (Debug) for (field in returnFields) {
            trace( printer.printField( field ) );

        }

        return returnFields;
    }

    //

    private static function extractRule(expr:Expr, fields:Array<Field>, typedImports:Array<Type>):Null<String> {
        switch expr {
            case _.expr => EConst(CString(v)):
                return v;

            case _.expr => EConst(CIdent(id)):
                for (field in fields) if (field.name == id) {
                    switch field.kind {
                        case FVar(ctype, e):
                            return extractRule(e, fields, typedImports);

                        case FProp(get, set, ctype, e):
                            return extractRule(e, fields, typedImports);

                        case FFun(method):

                    }

                    break;
                }

                // Attempt to load the `expr` type and pull a value from a matching field.
                var value = null;
                var warnings = [];
                try {
                    var type = expr.typeof().sure();
                    value = searchType(type, id);
                    if (value != null) return value;

                    warnings.push({msg:'Cannot find field `$id` on type `${type.getID()}`', pos:expr.pos});

                } catch (e:Any) {
                    warnings.push({msg:'Cannot determine type for `${expr.toString()}`', pos:expr.pos});

                }

                // Attempt to find a matching const value in one of the imports.
                try {
                    for (type in typedImports) {
                        value = searchType(type, id);
                        if (value != null) return value;
                        
                    }

                    warnings.push({msg:'Cannot find field `$id` on any local imports.', pos:expr.pos});

                } catch (e:Any) {
                    warnings.push({msg:e, pos:expr.pos});
                }

                for (warning in warnings) {
                    Context.warning(warning.msg, warning.pos);
                }

            case _.expr => EBinop(op, e1, e2):
                var v1:Null<String> = extractRule(e1, fields, typedImports);
                var v2:Null<String> = extractRule(e2, fields, typedImports);

                switch op {
                    case OpAdd: return v1 + v2;
					case _: Context.warning('Unsupported expression `${expr.toString()}`', expr.pos);
                }

            case _:
            
        }

        return null;
    }

    /**
        Loops through the available fields/statics to find a matching field,
        then attempts to pull a string value from the `typedExpr`.
    **/
    private static function searchType(type:Type, id:String):Null<String> {
        var value = null;

        switch type {
            case TInst(_.get() => cls, _):
                for (set in [cls.fields.get(), cls.statics.get()]) {
                    value = extractTypedRule(id, set);
                    if (value != null) return value;
                }

            case TAbstract(_.get() => abs, _):
                var impl = abs.impl == null ? null : abs.impl.get();

                if (impl != null) {
                    for (set in [impl.fields.get(), impl.statics.get()]) {
                        value = extractTypedRule(id, set);
                        if (value != null) return value;
                    }

                }

            case _:

        }

        return null;
    }

    /**
        Attempts to extract a string value from a matching fields `typedExpr`.
    **/
    private static function extractTypedRule(name:String, fields:Array<ClassField>):Null<String> {
        var value = null;

        for (field in fields) if (field.name == name) {
            var typedExpr = field.expr();

            if (typedExpr != null) {
                extractTypedExprRule(typedExpr).handle( o -> switch o {
                    case Success(v): value = v;
                    case Failure(e): Context.warning(e.message, typedExpr.pos);
                } );
                
                if (value != null) return value;
            }

            break;

        }

        return null;
    }

    /**
        Attempts to extract a string value from a `typedExpr`.
    **/
    private static function extractTypedExprRule(expr:TypedExpr, ?trigger:PromiseTrigger<String>):Promise<String> {
        var trigger:PromiseTrigger<String> = trigger == null ? Promise.trigger() : trigger;

        switch expr {
            case _.expr => TConst(TString(v)): 
                trigger.resolve(v);

            case _:
                expr.iter( extractTypedExprRule.bind(_, trigger) );
                trigger.reject(Error.withData(NotFound, 'Unable to find const string.', expr));

        }
        return trigger.asPromise();
    }

    private static function rangeKey(value:CharRange):String {
        return '' + value.min + ':' + value.max;
    }

    private static function rangeName(range:CharRange):String {
        return 'range${range.min}${range.max}';
    }

    private static function patternName(pattern:Pattern):String {
        var sig:String = Context.signature(pattern);
        sig = sig.substring(sig.length-6, sig.length);
        return '${pattern.getName()}$sig';
    }

    private static function methodName(key:String):String {
        var sig:String = Context.signature(key);
        sig = sig.substring(sig.length-6, sig.length);
        return 'method$sig';
    }

    private static function rangeExpr(range:CharRange):Expr {
        return macro { min:$v{range.min}, max:$v{range.max} };
    }

    private static function generatePatternAccess(p:Pattern):String {
        var key = patternName(p);
        var info = patterns.get(key);
        var access = info.type.getID() + '.' + key;
        return access;
    }

    private static function cacheRanges(pattern:Pattern, sourceType:Type):Void {
        switch pattern {
            case Match(values):
                for (value in values) {
                    var key = rangeKey(value);

                    if (!ranges.exists(key)) {
                        ranges.set(key, {range:value, type:sourceType});

                    }

                }

            case Star(p), Plus(p), Group(p):
                cacheRanges(p, sourceType);

            case Next(a, b), Choice(a, b):
                cacheRanges(a, sourceType);
                cacheRanges(b, sourceType);

            case Empty:

        }
    }

    private static function patternExpr(v:{pattern:Pattern, type:Type, depth:Int}):Expr {
        return switch v.pattern {
            case Empty: 
                macro hxparse.Pattern.Empty;

            case Match(c): 
                var array = [for (v in c) {
                    var key = rangeKey(v);
                    var value = ranges.get(key);
                    var access = value.type.getID() + '.' + rangeName(v);
                    macro $e{access.resolve()};
                }];
                macro hxparse.Pattern.Match([$a{ array }]);

            case Star(p):
                var access = generatePatternAccess(p);
                macro hxparse.Pattern.Star($e{access.resolve()});

            case Plus(p):
                var access = generatePatternAccess(p);
                macro hxparse.Pattern.Plus($e{access.resolve()});

            case Group(p): 
                var access = generatePatternAccess(p);
                macro hxparse.Pattern.Group($e{access.resolve()});

            case Next(p1, p2):
                var access1 = generatePatternAccess(p1);
                var access2 = generatePatternAccess(p2);
                macro hxparse.Pattern.Next($e{access1.resolve()}, $e{access2.resolve()});

            case Choice(p1, p2):
                var access1 = generatePatternAccess(p1);
                var access2 = generatePatternAccess(p2);
                macro hxparse.Pattern.Choice($e{access1.resolve()}, $e{access2.resolve()});

        }

    }

    private static function cachePatterns(pattern:Pattern, sourceType:Type, depth:Int = 0):Int {
        var key = patternName(pattern);

        /**
        I'm not happy with the way `depth` is determined. 
        But its currently working.
        **/

        if (!patterns.exists(key)) {
            patterns.set( key, {
                pattern: pattern,
                type: sourceType,
                depth: 0
            } );

            switch pattern {
                case Empty:
                case Match(_):
                case Star(p), Plus(p), Group(p): 
                    depth += cachePatterns(p, sourceType, depth+1);

                case Next(p1, p2), Choice(p1, p2): 
                    depth += cachePatterns(p1, sourceType, depth+1);
                    depth += cachePatterns(p2, sourceType, depth+1);

            }

            var info = patterns.get(key);
            info.depth = depth;
            patterns.set(key, info);

        } else {
            var info = patterns.get(key);
            depth = info.depth;

        }

        return depth;
    }

}