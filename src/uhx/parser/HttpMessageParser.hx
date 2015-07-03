package uhx.lexer;

import uhx.mo.Token;
import byte.ByteData;
import haxe.ds.StringMap;
import uhx.lexer.HttpMessageLexer;

using Mo;
using StringTools;

/**
 * ...
 * @author Skial Bainn
 */
class HttpMessageParser {
	
	private var lexer:HttpMessageLexer;

	public function new() {
		
	}
	
	public function toTokens(input:ByteData, name:String):Array<Token<HttpMessageKeywords>> {
		var results = [];
		
		lexer = new HttpMessageLexer( input, name );
		
		try while (true) {
			var token = lexer.token( HttpMessageLexer.root );
			results.push( token );
			
		} catch (e:Dynamic) { }
		
		return results;
	}
	
	public function toMap(tokens:Array<Token<HttpMessageKeywords>>):StringMap<String> {
		var result = new StringMap<String>();
		var current = null;
		
		try for (token in tokens) {
			
			switch (token) {
				case Keyword( KwdHttp( version ) ): 
					result.set( 'http', version );
					
				case Keyword( KwdStatus(code, status) ):
					result.set( 'code', '' + code );
					result.set( 'status', status );
					
				case Keyword( KwdHeader( name, value ) ):
					result.set( name.toLowerCase(), value.trim() );
					
				case _:
					
					
			}
			
		} catch (e:Dynamic) { }
		
		return result;
	}
	
	public function printString(token:Token<HttpMessageKeywords>):String {
		return switch (token) {
			case Tab(n): [for (i in 0...n) '\t'].join('');
			case Space(n): [for (i in 0...n) ' '].join('');
			case Newline: '\n';
			case Carriage: '\r';
			case DoubleQuote: '"';
			case Keyword(KwdHttp(v)): 'http $v';
			case Keyword(KwdStatus(c, s)): '$c $s';
			case Keyword(KwdHeader(k, v)): '$k:$v';
			case _: '';
		}
	}
	
	public function printHTML(token:Token<HttpMessageKeywords>, ?tag:String = 'span'):String {
		var name = token.toCSS();
		var result = new StringBuf();
		
		switch (token) {
			case Keyword(KwdHttp(v)): 
				result.add( '<$tag class="$name">http</$tag>' );
				result.add( '<$tag class="space"> </$tag>' );
				result.add( '<$tag class="version">$v</$tag>' );
				
			case Keyword(KwdStatus(c, s)):
				result.add( '<$tag class="$name code">$c</$tag>' );
				result.add( '<$tag class="space"> </$tag>' );
				result.add( '<$tag class="$name message">$s</$tag>' );
				
			case Keyword(KwdHeader(k, v)):
				result.add( '<$tag class="$name key">$k</$tag>' );
				result.add( '<$tag class="separator">:</$tag>' );
				result.add( '<$tag class="$name value">$v</$tag>' );
				
			case _:
				result.add( '<$tag class="$name">' + printString( token ) + '</$tag>' );
				
		}
		
		return result.toString();
	}
	
}