package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import uhx.mo.TokenDef;
import hxparse.Ruleset;
import hxparse.Position;
import haxe.ds.StringMap;
import hxparse.UnexpectedChar;

using StringTools;

private typedef Tokens = Array<Token<HtmlKeywords>>;

enum HtmlKeywords {
	End(name:String);
	Ref(entity:HtmlReference);
	Instruction(name:String, attributes:StringMap<String>);
	Tag(name:String, attributes:Map<String,String>, tokens:Tokens, selfClosing:Bool, complete:Bool);
}

private class HtmlReference {
	
	public var name:String;
	public var tokens:Tokens;
	public var complete:Bool;
	public var selfClosing:Bool;
	public var attributes:Map<String,String>;
	
	public function new(name:String, attributes:Map<String,String>, tokens:Tokens, selfClosing:Bool, complete:Bool) {
		this.name = name;
		this.attributes = attributes;
		this.tokens = tokens;
		this.selfClosing = selfClosing;
		this.complete = complete;
	}
	
	public function get():HtmlKeywords {
		return Tag( name, attributes, tokens, selfClosing, complete );
	}
	
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
	
	public static var openTags:Array<HtmlReference> = [];
	
	public static var tags = Mo.rules( [
		' ' => Mo.make( lexer, Space(1) ),
		'\n' => Mo.make( lexer, Newline ),
		'\r' => Mo.make( lexer, Carriage ),
		'\t' => Mo.make( lexer, Tab(1) ),
		'<![$tagChars]+>' => {
			var current = lexer.current;
			var att = mapAttributes(ByteData.ofString(current.substring(2, current.length - 1)), 'instruction');
			var tag = att.get('tag');
			att.remove('tag');
			
			Mo.make( lexer, Keyword( Instruction(tag, att) ) );
		},
		'</[$tagChars]*>' => {
			Mo.make( lexer, Keyword( End( lexer.current.substring(2, lexer.current.length - 1) ) ) );
		},
		'<[^/][$tagChars]*>' => {
			var current = lexer.current.substring(1, lexer.current.length - 1).trim();
			var isVoid = current.endsWith('/');
			
			if (isVoid) current = current.substring(0, current.length - 1);
			
			var att = mapAttributes(ByteData.ofString(current), current);
			var tag = att.get('tag');
			att.remove('tag');
			
			var parsed:Tokens = [];
			var entity = new HtmlReference(tag, att, parsed, isVoid, false);
			var position = openTags.push( entity );
			
			if (!isVoid) try while (true) {
				var token:Token<HtmlKeywords> = lexer.token( tags );
				
				switch (token.token) {
					/*case Keyword( End( t ) ) if (t == tag): 
						entity.complete = true;
						
						if (index != -1) {
							openTags.splice(index, 1);
						}
						break;*/
						
					case Keyword( End( t ) ):
						var index = -1;
						var tag = null;
						
						for (i in 0...openTags.length) {
							tag = openTags[i];
							
							if (tag != null && t == tag.name) {
								tag.complete = true;
								index = i;
								break;
							}
						}
						
						if (index != -1) {
							openTags[index] = null;
							break;
						}
						
					case _:
				}
				
				parsed.push( token );
			} catch (e:Eof) { 
				
			} catch (e:Dynamic) {
				trace( e );
			} else {
				entity.complete = true;
			}
			
			if (openTags[position] != null && !openTags[position].complete) {
				Mo.make( lexer, Keyword( Ref(entity) ) );
			} else {
				entity.complete = true;
				Mo.make( lexer, Keyword( entity.get() ) );
			}
		},
		'[^</!>]+' => {
			Mo.make( lexer, Const(CString(lexer.current)) );
		},
		'<' => Mo.make( lexer, Const(CString(lexer.current)) ),
		'>' => Mo.make( lexer, Const(CString(lexer.current)) ),
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
		} catch (e:Eof) { }
		catch (e:Dynamic) {
			trace( e );
		}
		
		return map;
	}
	
}