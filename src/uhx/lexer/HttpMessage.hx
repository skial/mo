package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import haxe.ds.StringMap;

using Std;
using StringTools;
using uhx.lexer.HttpMessage;

/**
 * ...
 * @author Skial Bainn
 */
enum HttpMessageKeywords {
	@css(3) KwdHeader(n:String, v:String);
	@css(3) KwdHttp(v:String);
	// Microsoft can return additional sub decimal values. Of course they can.
	@css(3) KwdStatus(c:Float, s:String);
	@css(3) KwdSeparator(v:String);
}
 
class HttpMessage extends Lexer {

	public function new(content:ByteData, name:String) {
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
	
	public static var root = Mo.rules( [
		LF => lexer -> Newline,
		CR => lexer -> Carriage,
		HT => lexer -> Tab(lexer.current.length),
		SP + '+' => Space(lexer.current.length),
		DQ => lexer -> DoubleQuote,
		SEP => lexer -> {
			var sep = lexer.current;
			if (check( sep )) {
				check = function(v) return false;
				callback();	
			}
			return Keyword( KwdSeparator( sep ) );
		},
		NAME => lexer -> {
			var result = switch (lexer.current) {
				case _.toLowerCase() => 'http':
					buf = new StringBuf();
					try lexer.token( response ) catch (e:Eof) throw e;
					Keyword( KwdHttp( buf.toString() ) );
					
				case _.isStatusCode() => true:
					buf = new StringBuf();
					var code = lexer.current.parseFloat();
					try lexer.token( response ) catch (e:Eof) throw e;
					Keyword( KwdStatus( code, buf.toString() ) );
					
				case _:
					var name = lexer.current;
					buf = new StringBuf();
					check = function(v) return v == ':';
					callback = function() {
						lexer.token( value );
					}
					lexer.token( root );
					Keyword( KwdHeader( name.trim(), buf.toString() ) );
			}
			return result;
		},
	] );
	
	public static var response = Mo.rules( [
		SEP => lexer -> lexer.token( response ),
		NAME => lexer -> buf.add( lexer.current ),
	] );
	
	public static var value = Mo.rules( [
		SEP => lexer -> lexer.token( value ),
		VALUE => lexer -> buf.add( lexer.current ),
	] );
	
	// Internal
	
	private static var check:String->Bool = function(v) return false;
	private static var callback:Void->Void;
	
	private static function isStatusCode(v:String):Bool {
		var f = v.parseFloat();
		return f >= 100 && f <= 600;
	}
	
}