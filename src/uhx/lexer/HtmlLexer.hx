package uhx.lexer;

import haxe.io.Eof;
import hxparse.Ruleset.Ruleset;
import hxparse.UnexpectedChar;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import uhx.mo.TokenDef;

using StringTools;

private typedef Tokens = Array<Token<HtmlKeywords>>;

enum HtmlKeywords {
	Instruction(name:String, attributes:Map<String,String>);
	Tag(name:String, attributes:Map<String,String>, tokens:Tokens, selfClosing:Bool, complete:Bool);
}

/**
 * ...
 * @author Skial Bainn
 */
class HtmlLexer extends Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var tagChars = 'a-zA-Z0-9 \\-\\^\\[\\]\\(\\)\\*\\+\\?\\!\\|"\'£$%&_={}:;@~#,/';
	public static var attributeChars = 'a-zA-Z0-9\\-\\^\\[\\]\\(\\)\\*\\+\\?\\!\\|"\'£$%&_{}:;@~#,/';
	
	private static var stack:Array<TokenDef<HtmlKeywords>> = [];
	
	public static var tags = Mo.rules( [
		' ' => Mo.make( lexer, Space(1) ),
		'\n' => Mo.make( lexer, Newline ),
		'\r' => Mo.make( lexer, Carriage ),
		'\t' => Mo.make( lexer, Tab(1) ),
		'<![$tagChars]+>' => {
			var current = lexer.current;
			//var att = mapAttributes(lexer.bytes.readBytes(2, lexer.bytes.length - 1), 'instruction');
			var att = mapAttributes(ByteData.ofString(current.substring(2, current.length - 1), 'instruction');
			var tag = att.get('tag');
			att.remove('tag');
			
			Mo.make( lexer, Keyword( Instruction(tag, att) ) );
		},
		'</[$tagChars]*>' => {
			Mo.make( lexer, Keyword( Tag( lexer.current, [''=>''], [], true, true ) ) );
		},
		'<[^/][$tagChars]*>' => {
			var current = lexer.current.substring(1, lexer.current.length - 1).trim();
			var isVoid = current.endsWith('/');
			
			if (isVoid) current = current.substring(0, current.length - 1);
			
			var att = mapAttributes(ByteData.ofString(current), current);
			var tag = att.get('tag');
			att.remove('tag');
			
			/*var inner = ByteData.alloc(0);
			
			try {
				inner = lexer.token( tillClosing( tag ) );
			} catch (e:Dynamic) {
				inner = null;
				trace(e);
			}
			
			var parsed = parse(inner, tag);*/
			
			//var position = stack.push( Keyword( Tag(tag, _, _, _, _) ) );
			
			var match:Bool = false;
			var parsed:Tokens = [];
			try while (true) {
				var token:Token<HtmlKeywords> = lexer.token( tags );
				
				switch (token.token) {
					case Keyword( Tag( t, _, _, _, _) ) if (t == '</$tag>'): 
						match = true;
						break;
						
					case _:
				}
				
				parsed.push( token );
				
			} catch (e:Dynamic) {
				trace( e );
			}
			
			Mo.make( lexer, Keyword( Tag(tag, att, parsed, isVoid, match) ) );
		},
		'[^</!>]+' => {
			Mo.make( lexer, Const(CString(lexer.current)) );
		}
	] );
	
	/*public static function tillClosing(tag:String) {
		var copy = tag.substring(0);
		return Mo.rules( [
			'[^</!>]*</$copy>' => {
				lexer.bytes.readBytes(0, lexer.bytes.length - '</$copy>'.length);
			},
		] );
	}*/
	
	public static var root = tags;
	
	/*private static function parse(value:ByteData, name:String):Tokens {
		var lexer = new HtmlLexer( value, 'inner' );
		var tokens = [];
		try {
			while (true) {
				tokens.push( lexer.token( tags ) );
			}
		} catch (e:Dynamic) {
			trace(lexer.input.readString(lexer.curPos().pmin, lexer.input.length));
			trace(e);
		}
		return tokens;
	}*/
	
	private static function mapAttributes(value:ByteData, name:String):Map<String,String> { 
		var map = new Map<String,String>();
		var attributes:Ruleset<Void> = null;
		attributes = Mo.rules( [
			'[ \n\r\t]' => lexer.token(attributes),
			'[$attributeChars]+[ ]*=[ ]*("[^"]+"|\'[^\']+\'|[$attributeChars]+)' => {
				var c = lexer.current;
				var p = c.split('=');
				var h = c.charCodeAt(c.length - 1) == '"'.code || c.charCodeAt(c.length - 1) == "'".code;
				var r = h ? p[1].substring(1, p[1].length - 1) : p[1];
				map.set(p[0], r);
			},
			/*'[$attributeChars]+=[$attributeChars]+' => {
				var c = lexer.current;
				var p = c.split('=');
				map.set(p[0], p[1]);
			},*/
			'[$attributeChars]+' => {
				if (!map.exists('tag')) {
					map.set('tag', lexer.current);
				} else {
					map.set(lexer.current, '');
				}
			},
		] );
		
		var lexer = new HtmlLexer( value, '$name-attributes' );
		
		try {
			while (true) {
				lexer.token( attributes );
			}
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return map;
	}
	
}