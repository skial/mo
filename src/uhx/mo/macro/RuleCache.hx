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
    **/
    @:persistent
    private static var patterns:Map<String, {pattern:Pattern, type:Type}> = [];

    public static function build():Array<Field> {
        var local = Context.getLocalType();
        var localName = local.getID();
        var fields:Array<Field> = Context.getBuildFields();

        var returnFields = [];
        var reconstruct:Map<String, {field:Field, ctype:Null<ComplexType>, expr:Null<Expr>, keys:Array<String>}> = [];

        for (field in fields) {
            var isStatic = false;

            for (access in field.access) {
                if ((isStatic = (access == AStatic))) break;
            }

            if (isStatic) switch field.kind {
                case FVar(ct, e):
                    var keys = [];
                    var rules:Map<String, {field:Field, ctype:Null<ComplexType>, method:Expr}> = [];

                    switch e {
                        case macro Mo.rules( [$a{exprs}] ):
                            for (expr in exprs) switch expr {
                                case macro $key => $func:
                                    var value = key.getValue();

                                    if (keys.lastIndexOf(value) == -1) {
                                        keys.push(value);
                                    }

                                    if (!patterns.exists(value)) {
                                        var pattern = hxparse.LexEngine.parse(value);
                                        // Fill `ranges` with `CharRange` values.
                                        inlineRanges(pattern, local);
                                        patterns.set( value, {pattern:pattern, type:local} );

                                    }

                                    if (!rules.exists(value)) {
                                        rules.set( value, { field: field, ctype:ct, method: func } );

                                    }

                                case _:
                                    trace('failed to match');

                            }

                            if (!reconstruct.exists(localName + field.name)) {
                                reconstruct.set(
                                    localName + field.name, 
                                    {
                                        field:field, 
                                        ctype:ct, 
                                        expr:e, 
                                        keys:keys
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

                                var tmp = (macro class {
                                    public static function $methodName(lexer:$lexerType) $methodBody;
                                });

                                returnFields.push( tmp.fields[0] );

                            }

                            continue;

                        case _:

                    }

                case _:
                
            }

            returnFields.push( field );

        }

        for (key => value in ranges) {
            var rangeName = rangeName(value.range);
            var rangeExpr = rangeExpr(value.range);

            var tmp = (macro class {
                @:noCompletion 
                public static final $rangeName:hxparse.CharRange = $rangeExpr;
            });

            returnFields.push( tmp.fields[0] );

        }

        for (key => value in patterns) {
            var patternName = patternName(key);
            var patternExpr = patternExpr(value.pattern);

            var tmp = (macro class {
                @:noCompletion 
                public static final $patternName:hxparse.Pattern = $patternExpr;
            });

            returnFields.push( tmp.fields[0] );

        }

        for (key => value in reconstruct) {
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

            var eof = macro null; // TODO use existing matched EOF functions.
            var cases = [for (_key in value.keys) {
                var value = patterns.get(_key);
                var access = value.type.getID() + '.' + patternName(_key);
                macro $e{access.resolve()}
            }];
            var funcs = [for (_key in value.keys) {
                macro $i{name + '_' + methodName(localName + _key)}
            }];

            var tmp = (macro class {
                public static final $name = new hxparse.Ruleset<$lexerType, $returnType>(
                    new hxparse.LexEngine([$a{cases}]).firstState(),
                    [$a{funcs}], $eof, $v{localName + '.' + name}
                );
            });

            returnFields.push( tmp.fields[0] );
        }

        for (field in returnFields) {
            if (Context.defined('debug')) {
                trace( printer.printField( field ) );

            }

        }

        return returnFields;
    }

    //

    /*private static function getKey(value:String):String {
        var regex = new EReg("\\0", "g");
        if (regex.match(value)) {
            value = regex.replace(value, '__NUL__');
        }
        return value;
    }*/

    private static function inlineRanges(pattern:Pattern, sourceType:Type):Void {
        switch pattern {
            case Match(values):
                for (value in values) {
                    var key = rangeKey(value);

                    if (!ranges.exists(key)) {
                        ranges.set(key, {range:value, type:sourceType});

                    }

                }

            case Star(p), Plus(p), Group(p):
                inlineRanges(p, sourceType);

            case Next(a, b), Choice(a, b):
                inlineRanges(a, sourceType);
                inlineRanges(b, sourceType);

            case _:

        }
    }

    private static function rangeKey(value:CharRange):String {
        return '' + value.min + ':' + value.max;
    }

    private static function rangeName(range:CharRange):String {
        return 'range${range.min}${range.max}';
    }

    private static function patternName(key:String):String {
        var sig = Context.signature(key);
        sig = sig.substring(sig.length-6, sig.length);
        return 'pattern$sig';
    }

    private static function methodName(key:String):String {
        var sig = Context.signature(key);
        sig = sig.substring(sig.length-6, sig.length);
        return 'method$sig';
    }

    private static function rangeExpr(range:CharRange):Expr {
        return macro { min:$v{range.min}, max:$v{range.max} };
    }

    private static function patternExpr(pattern:Pattern):Expr {
        return switch pattern {
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
                macro hxparse.Pattern.Star($e{patternExpr(p)});

            case Plus(p): 
                macro hxparse.Pattern.Plus($e{patternExpr(p)});

            case Group(p): 
                macro hxparse.Pattern.Group($e{patternExpr(p)});

            case Next(p1, p2): 
                macro hxparse.Pattern.Next($e{patternExpr(p1)}, $e{patternExpr(p2)});

            case Choice(p1, p2): 
                macro hxparse.Pattern.Choice($e{patternExpr(p1)}, $e{patternExpr(p2)});

        }
    }

}