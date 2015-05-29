package uhx.lexer;

import haxe.DynamicAccess;
import haxe.io.Eof;
import hxparse.Unexpected.Unexpected;
import hxparse.UnexpectedChar;
import uhx.lexer.MarkdownLexer.Container;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import hxparse.Ruleset;
import haxe.ds.StringMap;
import hxparse.RuleBuilder;
import uhx.sys.Seri;
import uhx.sys.seri.CodePoint;

using Lambda;
using StringTools;
using haxe.EnumTools;

class Inline extends Container<AInline, String> {
	
	public function new(type:AInline, ?tokens:Array<String>) {
		super(type, tokens);
	}
	
}

class Leaf extends Container<ALeaf, Inline> {
	
	public function new(type:ALeaf, ?tokens:Array<Inline>) {
		super(type, tokens);
	}
	
}

class Block extends Container<ABlock, Leaf> {
	
	public function new(type:ABlock, ?tokens:Array<Leaf>) {
		super(type, tokens);
	}
	
}

class Container<T1, T2> {
	
	public var type:T1;
	public var tokens:Array<T2>;
	public var extra:DynamicAccess<String>;
	
	public function new(type:T1, tokens:Array<T2>) {
		this.type = type;
		this.tokens = tokens == null ? [] : tokens;
		this.extra = new DynamicAccess();
	}
	
}

@:enum abstract ABlock(Int) from Int to Int {
	var Quote = 0;
	var List = 1;
	var ListItem = 2;
	var Text = 3;
}

@:enum abstract ALeaf(Int) from Int to Int {
	var Rule = 0;
	var Header = 1;
	var Code = 2;
	var Html = 3;
	var Reference = 4;
	var Paragraph = 5;
	var Text = 6;
}

@:enum abstract AInline(Int) from Int to Int {
	var BackSlash = 0;
	var Entity = 1;
	var Code = 2;
	var Emphasis = 3;
	var Link = 4;
	var Image = 5;
	var Html = 6;
	var LineBreak = 7;
	var Text = 8;
}

/**
 * ...
 * @author Skial Bainn
 */
class MarkdownLexer extends Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	/**
	 * @see http://spec.commonmark.org/0.18/#character
	 * A character is a unicode code point. This spec does not specify
	 * an encoding; it thinks of lines as composed of characters rather 
	 * than bytes. A conforming parser may be limited to a certain encoding.
	 */
	public static var character = '.';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#line-ending
	 * A line ending is, depending on the platform, a newline (U+000A), 
	 * carriage return (U+000D), or carriage return + newline.
	 */
	public static var lineEnding = '[\n\r]+';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#line
	 * A line is a sequence of zero or more characters followed by a line 
	 * ending or by the end of file.
	 */
	public static var line = '[$character]+$lineEnding';
	
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
	public static var whitespace = ' \t\n\u0009\u000C\r';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#unicode-whitespace-character
	 * A unicode whitespace character is any code point in the unicode Zs 
	 * class, or a tab (U+0009), carriage return (U+000D), newline (U+000A), 
	 * or form feed (U+000C).
	 */
	public static var unicodeWhitespace = Seri.getCategory( 'Zs' ).map(escape).join('') + '\u0009\u000D\u000A\u000C';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#non-space-character
	 * A non-space character is anything but U+0020.
	 */
	public static var nonSpace = '[^ ]*';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#ascii-punctuation-character
	 */
	public static var asciiPunctuation = '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#punctuation-character
	 */
	public static var unicodePunctuation = Seri.getCategory( 'P' ).map(escape).join('');
	
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
	 * @see http://spec.commonmark.org/0.18/#horizontal-rules
	 */
	public static var rule = '$si(\\* *\\* *\\* *(\\* *)+|- *- *- *(- *)+|_ *_ *_ *(_ *)+) *';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#atx-header
	 */
	public static var atxHeader = '$si##?#?#?#?#? ([$character]+)( #* *)?';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#setext-header
	 */
	public static var setextHeader = '$si$line$si(=+|-+) *';
	
	public static var indentedCode = '(     *(.))+';
	public static var fencedCode = '(````*|~~~~*)( *[$character]+)? *$si(````*|~~~~*) *';
	
	public static var htmlOpen = '<[$character]+>';
	public static var htmlClose = '</[$character]+>';
	
	public static var linkReference = '$si\\[[$character]+\\]: *$lineEnding? ?$line *[$character]*';
	
	public static var paragraph = '($line)+';
	
	//\/\// Container Blocks - @see http://spec.commonmark.org/0.18/#container-blocks
	
	/**
	 * @see http://spec.commonmark.org/0.18/#block-quotes
	 */
	public static var quote = '($si> ?$paragraph)+';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#bullet-list-marker
	 */
	public static var bulletList = '(-|+|\\*)';
	
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
	public static var listItem = '$listMarker($paragraph)+$lineEnding?';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#lists
	 */
	public static var list = ' ';
	
	public static var notContainer = '[^>-+\\*0-9]*';
	
	//\/\// Inlines - @see http://spec.commonmark.org/0.18/#inlines
	
	/**
	 * @see http://spec.commonmark.org/0.18/#backslash-escapes
	 */
	public static var backslash = '\\[$asciiPunctuation]+';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#entities
	 */
	public static var entity = ' ';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#code-spans
	 */
	public static var codeSpan = ' ';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#emphasis-and-strong-emphasis
	 */
	public static var emphasis = ' ';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#links
	 */
	public static var link = ' ';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#images
	 */
	public static var image = ' ';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#autolinks
	 */
	public static var autoLink = ' ';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#raw-html
	 */
	public static var rawHTML = ' ';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#hard-line-breaks
	 */
	public static var hardLineBreak = ' ';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#soft-line-breaks
	 */
	public static var softLineBreak = ' ';
	
	public static var containterBlocks = Mo.rules( [
	quote => { 
		trace( 'quote', lexer.current );
		new Block( ABlock.Quote, [new Leaf( ALeaf.Paragraph, [new Inline( AInline.Text, [lexer.current] )] )] );
	},
	list => { 
		trace( 'list', lexer.current );
		new Block( ABlock.List, [new Leaf( ALeaf.Paragraph, [new Inline( AInline.Text, [lexer.current] )] )] );
	},
	listItem => { 
		trace( 'list item', lexer.current );
		new Block( ABlock.ListItem, [new Leaf( ALeaf.Paragraph, [new Inline( AInline.Text, [lexer.current] )] )] );
	},
	notContainer => {
		trace( 'not container', lexer.current );
		new Block( ABlock.Text, [new Leaf( ALeaf.Paragraph, [new Inline( AInline.Text, [lexer.current] )] )] );
	},
	blank => {
		trace( 'blank', lexer.current );
		new Block( ABlock.Text, [new Leaf( ALeaf.Text, [new Inline( AInline.Text, [lexer.current] )] )] );
	}
	] );
	
	/*public static var leafBlocks = Mo.rules( [ 
	rule => { 
		new Leaf( ALeaf.Rule, [] );
	},
	atxHeader => { 
		new Leaf( ALeaf.Header, [] );
	},
	setextHeader => { 
		new Leaf( ALeaf.Header, [] );
	},
	indentedCode => { 
		new Leaf( ALeaf.Code, [] );
	},
	fencedCode => { 
		new Leaf( ALeaf.Code, [] );
	},
	htmlOpen => { 
		new Leaf( ALeaf.Html, [] );
	},
	htmlClose => { 
		new Leaf( ALeaf.Html, [] );
	},
	linkReference => { 
		new Leaf( ALeaf.Reference, [] );
	},
	paragraph => { 
		new Leaf( ALeaf.Paragraph, [] );
	},
	] );*/
	
	/*public static var inlines = Mo.rules( [ 
	backslash => { 
		new Inline( AInline.BackSlash, [] );
	},
	entity => { 
		new Inline( AInline.Entity, [] );
	},
	codeSpan => { 
		new Inline( AInline.Code, [] );
	},
	emphasis => { 
		new Inline( AInline.Emphasis, [] );
	},
	link => { 
		new Inline( AInline.Link, [] );
	},
	image => { 
		new Inline( AInline.Image, [] );
	},
	autoLink => { 
		new Inline( AInline.Link, [] );
	},
	rawHTML => { 
		new Inline( AInline.Html, [] );
	},
	hardLineBreak => { 
		new Inline( AInline.LineBreak, [] );
	},
	softLineBreak => { 
		new Inline( AInline.LineBreak, [] );
	},
	] );*/
	
	public static var root = containterBlocks;
	
	private static function parse<T>(value:String, name:String, rule:Ruleset<T>):Array<T> {
		var l = new MarkdownLexer( ByteData.ofString( value ), name );
		var t = [];
		
		try {
			while (true) {
				t.push(l.token( rule ));
			}
		} catch (e:Eof) { } catch (e:Dynamic) {
			trace(e);
			trace(value.substring(l.pos));
		}
		
		return t;
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
	
}