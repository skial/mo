package uhx.parser;


import haxe.io.Eof;
import byte.ByteData;
import uhx.lexer.Css as CssLexer;
import uhx.lexer.Css.NthExpressions;

class NthExpression {
	
	public function new() {
		
	}
	
	public function toTokens(bytes:ByteData, name:String):NthExpressions {
		var lexer = new CssLexer(bytes, name);
		var tokens = [];
		
		try while ( true ) {
			tokens.push( lexer.token( CssLexer.nthExpression ) );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		//if (tokens.length == 0) return Unknown;
		//trace( bytes, tokens[0] );
		return switch tokens[0] {
			case Notation(a, b, isNegative):
				if (a == 0 && b > 0) {
					Index(b);
					
				} else {
					tokens[0];
					
				}
				
			case _:
				tokens[0];
		}
		
	}
	
}
