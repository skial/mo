package uhx.lexer;

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

using Lambda;
using StringTools;
using haxe.EnumTools;

private typedef Leafs = Array<Leaf>;
private typedef Blocks = Array<Block>;

class Leaf extends Container<ALeaf, String> {
	
}

class Block extends Container<ABlock, Leafs> {
	
}

@:generic class Container<T1, T2> {
	
	public var type:T1;
	public var tokens:Array<T2>;
	
	public function new(type:T1, tokens:Array<T2>) {
		this.type = type;
		this.tokens = tokens;
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
}

@:enum abstract AInline(Int) from Int to Int {
	var BackSlash = 0;
	var Entity = 1;
	var Code = 2;
	var Emphasis = 3;
	var Link = 4;
	var Image = 5;
	var HTML = 6;
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
	public static var unicodeWhitespace = Seri.getCategory( 'Zs' ).join('') + '\u0009\u000D\u000A\u000C';
	
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
	public static var unicodePunctuation = Seri.getCategory( 'P' ).join('');
	
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
	public static var rule = '$si(\* *\* *\* *(\* *)+|- *- *- *(- *)+|_ *_ *_ *(_ *)+) *';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#atx-header
	 */
	public static var atxHeader = '$si##?#?#?#?#? ($text)( #* *)?';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#setext-header
	 */
	public static var setextHeader = '$si$text$lineEnding$si(=+|-+) *';
	
	public static var indentedCode = '(     *(.))+';
	public static var fencedCode = '(````*|~~~~*)( *$text)? *$si(````*|~~~~*) *';
	
	public static var htmlOpen = '<$text>';
	public static var htmlClose = '</$text>';
	
	public static var linkReference = '$si\[$text\]: *$lineEnding? ?$text$lineEnding *$text';
	
	public static var paragraph = '';
	
	//\/\// Container Blocks - @see http://spec.commonmark.org/0.18/#container-blocks
	
	/**
	 * @see http://spec.commonmark.org/0.18/#block-quotes
	 */
	public static var quote = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#list-items
	 */
	public static var listItem = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#lists
	 */
	public static var list = '';
	
	//\/\// Inlines - @see http://spec.commonmark.org/0.18/#inlines
	
	/**
	 * @see http://spec.commonmark.org/0.18/#backslash-escapes
	 */
	public static var backslash = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#entities
	 */
	public static var entity = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#code-spans
	 */
	public static var codeSpan = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#emphasis-and-strong-emphasis
	 */
	public static var emphasis = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#links
	 */
	public static var link = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#images
	 */
	public static var image = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#autolinks
	 */
	public static var autoLink = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#raw-html
	 */
	public static var rawHTML = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#hard-line-breaks
	 */
	public static var hardLineBreak = '';
	
	/**
	 * @see http://spec.commonmark.org/0.18/#soft-line-breaks
	 */
	public static var softLineBreak = '';
	
	//public static var root = blocks;
	
	public static var blocks = Mo.rules( [ 
	paragraph => { },
	quotation => { },
	atxHeader => { },
	setextHeader => { },
	list => { },
	rule => { },
	code => { },
	block => { },
	] );
	
	public static var inlines = Mo.rules( [ 
	text => { },
	space => { },
	link => { }
	image => { },
	code => { },
	] );
	
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
	
}