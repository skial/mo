package uhx.lexer;

import haxe.io.Eof;
import haxe.DynamicAccess;
import hxparse.Unexpected.Unexpected;
import hxparse.UnexpectedChar;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import hxparse.Ruleset;
import haxe.ds.StringMap;
import hxparse.RuleBuilder;
import uhx.sys.HtmlEntities;
import uhx.sys.Seri;
import uhx.sys.seri.CodePoint;
import unifill.CodePointIter;
import unifill.InternalEncoding;
import uhx.sys.HtmlEntity;
import uhx.sys.HtmlEntities;
import unifill.Unicode;
import unifill.Unifill;

using Lambda;
using StringTools;
using haxe.EnumTools;
using uhx.lexer.Markdown;
using uhx.lexer.Markdown.BitSets;

class Container<T> {
	
	private static var counter:Int = 0;
	
	public var id:Int = counter++;
	public var tokens:T;
	public var type:Int = -1;
	public var complete:Bool = false;
	
	public inline function new(type:Int, tokens:T) {
		this.type = type;
		this.tokens = tokens;
	}
}

typedef Inline = Container<Array<String>>;
typedef Leaf = Container<Array<Inline>>;
typedef Block = Container<Array<Leaf>>;
typedef Generic = Container<Array<Dynamic>>;

@:enum abstract LexerAction(Int) from Int to Int {
	public var Nothing = -1;
	public var Break = 0;
	public var Continue = 1;
	public var End = 2;
}

@:enum abstract ABlock(Int) from Int to Int {
	var Quote = 0;
	var List = 1;
	var ListItem = 2;
	var Text = 3;
	
	public inline function new(v) this = v;
	
	@:to public function toString():String {
		return switch (this) {
			case Quote:'Quote';
			case List:'List';
			case ListItem:'ListItem';
			case Text:'Text';
			case _: 'Unknown';
		}
	}
	
	@:op(A + B) public inline function add(n:Int) {
		return new ABlock(this.add(n));
    }
    
    @:op(A-B) public inline function remove(n:Int) {
		return new ABlock(this.remove(n));
    }   
    
    @:op(A==B) public inline function contains(n:Int) {
		return this.contains(n);
    } 
	
	public static inline var MIN:Int = Quote;
	public static inline var MAX:Int = Text;
	
	static inline function value(index:Int) return 1 << index;
	public static inline function match(v:Int):Bool return v >= MIN && v <= MAX;
}

@:enum abstract ALeaf(Int) from Int to Int {
	var ThematicBreak = 4;
	var Header = 5;
	var Code = 6;
	var Html = 7;
	var Reference = 8;
	var Paragraph = 9;
	var Text = 10;
	
	public inline function new(v) this = v;
	
	@:to public function toString():String {
		return switch (this) {
			case ThematicBreak:'ThematicBreak';
			case Header:'Header';
			case Code:'Code';
			case Html:'Html';
			case Reference:'Reference';
			case Paragraph:'Paragraph';
			case Text:'Text';
			case _: 'Unknown';
		}
	}
	
	@:op(A + B) public inline function add(n:Int) {
		return new ALeaf(this.add(n));
    }
    
    @:op(A-B) public inline function remove(n:Int) {
		return new ALeaf(this.remove(n));
    }   
    
    @:op(A==B) public inline function contains(n:Int) {
		return this.contains(n);
    } 
	
	public static inline var MIN:Int = ThematicBreak;
	public static inline var MAX:Int = Text;
	
	static inline function value(index:Int) return 1 << index;
	public static inline function match(v:Int):Bool return v >= MIN && v <= MAX;
}

@:enum abstract AInline(Int) from Int to Int {
	var BackSlash = 11;
	var Entity = 12;
	var Code = 13;
	var Emphasis = 14;
	var Link = 15;
	var Image = 16;
	var Html = 17;
	var LineBreak = 18;
	var Text = 19;
	
	public inline function new(v) this = v;
	
	@:to public function toString():String {
		return switch (this) {
			case BackSlash:'BackSlash';
			case Entity:'Entity';
			case Code:'Code';
			case Emphasis:'Emphasis';
			case Link:'Link';
			case Image:'Image';
			case Html:'Html';
			case LineBreak:'LineBreak';
			case Text:'Text';
			case _: 'Unknown';
		}
	}
	
	@:op(A + B) public inline function add(n:Int) {
		return new AInline(this.add(n));
    }
    
    @:op(A-B) public inline function remove(n:Int) {
		return new AInline(this.remove(n));
    }   
    
    @:op(A==B) public inline function contains(n:Int) {
		return this.contains(n);
    }  
	
	public static inline var MIN:Int = BackSlash;
	public static inline var MAX:Int = Text;
	
	static inline function value(index:Int) return 1 << index;
	public static inline function match(v:Int):Bool return v >= MIN && v <= MAX;
	
}

/**
 * @see: http://blog.stroep.nl/2015/08/biwise-operations-made-easy-with-haxe/
 * @also: http://try.haxe.org/#27b22
 */
@:enum abstract ListFeature(Int) from Int to Int {
	var None = 0;
	var Ordered = value( 1 );
	var Tight = value( 2 );
	
	private static inline function value(index:Int) return 1 << index;
	
	public inline function new(v) this = v;
	
	@:op(A + B) public inline function add(n:Int) {
		return new ListFeature(this.add(n));
    }
    
    @:op(A-B) public inline function remove(n:Int) {
		return new ListFeature(this.remove(n));
    }   
    
    @:op(A==B) public inline function contains(n:Int) {
		return this.contains(n);
    }   
	
}

class BitSets {
	
	inline public static function remove(bits:Int, mask:Int):Int {
		return bits & ~mask;
	}
    
	inline public static function add(bits:Int, mask:Int):Int {
		return bits | mask;
	}
    
	inline public static function contains(bits:Int, mask:Int):Bool	{
		return bits & mask != 0;
	}
	
}

/**
 * ...
 * @author Skial Bainn
 */
@:access(hxparse.Lexer) class Markdown extends Lexer {
	
	public var newlines:Int = 0;
	public var backlog:Array<Generic> = [];
	public var containers:Array<Generic> = [];
	
	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	/**
	 * @see http://spec.commonmark.org/0.18/#character
	 * A character is a unicode code point. This spec does not specify
	 * an encoding; it thinks of lines as composed of characters rather 
	 * than bytes. A conforming parser may be limited to a certain encoding.
	 */
	public static var character = '[^\n\r]';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#line-ending
	 * A line ending is, depending on the platform, a newline (U+000A), 
	 * carriage return (U+000D), or carriage return + newline.
	 */
	//public static var lineEnding = '[\n\r]+';
	public static var lineEnding = '(\n|\r|\n\r|\r\n)';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#line
	 * A line is a sequence of zero or more characters followed by a line 
	 * ending or by the end of file.
	 */
	//public static var line = '[$character]+$lineEnding';
	public static var line = '$character+$lineEnding?';
	
	/**
	 * For security reasons, a conforming parser must strip or replace the
	 * Unicode character U+0000.
	 */
	public static var strippable = '\u0000';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#blank-line
	 * A line containing no characters, or a line containing only spaces (U+0020) 
	 * or tabs (U+0009), is called a blank line.
	 */
	public static var blank = '[ \t]*';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#whitespace-character
	 * A whitespace character is a space (U+0020), tab (U+0009), 
	 * newline (U+000A), line tabulation (U+000B), form feed (U+000C), 
	 * or carriage return (U+000D).
	 */
	public static var whitespace = ' \t\n\u000B\u000C\r';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#unicode-whitespace-character
	 * A unicode whitespace character is any code point in the unicode Zs 
	 * class, or a tab (U+0009), carriage return (U+000D), newline (U+000A), 
	 * or form feed (U+000C).
	 * 
	 * '\u0009\u000D\u000A\u000C' are actaully defined in the `Other` category...
	 */
	public static var unicodeWhitespace = [for (codepoint in Seri.getCategory( 'Zs' )) codepoint].map(escape).join('') + '\u0009\u000D\u000A\u000C';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#non-space-character
	 * A non-space character is anything but U+0020.
	 */
	public static var nonSpace = '[^ ]*';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#ascii-punctuation-character
	 */
	public static var asciiPunctuation = '!"#$%&\'\\(\\)\\*\\+,\\-\\./:;<=>\\?@\\[\\]\\^_`{\\|}~\\\\';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#punctuation-character
	 */
	public static var unicodePunctuation = [for (codepoint in Seri.getCategory( 'P' )) codepoint].map(escape).join('');
	
	/**
	 * @see http://spec.commonmark.org/0.18/#punctuation-character
	 * A punctuation character is an ASCII punctuation character or anything
	 * in the unicode classes Pc, Pd, Pe, Pf, Pi, Po, or Ps.
	 */
	public static var punctuation = asciiPunctuation + unicodePunctuation;
	
	// Space Indentation
	public static var si = '( ? ? ?)';
	
	//\/\// Leaf Blocks - @see http://spec.commonmark.org/0.18/#leaf-blocks
	
	/**
	 * @see http://spec.commonmark.org/0.24/#thematic-breaks
	 */
	//public static var thematicBreak = '$si(\\* *\\* *\\* *(\\* *)+|- *- *- *(- *)+|_ *_ *_ *(_ *)+) *';
	public static var thematicBreak = '$si(\\* *\\* *(\\* *)+|- *- *(- *)+|_ *_ *(_ *)+) *';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#atx-header
	 */
	//public static var atxHeader = '$si#(#?#?#?#?#?) ($character+)( #* *)?';
	public static var atxHeaderStart = '$si(#?#?#?#?#?) ';
	public static var atxHeader = '$atxHeaderStart($character+)( #* *)?';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#setext-header
	 */
	//public static var setextHeader = '$si$line$si(=+|-+) *';
	public static var setextHeader = '$si$paragraph$si(=+|-+) *';
	
	//public static var indentedCode = '(     *(.))+';
	//public static var indentedCode = '(     *($character+))+';
	public static var indentedCodeStart = '   [ ]+';
	public static var indentedCode = '($indentedCodeStart($character+))+';
	//public static var fencedCode = '(````*|~~~~*)( *[$character]+)? *$si(````*|~~~~*) *';
	public static var fencedCodeStart = '(````*|~~~~*)';
	//public static var fencedCode = '(````*|~~~~*)( *$character+)? *$si(````*|~~~~*) *';
	public static var fencedCode = '$fencedCodeStart( *$character+)? *$si$fencedCodeStart *';
	
	//public static var htmlOpen = '<[$character]+>';
	public static var htmlOpen = '<$character+>';
	//public static var htmlClose = '</[$character]+>';
	public static var htmlClose = '</$character+>';
	
	//public static var linkReference = '$si\\[[$character]+\\]: *$lineEnding? ?$line *[$character]*';
	public static var linkReference = '$si\\[$character+\\]: *$lineEnding? ?$line *$character*';
	
	public static var paragraph = '($line)+';
	
	//\/\// Container Blocks - @see http://spec.commonmark.org/0.18/#container-blocks
	
	/**
	 * @see http://spec.commonmark.org/0.18/#block-quotes
	 */
	public static var quoteStart = '$si> ?';
	public static var quote = '($quoteStart$paragraph)+';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#bullet-list-marker
	 */
	//public static var bulletList = '(-|+|\\*)';
	public static var bulletList = '(\\-|\\+|\\*)';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#ordered-list-marker
	 */
	public static var orderedList = '[0-9]+(\\.|\\))';
	
	/**
	 * A list marker is a bullet list marker or an ordered list marker.
	 * @see http://spec.commonmark.org/0.18/#list-marker
	 */
	public static var listMarker = '$si($bulletList|$orderedList) *';
	
	/**
	 * It is tempting to think of this in terms of columns: the continuation 
	 * blocks must be indented at least to the column of the first non-space 
	 * character after the list marker. However, that is not quite right. The 
	 * spaces after the list marker determine how much relative indentation is 
	 * needed
	 * @see http://spec.commonmark.org/0.18/#list-items
	 */
	//public static var listItem = '$listMarker($paragraph)+$lineEnding?';
	public static var listItem = '$listMarker$paragraph';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#lists
	 */
	public static var list = '$si[\\-\\+\\*0-9\\.\\)]$paragraph';
	
	public static var notContainer = '[^>-\\+\\*0-9]*';
	//public static var notContainer = '([^>-+\\*0-9]*)+$lineEnding';
	
	//\/\// Inlines - @see http://spec.commonmark.org/0.18/#inlines
	
	/**
	 * @see http://spec.commonmark.org/0.18/#backslash-escapes
	 */
	public static var backslash = '\\\\';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#entities
	 */
	public static var namedEntities = '&(' + HtmlEntities.names.join('|') + ');';
	public static var decimalEntities = '&#[0-9]+;';
	public static var hexadecimalEntities = '&#(X|x)[a-zA-Z0-9]+;';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#code-spans
	 */
	public static var codeSpan = 'a';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#emphasis-and-strong-emphasis
	 */
	public static var emphasis = 'a ';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#links
	 */
	public static var link = 'a';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#images
	 */
	public static var image = 'a';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#autolinks
	 */
	public static var autoLink = 'a';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#raw-html
	 */
	public static var rawHTML = ' a';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#hard-line-breaks
	 */
	public static var hardLineBreak = 'a ';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#soft-line-breaks
	 */
	public static var softLineBreak = 'a ';
	
	public static var blockRuleSet = Mo.rules( [ 
	quote => {
		lexer.createContainer( ABlock.Quote, function(s) return s.substring(1).ltrim(), leafRuleSet, blockRuleSet );
	},
	notContainer => {
		lexer.createContainer( ABlock.Text, function(s) return s, leafRuleSet, blockRuleSet );
	}
	] );
	
	public static var leafRuleSet = Mo.rules( [ 
	lineEnding => {
		lexer.processNewline();
		lexer.token( leafRuleSet );
	},
	atxHeader => {
		//new Leaf( ALeaf.Header, lexer.parse( lexer.current.replace('#', '').ltrim(), ALeaf.Header, inlineRuleSet, leafRuleSet ) );
		lexer.createContainer( ALeaf.Header, function(s) return s.replace('#', '').ltrim(), inlineRuleSet, leafRuleSet );
	},
	indentedCode => {
		//new Leaf( ALeaf.Code, lexer.parse( lexer.current, ALeaf.Code, inlineRuleSet, leafRuleSet ) );
		lexer.createContainer( ALeaf.Code, function(s) return s, inlineRuleSet, leafRuleSet );
	},
	fencedCode => {
		//new Leaf( ALeaf.Code, lexer.parse( lexer.current, ALeaf.Code, inlineRuleSet, leafRuleSet ) );
		lexer.createContainer( ALeaf.Code, function(s) return s, inlineRuleSet, leafRuleSet );
	},
	'([^#>\n\r]+$character+$lineEnding?)+' => {
		//new Leaf( ALeaf.Paragraph, lexer.parse( lexer.current, ALeaf.Paragraph, inlineRuleSet, leafRuleSet ) );
		var leaf = lexer.createContainer( ALeaf.Paragraph, function(s) return s, inlineRuleSet, leafRuleSet );
		//leaf.complete = true;
		leaf;
	},
	'' => lexer.token( blockRuleSet ),
	] );
	
	public static var inlineRuleSet = Mo.rules( [ 
	lineEnding => {
		lexer.processNewline();
		lexer.token( inlineRuleSet );
	},
	'$character+' => {
		new Inline( AInline.Text, [lexer.current] );
	},
	'' => lexer.token( leafRuleSet ),
	] );
	
	public static var root = blockRuleSet;
	
	@:access(uhx.lexer.Markdown)
	private static function parse<T>(lexer:Markdown, value:String, type:Int, subRuleSet:Ruleset<T>, unexpectedRuleSet:Ruleset<T>):Array<T> {
		var results = [];
		//trace( printType( type ) );
		trace( value );
		//var mdl = new Markdown( ByteData.ofString( value ), name );
		var mdl = lexer;
		var originalBytes = lexer.input;
		var originalPosition = lexer.pos;
		
		lexer.pos = 0;
		lexer.input = ByteData.ofString( value );
		
		try while (true) {
			results.push( mdl.token( subRuleSet ) );
			
		} catch (e:Eof) {
			
		} catch (e:UnexpectedChar) {
			trace( 'unexpected character ' + e );
			//var popped:Null<Generic> = lexer.containers[lexer.containers.length - 2];
			/*if (popped != null) {
				trace( printType( popped ) );
				var mergable = [];
				var rejected = [];
				for (result in results) if ((cast result).id != popped.id) {
					mergable.push( result );
					
				} else {
					lexer.backlog.push( cast result );
					
				}
				
				trace( popped );
				trace( mergable );
				//trace( rejected );
				
				if (mergable.length > 0) popped.tokens = popped.tokens.concat( mergable );
				//popped.tokens = popped.tokens.concat( results );
				//results = rejected;
				results = [];
				
				trace( 'running unexpected ruleset' );*/
				lexer.token( unexpectedRuleSet );
				/*var limbo = cast lexer.token( unexpectedRuleSet );
				if (results.lastIndexOf( cast limbo ) == -1 && lexer.backlog.lastIndexOf( limbo ) == -1) lexer.backlog.push( limbo );
				trace( lexer.backlog.map( function(t) return printType(t) ) );*/
				
				/*trace( printType( popped ) );
				//popped.complete = true;
				
			}*/
			
			
		}
		
		lexer.pos = originalPosition;
		lexer.input = originalBytes;
		
		return results;
	}
	
	private static function contained<T>(token:T, array:Array<T>):Bool {
		return array.lastIndexOf( token ) == -1;
	}
	
	private static function createContainer(lexer:Markdown, type:Int, sanitize:String->String, subRuleSet:Ruleset<Generic>, unexpectedRuleSet:Ruleset<Generic>):Generic {
		var block = lexer.matchContainer( type );
		
		if (block != null && !block.complete) {
			trace( 'using previous ' + printType( block ) );
			var tokens = lexer.parse( sanitize( lexer.current ), type, subRuleSet, unexpectedRuleSet );
			trace( block.tokens, tokens );
			block.tokens = block.tokens.concat( tokens.filter( contained.bind(_, block.tokens) ) );
			
		} else {
			lexer.containers.push( block = new Container( type, [] ) );
			trace( 'create new ' + printType( block ) );
			var tokens =  lexer.parse( sanitize( lexer.current ), type, subRuleSet, unexpectedRuleSet );
			trace( block.tokens, tokens );
			//block.tokens = block.tokens.concat( tokens );
			block.tokens = tokens.concat( cast block.tokens );
			
		}
		
		return block;
	}
	
	private static function matchContainer(lexer:Markdown, type:Int):Null<Generic> {
		var result = null;
		var index = lexer.containers.length - 1;
		
		while (index > -1) {
			if (!lexer.containers[index].complete && lexer.containers[index].type == type) {
				result = lexer.containers[index];
				break;
				
			}
			
			index--;
		}
		
		return result;
	}
	
	private static function matchCategory(lexer:Markdown, type:Int):Null<Generic> {
		var result = null;
		var index = lexer.containers.length - 1;
		
		while (index > -1) {
			var it = lexer.containers[index].type;
			if (!lexer.containers[index].complete && (AInline.match(it) && AInline.match(type)) || (ALeaf.match(it) && ALeaf.match(type)) || (ABlock.match(it) && ABlock.match(type))) {
				result = lexer.containers[index];
				break;
				
			}
			
			index--;
		}
		
		return result;
	}
	
	public static function printType(t:Generic):String {
		var result = switch (t.type) {
			case x if (ABlock.match(x)): 'Block.' + (x:ABlock);
			case x if (ALeaf.match(x)): 'Leaf.' + (x:ALeaf);
			case x if (AInline.match(x)): 'Inline.' + (x:AInline);
			case _: 
				trace( t.type );
				'<unknown>';
		}
		
		return result + '(${t.id})' + (t.complete?'':'!') + ':${t.tokens.length}';
	}
	
	private static function escape(value:CodePoint):String {
		return switch (value.toString()) {
			// * + ? | [ ] ( ) slash
			case '\u002A', '\u002B', '\u003F', '\u007C', '\u005B', '\u005D', '\u0028', '\u0029', '\u005C':
				'\\' + value.toString();
				
			case _:
				value.toString();
				
		}
	}
	
	private static function check(codepoint:Int):Bool {
		return codepoint == '"'.code || codepoint == '&'.code || codepoint == '<'.code || codepoint == '>'.code;
	}
	
	private static inline function processNewline(lexer:Markdown):Void {
		lexer.newlines++;
		
		if (lexer.newlines > 2) {
			var token = lexer.matchContainer( ALeaf.Paragraph );
			if (token != null) token.complete = true;
			lexer.newlines = -1;
			
		}
	}
	
}