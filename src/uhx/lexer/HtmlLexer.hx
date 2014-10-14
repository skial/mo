package uhx.lexer;

import haxe.EnumTools;
import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import uhx.mo.Token;
import hxparse.Ruleset;
import hxparse.Position;
import haxe.ds.StringMap;
import hxparse.UnexpectedChar;

using StringTools;
using uhx.lexer.HtmlLexer;

private typedef Tokens = Array<Token<HtmlKeywords>>;

enum HtmlKeywords {
	End(name:String);
	Ref(entity:HtmlReference);
	Instruction(name:String, attributes:Array<String>);
	Tag(
		name:String, 
		attributes:Map<String,String>, 
		categories:Array<Category>, 
		tokens:Tokens,
		parent:Void->Token<HtmlKeywords>
	);
}

private class HtmlReference {
	
	public var name:String;
	public var tokens:Tokens;
	public var complete:Bool;
	public var parent:Void->Token<HtmlKeywords>;
	public var categories:Array<Category>;
	public var attributes:Map<String,String>;
	
	private var result:Token<HtmlKeywords> = null;
	
	public function new(
		name:String, attributes:Map<String,String>, 
		categories:Array<Category>, tokens:Tokens, 
		parent:Null<Void->Token<HtmlKeywords>>, complete:Bool
	) {
		this.name = name;
		if (parent != null) {
			this.parent = parent;
		} else {
			this.parent = this.get;
		}
		this.attributes = attributes;
		this.categories = categories;
		this.tokens = tokens;
		this.complete = complete;
	}
	
	public function get():Token<HtmlKeywords> {
		if (result == null) {
			result = Keyword(Tag( name, attributes, categories, tokens, parent ));
		}
		
		return result;
	}
	
	public function clone(deep:Bool):HtmlReference {
		return new HtmlReference(
			name, 
			[for (k in attributes.keys()) k => attributes.get(k)], 
			categories.copy(), 
			tokens.copy(), 
			parent,
			complete
		);
	}
	
}

@:enum abstract Category(Int) from Int to Int {
	public var Unknown = -1;
	public var Metadata = 0;
	public var Flow = 1;
	public var Sectioning = 2;
	public var Heading = 3;
	public var Phrasing = 4;
	public var Embedded = 5;
	public var Interactive = 6;
	public var Palpable = 7;
	public var Scripted = 8;
}

@:enum abstract Model(Int) from Int to Int {
	public var Empty = 1;
	public var Text = 2;
	public var Element = 3;
}

@:enum abstract NodeType(Int) from Int to Int {
	public var Unknown = -1;
	public var Document = 0;
	public var Comment = 1;
	public var Text = 2;
	public var Element = 3;
}

@:enum abstract HtmlTag(String) from String to String {
	public var Base = 'base';
	public var Link = 'link';
	public var Meta = 'meta';
	public var NoScript = 'noscript';
	public var Script = 'script';
	public var Style = 'style';
	public var Template = 'template';
	public var Title = 'title';
	public var A = 'a';
	public var Abbr = 'abbr';
	public var Address = 'address';
	public var Area = 'area';
	public var Article = 'article';
	public var Aside = 'aside';
	public var Audio = 'audio';
	public var B = 'b';
	public var Bdi = 'bdi';
	public var Bdo = 'bdo';
	public var BlockQuote = 'blockquote';
	public var Br = 'br';
	public var Button = 'button';
	public var Canvas = 'canvas';
	public var Cite = 'cite';
	public var Code = 'code';
	public var Data = 'data';
	public var DataList = 'datalist';
	public var Del = 'del';
	public var Details = 'details';
	public var Dfn = 'dfn';
	public var Dialog = 'dialog';
	public var Div = 'div';
	public var Dl = 'dl';
	public var Em = 'em';
	public var Embed = 'embed';
	public var FieldSet = 'fieldset';
	public var Figure = 'figure';
	public var Footer = 'footer';
	public var Form = 'form';
	public var H1 = 'h1';
	public var H2 = 'h2';
	public var H3 = 'h3';
	public var H4 = 'h4';
	public var H5 = 'h5';
	public var H6 = 'h6';
	public var Header = 'header';
	public var Hr = 'hr';
	public var I = 'i';
	public var Iframe = 'iframe';
	public var Img = 'img';
	public var Input = 'input';
	public var Ins = 'ins';
	public var Kbd = 'kbd';
	public var Keygen = 'keygen';
	public var Label = 'label';
	public var Main = 'main';
	public var Map = 'map';
	public var Mark = 'mark';
	public var Math = 'math';
	public var Menu = 'menu';
	public var Meter = 'meter';
	public var Nav = 'nav';
	public var Object = 'object';
	public var Ol = 'ol';
	public var Output = 'output';
	public var P = 'p';
	public var Pre = 'pre';
	public var Progress = 'progress';
	public var Q = 'q';
	public var Ruby = 'ruby';
	public var S = 's';
	public var Samp = 'samp';
	public var Section = 'section';
	public var Select = 'select';
	public var Small = 'small';
	public var Span = 'span';
	public var Strong = 'strong';
	public var Sub = 'sub';
	public var Sup = 'sup';
	public var Svg = 'svg';
	public var Table = 'table';
	public var TextArea = 'textarea';
	public var Time = 'time';
	public var U = 'u';
	public var Ul = 'ul';
	public var Var = 'var';
	public var Video = 'video';
	public var Wbr = 'wbr';
	
	public var Col = 'col';
	public var Command = 'command';
	public var FigCaption = 'figcaption';
	public var HGroup = 'hgroup';
	public var Param = 'param';
	public var RP = 'rp';
	public var RT = 'rt';
	public var Source = 'source';
	public var Summary = 'summary';
	public var Track = 'track';
	
	public var Content = 'content';
	
	public var Html = 'html';
	public var Head = 'head';
}

/**
 * ...
 * @author Skial Bainn
 */

class HtmlLexer extends Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var parent:Void->Token<HtmlKeywords> = null;
	public static var openTags:Array<HtmlReference> = [];
	
	public static var openClose = Mo.rules( [
	'<' => lexer.token( tags ),
	'>' => GreaterThan,
	' +' => Space(lexer.current.length),
	'\n' => Newline,
	'\r' => Carriage,
	'\t' => Tab(1),
	'[^<>]+' => Const( CString( lexer.current ) ),
	] );
	
	public static var tags = Mo.rules( [ 
	' +' => Space(lexer.current.length),
	'\r' => Carriage,
	'\n' => Newline,
	'\t' => Tab(1),
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
				
				switch (token) {
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
		
		Keyword( Instruction(tag, attrs) );
	},
	'/[^\r\n\t <>]+>' => {
		Keyword( End( lexer.current.substring(1, lexer.current.length -1) ) );
	},
	'[a-zA-Z0-9:]+' => {
		var tokens:Tokens = [];
		var tag:String = lexer.current;
		var categories = tag.categories();
		var model = tag.model();
		var attrs:Array<Array<String>> = [];
		var isVoid = 
		if (model == Model.Empty || categories.length == 1 && categories[0] == Category.Metadata) {
			true;
		} else {
			false;
		}
		
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
					
					switch (token) {
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
				
			} else if (e.char == '>') {
				untyped lexer.pos++;
			}
			
			
		} catch (e:Dynamic) {
			untyped console.log( e );
		}
		
		var ref = new HtmlReference(
			tag, 
			[for (pair in attrs) pair[0] => pair[1]], 
			categories, 
			tokens,
			parent,
			false
		);
		
		var position = -1;
		
		if (!isVoid) {
			
			switch (categories) {
				case x if (x.indexOf( Category.Metadata ) != -1):
					position = buildMetadata( ref, lexer );
					
				case _:
					position = buildChildren( ref, lexer );
					
			}
			
			
		} else {
			ref.complete = true;
		}
		
		if (position > -1 && !openTags[position].complete) {
			Keyword( Ref(ref) );
		} else {
			ref.complete = true;
			ref.get();
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
	'[^\r\n\t<> "\\[]+' => lexer.current,
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
	},
	'"' => {
		var value = '';
		
		try while (true) {
			var token = lexer.token( Mo.rules([ '"' => '"', '[^"]+' => lexer.current ])  );
			
			switch (token) {
				case '"':
					break;
					
				case _:
					
			}
			
			value += token;
		} catch (e:Dynamic) {
			untyped console.log( e );
		}
		'$value';
	}
	] );
	
	public static var instructionText = Mo.rules( [
	'[^\\]<>]+' => lexer.current,
	'\\]' => ']',
	'<' => '<',
	'>' => '>'
	] );
	
	public static var root = openClose;
	
	// Get the categories the each element fall into.
	private static function categories(tag:String):Array<Category> {
		/**
		Unknown = -1;
		Metadata = 0;
		Flow = 1;
		Sectioning = 2;
		Heading = 3;
		Phrasing = 4;
		Embedded = 5;
		Interactive = 6;
		Palpable = 7;
		Scripted = 8;
		 */
		return switch (tag) {
			case Base, Link, Meta, Title: [0];
			case Style: [0, 1];
			case Dialog, Hr: [1];
			case NoScript, Command: [0, 1, 4];
			case Area, Br, DataList, Del, Link, Meta, Time, Wbr: [1, 4];
			case TextArea: [1, 4, 6];
			case H1, H2, H3, H4, H5, H6, HGroup: [1, 3, 7];
			case Address, BlockQuote, Div, Dl, FieldSet, Figure,
				 Footer, Form, Header, Main, Menu, Ol, P, Pre, 
				 Table, Ul: [1, 7];
			case Article, Aside, Nav, Section: [1, 2, 7];
			case Abbr, B, Bdi, Bdo, Cite, Code, Data, Dfn, Em, 
				 I, Ins, Kbd, Map, Mark, Meter, Output, Progress,
				 Q, Ruby, S, Samp,  Small, Span, Strong,
				 Sub, Sup, U, Var: [1, 4, 7];
			case Details: [1, 6, 7];
			case Canvas, Math, Svg: [1, 4, 5, 7];
			case A, Button, Input, Keygen, Label, Select: [1, 4, 6, 7];
			case Audio, Embed, Iframe, Img, Object, Video: [1, 4, 5, 6, 7];
			case Script, Template: [0, 1, 4, 8];
			case _: [ -1];
		}
	}
	
	// Get the expected content model for the html element.
	private static function model(tag:String):Model {
		return switch (tag) {
			case Area, Base, Br, Col, Command, Embed, Hr, Img,
				 Input, Keygen, Link, Meta, Param, Source, Track,
				 Wbr:
				Model.Empty;
				
			case NoScript, Script, Style, Title, Template:
				Model.Text;
				
			case _:
				Model.Element;
				
		}
	}
	
	// Build descendant html elements
	private static function buildChildren(ref:HtmlReference, lexer:Lexer):Int {
		var position = openTags.push( ref ) - 1;
		
		var previousParent = parent;
		parent = ref.get;
		
		try while (true) {
			
			var token:Token<HtmlKeywords> = lexer.token( openClose );
			
			switch (token) {
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
					
				/*case Keyword( Tag(n, a, c, t, p) ):
					// I just want to change the `p` parent variable, not recreate it.
					token = Keyword( Tag(n, a, c, t, ref.get) );
					//p = ref.get;
					
				case Keyword( Ref(e) ):
					untyped console.log( e.name, e.parent().name );
					//e.parent = ref.get;
					//untyped console.log( e.name, e.parent().name );
					var clone = e.clone(true);
					clone.parent = ref.get;
					token = Keyword(Ref( clone ));
					untyped console.log( e.name, clone.parent().name );*/
					
				case _:
			}
			
			ref.tokens.push( token );
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
		
		parent = previousParent;
		
		return position;
	}
	
	private static function scriptedRule(tag:String) return Mo.rules( [
	'</[ ]*$tag[ ]*>' => {
		Keyword( End( lexer.current.substring(2, lexer.current.length - 1) ) );
	},
	'[^\r\n\t<]+' => {
		Const(CString( lexer.current ));
	},
	'[\r\n\t]+' => {
		Const(CString( lexer.current ));
	},
	'<' => {
		Const(CString( lexer.current ));
	},
	] );
	
	// Build Html Category of type Metadata
	private static function buildMetadata(ref:HtmlReference, lexer:Lexer):Int {
		var position = openTags.push( ref ) - 1;
		var rule = scriptedRule( ref.name );
		
		try while (true) {
			var token = lexer.token( rule );
			
			switch (token) {
				case Keyword(End( x )) if (x == ref.name):
					// Set the reference as complete.
					ref.complete = true;
					// Combine all tokens into one token.
					ref.tokens = [
						Const(CString( 
							[for (t in ref.tokens) switch(t) {
								case Const(CString(x)): x;
								case _: '';
							}].join('')
						))
					];
					break;
					
				case _:
					
			}
			
			ref.tokens.push( token );
		} catch (e:Dynamic) {
			untyped console.log( e );
		}
		
		return position;
	}
	
}