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
	
	public static var tagChars = 'a-zA-Z0-9 \\-\\^\\[\\]\\(\\)\\*\\+\\?\\!\\|"\'£$%&_={}:;@~#,/><';
	public static var attributeChars = 'a-zA-Z0-9\\-\\^\\[\\]\\(\\)\\*\\+\\?\\!\\|"\'£$%&_{}:;@~#,/';
	
	public static var openTags:Array<HtmlReference> = [];
	
	public static var openClose = Mo.rules( [
	'<' => lexer.token( tags ),
	'>' => Mo.make( lexer, GreaterThan ),
	' ' => Mo.make( lexer, Space(1) ),
	'\n' => Mo.make( lexer, Newline ),
	'\r' => Mo.make( lexer, Carriage ),
	'\t' => Mo.make( lexer, Tab(1) ),
	'[^<>]+' => Mo.make( lexer, Const( CString( lexer.current ) ) ),
	] );
	
	public static var tags = Mo.rules( [ 
	' +' => Mo.make( lexer, Space(lexer.current.length) ),
	'\r' => Mo.make( lexer, Carriage ),
	'\n' => Mo.make( lexer, Newline ),
	'\t' => Mo.make( lexer, Tab(1) ),
	'/>' => lexer.token( openClose ),
	'!' => {
		Mo.make( lexer, Keyword( Instruction('', ['' => '']) ) );
	},
	'/[^\r\n\t <>]+>' => {
		Mo.make( lexer, Keyword( End( lexer.current.substring(1, lexer.current.length -1) ) ) );
	},
	'[a-zA-Z0-9]+' => {
		var tokens:Tokens = [];
		var tag = lexer.current;
		var attrs:Array<Array<String>> = [];
		var isVoid = false;
		
		try while (true) {
			var token:Array<String> = lexer.token( attributes );
			attrs.push( token );
			
		} catch (e:Eof) {
			
		} catch (e:UnexpectedChar) {
			if (e.char == '/') {
				isVoid = true;
			}
			
		} catch (e:Dynamic) {
			untyped console.log( e );
		}
		
		var entity = new HtmlReference(tag, [for (pair in attrs) pair[0] => pair[1]], tokens, isVoid, false);
		var position = -1;
		
		if (!isVoid) {
			
			position = openTags.push( entity );
			
			try while (true) {
				var token:Token<HtmlKeywords> = lexer.token( openClose );
				
				switch (token.token) {
					case GreaterThan:
						continue;
						
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
				
				tokens.push( token );
			} catch (e:Eof) {
				
			} catch (e:Dynamic) {
				untyped console.log( e );
			}
			
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
	'<' => Mo.make( lexer, LessThan ),
	'>' => Mo.make( lexer, GreaterThan ),
	] );
	
	public static var attributes = Mo.rules( [
	'[ \r\n\t]' => lexer.token( attributes ),
	'[a-zA-Z0-9_\\-]+[\r\n\t ]*=' => {
		var key = lexer.current.substring(0, lexer.current.length -1);
		var value = '';
		var original = null;
		
		try while (true) {
			var token = lexer.token( attributesText );
			
			switch (token) {
				case '"' if (original == null):
					original = token;
					continue;
					
				case '\'' if (original == null):
					original = token;
					continue;
					
				case '"' if (token == original):
					original = null;
					break;
					
				case '\'' if (token == original):
					original = null;
					break;
					
				case _ if (original == null):
					original = ' ';
					
				case ' ' if (token == original):
					original = null;
					break;
					
				case _:
					
			}
			
			value += token;
			
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			untyped console.log( e );
		}
		
		[key, value];
	},
	'[a-zA-Z0-9_\\-]+' => [lexer.current, '']
	] );
	
	public static var attributesText = Mo.rules( [
	' ' => ' ',
	'"' => '"',
	'\'' => '\'',
	'[^\'" ]+' => lexer.current
	] );
	
	/*public static var tags = Mo.rules( [
		' ' => Mo.make( lexer, Space(1) ),
		'\n' => Mo.make( lexer, Newline ),
		'\r' => Mo.make( lexer, Carriage ),
		'\t' => Mo.make( lexer, Tab(1) ),
		'![$tagChars]+' => {
			var current = lexer.current;
			var att = mapAttributes(ByteData.ofString(current.substring(2, current.length - 1)), 'instruction');
			var tag = att.get('tag');
			att.remove('tag');
			
			Mo.make( lexer, Keyword( Instruction(tag, att) ) );
		},
		'/[$tagChars]+' => {
			Mo.make( lexer, Keyword( End( lexer.current.substring(2, lexer.current.length - 1) ) ) );
		},
		'[^/][$tagChars]*' => {
			var current = lexer.current.substring(1, lexer.current.length - 1).trim();
			untyped console.log( current );
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
		'>' => lexer.token( openClose ),
		//'<' => lexer.token( tags ),
	] );*/
	
	public static var root = openClose;
	
	/*private static function mapAttributes(value:ByteData, name:String):Map<String,String> { 
		var map = new Map<String,String>();
		var attributes:Ruleset<Void> = null;
		attributes = Mo.rules( [
			'[ \n\r\t]' => lexer.token(attributes),
			//'[$attributeChars]+[ ]*=[ ]*("[^"]+"|\'[^\']+\'|[$attributeChars]+)' => {
			'[^\t\r\n\'" ]+[ \t\r\n]*=[ \t\r\n]*("[^"]+"|\'[^\']+\'|[^\t\r\n ]+)' => {
				untyped console.log(lexer.current);
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
			/*//'[$attributeChars]+' => {
			'[^\t\r\n\'" ]+' => {
				untyped console.log(lexer.current);
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
	*/
}