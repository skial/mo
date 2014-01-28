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
		var iterator = tokens.iterator();
		var current = null;
		
		try for (token in tokens) {
			
			switch (token.token) {
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
		return switch (token.token) {
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
		var name = token.token.toCSS();
		var result = new StringBuf();
		
		switch (token.token) {
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
	
	/*public function toHTML(tokens:Array<Token<HttpMessageKeywords>>):String {
		var result = new StringBuf();
		
		result.start( 'http' );
		
		for (token in tokens) {
			var name = token.token.toCSS();
			
			switch (token.token) {
				case Tab(n): Mo.add( result, [for (i in 0...n) '\t'].join(''), name );
				case Space(n): Mo.add( result, [for (i in 0...n) ' '].join(''), name );
				case Newline: Mo.add( result, '\n', name );
				case Carriage: Mo.add( result, '\r', name );
				case DoubleQuote: Mo.add( result, '"', name );
				case Keyword(KwdHttp(v)): 
					Mo.add( result, 'http', name );
					Mo.add( result, '$v', 'version' );
					
				case Keyword(KwdStatus(c, s)):
					Mo.add( result, '$c', '$name code' );
					Mo.add( result, '$s', '$name message' );
					
				case Keyword(KwdHeader(k, v)):
					Mo.add( result, k, '$name key' );
					Mo.add( result, ':', 'separator' );
					Mo.add( result, v, '$name value' );
					
				case _:
			}
		}
		
		result.end();
		
		return result.toString();
	}
	
	public function toString(tokens:Array<Token<HttpMessageKeywords>>):String {
		var result = new StringBuf();
		
		for (token in tokens) {
			
			switch (token.token) {
				case Tab(n): result.add( [for (i in 0...n) '\t'].join('') );
				case Space(n): result.add( [for (i in 0...n) ' '].join('') );
				case Newline: result.add( '\n' );
				case Carriage: result.add( '\r' );
				case DoubleQuote: result.add( '"' );
				case Keyword(KwdHttp(v)): 
					result.add( 'http' );
					result.add( '$v' );
					
				case Keyword(KwdStatus(c, s)):
					result.add( '$c' );
					result.add( '$s' );
					
				case Keyword(KwdHeader(k, v)):
					result.add( k );
					result.add( ':' );
					result.add( v );
					
				case _:
			}
		}
		
		return result.toString();
	}*/
	
}