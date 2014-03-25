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
	
	public static var tags = Mo.rules( [
		' ' => Mo.make( lexer, Space(1) ),
		'\n' => Mo.make( lexer, Newline ),
		'\r' => Mo.make( lexer, Carriage ),
		'\t' => Mo.make( lexer, Tab(1) ),
		'<![$tagChars]+>' => {
			var current = lexer.current;
			var att = mapAttributes(current.substring(2, current.length-1), 'instruction');
			var tag = att.get('tag');
			att.remove('tag');
			
			Mo.make( lexer, Keyword( Instruction(tag, att) ) );
		},
		'<[^/][$tagChars]+>' => {
			var current = lexer.current.substring(1, lexer.current.length - 1);
			
			var att = mapAttributes(current, current);
			var tag = att.get('tag');
			att.remove('tag');
			
			var inner = '';
			
			try {
				inner = lexer.token( tillClosing( tag ) );
			} catch (e:Dynamic) {
				trace(e);
			}
			
			var parsed = parse(inner, tag);
			
			Mo.make( lexer, Keyword( Tag(tag, att, parsed, true, inner == '') ) );
		},
		'[^</!>]+' => {
			Mo.make( lexer, Const(CString(lexer.current)) );
		}
	] );
	
	public static function tillClosing(tag:String) {
		var copy = tag.substring(0);
		return Mo.rules( [
			'.*</$copy>' => {
				var c = lexer.current;
				c.substring(0, c.length - '</$copy>'.length);
			},
		] );
	}
	
	public static var root = tags;
	
	private static function parse(value:String, name:String):Tokens {
		var lexer = new HtmlLexer( ByteData.ofString( value ), '$name-inner' );
		var tokens = [];
		try {
			while (true) {
				tokens.push( lexer.token( tags ) );
			}
		} catch (e:Eof) if (lexer.pos != lexer.input.length) {
			// This forces the damn thing to continue working. Why did you stop.
			// See issue https://github.com/skial/mo/issues/1
			tokens = tokens.concat( parse( value.substring(lexer.pos), name ) );
		} catch (e:Dynamic) {
			trace( lexer.input.length );
			trace( lexer.pos );
			trace(e);
		}
		return tokens;
	}
	
	private static function mapAttributes(value:String, name:String):Map<String,String> { 
		var map = new Map<String,String>();
		
		var attributes:Ruleset<Void> = null;
		attributes = Mo.rules( [
			'[ \n\r\t]' => lexer.token(attributes),
			'[$attributeChars]+' => {
				if (!map.exists('tag')) {
					map.set('tag', lexer.current);
				} else {
					map.set(lexer.current, '');
				}
			},
			'[$attributeChars]+=("[$tagChars]+"|\'[$tagChars]+\')' => {
				var c = lexer.current;
				var p = c.split('=');
				map.set(p[0], p[1].substring(1, p[1].length - 1));
			},
			'[$attributeChars]+=[$attributeChars]+' => {
				var c = lexer.current;
				var p = c.split('=');
				map.set(p[0], p[1]);
			},
		] );
		
		var lexer = new HtmlLexer( ByteData.ofString( value ), '$name-attributes' );
		
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