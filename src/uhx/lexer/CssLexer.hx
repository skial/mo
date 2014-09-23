package uhx.lexer;

import haxe.io.Eof;
import uhx.lexer.CssLexer.AttributeType;
import uhx.lexer.CssLexer.CssKeywords;
import uhx.lexer.CssLexer.CssSelectors;
import uhx.mo.Token;
import hxparse.Lexer;
import byte.ByteData;
import hxparse.Ruleset;

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
	Expr(tokens:Selectors);
}

enum AttributeType {
	Name(value:String);	// 	Just the attribute name
	Value(value:String);//	val
	Exact;				//	att=val
	List;				//	att~=val
	@split DashList;	//	att|=val
	Prefix;				//	att^=val
	Suffix;				//	att$=val
	Contains;			//	att*=val
}

@:enum abstract CombinatorType(Int) from Int to Int {
	public var None = 1;				// Used in `type.class` and `type:pseudo`
	public var Child = 2;				//	`>`
	public var Descendant = 3;			//	` `
	public var Adjacent = 4;			//	`+`
	public var General = 5;				//	`~`
}

private typedef Queries = Array<CssMedia>;

enum CssMedia {
	Only;
	Not;
	Feature(name:String);
	Group(queries:Array<Queries>);
	Expr(name:String, value:String);
}
 
class CssLexer extends Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var s = ' \t\r\n';
	public static var ident = 'a-zA-Z0-9\\-\\_';
	public static var selector = 'a-zA-Z0-9$:#=>~\\.\\-\\_\\*\\^\\|';
	public static var any = 'a-zA-Z0-9 "\',%#~=:;@!$&\t\r\n\\{\\}\\(\\)\\[\\]\\|\\.\\-\\_\\*\\\\';
	public static var declaration = '[$ident]+[$s]*:[$s]*[^;{]+;';
	public static var combinator = '( +| *> *| *\\+ *| *~ *|\\.)?';
	
	private static function makeRuleSet(rule:String, tokens:Tokens) {
		var selector = parse(ByteData.ofString(rule), 'selector', selectors);
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
	'[^\r\n/@}{][$selector,"\'/ \\[\\]\\(\\)$s]+{' => handleRuleSet(lexer, makeRuleSet, BraceClose),
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
		var current = lexer.current;
		var result = null;
		var len = current.length - 1;
		var idx = -1;
		var type = null;
		
		while (len > 0) {
			switch (current.charCodeAt(len)) {
				case ' '.code: 
					type = Descendant;
					idx = len;
					
				case '.'.code, ':'.code:
					// Used for `type.class` or `type:pseudo` instances.
					// Not an actual css spec combinator.
					type = None;
					idx = len;
					lexer.pos--;
					break;
					
				case '>'.code: 
					type = Child;
					idx = len;
					len = 0;
					break;
					
				case '+'.code:
					type = Adjacent;
					idx = len;
					len = 0;
					break;
					
				case '~'.code:
					type = General;
					idx = len;
					len = 0;
					break;
					
				case _:
					len = 0;
					break;
			}
			len--;
		}
		
		if (type != null) {
			var tokens = [];
			try while (true) {
				tokens.push( lexer.token(selectors) );
			} catch (e:Eof) {
				
			} catch (e:Dynamic) {
				trace( e );
			}
			
			var next = tokens.length > 1 ? CssSelectors.Group(tokens) : tokens[0];
			if (tokens.length > 0) result = Combinator(single(idx), next, type);
		}
		
		if (result == null) result = single(idx);
		
		return result;
	}
	
	public static var selectors = Mo.rules([
	' +' => lexer.token( selectors ),
	'/\\*[^*]+\\*/' => lexer.token( selectors ),
	'[\t\r\n]+' => lexer.token( selectors ),
	'\\*$combinator' => {
		handleSelectors(lexer, function(_) return Universal);
	},
	'[$ident]+$combinator' => {
		var current = lexer.current.trim();
		var name = ['.'.code, ':'.code].indexOf(current.charCodeAt(current.length - 1)) > -1 
			? current.substring(0, current.length - 1).trim() 
			: current;
		handleSelectors(lexer, function(i) { 
			return Type( i > -1 ? name.substring(0, i).rtrim() : name );
		} );
	},
	'#[$ident]+$combinator' => {
		var name = lexer.current;
		handleSelectors(lexer, function(i) {
			return ID( i > -1 ? name.substring(1, i).rtrim() : name.substring(1, name.length) );
		} );
	},
	'([$s]*\\.[$ident]+)+$combinator' => {
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
	'::?[$ident]+[ ]*(\\([^()]*\\))?($combinator|[ ]*)' => {
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
	'\\[[$s]*[$ident]+[$s]*([=~$\\*\\^\\|]+[$s]*[^\r\n]+)?\\]' => {
		var c = lexer.current;
		
		var t = parse(ByteData.ofString(c.substring(1, c.length - 1)), 'attributes', attributes);
		var name = '';
		var type = null;
		var value = '';
		
		for (i in 0...t.length) switch(i) {
			case 0: name = std.Type.enumParameters(t[0])[0];
			case 1: type = t[1];
			case 2: value = std.Type.enumParameters(t[2])[0];
			case _:
		}
		Attribute(name, type == null ? t[0] : type, value);
	},
	'([^,]+,[^,]+)+' => {
		var tokens = [];
		
		for (part in lexer.current.split(',')) {
			tokens = tokens.concat(parse(ByteData.ofString(part.trim()), 'group-selector', selectors));
		}
		
		CssSelectors.Group(tokens);
	},
	'\\(' => {
		var tokens = [];
		try while (true) {
			var token = lexer.token( selectors );
			switch (token) {
				case Type(')'): break;
				case _:
			}
			tokens.push( token );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return CssSelectors.Expr(tokens);
	},
	'\\)' => Type(')'),
	'[,: ]' => lexer.token( selectors ),
	]);
	
	public static var attributes = Mo.rules([
	'=' => Exact,
	'~=' => AttributeType.List,
	'\\|=' => DashList,
	'\\^=' => Prefix,
	'$=' => Suffix,
	'\\*=' => Contains,
	'[$s]*[^$s=~$\\|\\^\\*]+[$s]*' => Name(lexer.current.trim()),
	'[$s]*[^$s=~$\\|\\^\\*]+' => Value(lexer.current.trim()),
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
		var lexer = new CssLexer(value, name);
		var tokens = [];
		
		try while (true) {
			tokens.push( lexer.token( rule ) );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			//untyped trace( lexer.input.readString( lexer.curPos().pmin, lexer.curPos().pmax ) );
			trace( e );
			trace( value.readString(0, value.length) );
		}
		
		return tokens;
	}
	
}