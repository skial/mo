package dtx.mo;

import haxe.io.Eof;
import hxparse.Lexer;
import uhx.mo.Token;
import uhx.lexer.HtmlLexer;
import byte.ByteData;

/**
 * ...
 * @author Skial Bainn
 */
abstract DOMNode(Token<HtmlKeywords>) from Token<HtmlKeywords> to Token<HtmlKeywords> {
	//public var innerHTML(get, set):String;
	public var nodeType(get, never):Int;
	public var nodeValue(get, set):String;
	public var nodeName(get, never):String;
	public var attributes(get, never):Iterable<{name:String, value:String}>;
	public var childNodes(get, set):Iterable<DOMNode>;
	public var parentNode(get, set):DOMNode;
	public var firstChild(get, never):DOMNode;
	public var lastChild(get, never):DOMNode;
	public var nextSibling(get, never):DOMNode;
	public var previousSibling(get, never):DOMNode;
	public var textContent(get, set):String;
	
	public inline function new(v:Token<HtmlKeywords>) this = v;
	
	public inline function token():Token<HtmlKeywords> return this;
	
	@:op(A == B) 
	@:noCompletion 
	public static inline function toBool1(a:DOMNode, b:DOMNode):Bool {
		return a.equals( b );
	}
	
	@:op(A == B) 
	@:noCompletion 
	public static inline function toBool2(a:Null<DOMNode>, b:Null<DOMNode>):Bool {
		return a != null && b != null && a.equals( b );
	}
	
	@:op(A == B)
	@:noCompletion
	public inline function toBool3(b:Token<HtmlKeywords>):Bool {
		return this.equals( b );
	}
	
	@:allow(dtx)
	inline function _getInnerHTML():String {
		var html = "";
		for (child in childNodes) {
			html += child.toString();
		}
		return html;
	}
	
	@:allow(dtx)
	inline function _setInnerHTML(html:String):String {
		
		if (nodeType == DOMType.ELEMENT_NODE) {
			var lexer = new HtmlLexer( ByteData.ofString( html ), 'innerHTML' );
			var tokens = [];
			
			try while (true) {
				tokens.push( lexer.token( HtmlLexer.root ) );
			} catch(e:Eof) { } catch (e:Dynamic) { }
			
			switch (this) {
				case Keyword(Tag(e)):
					e.tokens = tokens;
					/*for (t in (e.tokens:Array<DOMNode>)) {
						t.parentNode = (this:DOMNode);
					}*/
					
				case _:
					
			}
			
		}
		
		return html;
	}
	
	public function hasChildNodes():Bool {
		return switch (this) {
			case Keyword(Tag(e)):
				e.tokens.length > 0;
				
			case _:
				false;
				
		}
	}
	
	public function hasAttributes():Bool {
		return switch (this) {
			case Keyword(Tag(e)):
				e.attributes.iterator().hasNext();
				
			case _:
				false;
		}
	}
	
	public function getAttribute(name:String):String {
		return switch (this) {
			case Keyword(Tag(e)) if (e.attributes.exists( name )): 
				StringTools.htmlUnescape( e.attributes.get( name ) );
				
			case _: 
				'';
		}
	}
	
	public function setAttribute(name:String, value:String):Void {
		switch (this) {
			case Keyword(Tag(e)):
				e.attributes.set( name, value );
				
			case _:
				
		}
	}
	
	public function removeAttribute(name:String):Void {
		switch (this) {
			case Keyword(Tag(e)):
				e.attributes.remove( name );
				
			case _:
				
		}
	}
	
	public function appendChild(newChild:DOMNode):DOMNode {
		switch (this) {
			case Keyword(Tag(e)):
				if (newChild.parentNode != null) {
					newChild.parentNode.removeChild( newChild );
				}
				
				newChild.parentNode = this;
				e.tokens.push( newChild );
				
			case _:
				
		}
		
		return newChild;
	}
	
	public function insertChild(newChild:DOMNode, index:Int):Void {
		switch (this) {
			case Keyword(Tag(e)):
				if (newChild.parentNode != null) {
					newChild.parentNode.removeChild( newChild );
				}
				
				newChild.parentNode = this;
				e.tokens.insert( index, newChild );
				
			case _:
				
		}
	}
	
	public function insertBefore(newChild:DOMNode, refChild:DOMNode):DOMNode {
		switch (this) {
			case Keyword(Tag(e)):
				if (newChild.parentNode != null) {
					newChild.parentNode.removeChild( newChild );
				}
				
				newChild.parentNode = this;
				e.tokens.insert( (e.tokens:NodeList).indexOf( refChild ), newChild );
				
			case _:
				
		}
		
		return newChild;
	}
	
	public function removeChild(oldChild:DOMNode):DOMNode {
		switch (this) {
			case Keyword(Tag(e)):
				e.tokens.remove( oldChild );
				oldChild.parentNode = null;
				
			case _:
				
		}
		
		return oldChild;
	}
	
	public function cloneNode(deep:Bool):DOMNode {
		return switch (this) {
			case Keyword(HtmlKeywords.Text(e)):
				Keyword(HtmlKeywords.Text(e.clone( deep )));
				
			case Keyword(Tag(e)):
				Keyword(Tag(e.clone( deep )));
				
			case Keyword(Instruction(e)):
				Keyword(Instruction(e.clone( deep )));
				
			case Keyword(End(n)):
				Keyword(End('$n'));
				
			case Const(CString(s)):
				Const(CString('$s'));
				
			case _:
				null;
		}
	}
	
	/**
	 * Do **not** put @:to on this method. It messes with 
	 * `using Detox; ... '#selector'.find()` and `ele.find('#selector')`.
	 */
	public function toString():String {
		var result = '';
		
		for (child in (this:DOMNode).childNodes) switch (child.token()) {
			case Keyword(Tag(e)):
				result += '<${e.name}';
				if (e.attributes.iterator().hasNext()) result += [for (k in e.attributes.keys()) '$k="${e.attributes.get(k)}"'].join(' ');
				result += (e.selfClosing ? '/>' : '>' );
				if (!e.selfClosing) result += ' ' + [for (i in e.tokens) (i:DOMNode).toString()].join('') + '</${e.name}>';
				
			case Keyword(Instruction(e)):
				if (e.tokens[0] == '--' && e.tokens[e.tokens.length - 1] == '--') {
					result += '<!-- ' + [for (i in 1...e.tokens.length - 1) e.tokens[i]].join(' ') + ' -->';
				} else {
					result += '<!' + [for (i in e.tokens) i].join(' ') + '>';
				}
				
			case Keyword(HtmlKeywords.Text(e)):
				result += e.tokens;
				
			case Const(CString(s)):
				result += s;
				
			case _:
				
		}
		
		return result;
	}
	
	/*public inline function get_innerHTML():String {
		return toString();
	}
	
	public function set_innerHTML(value:String):String {
		var lexer = new HtmlLexer( ByteData.ofString( value ), 'innerHTML' );
		var tokens = [];
		
		try while (true) {
			tokens.push( lexer.token( HtmlLexer.root ) );
		} catch (e:Dynamic) { }
		
		switch (this) {
			case Keyword(Tag(_, _, _, t, _)):
				t = tokens;
				
			case Keyword(Ref(e)):
				e.tokens = tokens;
				
			case _:
				
		}
		return value;
	}*/
	
	public function get_nodeType():Int {
		return switch (this) {
			case Keyword(Tag(ref)):
				/*switch (ref.name) {
					case uhx.lexer.HtmlLexer.HtmlTag.Html:
						uhx.lexer.HtmlLexer.NodeType.Document;
						
					case _:*/
						uhx.lexer.HtmlLexer.NodeType.Element;
						
				//}
				
			case Keyword(HtmlKeywords.Text(_)):
				uhx.lexer.HtmlLexer.NodeType.Text;
				
			case Keyword(Instruction(_)):
				uhx.lexer.HtmlLexer.NodeType.Comment;
				
			case _:
				uhx.lexer.HtmlLexer.NodeType.Unknown;
				
		}
	}
	
	public function get_nodeValue():String {
		return switch (this) {
			case Const(CString(s)): 
				StringTools.htmlUnescape( s );
				
			case Keyword(HtmlKeywords.Text(e)):
				StringTools.htmlUnescape( e.tokens );
				
			case Keyword(Instruction( { tokens:a } )):
				if (a[0] == '--' && a[a.length - 1] == '--') {
					//a.slice(1, a.length - 1).join(' ');
					a.slice(1, a.length - 1).join('');
				} else {
					a.join('');
				}
				
			case _:
				'';
		}
	}
	
	public /*inline*/ function set_nodeValue(value:String):String {
		switch (this) {
			case Const(s): 
				//this = Const(CString(value));
				// TODO figure out less hacky solution;
				s.getParameters()[0] = value;
				
			case Keyword(HtmlKeywords.Text(e)):
				e.tokens = value;
				
			case Keyword(Instruction(ref)):
				if (ref.tokens[0] == '--' && ref.tokens[ref.tokens.length -1] == '--') {
					ref.tokens = [];
					var l = new Lexer( ByteData.ofString('--$value--'), 'set_nodevalue' );
					try while (true) {
						ref.tokens.push( l.token( HtmlLexer.instructions ) );
					} catch (e:Dynamic) { }
				} else {
					ref.tokens = [];
					var l = new Lexer( ByteData.ofString(value), 'set_nodevalue' );
					try while (true) {
						ref.tokens.push( l.token( HtmlLexer.instructions ) );
					} catch (e:Dynamic) { }
				}
				//this = Keyword(Instruction(n, [value]));
				
			case _:
				
		}
		return value;
	}
	
	public function get_nodeName():String {
		return switch (this) {
			case Keyword(Tag(ref)):
				ref.name;
				
			case Keyword(End(n)):
				n;
				
			case Const(CString(_)) | Keyword(HtmlKeywords.Text(_)):
				'#text';
				
			case Keyword(Instruction(_)):
				'#comment';
				
			case _:
				null;
		}
	}
	
	public function get_attributes():Iterable<{name:String, value:String}> {
		var list = new List();
		
		switch (this) {
			case Keyword(Tag(e)):
				for (k in e.attributes.keys()) {
					list.push( { name: k, value: e.attributes.get( k ) } );
				}
				
			case _:
				
		}
		
		return list;
	}
	
	public inline function get_childNodes():NodeList {
		return switch (this) {
			case Keyword(Tag(e)): 
				e.tokens;
				
			case _: 
				[];
		}
	}
	
	public inline function set_childNodes(v:Iterable<DOMNode>):Iterable<DOMNode> {
		return switch (this) {
			case Keyword(Tag(e)):
				e.tokens = cast v;
				
			case _:
				[];
				
		}
	}
	
	public inline function iterator():Iterator<DOMNode> {
		return get_childNodes().iterator();
	}
	
	public inline function get_parentNode():DOMNode {
		return switch (this) {
			case Keyword(HtmlKeywords.Text(e)):
				e.parent();
				
			case Keyword(Tag(e)):
				e.parent();
				
			case Keyword(Instruction(e)):
				e.parent();
				
			case _:
				null;
		}
	}
	
	public inline function set_parentNode(v:DOMNode):DOMNode {
		switch (this) {
			case Keyword(HtmlKeywords.Text(e)): e.parent = function() return v.token();
			case Keyword(Tag(e)): e.parent = function() return v.token();
			case Keyword(Instruction(e)): e.parent = function() return v.token();
			case _:
		}
		return v;
	}
	
	public function get_firstChild():DOMNode {
		return switch (this) {
			case Keyword(Tag(e)):
				e.tokens[0];
				
			case _:
				null;
		}
	}
	
	public function get_lastChild():DOMNode {
		return switch (this) {
			case Keyword(Tag(e)):
				e.tokens[e.tokens.length-1];
				
			case _:
				null;
		}
	}
	
	public function get_nextSibling():DOMNode {
		var parent = (this:DOMNode).parentNode;
		return parent != null ? parent.childNodes[parent.childNodes.indexOf( this ) + 1] : null;
	}
	
	public function get_previousSibling():DOMNode {
		var parent = (this:DOMNode).parentNode;
		return parent != null ? parent.childNodes[parent.childNodes.indexOf( this ) - 1] : null;
	}
	
	public function get_textContent():String {
		var result = '';
		
		switch (this) {
			case Const(CString(s)):
				result += s;
				
			case Keyword(HtmlKeywords.Text(e)):
				result += e.tokens;
				
			case Keyword(Tag(e)):
				for (i in (e.tokens:Array<DOMNode>).filter(function(f) return !f.token().match(Keyword(Instruction(_))))) {
					result += i.textContent;
				}
				
			case _:
				result = nodeValue;
				
		}
		
		return result;
	}
	
	public /*inline*/ function set_textContent(text:String):String {
		switch (this) {
			case Const(s):
				// TODO find less hacky solution.
				s.getParameters()[0] = text;
				
			case Keyword(HtmlKeywords.Text(e)):
				e.tokens = text;
				
			case Keyword(Tag(e)):
				e.tokens = [Keyword(HtmlKeywords.Text( new Ref(text, function() return this) ))];
				//this = Keyword(Tag(e));
				
			case Keyword(Instruction(e)):
				//this = Keyword(Instruction(n, [text]));
				e.tokens = [text];
				
			case _:
				
		}
		
		return text;
	}
	
}