package uhx.lexer;

import haxe.CallStack;
import haxe.ds.ArraySort;
import haxe.ds.IntMap;
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
	public var spaces:Int = 0;	//	The amount of spaces that follow a _marker_;
	public var indentation:Int = 0;	//	The amount of, max?, spaces the should preceed children.
	public var complete:Bool = false;
	public var info:StringMap<String>;
	
	public inline function new(type:Int, tokens:T) {
		this.type = type;
		this.tokens = tokens;
		this.info = new StringMap();
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
	public var document:Generic = new Generic( -1, [] );
	public var parent:Generic;
	
	public function new(content:ByteData, name:String) {
		super( content, name );
		parent = document;
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
	//public static var si = ' *';
	
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
	public static var atxHeaderStart = '$si(##?#?#?#?) ';
	public static var atxHeader = '$atxHeaderStart($character+)( #* *)?';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#setext-header
	 */
	//public static var setextHeader = '$si$line$si(=+|-+) *';
	public static var setextHeader = '$si$paragraph$si(\\=+|\\-+) *';
	
	//public static var indentedCode = '(     *(.))+';
	//public static var indentedCode = '(     *($character+))+';
	public static var indentedCodeStart = '   [ ]+';
	//public static var indentedCode = '($indentedCodeStart($character+))+';
	//public static var indentedCode = '($indentedCodeStart$character+)+';
	public static var indentedCode = '$indentedCodeStart$character+';
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
	public static var quote = '($quoteStart($paragraph)?)+';
	
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
	public static var listMarker = '$si($bulletList|$orderedList) +';
	
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
	
	//public static var notContainer = '[^>\\-\\+\\*\n\r0123456789]+.+';
	//public static var notContainer = '$si([^>\n\r\\*\\-\\+\\.\\)0123456789]+$character+$lineEnding?)+';
	public static var notContainer = '([^\n\r\\>\\-\\+\\*\\.\\)0123456789]+$character+$lineEnding?)+';
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
	lineEnding => {
		lexer.newlines++;
		lexer.processNewline( ABlock.MIN );
		lexer.token( blockRuleSet );
	},
	//'   [ ]+' => {
	' *' => {
		var ruleset = inlineRuleSet;
		var spaces = lexer.current.length;
		var result = -1;
		var token = null;
		
		trace( 'number of spaces is ' + spaces );
		//if (spaces > 3) {
			/*trace( _matchContainerIndent( lexer.containers, ABlock.Text, spaces ) );
			trace( _matchCategoryIndent( lexer.containers, ABlock.Text, spaces ) );
			trace( matchIndent( lexer.containers, spaces ) );*/
			/*var index = lexer.containers.length - 1;
			
			while (index > -1) {
				if (lexer.containers[index].indentation <= spaces) {
					token = lexer.containers[index];
					break;
					
				}
				
				index--;
			}*/
			token = _matchCategoryIndent( lexer.containers, ABlock.MAX, spaces );
			
		/*} else {
			//ruleset = blockRuleSet;
			
		}*/
		
		trace( token == null ? null : printType( token ) );
		
		if (token == null) {
			var parent = null;
			result = lexer.containers.push( parent = new Generic( ABlock.Text, [token = new Generic( (spaces > 3) ? ALeaf.Code : ALeaf.Paragraph, [] )] ) );
			parent.indentation = token.indentation = spaces;
			lexer.containers.push( token );
			lexer.parent.tokens.push( parent );
			lexer.parent = parent;
			//ruleset = inlineRuleSet;
			trace( 'creating ' + printType( token ) );
			
		} /*else if (token != null && token.type == ALeaf.Code) {
			//ruleset = inlineRuleSet;
			
		}*/ else {
			var child:Null<Generic> = null;
			
			if ((spaces - token.indentation) == 0) {
				child = matchIndent( lexer.containers, spaces );
				trace('re/using ' + token.printType() );
				if (child.type != ALeaf.Code) ruleset = leafRuleSet; 
				token = child;
				
			} else if ((spaces - token.indentation) > 3) {
				child = _matchContainerIndent( lexer.containers, ALeaf.Code, spaces );
				//var child = _matchCategoryIndent( lexer.containers, ALeaf.Code, spaces );
				if (child == null) {
					result = lexer.containers.push( child = new Generic( ALeaf.Code, [] ) );
					child.indentation = spaces;
					token.tokens.push( child );
					
				}
				trace('re/using ' + token.printType() );
				if (child.type != ALeaf.Code) ruleset = leafRuleSet; 
				token = child;
				
			} else {
				
				// Let it fall through to the next set of rulesets.
				ruleset = leafRuleSet;
				//if (token.indentation < spaces) lexer.pos -= (spaces - token.indentation);
			}
			
			trace('reusing ' + token.printType(), spaces, token.indentation );
			
		}
		
		var originalParent = lexer.parent;
		lexer.parent = token;
		
		var lastPosition = 0;
		
		try /*while (true)*/ {
			lastPosition = lexer.pos;
			lexer.token( ruleset );
			
		} catch (e:UnexpectedChar) {
			trace( e, lastPosition, spaces, lexer.parent.indentation );
			lexer.pos = lastPosition;
			lexer.token( blockRuleSet );
			
		} catch (e:Eof) {
			
		}
		
		lexer.parent = originalParent;
		
		result;
	},
	/*quote => {
		lexer.createContainer( ABlock.Quote, leafRuleSet, blockRuleSet, function(s) return s.substring(1).ltrim() );
	},*/
	//quoteStart => {
	'$si> ?' => {
		var result = -1;
		trace( lexer.current );
		var spaces = lexer.current.countLeadingSpaces();
		var quote = _matchContainerIndent( lexer.containers, ABlock.Quote, lexer.current.length - spaces - 2 );
		if (quote == null) {
			lexer.containers.push( quote = new Generic( ABlock.Quote, [] ) );
			quote.spaces = spaces;
			quote.indentation = lexer.current.length - quote.spaces - 2;
			lexer.parent.tokens.push( quote );
			trace( 'create new ' + quote.printType() );
			
		} else {
			trace( 'reusing previous ' + quote.printType() );
			
		}
		
		trace( lexer.parent.printType() );
		var originalParent = lexer.parent;
		lexer.parent = quote;
		//lexer.pos -= lexer.current.length;
		
		try {
			//lexer.token( leafRuleSet );
			lexer.token( blockRuleSet );
			
		} catch (e:UnexpectedChar) {
			trace( e.char.replace(' ', '\\s') );
			//trace( CallStack.toString( CallStack.exceptionStack() ) );
			//trace( CallStack.toString( CallStack.callStack() ) );
			//lexer.token( blockRuleSet );
			
		}
		
		lexer.parent = originalParent;
		
		result;
	},
	listMarker => {
		var result = -1;
		var list = _matchContainerIndent( lexer.containers, ABlock.List, lexer.parent.indentation );
		var map = collectListInfo( lexer.current );
		trace( lexer.current, lexer.parent.indentation, lexer.current.countLeadingSpaces() );
		if (list == null || list.info.get('marker') != map.get('marker')) {
			if (list != null) {
				list.complete = true;
				for (token in list.tokens) token.complete = true;
			}
			
			lexer.containers.push( list = new Generic( ABlock.List, [] ) );
			list.info = map;
			list.spaces = lexer.current.countLeadingSpaces();
			list.indentation = lexer.current.length;
			
			result = if ([ABlock.Text].indexOf( lexer.parent.type ) != -1) {
				lexer.parent.complete = true;
				for (token in lexer.parent.tokens) token.complete = true;
				lexer.document.tokens.push( list );
				
			} else {
				lexer.parent.tokens.push( list );
			}
			trace( 'create new ' + printType( list ) );
			
		}  else {
			trace( 'using previous ' + printType( list ) );
		}
		
		var originalParent = lexer.parent;
		lexer.parent = list;
		
		lexer.pos -= lexer.current.length;
		// TODO add try catch blocks.
		try {
			lexer.token( listRuleSet );
			
		} catch (e:UnexpectedChar) {
			/*trace( lexer.input );
			trace( e.char.replace(' ', '\\s') );
			trace( CallStack.toString( CallStack.exceptionStack() ) );
			trace( CallStack.toString( CallStack.callStack() ) );*/
			//lexer.token( blockRuleSet );
			
		}
		
		lexer.parent = originalParent;
		result;
	},
	//'$si[^ \n\r\\+\\*\\.\\)\\>]' => {
	//'$si[^ \n\r]' => {
	'[^ \n\r]' => {
		var result = -1;
		var text = _matchCategoryIndent( lexer.containers, ABlock.Text, lexer.parent.indentation );
		if (text == null) {
			lexer.containers.push( text = new Generic( ABlock.Text, [] ) );
			lexer.parent.tokens.push( text );
			trace( 'create new ' + text.printType() );
			
		} else {
			trace( 'using previous ' + text.printType() );
			
		}
		trace( lexer.parent.printType() );
		var originalParent = lexer.parent;
		lexer.parent = text;
		lexer.pos--;
		
		try {
			lexer.token( leafRuleSet );
			
		} catch (e:UnexpectedChar) {
			trace( e.char.replace(' ', '\\s') );
			//trace( CallStack.toString( CallStack.exceptionStack() ) );
			//trace( CallStack.toString( CallStack.callStack() ) );
			//lexer.token( blockRuleSet );
			
		}
		
		lexer.parent = originalParent;
		
		result;
	}
	] );
	
	public static var listRuleSet = Mo.rules( [ 
	lineEnding => {
		lexer.newlines++;
		lexer.processNewline( ABlock.MIN );
		lexer.token( listRuleSet );
	},
	'   [ ]+' => {
		var ruleset = listRuleSet;
		var spaces = lexer.current.length;
		var result = -1;
		var token = null;
		trace( 'number of spaces is ' + spaces );
		if (spaces > 3) {
			/*var index = lexer.containers.length - 1;
			
			while (index > -1) {
				if (lexer.containers[index].indentation >= spaces) {
					token = lexer.containers[index];
					break;
					
				}
				
				index--;
			}*/
			token = _matchContainerIndent( lexer.containers, ABlock.ListItem, spaces );
			
		}
		
		if (token == null) {
			result = lexer.containers.push( token = new Generic( ALeaf.Code, [] ) );
			token.indentation = spaces;
			lexer.containers.push( token );
			lexer.parent.tokens.push( token );
			ruleset = inlineRuleSet;
			
		}
		
		trace( 'creating ' + printType( token ) );
		
		var originalParent = lexer.parent;
		lexer.parent = token;
		
		try /*while (true)*/ {
			lexer.token( ruleset );
			
		} catch (e:UnexpectedChar) {
			
		} catch (e:Eof) {
			
		}
		
		lexer.parent = originalParent;
		
		result;
	},
	'$si$orderedList *' => {
		var result = -1;
		var list = null;
		var map = collectListInfo( lexer.current );
		
		if (list == null || list != null && lexer.parent.info.get('type') != map.get('type')) {
			lexer.containers.push( list = new Generic( ABlock.ListItem, [] ) );
			list.spaces = lexer.parent.spaces;
			list.indentation = lexer.parent.indentation;
			result = lexer.parent.tokens.push( list );
			
		}
		
		var originalParent = lexer.parent;
		lexer.parent = list;
		var lastPosition = 0;
		var lastNewlineCount = 0;
		
		try {
			lastPosition = lexer.pos;
			lastNewlineCount = lexer.newlines;
			lexer.token( leafRuleSet );
			
		} catch (e:UnexpectedChar) {
			trace( 'list unexpectedchar $e' );
			//trace( CallStack.toString( CallStack.exceptionStack() ) );
			//lexer.token( blockRuleSet );
			
		}
		
		lexer.parent = originalParent;
		
		result;
	},
	'$si$bulletList *' => {
		var result = -1;
		var list = null;
		var map = collectListInfo( lexer.current );
		
		if (list == null || list != null && lexer.parent.info.get('type') != map.get('type')) {
			lexer.containers.push( list = new Generic( ABlock.ListItem, [] ) );
			list.spaces = lexer.parent.spaces;
			list.indentation = lexer.parent.indentation;
			result = lexer.parent.tokens.push( list );
			
		}
		
		var originalParent = lexer.parent;
		lexer.parent = list;
		
		try {
			lexer.token( leafRuleSet );
			
		} catch (e:UnexpectedChar) {
			/*trace( 'list unexpectedchar $e' );
			trace( CallStack.toString( CallStack.exceptionStack() ) );*/
			/*lexer.pos -= e.char.length;
			lexer.token( blockRuleSet );*/
			
		}
		
		lexer.parent = originalParent;
		
		result;
	},
	] );
	
	public static var leafRuleSet = Mo.rules( [ 
	lineEnding => {
		lexer.newlines++;
		lexer.processNewline( ALeaf.MIN );
		lexer.token( leafRuleSet );
	},
	'   [ ]+' => {
		var ruleset = inlineRuleSet;
		var spaces = lexer.current.length;
		var result = -1;
		var token = null;
		trace( 'number of spaces is ' + spaces );
		if (spaces > 3) {
			/*var index = lexer.containers.length - 1;
			
			while (index > -1) {
				if (lexer.containers[index].indentation >= spaces) {
					token = lexer.containers[index];
					break;
					
				}
				
				index--;
			}*/
			token = _matchCategoryIndent( lexer.containers, ALeaf.MAX, spaces );
			
		}
		
		if (token == null) {
			result = lexer.containers.push( token = new Generic( ALeaf.Code, [] ) );
			token.indentation = spaces;
			lexer.containers.push( token );
			lexer.parent.tokens.push( token );
			//ruleset = inlineRuleSet;
			trace( 'creating ' + printType( token ) );
			
		} else {
			trace('reusing ' + token.printType(), spaces, token.indentation );
			
		}
		
		var originalParent = lexer.parent;
		lexer.parent = token;
		
		try /*while (true)*/ {
			lexer.token( ruleset );
			
		} catch (e:UnexpectedChar) {
			
		} catch (e:Eof) {
			
		}
		
		lexer.parent = originalParent;
		
		result;
	},
	thematicBreak => {
		trace( 'creating thematic break' );
		// find parent position
		var index = -1;
		for (i in 0...lexer.containers.length) if (lexer.parent.id == lexer.containers[i].id) {
			index = i - 1;
			break;
			
		}
		trace( lexer.containers.map( printType ), index );
		//lexer.parent.complete = true;
		var parent = null;
		if (index < 0) {
			lexer.document.tokens.push( parent = new Generic( ABlock.Text, [] ) );
			parent.complete = true;
			
		} else {
			lexer.parent;
			
		}
		parent.tokens.push( (new Leaf( ALeaf.ThematicBreak, [] ):Generic) );
		
		// Force completion of all current `lexer.containers` tokens.
		lexer.newlines = 4;
		lexer.processNewline();
	},
	//atxHeader => {
	atxHeaderStart => {
		//lexer.createContainer( ALeaf.Header, inlineRuleSet, leafRuleSet, function(s) return s.replace('#', '') );
		trace( 'creating atx header' );
		var result = -1;
		var spaces = lexer.parent.indentation;
		var token = _matchContainerIndent( lexer.containers, ALeaf.Header, spaces );
		
		if (token == null) {
			result = lexer.containers.push( token = new Generic( ALeaf.Header, [] ) );
			token.indentation = spaces;
			lexer.containers.push( token );
			lexer.parent.tokens.push( token );
			
		}
		
		var originalParent = lexer.parent;
		lexer.parent = token;
		lexer.token( inlineRuleSet );
		lexer.parent = originalParent;
		
		result;
		
	},
	/*fencedCode => {
		trace( 'fenced code' );
		lexer.createContainer( ALeaf.Code, inlineRuleSet, leafRuleSet );
	},*/
	//'([^\n\r\\_\\#\\>\\*\\-\\+\\.\\)0123456789]+$character+)+' => {
	//'[^ \n\r\\_\\#\\>\\*\\-\\+\\.\\)0123456789]+$character+' => {
	//'$character+' => {
	'[^ \n\r\\#\\>]' => {
		//lexer.createContainer( ALeaf.Paragraph, inlineRuleSet, leafRuleSet );
		trace( 'creating paragraph' );
		var result = -1;
		var spaces = lexer.parent.indentation;
		var token = _matchContainerIndent( lexer.containers, ALeaf.Paragraph, spaces );
		
		if (token == null) {
			result = lexer.containers.push( token = new Generic( ALeaf.Paragraph, [] ) );
			token.indentation = spaces;
			lexer.containers.push( token );
			lexer.parent.tokens.push( token );
			
		}
		
		var originalParent = lexer.parent;
		lexer.pos--;
		lexer.parent = token;
		lexer.token( inlineRuleSet );
		lexer.parent = originalParent;
		
		result;
	},
	//'' /*EOF*/ => {
		/*lexer.token( blockRuleSet );
	},*/
	] );
	
	public static var inlineRuleSet = Mo.rules( [ 
	lineEnding => {
		lexer.newlines++;
		lexer.processNewline( AInline.MIN );
		lexer.token( inlineRuleSet );
	},
	'[^ ]$character+' => {
		trace( 'creating text', lexer.current );
		lexer.newlines = 0;
		var block =  new Generic( AInline.Text, [lexer.current.trim()] );
		lexer.parent.tokens.push( block );
	},
	//'' /*EOF*/ => {
		/*lexer.token( leafRuleSet );
	},*/
	] );
	
	public static var root = blockRuleSet;
	
	@:access(uhx.lexer.Markdown)
	private static function parse(lexer:Markdown, value:String, type:Int, subRuleSet:Ruleset<Generic>, unexpectedRuleSet:Ruleset<Generic>):Void {
		trace( value );
		
		var originalBytes = lexer.input;
		var originalPosition = lexer.pos;
		
		lexer.pos = 0;
		lexer.input = ByteData.ofString( value );
		
		var lastPosition = 0;
		var lastNewlineCount = 0;
		
		while (true) try {
			lastPosition = lexer.pos;
			lastNewlineCount = lexer.newlines;
			lexer.token( subRuleSet );
			
		} catch (e:UnexpectedChar) {
			/*trace( '$e', e.pos.pmin, e.pos.pmax, lexer.pos, lastPosition, lexer.newlines, lastNewlineCount );
			trace( lexer.containers.map( printType ) );
			trace( CallStack.toString( CallStack.exceptionStack() ) );
			trace( CallStack.toString( CallStack.callStack() ) );*/
			lexer.pos = lastPosition;
			lexer.newlines = lastNewlineCount;
			lexer.token( unexpectedRuleSet );
			
		} catch (e:Eof) {
			break;
			
		}
		
		lexer.pos = originalPosition;
		lexer.input = originalBytes;
	}
	
	private static function createContainer(lexer:Markdown, type:Int, subRuleSet:Ruleset<Generic>, unexpectedRuleSet:Ruleset<Generic>, ?sanitize:String->String, ?inspect:Generic->String->Void) {
		var spaces = lexer.current.countLeadingSpaces();
		var indent = lexer.current.countSuccessiveSpaces();
		
		//trace( printType( new Generic(type, []) ), spaces, indent, lexer.parent.printType() );
		/*if (((spaces + indent) - lexer.parent.indentation) > 3 && type != ALeaf.Code) {
			/*type = switch (type) {
				case t if (ALeaf.match(t)): ALeaf.Code;
				case t if (AInline.match(t)): AInline.MAX;
				case t if (ABlock.match(t)): ABlock.MAX;
				case _: type;
			}*/
			/*type = ALeaf.Code;
			subRuleSet = inlineRuleSet;
			unexpectedRuleSet = leafRuleSet;
			sanitize = null;
			trace( 'setting default type' );
			
		}*/
		
		trace( lexer.containers.map( printType ) );
		var block = (/*type != ABlock.Quote && */ABlock.match( type )) ? lexer.matchCategoryIndent( type, indent ) : lexer.matchContainerIndent( type, indent );
		var originalParent = lexer.parent;
		var result = -1;
		var value = lexer.current;
		trace( value );
		trace(block != null , block != null && !block.complete , block != null && (spaces + indent) >= block.indentation);
		if (block != null && !block.complete && (spaces + indent) >= block.indentation) {
			trace( 'using previous ' + printType( block ) );
			if (inspect != null) inspect( block, lexer.current );
			lexer.parent = block;
			
			/*var index = 0;
			var value = [for (part in lexer.current.split('\n')) {
				index = part.countLeadingSpaces();
				index = (index < 0) ? 0 : index;
				if (index > 0) {
					if (lexer.containers[0] != lexer.parent) {
						part = part.substr( (index > lexer.parent.indentation) ? lexer.parent.indentation : index );
						
					} else if (index < 4) {
						part = part.substr( index );
						
					}
					
				}
				trace( index, lexer.parent.id, part );
				part;
			}].join('\n');*/
			
			var index = 0;
			var value = [for (part in lexer.current.split('\n')) {
				index = part.countLeadingSpaces();
				index = (index < 0) ? 0 : (index > lexer.parent.indentation) ? lexer.parent.indentation : index;
				if (index > 0) part = part.substr( index );
				trace( index, lexer.parent.printType(), part );
				part;
			}].join('\n');
			
			lexer.parse( sanitize == null ? value : sanitize( value ), type, subRuleSet, unexpectedRuleSet );
			
		} else {
			lexer.containers.push( block = new Container( type, [] ) );
			block.spaces = spaces;
			block.indentation = spaces + indent;
			if (inspect != null) inspect( block, lexer.current );
			lexer.parent = block;
			
			/*var index = 0;
			var value = [for (part in lexer.current.split('\n')) {
				index = part.countLeadingSpaces();
				index = (index < 0) ? 0 : index;
				if (index > 0) {
					if (lexer.containers[0] != lexer.parent) {
						part = part.substr( (index > lexer.parent.indentation) ? lexer.parent.indentation : index );
						
					} else if (index < 4) {
						part = part.substr( index );
						
					}
					
				}
				trace( index, lexer.parent.id, part );
				part;
			}].join('\n');*/
			
			var index = 0;
			var value = [for (part in lexer.current.split('\n')) {
				index = part.countLeadingSpaces();
				index = (index < 0) ? 0 : (index > lexer.parent.indentation) ? lexer.parent.indentation : index;
				if (index > 0) part = part.substr( index );
				trace( index, lexer.parent.printType(), part );
				part;
			}].join('\n');
			
			trace( 'create new ' + printType( block ) );
			result = originalParent.tokens.push( block );
			
			lexer.parse( sanitize == null ? value : sanitize( value ), type, subRuleSet, unexpectedRuleSet );
			
		}
		
		lexer.parent = originalParent;
		
		return result;
	}
	
	private static function matchCategoryIndent(lexer:Markdown, type:Int, min:Int):Null<Generic> {
		var result = null;
		var types = [for (token in lexer.containers) if (!token.complete && (AInline.match(token.type) && AInline.match(type)) || (ALeaf.match(token.type) && ALeaf.match(type)) || (ABlock.match(token.type) && ABlock.match(type))) token];
		var index = types.length - 1;
		
		while (index > -1) {
			if (min >= types[index].indentation) {
				result = types[index];
				break;
				
			}
			
			index--;
		}
		
		trace( 'looking for category of type ' + printType(new Generic(type, [])) + ' with indentation of $min, found ' + (result==null ? null : printType(result)) );
		
		return result;
	}
	
	private static inline function matchIndent(tokens:Array<Generic>, max:Int):Null<Generic> {
		return matchConditionedIndent(tokens, max, function(_) return true);
	}
	
	private static inline function _matchContainerIndent(tokens:Array<Generic>, type:Int, max:Int):Null<Generic> {
		return matchConditionedIndent(tokens, max, function(token:Generic) return token.type == type);
	}
	
	private static inline function _matchCategoryIndent(tokens:Array<Generic>, type:Int, max:Int):Null<Generic> {
		return matchConditionedIndent(tokens, max, function(token:Generic) {
			return (AInline.match(token.type) && AInline.match(type)) || (ALeaf.match(token.type) && ALeaf.match(type)) || (ABlock.match(token.type) && ABlock.match(type));
		} );
	}
	
	private static inline function _matchCategoriesIndent(tokens:Array<Generic>, types:Array<Int>, max:Int):Null<Generic> {
		return matchConditionedIndent(tokens, max, function(token:Generic) {
			return [for (type in types) if ((AInline.match(token.type) && AInline.match(type)) || (ALeaf.match(token.type) && ALeaf.match(type)) || (ABlock.match(token.type) && ABlock.match(type))) {
				true;
			}].length > 0;
		} );
	}
	
	private static function matchConditionedIndent(tokens:Array<Generic>, max:Int, condition:Generic->Bool):Null<Generic> {
		var result:Null<Generic> = null;
		var finalists:IntMap<Generic> = new IntMap();
		var potentials:Array<Generic> = [for (token in tokens) if (condition(token) && !token.complete && token.indentation <= max) token];
		
		trace( max, tokens.map( printType ) );
		
		ArraySort.sort( potentials, function(a, b) {
			var result = 0;
			result = (a.indentation < b.indentation) ? 1 : -1;
			return result;
		} );
		
		trace( potentials.map( printType ) );
		
		for (potential in potentials) {
			var indent = max;
			indent -= potential.indentation;
			
			if (result == null) result = potential;
			
			if (indent > 0 && potential.tokens.length > 0) {
				var child:Null<Generic> = matchConditionedIndent( cast potential.tokens, indent, condition );
				
				if (result == null || result != null && child != null && child.indentation < result.indentation) {
					result = child;
					
				}
				
			} else if (result != null && potential.indentation > result.indentation) {
				result = potential;
				
			}
			trace( indent );
		}
		
		trace( result == null ? null : result.printType() );
		
		return result;
	}
	
	private static function matchContainerIndent(lexer:Markdown, type:Int, min:Int):Null<Generic> {
		var result = null;
		var types = [for (token in lexer.containers) if (!token.complete && token.type == type) token];
		var index = types.length - 1;
		
		while (index > -1) {
			if (min >= types[index].indentation) {
				result = types[index];
				break;
				
			}
			
			index--;
		}
		
		trace( 'looking for container of type ' + printType(new Generic(type, [])) + ' with indentation of $min, found ' + (result==null ? null : printType(result)) );
		
		return result;
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
	
	private static inline function defaultType(type:Int):Int {
		return switch (type) {
			case x if (ALeaf.match(x)): ALeaf.MAX;
			case x if (AInline.match(x)): AInline.MAX;
			case _: ABlock.MAX;
		}
	}
	
	private static inline function defaultRuleSet(type:Int):Ruleset<Generic> {
		return switch (type) {
			case x if (ALeaf.match(x)): leafRuleSet;
			case x if (AInline.match(x)): inlineRuleSet;
			case _: blockRuleSet;
		}
	}
	
	public static function printType(t:Generic):String {
		var result = switch (t.type) {
			case x if (ABlock.match(x)): 'Block.' + (x:ABlock);
			case x if (ALeaf.match(x)): 'Leaf.' + (x:ALeaf);
			case x if (AInline.match(x)): 'Inline.' + (x:AInline);
			case _: '<unknown>';
		}
		
		return result + '(${t.id})' + (t.complete?'':'!') + ':${t.tokens.length}:(<${t.spaces},>${t.indentation})';
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
	
	private static function processNewline(lexer:Markdown, ?type:Int = 0):Void {
		// TODO only continue if two newlines follow in succession, not when a total of
		// newlines have been encounters.
		if (lexer.newlines > 1 && lexer.containers[lexer.containers.length - 1].type == ALeaf.Paragraph) {
			var token = lexer.containers.pop();
			token.complete = true;
			for (child in token.tokens) {
				child.complete = true;
				
			}
			
			trace( 'paragraph reset newlines ${lexer.newlines}' );
			
		}
		if (lexer.newlines > 2) {
			var index = lexer.containers.length - 1;
			trace( 'index => $index' );
			while (index > -1) {
				if (lexer.containers[index].type >= type) {
					lexer.containers[index].complete = true;
					
				} else {
					break;
					
				}
				
				index--;
				
			}
			trace( 'removing tokens until $index' );
			while (lexer.containers.length > index + 1) {
				var popped = lexer.containers.pop();
				trace( 'removed ' + popped.printType() );
			}
			
			
			/*for (token in lexer.containers) token.complete = true;
			while (lexer.containers.length > 0) {
				lexer.containers.pop().printType();
				
			}*/
			
			lexer.newlines = 0;
			trace( 'line break reset newlines ${lexer.newlines}' );
			
		} else {
			trace( 'newlines ${lexer.newlines}' );
			
		}
		
	}
	
	private static function collectListInfo(value:String):StringMap<String> {
		//var index = value.indexOf(' ');
		var marker = '';
		var result = new StringMap<String>();
		/*if (index > -1) {
			result.set( 'indent', '' + (value.length - index) );
		}*/
		value = value.rtrim();
		
		result.set( 'marker', marker = value.substr(value.length - 1, value.length) );
		
		switch (marker) {
			case ')', '.':
				result.set( 'start', value.substr(0, -1) );
				result.set( 'type', 'ordered' );
				
			case _:
				result.set( 'type', 'bullet' );
				
		}
		
		//trace( [for (k in result.keys()) '$k => ' + result.get( k )] );
		
		return result;
	}
	
	private static function countLeadingSpaces(value:String):Int {
		var result = 0;
		
		for (i in 0...value.length) if (value.charCodeAt(i) == ' '.code) {
			result++;
			
		} else {
			break;
			
		}
		
		return result;
	}
	
	private static function countSuccessiveSpaces(value:String):Int {
		var result = 0;
		var index = value.length - 1;
		while (index > -1) {
			if (value.charCodeAt(index) == ' '.code) {
				result++;
				
			} else {
				break;
				
			}
			
			index--;
			
		}
		
		return result;
	}
	
}