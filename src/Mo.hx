package ;

import haxe.rtti.Meta;
import hxparse.Ruleset;
import haxe.ds.StringMap;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
using haxe.macro.ComplexTypeTools;
#end

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
	
	public static function toCSS(token:Dynamic):String {
		var meta = Meta.getFields( Type.getEnum( token ) );
		var name = Type.enumConstructor( token );
		
		if (Reflect.hasField(meta, name)) {
			if (Reflect.hasField(Reflect.field(meta, name), 'css')) {
				var info = Reflect.field(Reflect.field(meta, name), 'css');
				name = name.substr(info[0]);
				
				if (info[1] != null) {
					for (param in Type.enumParameters( token ) ) {
						if (Reflect.isEnumValue( param )) {
							name += ' ' + toCSS( param );
						}
					}
				}
			}
			
			if (Reflect.hasField(Reflect.field(meta, name), 'split')) {
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
		
		switch (rules) {
			case macro [$a { values } ]:
				for (value in values) switch (value) {
					case macro $rule => $expr:
						results.push( macro @:pos(expr.pos) {rule:$rule, func:function(lexer:hxparse.Lexer) return $expr} );
						
					case _:
						
				}
				
			case _:
				
		}
		
		return macro hxparse.Lexer.buildRuleset([$a { results } ]);
	}
	
}