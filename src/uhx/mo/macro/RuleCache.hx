package uhx.mo.macro;

import hxparse.Pattern;
import hxparse.CharRange;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;
using haxe.macro.ExprTools;
using tink.MacroApi;

class RuleCache {

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
        var local:Type = Context.getLocalType();
        var localName:String = local.getID();
        var fields:Array<Field> = Context.getBuildFields();

        // There is no need to run in display mode.
        if (Context.defined('display') || Context.defined('display-details')) return fields;

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
                                    var value = key.getValue();

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

            // Add back any non matching field.
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

        // Split all enum ctors out into common groups to be ordered properly.
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

        if (Context.defined('debug')) for (field in returnFields) {
            trace( printer.printField( field ) );

        }

        return returnFields;
    }

    //

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