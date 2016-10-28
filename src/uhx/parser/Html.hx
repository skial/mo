package uhx.parser;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import uhx.lexer.Html.HtmlKeywords;
import uhx.lexer.Html as HtmlLexer;

@:forward private abstract Char(String) from String to String {
	
	public inline function new(v) this = v;
	
	@:op(A++) public inline function increase():Char {
		return this = this + this.charAt(0);
	}
	
	@:op(A--) public inline function decrease():Char {
		return this = this.substr(0, this.length -1);
	}
	
	@:op(A*B) public static function times(a:Char, b:Int):Char {
		return [for (i in 0...b) a.charAt(0)].join('');
	}
	
}

/**
 * ...
 * @author Skial Bainn
 */
class Html {
	
	private var tab:Char = '';

	public function new() {
		
	}
	
	public function toTokens(bytes:ByteData, name:String):Array<Token<HtmlKeywords>> {
		var lexer = new HtmlLexer(bytes, name);
		var tokens = [];
		
		try while ( true ) {
			tokens.push( lexer.token( HtmlLexer.root ) );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			
		}
		
		return tokens;
	}
	
	public function print(tokens:Array<Token<HtmlKeywords>>, ?buf:Null<StringBuf>):StringBuf {
		if (buf == null) {
			buf = new StringBuf();
			tab = '';
			
		}
		
		for (i in 0...tokens.length) switch tokens[i] {
			case Keyword(Tag( ref )):
				if (i != 0) buf.add( '\n' );
				buf.add( '$tab<' + ref.name );
				
				for (key in ref.attributes.keys()) {
					buf.add( ' ' + key + '="' + ref.attributes.get( key ) + '"');
					
				}
				
				if (!ref.selfClosing) {
					buf.add( '>' );
					
					if (ref.tokens.length > 0) {
						buf.add('\n');
						tab++;
						if (tab == '') tab = '\t';
						print( ref.tokens, buf );
						tab--;
						buf.add('\n' + tab);
						
					}
					
					buf.add( '</' + ref.name + '>' );
					
				} else {
					buf.add( ' />' );
					
				}
				
			case Keyword(Text( ref )):
				buf.add( tab + ref.tokens );
				
			case _:
				
		}
		
		return buf;
	}
	
}
