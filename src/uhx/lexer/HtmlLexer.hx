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
	Instruction(name:String, attributes:Array<String>);
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
	' +' => Mo.make( lexer, Space(lexer.current.length) ),
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
	'![a-zA-Z0-9_\\-]*' => {
		var tag = lexer.current.substring(1, lexer.current.length);
		var attrs = [];
		var tokens = [];
		
		try while (true) {
			var token:String = lexer.token( instructions );
			attrs.push( token );
			
		} catch (e:Eof) { } catch (e:UnexpectedChar) {
			// This skips over the self closing characters `/>`
			// I cant see at the moment how to handle this better.
			try while (true) {
				var token = lexer.token( openClose );
				
				switch (token.token) {
					case GreaterThan:
						break;
						
					case _:
						break;
				}
				
				tokens.push( token );
			} catch (e:Dynamic) { };
			
		} catch (e:Dynamic) {
			untyped console.log( e );
		}
		
		Mo.make( lexer, Keyword( Instruction(tag, attrs) ) );
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
			
		} catch (e:Eof) { } catch (e:UnexpectedChar) {
			if (e.char == '/') {
				isVoid = true;
				
				// This skips over the self closing characters `/>`
				// I cant see at the moment how to handle this better.
				try while (true) {
					var token = lexer.token( openClose );
					
					switch (token.token) {
						case Const(CString(x)) if (x.trim() == '/'):
							continue;
							
						case Const(CString('/')), Space(_):
							continue;
							
						case GreaterThan:
							break;
							
						case _:
							break;
					}
				} catch (e:Dynamic) {
					untyped console.log( e );
				};
				
			}
			
		} catch (e:Dynamic) {
			untyped console.log( e );
		}
		
		var entity = new HtmlReference(tag, [for (pair in attrs) pair[0] => pair[1]], tokens, isVoid, false);
		var position = -1;
		
		if (!isVoid) {
			
			position = openTags.push( entity ) - 1;
			
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
							
							if (!tag.complete && t == tag.name) {
								tag.complete = true;
								index = i;
								
								break;
							}
						}
						
						if (index == position) {
							break;
						} else if (index > -1) {
							continue;
						}
						
					case _:
				}
				
				tokens.push( token );
			} catch (e:Eof) {
				
			} catch (e:UnexpectedChar) {
				untyped console.log( e );
				untyped console.log( lexer.input.readString( 
					lexer.pos,
					lexer.input.length
				) );
			} catch (e:Dynamic) {
				untyped console.log( e );
			}
			
		} else {
			entity.complete = true;
		}
		
		if (position > -1 && !openTags[position].complete) {
			Mo.make( lexer, Keyword( Ref(entity) ) );
		} else {
			entity.complete = true;
			Mo.make( lexer, Keyword( entity.get() ) );
		}
	},
	//'<' => Mo.make( lexer, LessThan ),
	//'>' => Mo.make( lexer, GreaterThan ),
	] );
	
	public static var attributes = Mo.rules( [
	'[ \r\n\t]' => lexer.token( attributes ),
	'[a-zA-Z0-9_\\-]+[\r\n\t ]*=[\r\n\t ]*' => {
		var index = lexer.current.indexOf('=');
		var key = lexer.current.substring(0, index).rtrim();
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
	
	public static var instructions = Mo.rules( [
	'[^\r\n\t<> \\[]+' => lexer.current,
	'[\r\n\t ]+' => lexer.token( instructions ),
	'\\[' => {
		var value = '';
		var original = lexer.current;
		
		try while (true) {
			var token = lexer.token( instructionText );
			
			switch (token) {
				case ']' if (original == '['):
					value = '[$value]';
					break;
					
				case _:
					
			}
			
			value += token;
		} catch (e:Dynamic) {
			untyped console.log( e );
		}
		value;
	},
	'<' => {
		var value = '';
		var counter = 0;
		
		try while (true) {
			var token = lexer.token( instructionText );
			
			switch (token) {
				case '>' if (counter > 0):
					counter--;
					
				case '>':
					break;
					
				case '<':
					counter++;
					
				case _:
					
			}
			
			value += token;
		} catch (e:Dynamic) {
			untyped console.log( e );
		}
		'<$value>';
	}
	] );
	
	public static var instructionText = Mo.rules( [
	'[^\\]<>]+' => lexer.current,
	'\\]' => ']',
	'<' => '<',
	'>' => '>'
	] );
	
	public static var root = openClose;
	
}