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
	public var tokens:T2;
	
	public function new(type:T1, tokens:T2) {
		this.type = type;
		this.tokens = tokens;
	}
	
}

@:enum abstract ABlock(Int) from Int to Int {
	var Quote = 0;
	var List = 1;
	var ListItem = 2;
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
	var Textual = 8;
}

/**
 * ...
 * @author Skial Bainn
 */
class MarkdownLexer extends Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var character = '';
	public static var line = '';
	public static var lineEnding = '[\n\r]';
	public static var strippable = '\u0000';
	public static var blank = '[ \t]*';
	
	public static var whitespace = ' \t\n\u0009\u000C\r';
	public static var unicodeWhitespace = Seri.getCategory( 'Zs' ).join('') + '\u0009\u000D\u000A\u000C';
	public static var nonSpace = '[^ ]*';
	
	public static var asciiPunctuation = '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~';
	public static var unicodePunctuation = Seri.getCategory( 'P' ).join('');
	public static var punctuation = asciiPunctuation + unicodePunctuation;
	
	// Space Indentation
	public static var si = '( ? ? ?)';
	
	public static var text = '';
	
	public static var rule = '$si(\* *\* *\* *(\* *)+|- *- *- *(- *)+|_ *_ *_ *(_ *)+) *';
	
	public static var atxHeader = '$si##?#?#?#?#? ($text)( #* *)?';
	public static var setextHeader = '$si$text$lineEnding$si(=+|-+) *';
	
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