package ;

import uhx.mo.Token;
import hxparse.Lexer;
import haxe.rtti.Meta;
import hxparse.Ruleset;
import haxe.ds.StringMap;
import haxe.macro.Printer;

#if (macro||eval)
import haxe.macro.Type as MType;
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
using haxe.macro.ComplexTypeTools;
#end
using Reflect;
using StringTools;

/**
 * ...
 * @author Skial Bainn
 * Haitian Creole for Words
 */
class Mo {
	
	public static inline function add(buffer:StringBuf, value:String, ?cls:String = ''):Void {
		if (cls != '') cls = ' $cls';
		buffer.add( '<span class="token$cls">$value</span>' );
	}
	
	public static inline function start(buffer:StringBuf, language:String):Void {
		buffer.add( '<pre><code class="language $language">' );
	}
	
	public static inline function end(buffer:StringBuf):Void {
		buffer.add( '</code></pre>' );
	}
	
	/**
	 * This is a quick fix. Just blast everything to it html number.
	 * Ideally it would blast the problem characters into oblivon.
	 * It works.
	 */
	public static function htmlify(value:String):String {
		var result = new StringBuf();
		
		// Converts all ascii values between 32 and 127 to escaped html values.
		// And handle ascii values between 8 and 13 as special.
		for (i in 0...value.length) {
			
			var char = value.charAt( i );
			var code = value.fastCodeAt( i );
			
			if (code > 31 && code < 128) {
				result.add( '&#$code;' );
			} else switch (code) {
				case 8: result.add( '&#92;&#98;' );
				case 9: result.add( '&#92;&#116;' );
				case 10: result.add( '&#92;&#110;' );
				case 11: result.add( '&#92;&#118;' );
				case 12: result.add( '&#92;&#102;' );
				case 13: result.add( '&#92;&#114;' );
				case _: result.add( char );
			}
			
		}
		
		return result.toString();
	}
	
	public static function toCSS(token:EnumValue):String {
		var meta = Meta.getFields( Type.getEnum( token ) );
		var name = Type.enumConstructor( token );
		
		if (meta.hasField( name )) {
			var obj:Dynamic = meta.field( name );
			
			/*if (obj.hasField( 'css' )) {
				var css:Array<Dynamic> = obj.field( 'css' );
				
				if (css.length > 0) name = name.substr( css[0] );
				if (css.length > 1 && Std.is( css[1], Bool ) && cast(css[1], Bool) == true) {
					
					for (param in Type.enumParameters( token ) ) {
						
						if (param.isEnumValue()) {
							name += ' ' + toCSS( param );
						}
						
					}
					
				}
			}*/
			
			if (obj.hasField( 'loop' )) for (param in Type.enumParameters( token )) if (param.isEnumValue()) {
				var css = toCSS( param );
				if (obj.hasField( 'sub' )) css = css.substr( obj.field( 'sub' )[0] );
				name += ' $css';
			}
			
			if (obj.hasField( 'split' )) {
				var parts = name.split('');
				var i = 0;
				
				name = '';
				
				while ( i < parts.length ) {
					
					if (i != 0 && (parts[i].charAt(0) == parts[i].charAt(0).toUpperCase() )) {
						name += ' ';
					}
					
					name += parts[i];
					i++;
					
				}
				
			}
		}
		
		return name.toLowerCase();
	}
	
	public static macro function rules<T>(rules:ExprOf<StringMap<T>>):ExprOf<Ruleset<T>> {
		var results = [];
		
		return if (!Context.defined('display')) {
			switch (rules) {
				case macro [$a { values } ]:
					for (value in values) switch (value) {
						case macro $rule => $expr:
							var res = macro return $expr;
							
							switch (expr.expr) {
								case EBlock(es):
									var copy = es.copy();
									var last = copy.pop();
									copy.push( macro return $last );
									res = { expr:EBlock(copy), pos:expr.pos };
									
								case _:
									
							}
							
							var ltype = Context.getLocalType();
							var ctype = Context.toComplexType(ltype);
							if (!Context.unify( ltype, (macro:Lexer).toType() )) ctype = macro:Lexer;
							results.push( macro cast {rule:$rule, func:function(lexer:$ctype) $res} );
							
						case _:
							
					}
					
				case _:
					
			}
			
			macro hxparse.Lexer.buildRuleset([$a { results } ], $v{Context.getLocalMethod()});
		} else {
			macro hxparse.Lexer.buildRuleset([]);
		}
	}
	
}