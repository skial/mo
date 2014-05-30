package ;

import uhx.mo.Token;
import byte.ByteData;
import haxe.ds.StringMap;
import uhx.lexer.CssParser;
import uhx.lexer.HaxeParser;
import uhx.lexer.HttpMessageParser;
import uhx.lexer.MarkdownParser;

/**
 * ...
 * @author Skial Bainn
 */
typedef Parser = {
	function printString(token:Token<EnumValue>):String;
	function printHTML(token:Token<EnumValue>, ?tag:String):String;
	function toTokens(input:ByteData, name:String):Iterable<Token<EnumValue>>;
}
 
class Lang {

	private static var cssParser:CssParser = new CssParser();
	private static var hxParser:HaxeParser = new HaxeParser();
	private static var mdParser:MarkdownParser = new MarkdownParser();
	private static var httpParser:HttpMessageParser = new HttpMessageParser();
	
	public static var list:StringMap<Parser> = cast [
	'haxe' => cast hxParser, 'hx' => cast hxParser,
	'markdown' => cast mdParser, 'md' => cast mdParser,
	'css' => cast cssParser, 'http' => cast httpParser,
	];
	public static var uage:StringMap<Parser> = list;
	
}