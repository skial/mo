package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import uhx.mo.TokenDef;
import haxe.ds.StringMap;

using Std;
using StringTools;
using uhx.lexer.HttpMessageLexer;

/**
 * ...
 * @author Skial Bainn
 */
enum HttpMessageKeywords {
	KwdHeader(n:String, v:String);
	KwdHttp(v:String);
	// Microsoft can return additional sub decimal values. Of course they can.
	KwdStatus(c:Float, s:String);
	KwdSeparator(v:String);
}
 
class HttpMessageLexer extends Lexer {
	
	public var lang:String;
	public var ext:Array<String>;

	public function new(content:ByteData, name:String) {
		name = 'http';
		ext = [''];
		
		super( content, name );
	}
	
	public static var buf = new StringBuf();
	public static var CR:String = '\r';
	public static var LF:String = '\n';
	public static var SP:String = ' ';
	public static var HT:String = '\t';
	public static var DQ:String = '"';
	public static var CTL:String = '\\0|\\a|\\b|' + HT + '|' + LF + '|\\v|\\f|' + CR + '|\\e';
	public static var DIGIT:String = '0-9';
	public static var CRLF:String = CR + LF;
	public static var LWS:String = '[' + CRLF + ']?[' + SP + HT + ']+';
	public static var HEX:String = '[A-Fa-F' + DIGIT + ']';
	public static var CHARS:String = 'a-zA-Z' + DIGIT + '!#$%&\'\\*-.^_`~';
	public static var NAME:String = '[' + CHARS + LF + ']+';
	public static var separators:Array<String> = ['\\(', '\\)', '<', '>', '@', ',', ';', ':', '\\', DQ, '/', '\\[', '\\]', '\\?', '=', '{', '}', SP, HT];
	public static var SEP:String = separators.join('|');
	public static var VALUE:String = function() {
		var copy = CHARS + separators.join('');
		for (invalid in CTL.split('|').concat( ['\\(', '\\)'] )) {
			copy = copy.replace( invalid, '' );
		}
		return '[$copy]+';
	}();
	
	public static function mk<T>(lex:Lexer, tok:TokenDef<T>):Token<T> {
		return new Token<T>(tok, lex.curPos());
	}
	
	public static var root = Mo.rules( [
		LF => mk(lexer, Newline),
		CR => mk(lexer, Carriage),
		HT => mk(lexer, Tab(lexer.current.length)),
		SP + '+' => mk(lexer, Space(lexer.current.length)),
		DQ => mk(lexer, DoubleQuote),
		SEP => {
			var sep = lexer.current;
			switch (sep) {
				case _.check() => true: 
					callback();
					check = function(v) return false;
				case _:
					
			}
			return mk(lexer, Keyword( KwdSeparator( sep ) ));
		},
		NAME => {
			var result = switch (lexer.current) {
				case _.toLowerCase() => 'http':
					buf = new StringBuf();
					try lexer.token( response ) catch (e:Eof) throw e;
					mk(lexer, Keyword( KwdHttp( buf.toString() ) ));
					
				case _.isStatusCode() => true:
					buf = new StringBuf();
					var code = lexer.current.parseFloat();
					try lexer.token( response ) catch (e:Eof) throw e;
					mk(lexer, Keyword( KwdStatus( code, buf.toString() ) ));
					
				case _:
					var name = lexer.current;
					buf = new StringBuf();
					check = function(v) return v == ':';
					callback = function() {
						lexer.token( value );
					}
					lexer.token( root );
					mk(lexer, Keyword( KwdHeader( name.trim(), buf.toString() ) ) );
			}
			return result;
		},
	] );
	
	public static var response = Mo.rules( [
		SEP => lexer.token( response ),
		NAME => buf.add( lexer.current ),
	] );
	
	public static var value = Mo.rules( [
		SEP => lexer.token( value ),
		VALUE => buf.add( lexer.current ),
	] );
	
	// Internal
	
	private static var check:String->Bool = function(v) return false;
	private static var callback:Void->Void;
	
	private static function isStatusCode(v:String):Bool {
		var f = v.parseFloat();
		return f >= 100 && f <= 600;
	}
	
}