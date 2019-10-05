package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import hxparse.Ruleset;
import haxe.ds.StringMap;
import uhx.lexer.Consts.*;
//import uhx.lexer.Consts.Consts2;

using Std;
using StringTools;
using uhx.lexer.Consts;	// imports sub type `Consts2` values into scope.
using uhx.lexer.HttpMessage;

/**
 * ...
 * @author Skial Bainn
 */
enum HttpMessageKeywords {
	@css Header(n:String, v:String);
	@css Http(v:String);
	// Microsoft can return additional sub decimal values.
	@css Status(c:Float, s:String);
	@css Separator(v:String);
}
 
class HttpMessage extends Lexer implements uhx.mo.RulesCache {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var buf = new StringBuf();
	/*public static var CR:String = '\r';
	public static var LF:String = '\n';
	public static var HT:String = '\t';*/
	//public static var SP:String = ' ';
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
	public static var VALUE:String = (function() {
		var copy = CHARS + separators.join('');
		for (invalid in CTL.split('|').concat( ['\\(', '\\)'] )) {
			copy = copy.replace( invalid, '' );
		}
		return '[$copy]+';
	})();
	
	public static var root:Ruleset<HttpMessage, Token<HttpMessageKeywords>> = Mo.rules( [
		LF => lexer -> Newline,
		CR => lexer -> Carriage,
		HT => lexer -> Tab(lexer.current.length),
		SP + '+' => lexer -> Space(lexer.current.length),
		DQ => lexer -> DoubleQuote,
		'\\(|\\)|<|>|@|,|;|:|\\|"|/|\\[|\\]|\\?|=|{|}| |\t' => lexer -> {
			var sep = lexer.current;
			if (check( sep )) {
				check = v -> false;
				callback();	
			}
			Keyword( Separator( sep ) );
		},
		NAME => lexer -> {
			var result = switch (lexer.current) {
				case _.toLowerCase() => 'http':
					buf = new StringBuf();
					try lexer.token( response ) catch (e:Eof) throw e;
					Keyword( Http( buf.toString() ) );
					
				case _.isStatusCode() => true:
					buf = new StringBuf();
					var code = lexer.current.parseFloat();
					try lexer.token( response ) catch (e:Eof) throw e;
					Keyword( Status( code, buf.toString() ) );
					
				case _:
					var name = lexer.current;
					buf = new StringBuf();
					check = v -> v == ':';
					callback = function() {
						lexer.token( value );
					}
					lexer.token( root );
					Keyword( Header( name.trim(), buf.toString() ) );
			}
			result;
		},
		'' => lexer -> EOF,
	] );
	
	public static var response:Ruleset<HttpMessage, Void> = Mo.rules( [
		'\\(|\\)|<|>|@|,|;|:|\\|"|/|\\[|\\]|\\?|=|{|}| |\t' => lexer -> lexer.token( response ),
		NAME => lexer -> buf.add( lexer.current ),
	] );
	
	public static var value:Ruleset<HttpMessage, Void> = Mo.rules( [
		'\\(|\\)|<|>|@|,|;|:|\\|"|/|\\[|\\]|\\?|=|{|}| |\t' => lexer -> lexer.token( value ),
		'[a-zA-Z0-9!#$%&\'\\*-.^_`~\\(\\)<>@,;:\\"/\\[\\]\\?={} ]+' => lexer -> buf.add( lexer.current ),
	] );

	@:keep public static var emptyRuleSet:Ruleset<HttpMessage, Void> = Mo.rules( [] );
	
	// Internal
	
	private static var check:String->Bool = function(v) return false;
	private static var callback:Void->Void;
	
	private static function isStatusCode(v:String):Bool {
		var f = v.parseFloat();
		return f >= 100 && f <= 600;
	}
	
}