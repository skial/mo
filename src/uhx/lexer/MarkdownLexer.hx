package uhx.lexer;

import haxe.io.Eof;
import hxparse.Unexpected.Unexpected;
import hxparse.UnexpectedChar;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import hxparse.Ruleset;
import haxe.ds.StringMap;
import hxparse.RuleBuilder;

using Lambda;
using StringTools;
using haxe.EnumTools;

private typedef Tokens = Array<Token<MarkdownKeywords>>;

enum MarkdownKeywords {
	Paragraph(tokens:Tokens);
	Header(alt:Bool, length:Int, title:Tokens);
	Italic(underscore:Bool, tokens:Tokens);
	Bold(underscore:Bool, tokens:Tokens);
	Strike(tokens:Tokens);
	Collection(ordered:Bool, tokens:Tokens);
	Item(character:String, tokens:Tokens);
	Link(ref:Bool, text:String, url:String, title:String);
	Image(ref:Bool, text:String, url:String, title:String);
	Resource(text:String, url:String, title:String);
	Code(fenced:Bool, language:String, code:String);
	Blockquote(tokens:Tokens);
	Horizontal(character:String);
	Break;
}

/**
 * ...
 * @author Skial Bainn
 */
class MarkdownLexer extends Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var buffer:StringBuf;
	public static var values:StringMap<String>;
	
	public static var LF = '\n';
	public static var CR = '\r';
	public static var VT = '\t';
	public static var blank = '$CR$LF$CR$LF';
	public static var dot = '\\\\.|\\.';
	public static var hyphen = '\\-';
	// Character `Ê` causes the lexer to fail. See https://github.com/Simn/hxparse/issues/13
	// No international characters are allowed. The markdown should be preprocessed to turn into
	// html entities.
	public static var text = 'a-zA-Z0-9';
	public static var safeText = '$text&;:/,\'\\(\\)"';
	public static var allText = '${safeText}\\. ';
	
	//public static var italic = '\\*[$allText]+\\*|_[$allText]+_';
	//public static var bold = '\\*\\*[_$allText]+\\*\\*|__[$allText\\*]+__';
	//public static var strike = '~~[$allText]+~~';
	//public static var link = '\\[[$allText$hyphen]*\\]';
	
	//public static var image = '!\\[[$allText]*\\]';
	public static var special = '_#=$VT$hyphen\\*';
	public static var normal = '`\\.,&^%$£"!¬:;@~}{></\\+\\?\\|\\[\\]\\(\\)\'\\\\';
	public static var symbols = '\\.,=_&^%$£"!¬:;@~#}{<>/$hyphen\\+\\*\\?\\|\\[\\]\\(\\)\'';
	public static var anyCharacter = '=_&^%$£"!¬;@~#`}{<>\\+\\*\\?\\|\\[\\]$hyphen$allText';
	public static var code = '$text $symbols';
	
	public static var spaceOrTab = '(    [ ]*|$VT)';
	
	public static var horizontalStar = '(\\* ?\\* ?\\* ?(\\* ?)*)';
	public static var horizontalHyphen = '($hyphen ?$hyphen ?$hyphen ?($hyphen ?)*)';
	public static var horizontalUnderscore = '(_ ?_ ?_ ?(_ ?)*)';
	public static var horizontalRule = '($horizontalStar|$horizontalHyphen|$horizontalUnderscore)+$CR?$LF?';
	
	//public static var linkText = '\\[[$=_&^%$£"!¬;@~#`}{<>\\+\\*\\?\\|$hyphen$allText$CR$LF]+\\]';
	//public static var linkText = '\\[[^\t\\]]+\\]';
	//public static var linkText = '\\[[^\t]*\\]';
	public static var linkText = '\\[(\\[[^\t\\[\\]]*\\]|[^\t\\[\\]]*)*\\]';
	//public static var linkText = '\\[[=_&^%$£"!¬;@~#`}{<>\\+\\*\\?\\|$hyphen$allText$CR$LF]+\\]';
	public static var linkUrl = '[$anyCharacter]*';
	public static var linkTitle = '"[$anyCharacter]*"';
	// See issue http://github.com/skial/mo/issues/4
	public static var link = '$linkText\\(($linkUrl)?[$VT ]?($linkTitle)?\\)';
	
	public static var image = '!$link';
	
	// [link text][optional id]
	//public static var reference = '$linkText[ $CR$LF]*(\\[[$text \\[\\]]*\\])?';
	//public static var reference = '$linkText([ $CR$LF]*\\[[$=_&^%$£"!¬;@~#`}{<>\\+\\*\\?\\|$hyphen$allText$CR$LF]*\\])?';
	//public static var reference = '$linkText([ $CR$LF]*\\[[^\t]*\\])?';
	public static var reference = '$linkText([ $CR$LF]*$linkText)?';
	//public static var reference = '\\[[a-zA-Z]+\\]';
	
	// [id]: /url/ "optional title"
	public static var resourceTitle = '($linkTitle|\'$linkUrl\'|\\($linkUrl\\))?';
	//public static var resource = '$spaceOrTab?$linkText:[ $VT]+<?$linkUrl>?[ $CR$LF$VT]*$resourceTitle';
	public static var resource = '$linkText:[ $VT]+<?$linkUrl>?[ $CR$LF$VT]*$resourceTitle($CR$LF)?';
	
	public static var italic = '\\*[\\[\\]$safeText$CR$LF ]+\\*|_[\\[\\]$safeText$CR$LF ]+_';
	public static var bold = '\\*\\*[\\[\\]$safeText$CR$LF ]+\\*\\*|__[\\[\\]$safeText$CR$LF ]+__';
	public static var strike = '~~[\\[\\]$safeText$CR$LF ]+~~';
	
	//public static var inlineCode = '`[$code]+`';
	//public static var inlineCodeRule = '`[^`]+`';
	//public static var indentedCode = '($spaceOrTab([$code]+$CR?$LF?))+($blank)|($spaceOrTab([$code]+$CR?$LF?))+';
	//public static var indentedCode = '($spaceOrTab([$code]+$CR?$LF?))+($blank)?';
	public static var indentedCode = '($spaceOrTab([^`\r\n]+$CR?$LF?))+($blank)?';
	
	public static var header = '(#|##|###|####|#####|######) [$anyCharacter]+[# ]*';
	public static var altHeader = '[$anyCharacter]+$CR$LF(===(=)*|$hyphen$hyphen$hyphen($hyphen)*)+';
	
	public static var orderedMark = '[0-9]+\\.( |$VT)';
	//public static var orderedItem = '$orderedMark[$allText]+($CR$LF($CR$LF)?$VT([$allText]+)?)*($blank|$CR$LF)?';
	public static var orderedItem = '[0-9]+\\.[ \t][^\r\n]+($CR$LF($CR$LF)?$VT([^\r\n]+)?)*($blank|$CR$LF)?';
	//public static var orderedList = '($orderedMark[$anyCharacter]+($blank|[$CR$LF]+)?($VT[$anyCharacter$VT$CR$LF]+)?)+';
	public static var orderedList = '($orderedMark[^\r\n\t]+(\r\n\r\n|[\r\n]+)?(\t.+)?)+';
	
	/*public static var unorderedMark = '[\\*$hyphen\\+][ $VT]';
	public static var unorderedItem = '$unorderedMark([$allText]+)';
	public static var unorderedList = '($unorderedMark[$anyCharacter$VT]+$CR?$LF?($blank)?)+';//TODO use orderedList pattern*/
	
	// `[^\\*$hyphen\\+]` helps prevent horizontal lines from being captured as unordered lists.
	public static var unorderedMark = '[\\*$hyphen\\+]( |$VT)[^\\*$hyphen\\+]';
	//public static var unorderedItem = '$unorderedMark[$allText]+($CR$LF($CR$LF)?$VT([$allText]+)?)*($blank|$CR$LF)?';
	public static var unorderedItem = '$unorderedMark[^\r\n]+($CR$LF($CR$LF)?$VT([^\r\n]+)?)*($blank|$CR$LF)?';
	//public static var unorderedList = '($unorderedMark[$anyCharacter]+($blank|[$CR$LF]+)?($VT[$anyCharacter$VT$CR$LF]+)?)+';
	public static var unorderedList = '($unorderedMark[^\r\n\t]+(\r\n\r\n|[\r\n]+)?(\t.+)?)+';
	
	//public static var paragraphText = '([$anyCharacter]+$CR?$LF?)+';
	// `[^$hyphen]` allows `<h2>` alternative headers to be captured.
	//public static var paragraphText = '([^\\*\\-\\+# ]([a-zA-Z0-9 $normal$hyphen\\*]|$inlineCode)+$CR?$LF?)+';
	//public static var paragraphText = '([$text $normal]([$text $normal$special]+|$inlineCode)$CR?$LF?)+';
	public static var paragraphText = '(([^\t\r\n=#][^`])[^\r\n]+\r?\n?)+';
	//public static var paragraphText = '([^*-+# ][a-zA-Z0-9 $normal]([a-zA-Z0-9 $normal$special]|$inlineCode)+$CR?$LF?)+';
	//public static var paragraph = '($paragraphText($blank)|$paragraphText)';
	public static var paragraph = '$paragraphText($blank)?';
	
	//public static var blockquote = '> ($indentedCode|$paragraph)+';
	//public static var blockquote = '(> ($paragraphText|$indentedCode)*)+';
	//public static var blockquote = '(> ([$anyCharacter]*$CR?$LF?)+($blank)?';
	//public static var blockquote = '> ([$text $normal>]([$text $normal$special]|$inlineCode)*$CR?$LF?)+';
	public static var blockquote = '> ([^>][^\r\n]+$CR?$LF?)+';
	
	private static function handleBlockQuote(lexer:Lexer) {
		var current = lexer.current;
		var lines = current.split( LF );
		
		//trace( current );
		
		for (i in 0...lines.length) if (lines[i].startsWith('> ')) {
			lines[i] = lines[i].substring(2);
		} else if (lines[i].startsWith('>')) {
			lines[i] = lines[i].substring(1);
		}
		
		current = lines.join( LF );
		
		return Keyword(Blockquote( parse( current, 'md-blockquote', blocks ) ));
	}
	
	private static function handleHeader(lexer:Lexer) {
		var current = lexer.current;
		var len = 0;
		
		//trace( current );
		
		while (current.startsWith('#')) {
			len++;
			current = current.substring(1);
		}
		
		if (current.endsWith('#')) while (current.endsWith('#')) {
			current = current.substring(0, current.length - 1);
		}
		
		return Keyword(Header(false, len, parse(current.trim(), 'md-header', span) ));
	}
	
	private static function handleAltHeader(lexer:Lexer) {
		var current = lexer.current;
		var h1 = current.endsWith('=');
		
		//trace( current );
		
		while (current.endsWith(h1?'=':'-')) {
			current = current.substring(0, current.length - 1);
		}
		
		return Keyword(Header(true, h1?1:2, parse(current.rtrim(), 'md-alt-header', span) ));
	}
	
	private static function handleResource(value:String) {
		//var current = value.substring(1);
		//trace(value);
		var current = value;
		var text = '';
		var url = '';
		var title = '';
		var pos = 0;
		//var isInline = false;
		//var isRef = false;
		var isLazy = true;
		
		var char = current.charAt( pos );
		//trace( current );
		
		var whitespace = function(value:String) return switch (value) {
			case ' ', '\n' if (current.charAt( pos-2 ) != ' '): ' ';
			case '\r', '\n', '\t': '';
			case _: value;
		}
		
		while (pos < current.length) switch (char) {
			case ' ', '\t', '\r', '\n':
				pos++;
				char = current.charAt( pos );
				
			// The `[text]()` part.
			case '[' if (text == ''):
				pos++;
				char = current.charAt( pos );
				var open = 1;
				
				while (pos < current.length) switch (char) {
					case ']' if (open == 0):
						break;
						
					case _:
						text += whitespace( char );
						pos++;
						char = current.charAt( pos );
						
						if (char == '[') open++;
						if (char == ']') open--;
						
				}
				
			// The `[](url)` part for inline links.
			case '(', ':' if (url == ''):
				pos++;
				char = current.charAt( pos );
				
				isLazy = false;
				
				while (pos < current.length) switch (char) {
					case '"', ')', "'":
						break;
						
					case _:
						if (char != '<' && char != '>') url += whitespace( char );
						pos++;
						char = current.charAt( pos );
						
				}
				
			// The `[]: url` part for reference links.
			case '[' if (url == ''):
				var isRef = char == '[';
				
				pos++;
				char = current.charAt( pos );
				
				isLazy = false;
				
				while (pos < current.length) switch (char) {
					case ']':
						break;
						
					case _:
						url += whitespace( char );
						pos++;
						char = current.charAt( pos );
						
				}
				
				if (isRef && url == '') url = text;
				
			// The `[]: / "title"` part for reference links.
			case '"', "'", '(' if (title == ''):
				pos++;
				char = current.charAt( pos );
				
				while (pos < current.length) switch (char) {
					case '"', "'", ')':
						break;
						
					case _:
						title += whitespace( char );
						pos++;
						char = current.charAt( pos );
						
				}
				
			case _:
				if (pos == current.length) break;
				
				pos++;
				char = current.charAt( pos );
				
		}
		
		if (isLazy && url == '') url = text;
		
		return { text:text, url:url.trim(), title:title.trim() };
	}
	
	private static var codeRule = Mo.rules( [
	'``*' => '`',
	'[^`]+' => lexer.current,
	] );
	
	private static var codeBlockRule = Mo.rules( [
	'`[a-zA-Z0-9]+\r\n' => lexer.current.rtrim(),
	'````*' => '```',
	'[^`]+' => lexer.current,
	] );
	
	private static var emphasis = Mo.rules( [
	'\r' => Carriage,
	'\n' => Newline,
	'\\*' => Asterisk,
	'\\_' => Underscore,
	'~' => Tilde,
	'`' => GraveAccent,
	'\t' => Tab(1),
	' ' => Space(1),
	'[^\r\n\t\\_\\*~` ]+' => Const(CString(lexer.current)),
	] );
	
	public static var span = Mo.rules( [
		//dot => Dot,
		'\t' => Tab(1),
		'\n' => Newline,
		'\r' => Carriage,
		' ' => Space(1),
		//inlineCodeRule => {
		'``*' => {
			var current = lexer.current;
			var tokens = [];
			
			try while (true) {
				var token:String = lexer.token( codeRule );
				switch (token) {
					case '`': break;
					case _:
				}
				tokens.push( token );
			} catch (e:Eof) { } catch (e:Dynamic) trace( e );
			
			Keyword(Code( false, '', tokens.join('') ));
		},
		//italic => {
		'\\*|\\_' => {
			var current = lexer.current;
			var underscore = current == '_';
			var tokens = [];
			
			try while (true) {
				var token:Token<MarkdownKeywords> = lexer.token( emphasis );
				switch (token) {
					case Underscore if (underscore): break;
					case Asterisk if (!underscore): break;
					case _:
				}
				tokens.push( token );
			} catch (e:Eof) { } catch (e:Dynamic) trace( e );
			
			Keyword(Italic( underscore, tokens ));
		},
		//bold => {
		'\\*\\*|\\_\\_' => {
			var current = lexer.current;
			var underscore = current == '__';
			var tokens:Tokens = [];
			
			try while (true) {
				tokens.push( lexer.token( emphasis ) );
				
				switch (tokens.slice(tokens.length-2).map(function(t) return t)) {
					case [Underscore, Underscore] if (underscore): 
						tokens.pop();
						tokens.pop();
						break;
						
					case [Asterisk, Asterisk] if (!underscore):
						tokens.pop();
						tokens.pop();
						break;
						
					case _:
				}
				
			} catch (e:Eof) { } catch (e:Dynamic) trace( e );
			
			Keyword(Bold( underscore, tokens ));
		},
		//strike => {
		'~~' => {
			var current = lexer.current;
			var tokens = [];
			
			try while (true) {
				tokens.push( lexer.token( emphasis ) );
				
				switch (tokens.slice(tokens.length-2).map(function(t) return t)) {
					case [Tilde, Tilde]: 
						tokens.pop();
						tokens.pop();
						break;
						
					case _:
				}
				
			} catch (e:Eof) { } catch (e:Dynamic) trace( e );
			
			Keyword(Strike( tokens ));
		},
		blockquote => {
			handleBlockQuote(lexer);
		},
		unorderedItem => {
			var current = lexer.current;
			Keyword(Item( current.substring(0, 1), parse( current.substring(1).ltrim(), 'md-unordered-item', span ) ));
		},
		orderedItem => {
			var current = lexer.current;
			var index = current.indexOf('.');
			Keyword(Item( current.substring(0, index), parse( current.substring(index + 1).ltrim(), 'md-ordered-item', span ) ));
		},
		link => {
			//trace( 'link' );
			var res = handleResource( lexer.current );
			Keyword(Link(false, res.text, res.url, res.title));
		},
		image => {
			//trace( 'img' );
			var res = handleResource( lexer.current.substring(1) );
			Keyword(Image(false, res.text, res.url, res.title));
		},
		'!$reference' => {
			//trace( 'img reference' );
			var res = handleResource( lexer.current.substring(1) );
			Keyword(Image(true, res.text, res.url, res.title));
		},
		reference => { 
			//trace( 'reference' );
			var res = handleResource( lexer.current );
			Keyword(Link(true, res.text, res.url, res.title));
		},
		resource => {
			//trace( 'resource' );
			var res = handleResource( lexer.current );
			Keyword(Resource(res.text, res.url, res.title));
		},
		'[\\-]+' => Hyphen(lexer.current.length),
		//'  [ ]*$CR?$LF' => Mo.make(lexer, Keyword(Break)),
		//'[$safeText]+' => Mo.make(lexer, Const(CString( lexer.current ))),
		'[^\t\r\n\\*\\_~`\\[ ]+' => Const(CString( lexer.current )),
		'~' => Tilde,
		/*'\\#' => Mo.make(lexer, Const(CString( lexer.current ))),
		'\\\\' => Mo.make(lexer, Const(CString('\\'))),*/
		/*'\\~' => Mo.make(lexer, Const(CString( lexer.current ))),
		'\\]' => Mo.make(lexer, Const(CString(']'))),
		'\\[' => Mo.make(lexer, Const(CString('['))),
		'!' => Mo.make(lexer, Const(CString('!'))),
		'%' => Mo.make(lexer, Const(CString('%'))),
		'?' => Mo.make(lexer, Const(CString('?'))),
		'[a-zA-Z0-9]#' => Mo.make(lexer, Const(CString(lexer.current))),*/
	] );
	
	public static var blocks = Mo.rules( [
		header => handleHeader(lexer),
		altHeader => handleAltHeader(lexer),
		indentedCode => {
			Keyword(Code(false, '', lexer.current.ltrim()));
		},
		'````*' => {
			var current = lexer.current;
			var tokens = [];
			var language = '';
			untyped lexer.pos--;
			try while (true) {
				var token:String = lexer.token( codeBlockRule );
				switch (token) {
					case '```': break;
					case _:
						var c = token.charCodeAt(token.length - 1);
						var a = 'a'.code, z = 'z'.code;
						var A = 'A'.code, Z = 'Z'.code;
						var _0 = '0'.code, _9 = '9'.code;
						
						if (token.startsWith('`') && ((c >= a && c <= z) || (c >= A && c <= Z ) || (c >= _0 && c <= _9))) {
							language = token.replace('`', '');
							continue;
						}
				}
				tokens.push( token );
			} catch (e:Eof) { } catch (e:Dynamic) trace( e );
			
			Keyword(Code( true, language, tokens.join('') ));
		},
		unorderedList => Keyword(Collection( false, parse( lexer.current, 'md-unordered-list', span ) )),
		orderedList => {
			Keyword(Collection( true, parse( lexer.current, 'md-ordered-list', span ) ));
		},
		/*horizontalRule => {
			var current = lexer.current;
			var character = current.substring(0, 2);
			character = character.endsWith(' ') ? character : character.substring(0, 1);
			Mo.make(lexer, Keyword(Horizontal(character)));
		},*/
		blockquote => {
			handleBlockQuote(lexer);
		},
		/*paragraph => {
			//trace( lexer.current );
			//trace( lexer.current.replace('\r', '\\r').replace('\n', '\\n') );
			Mo.make(lexer, Keyword(Paragraph( parse( lexer.current, 'md-paragraph', span ) )));
		},*/
		'$horizontalRule|$paragraph' => {
			var current = lexer.current;
			switch (current.substring(0, 3)) {
				case '***', '* *', '---', '- -', '___', '_ _':
					var char = current.substring(0, 2);
					char = char.endsWith(' ') ? char : char.substring(0, 1);
					Keyword(Horizontal(char));
					
				case _:
					//trace( lexer.current );
					//trace( lexer.current.replace('\r', '\\r').replace('\n', '\\n').replace('\t', '\\t') );
					Keyword(Paragraph( parse( lexer.current, 'md-paragraph', span ) ));
			}
		},
		'\t' => Tab(1),
		'\r' => Carriage,
		'\n' => Newline,
		' ' => Space(1),
	] );
	
	public static var root = blocks;
	
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