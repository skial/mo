package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import uhx.lexer.Css;
import hxparse.Lexer;
import byte.ByteData;
import hxparse.Ruleset;
import haxe.extern.EitherType;

using StringTools;

/**
 * ...
 * @author Skial Bainn
 */
private typedef Tokens = Array<Token<CssKeywords>>;

enum CssKeywords {
	RuleSet(selector:CssSelectors, tokens:Tokens);
	AtRule(name:String, query:Array<CssMedia>, tokens:Tokens);
	Declaration(name:String, value:String);
}

private typedef Selectors = Array<CssSelectors>;

enum CssSelectors {
	Group(selectors:Selectors);
	Type(name:String);
	Universal;
	Attribute(name:String, type:AttributeType, value:String);
	Class(names:Array<String>);
	ID(name:String);
	Pseudo(name:String, expr:String);
	Combinator(selector:CssSelectors, next:CssSelectors, type:CombinatorType);
}

@:enum abstract AttributeType(EitherType<Int,String>) from EitherType<Int,String> to EitherType<Int,String> {
	public var Unknown = -1;
	public var Exact = 0;				//	att=val
	public var List = 1;				//	att~=val
	/*@split */public var DashList = 2;		//	att|=val
	public var Prefix = 3;				//	att^=val
	public var Suffix = 4;				//	att$=val
	public var Contains = 5;			//	att*=val
}

@:enum abstract CombinatorType(Int) from Int to Int {
	public var None = 0;				// Used in `type.class`, `type:pseudo` and `type[attribute]`
	public var Child = 1;				//	`>`
	public var Descendant = 2;			//	` `
	public var Adjacent = 3;			//	`+`
	public var General = 4;				//	`~`
	public var Shadow = 5;				//	`>>>`
}

private typedef Queries = Array<CssMedia>;

enum CssMedia {
	Only;
	Not;
	Feature(name:String);
	Group(queries:Array<Queries>);
	Expr(name:String, value:String);
}
 
@:access(hxparse.Lexer) class Css extends Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var s = ' \t\r\n';
	public static var escaped = '(\u005c\u005c.?)';
	public static var ident = 'a-zA-Z0-9\\-\\_';
	public static var selector = 'a-zA-Z0-9$:#=>~\\.\\-\\_\\*\\^\\|\\+';
	public static var any = 'a-zA-Z0-9 "\',%#~=:;@!$&\t\r\n\\{\\}\\(\\)\\[\\]\\|\\.\\-\\_\\*';
	public static var declaration = '[$ident]+[$s]*:[$s]*[^;{]+;';
	public static var combinator = '( +| *> *| *\\+ *| *~ *|\\.|:|\\[)?';
	
	private static function makeRuleSet(rule:String, tokens:Tokens) {
		var selector = parse(ByteData.ofString(rule), 'selector', selectors);
		
		// Any Attribute or Pseudo selector without a preceeding selector is treated
		// as having a Universal selector preceeding it. 
		// `[a=1]` becomes `*[a=1]`
		// `:first-child` becomes `*:first-child`
		for (i in 0...selector.length) switch(selector[i]) {
			case Attribute(_, _, _) | Pseudo(_, _) | 
			Combinator(Attribute(_, _, _), _, _) | Combinator(Pseudo(_, _), _, _):
				selector[i] = Combinator(Universal, selector[i], None);
				
			case _:
				
		}
		
		return Keyword(RuleSet(selector.length > 1? CssSelectors.Group(selector) : selector[0], tokens));
	}
	
	private static function makeAtRule(rule:String, tokens:Tokens) {
		var index = rule.indexOf(' ');
		var query = parse(ByteData.ofString(rule.substring(index)), 'media query', mediaQueries);
		return Keyword(AtRule(rule.substring(1, index), /*query.length > 1? CssMedia.Group(query) : query[0]*/query, tokens));
	}
	
	private static function handleRuleSet(lexer:Lexer, make:String->Tokens->Token<CssKeywords>, breakOn:Token<CssKeywords>) {
		var current = lexer.current;
		var rule = current.substring(0, current.length - 1);
		var tokens:Tokens = [];
		
		try while (true) {
			var token:Token<CssKeywords> = lexer.token( root );
			switch (token) {
				case x if(x == breakOn): break;
				case _:
			}
			tokens.push( token );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return make(rule.trim(), tokens);
	}
	
	public static var root = Mo.rules([
	'[\n\r\t ]*' => lexer.token( root ),
	'/\\*' => {
		var tokens = [];
		try while ( true ) {
			var token:String = lexer.token( comments );
			switch (token) {
				case '*/': break;
				case _:
			}
			tokens.push( token );
		} catch (e:Eof) { } catch (e:Dynamic) {
			trace( e );
		}
		
		return Comment( tokens.join('').trim() );
	},
	'[^\r\n/@}{]([$selector,"\'/ \\[\\]\\(\\)$s]+$escaped*)+{' => handleRuleSet(lexer, makeRuleSet, BraceClose),
	'@[$selector \\(\\),]+{' => {
		handleRuleSet(lexer, makeAtRule, BraceClose);
	},
	declaration => {
		var tokens = parse(ByteData.ofString(lexer.current), 'declaration', declarations);
		Keyword(Declaration(tokens[0], tokens[1]));
	},
	'{' => BraceOpen,
	'}' => BraceClose,
	';' => Semicolon,
	':' => Colon,
	'#' => Hash,
	',' => Comma,
	]);
	
	public static var comments = Mo.rules([
	'\\*/' => '*/',
	'[^*/]+' => lexer.current,
	'\\*' => '*',
	'/' => '/',
	]);
	
	private static function handleSelectors(lexer:Lexer, single:Int->CssSelectors) {
		var idx = -1;
		var result = null;
		var tmp = new StringBuf();
		var current = lexer.current;
		var len = current.length - 1;
		var type:Null<CombinatorType> = null;
		
		// Putting `-(current.lenght+1)...1` causes Neko to crash with a stringbuf error.
		for (i in -current.length + 1...1) tmp.addChar( current.fastCodeAt( -i ) );
		var combinatorLexer = new Lexer(ByteData.ofString( tmp.toString() ), 'combinator');
		
		try while (true) {
			type = combinatorLexer.token( combinators );
			
			switch (type) {
				case None, Descendant, Child, Adjacent, General:
					idx = current.length - combinatorLexer.pos;
					if (type != Descendant) break;
					
				case _:
					idx = 0;
					
			}
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			//trace( e );
		}
		
		if (type == None) lexer.pos--;
		
		if (type != null) {
			var tokens = [];
			try while (true) {
				tokens.push( lexer.token(selectors) );
				
			} catch (e:Eof) {
				
			} catch (e:Dynamic) {
				trace( e );
				trace( lexer.input );
				trace( lexer.input.readString(0, lexer.pos) );
			}
			
			var next = tokens.length > 1 ? CssSelectors.Group(tokens) : tokens[0];
			if (tokens.length > 0) result = Combinator(single(idx), next, type);
		}
		
		if (result == null) result =  single(idx);
		
		return result;
	}
	
	public static var combinators = Mo.rules([
	'(.?\u005c\u005c)?' => lexer.token( combinators ),	// reversed escape sequence
	'[.:\\[]' => None,
	' ' => Descendant,
	'>' => Child,
	'+' => Adjacent,
	'~' => General,
	'>>>' => Shadow,
	]);
	
	public static var scoped:Bool = false;
	
	public static var selectors = Mo.rules([
	' +' => lexer.token( selectors ),
	'/\\*[^\\*]*\\*/' => lexer.token( selectors ),
	'[\t\r\n]+' => lexer.token( selectors ),
	'\\*$combinator' => {
		handleSelectors(lexer, function(_) return Universal);
	},
	'([$ident]+$escaped*)+$combinator' => {
		var current = lexer.current.trim();
		var name = ['.'.code, ':'.code].indexOf(current.charCodeAt(current.length - 1)) > -1 
			? current.substring(0, current.length - 1).trim() 
			: current;
		handleSelectors(lexer, function(i) { 
			return Type( i > -1 ? name.substring(0, i).rtrim() : name );
		} );
	},
	'#([$ident]+$escaped*)+$combinator' => {
		var name = lexer.current;
		handleSelectors(lexer, function(i) {
			return ID( i > -1 ? name.substring(1, i).rtrim() : name.substring(1, name.length) );
		} );
	},
	'([\t\r\n]*\\.([$ident]+$escaped*)+)+$combinator' => {
		var parts = [];
		
		if (lexer.current.lastIndexOf('.') != 0) {
			parts = lexer.current.split('.').map(function(s) return s.trim()).filter(function(s) return s != '');
		} else {
			parts = [lexer.current.substring(1).trim()];
		}
		
		handleSelectors(lexer, function(i) {
			if (i > -1) {
				var j = parts.length -1;
				parts[j] = parts[j].substring(0, i - 1).trim();
			}
			
			return Class( parts );
		} );
	},
	'::?([$ident]+$escaped*)+[ ]*(\\(.*\\))?($combinator|[ ]*)' => {
		var current = lexer.current.trim();
		var expression = '';
		var index = current.length;
		
		if (current.endsWith(')')) {
			index = current.indexOf('(');
			expression = current.substring(index + 1, current.length - 1);
		}
		
		handleSelectors(lexer, function(i) {
			if (i > -1 && i < index) {
				index = i;
			}
			
			return Pseudo(current.substring(1, index).trim(), expression);
		} );
	},
	'\\[[$s]*([$ident]+$escaped*)+[$s]*([=~$\\*\\^\\|]+[$s]*[^\r\n\\[\\]]+)?\\]$combinator' => {
		var current = lexer.current;
		
		handleSelectors(lexer, function(i) {
			var tokens = parse(ByteData.ofString(current.substring(1, i == -1 ? current.length - 1 : i-1)), 'attributes', attributes);
			return Attribute( 
				(tokens.length > 0) ? tokens[0] : '', 
				(tokens.length > 1) ? tokens[1] : -1, 
				(tokens.length > 2) ? tokens[2] : '' 
			);
		} );
	},
	'([^,(]+,[^,)]+)+' => {
		var tokens = [];
		
		for (part in lexer.current.split(',')) {
			tokens = tokens.concat(parse(ByteData.ofString(part.trim()), 'css-group-selector', selectors));
		}
		
		CssSelectors.Group(tokens);
	},
	'>' => {
		!scoped
			? lexer.token( selectors )
			: Combinator(Pseudo('scope', ''), lexer.token( selectors ), Child);
	},
	'\\+' => {
		!scoped
			? Pseudo('not', '*')
			: Combinator(Pseudo('scope', ''), lexer.token( selectors ), Adjacent);
	},
	'~' => {
		!scoped
			? Pseudo('not', '*')
			: Combinator(Pseudo('scope', ''), lexer.token( selectors ), General);
	},
	]);
	
	public static var attributes = Mo.rules([
	'=' => Exact,
	'~=' => AttributeType.List,
	'\\|=' => DashList,
	'\\^=' => Prefix,
	'$=' => Suffix,
	'\\*=' => Contains,
	'[$s]*[^$s=~$\\|\\^\\*\\[\\]]+[$s]*' => {
		var value = lexer.current.trim();
		if (value.startsWith('"')) value = value.substring(1);
		if (value.endsWith('"')) value = value.substring(0, value.length - 1);
		value;
	}
	]);
	
	public static var declarations = Mo.rules([
	'[$ident]+[$s]*:' => {
		untyped lexer.pos--;
		lexer.current.substring(0, lexer.current.length - 1).trim();
	},
	':[$s]*[^;]+;' => lexer.current.substring(1, lexer.current.length-1).trim(),
	]);
	
	public static var mediaQueries = Mo.rules([
	'([^,]+,[^,]+)+' => {
		var tokens = [];
		
		for (part in lexer.current.split(',')) {
			tokens.push( parse(ByteData.ofString(part.trim()), 'group-media', mediaQueries) );
		}
		
		CssMedia.Group(tokens);
	},
	'(n|N)(o|O)(t|T)' => Not,
	'(o|O)(n|N)(l|L)(y|Y)' => Only,
	//'(a|A)(n|N)(d|D)|(a|A)(l|L)+' => lexer.token( mediaQueries ),
	'[$ident]+' => Feature(lexer.current),
	'[$ident]+[$s]*:[$s]*[$ident]+' => {
		var current = lexer.current;
		var parts = current.split(':');
		CssMedia.Expr(parts[0].trim(), parts[1].trim());
	},
	'\\(' => {
		var tokens = [];
		try while (true) {
			var token = lexer.token( mediaQueries );
			switch (token) {
				case Feature(')'): break;
				case _:
			}
			tokens.push( token );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return tokens[0];
	},
	'\\)' => Feature(')'),
	'[ :,]' => lexer.token( mediaQueries ),
	]);
	
	private static function parse<T>(value:ByteData, name:String, rule:Ruleset<T>):Array<T> {
		var lexer = new Css(value, name);
		var tokens = [];
		
		try while (true) {
			tokens.push( lexer.token( rule ) );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			//untyped trace( lexer.input.readString( lexer.curPos().pmin, lexer.curPos().pmax ) );
			trace( e );
			trace( name );
			trace( tokens );
			trace( value.readString(0, value.length) );
		}
		
		return tokens;
	}
	
}