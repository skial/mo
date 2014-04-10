package uhx.lexer;

import haxe.io.Eof;
import uhx.lexer.CssLexer.AttributeType;
import uhx.lexer.CssLexer.CssKeywords;
import uhx.lexer.CssLexer.CssSelectors;
import uhx.mo.Token;
import hxparse.Lexer;
import byte.ByteData;
import hxparse.Ruleset;
import uhx.mo.TokenDef;

using StringTools;

/**
 * ...
 * @author Skial Bainn
 */
private typedef Tokens = Array<Token<CssKeywords>>;

enum CssKeywords {
	RuleSet(selector:CssSelectors, tokens:Tokens);
	AtRule(name:String, query:CssMedia, tokens:Tokens);
	Declaration(name:String, value:String);
	CssComment(tokens:Tokens);
}

private typedef Selectors = Array<CssSelectors>;

enum CssSelectors {
	Group(selectors:Selectors);
	Type(name:String);
	Universal;
	Attribute(name:String, type:AttributeType, value:String);
	Class(names:Array<String>);
	ID(name:String);
	Pseudo(name:String);
	Combinator(selector:CssSelectors, next:CssSelectors, type:CombinatorType);
	Expr(tokens:Selectors);
}

enum AttributeType {
	Name(value:String);	// 	Just the attribute name
	Value(value:String);//	val
	Exact;				//	att=val
	List;				//	att~=val
	DashList;			//	att|=val
	Prefix;				//	att^=val
	Suffix;				//	att$=val
	Contains;			//	att*=val
}

enum CombinatorType {
	None;				// Used in `type.class`
	Child;				//	`>`
	Descendant;			//	` `
	Adjacent;			//	`+`
	General;			//	`~`
}

private typedef Queries = Array<CssMedia>;

enum CssMedia {
	Only;
	Not;
	Feature(name:String, value:String);
	Group(queries:Queries);
	Expr(tokens:Queries);
}
 
class CssLexer extends Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var s = ' \t\r\n';
	public static var ident = 'a-zA-Z0-9\\-\\_';
	public static var selector = 'a-zA-Z0-9:#=~\\.\\-\\_\\*\\^\\|';
	public static var any = 'a-zA-Z0-9 "\',%#~=:;@!$&\t\r\n\\{\\}\\(\\)\\[\\]\\|\\.\\-\\_\\*\\\\';
	public static var declaration = '[$ident]+[$s]*:[$s]*[^;]+;';
	public static var combinator = '( +| *> *| *\\+ *| *~ *|\\.)?';
	
	private static function makeRuleSet(rule:String, tokens:Tokens) {
		var selector = parse(ByteData.ofString(rule), 'selector', selectors);
		//untyped console.log( selector );
		return Keyword(RuleSet(selector.length > 1? CssSelectors.Group(selector) : selector[0], tokens));
	}
	
	private static function makeAtRule(rule:String, tokens:Tokens) {
		var index = rule.indexOf(' ');
		var query = parse(ByteData.ofString(rule.substring(index)), 'media query', mediaQueries);
		//untyped console.log(query);
		return Keyword(AtRule(rule.substring(1, index), query.length > 1? CssMedia.Group(query) : query[0], tokens));
	}
	
	private static function handleRuleSet(lexer:Lexer, make:String->Tokens->TokenDef<CssKeywords>, breakOn:TokenDef<CssKeywords>) {
		var current = lexer.current;
		var rule = current.substring(0, current.length - 1);
		
		var tokens:Tokens = [];
		
		try while (true) {
			var token:Token<CssKeywords> = lexer.token( root );
			switch (token.token) {
				case x if(x == breakOn): break;
				case _:
			}
			tokens.push( token );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return Mo.make(lexer, make(rule.trim(), tokens));
	}
	
	public static var root = Mo.rules([
	'[\n\r]|[ \t]*' => lexer.token( root ),
	'[$selector,"\'/ \\[\\]]+{' => handleRuleSet(lexer, makeRuleSet, BraceClose),
	'@[$selector \\(\\)]+{' => handleRuleSet(lexer, makeAtRule, BraceClose),
	declaration => {
		var tokens = parse(ByteData.ofString(lexer.current), 'declaration', declarations);
		Mo.make(lexer, Keyword(Declaration(tokens[0], tokens[1])));
	},
	'{' => Mo.make(lexer, BraceOpen),
	'}' => Mo.make(lexer, BraceClose),
	';' => Mo.make(lexer, Semicolon),
	':' => Mo.make(lexer, Colon),
	'#' => Mo.make(lexer, Hash),
	',' => Mo.make(lexer, Comma),
	'/\\*[^\\*]+\\*/' => Mo.make(lexer, Comment(lexer.current)),
	]);
	
	private static function handleSelectors(lexer:Lexer, single:CssSelectors) {
		var current = lexer.current;
		var result = single;
		
		var len = current.length-1;
		var type = null;
		
		while (len > 0) {
			switch (current.charCodeAt(len)) {
				case ' '.code: 
					type = Descendant;
					
				case '.'.code:
					// Used for `type.class` instances.
					// Not an actual css spec combinator.
					type = None;
					lexer.pos--;
					break;
					
				case '>'.code: 
					type = Child;
					len = 0;
					break;
					
				case '+'.code:
					type = Adjacent;
					len = 0;
					break;
					
				case '~'.code:
					type = General;
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
			if (tokens.length > 0) result = Combinator(single, next, type);
		}
		
		return result;
	}
	
	public static var selectors = Mo.rules([
	'([^,]+,[^,]+)+' => {
		var tokens = [];
		
		for (part in lexer.current.split(',')) {
			tokens = tokens.concat(parse(ByteData.ofString(part.trim()), 'group-selector', selectors));
		}
		
		CssSelectors.Group(tokens);
	},
	'\\*$combinator' => handleSelectors(lexer, Universal),
	'[$ident]+$combinator' => {
		var current = lexer.current.trim();
		var name = current.endsWith('.') ? current.substring(0, current.length - 1).trim() : current;
		handleSelectors(lexer, Type( name ));
	},
	'(\\.[$ident]+)+$combinator' => {
		var parts = [];
		
		if (lexer.current.lastIndexOf('.') != 0) {
			parts = lexer.current.split('.').map(function(s) return s.trim());
		} else {
			parts = [lexer.current.substring(1).trim()];
		}
		handleSelectors(lexer, Class( parts ));
	},
	'::?[$ident]+$combinator' => handleSelectors(lexer, Pseudo(lexer.current.replace(':', '').trim())),
	'\\[[$s]*[$ident]+[$s]*([=~$\\*\\^\\|]+[$s]*[$ident/"\']+)?\\]' => {
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
	'\\(' => {
		var tokens = [];
		try while (true) {
			var token = lexer.token( selectors );
			switch (token) {
				case Type(')'): break;
				case _:
			}
			tokens.push( token );
		}  catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return CssSelectors.Expr(tokens);
	},
	'\\)' => Type(')'),
	'[,: ]' => lexer.token( selectors ),
	]);
	
	public static var attributes = Mo.rules([
	'[$s]*[$ident]+[$s]*' => Name(lexer.current.trim()),
	'[$s]*[$ident/"\']+' => Value(lexer.current.trim()),
	'=' => Exact,
	'~=' => AttributeType.List,
	'\\|=' => DashList,
	'\\^=' => Prefix,
	'$=' => Suffix,
	'\\*=' => Contains,
	]);
	
	public static var declarations = Mo.rules([
	'[$ident]+[$s]*:' => {
		untyped lexer.pos--;
		lexer.current.substring(0, lexer.current.length - 1).trim();
	},
	':[$s]*[^;]+;' => lexer.current.substring(1, lexer.current.length-1).trim(),
	]);
	
	public static var mediaQueries = Mo.rules([
	'(n|N)(o|O)(t|T)' => Not,
	'(o|O)(n|N)(l|L)(y|Y)' => Only,
	'(a|A)(n|N)(d|D)|(a|A)(l|L)+' => lexer.token( mediaQueries ),
	'[$ident]+' => Feature(lexer.current, ''),
	'[$ident]+[$s]*:[$s]*[$ident]+' => {
		var current = lexer.current;
		var parts = current.split(':');
		Feature(parts[0].trim(), parts[1].trim());
	},
	'\\(' => {
		var tokens = [];
		try while (true) {
			var token = lexer.token( mediaQueries );
			switch (token) {
				case Feature(')', ''): break;
				case _:
			}
			tokens.push( token );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return CssMedia.Expr(tokens);
	},
	'\\)' => Feature(')', ''),
	'[ :,]' => lexer.token( mediaQueries ),
	]);
	
	private static function parse<T>(value:ByteData, name:String, rule:Ruleset<T>):Array<T> {
		var lexer = new CssLexer(value, name);
		var tokens = [];
		
		try while (true) {
			tokens.push( lexer.token( rule ) );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return tokens;
	}
	
}