package dtx.mo;

import uhx.mo.Token;
import uhx.lexer.HtmlLexer;
import byte.ByteData;

/**
 * ...
 * @author Skial Bainn
 */
abstract DOMNode(Token<HtmlKeywords>) from Token<HtmlKeywords> to Token<HtmlKeywords> {
	public var innerHTML(get, set):String;
	public var nodeType(get, never):Int;
	public var nodeValue(get, set):String;
	public var nodeName(get, never):String;
	public var attributes(get, never):Iterable<{name:String, value:String}>;
	public var childNodes(get, never):Iterable<DOMNode>;
	public var parentNode(get, never):DOMNode;
	public var firstChild(get, never):DOMNode;
	public var lastChild(get, never):DOMNode;
	public var nextSibling(get, never):DOMNode;
	public var previousSibling(get, never):DOMNode;
	public var textContent(get, set):String;
	
	public inline function new(v:Token<HtmlKeywords>) this = v;
	
	public inline function token():Token<HtmlKeywords> return this;
	
	@:allow(dtx)
	function _getInnerHTML():String {
		var html = "";
		for (child in childNodes) {
			html += child.toString();
		}
		return html;
	}
	
	@:allow(dtx)
	function _setInnerHTML( html:String ):String {
		if (nodeType == DOMType.ELEMENT_NODE) {
			innerHTML = html;
		}
		return html;
	}
	
	public function hasChildNodes():Bool {
		return switch (this) {
			case Keyword(Tag(_, _, _, t, _)):
				t.length > 0;
				
			case Keyword(Ref(e)):
				e.tokens.length > 0;
				
			case _:
				false;
				
		}
	}
	
	public function getAttribute(name:String):String {
		return switch (this) {
			case Keyword(Tag(_, a, _, _, _)): 
				a.exists( name ) ? a.get( name ) : '';
				
			case Keyword(Ref(e)): 
				e.attributes.exists( name ) ? e.attributes.get( name ) : '';
				
			case _: 
				'';
		}
	}
	
	public function setAttribute(name:String, value:String):Void {
		switch (this) {
			case Keyword(Tag(_, a, _, _, _)):
				a.set( name, value );
				
			case Keyword(Ref(e)):
				e.attributes.set( name, value );
				
			case _:
				
		}
	}
	
	public function removeAttribute(name:String):Void {
		switch (this) {
			case Keyword(Tag(_, a, _, _, _)):
				a.remove( name );
				
			case Keyword(Ref(e)):
				e.attributes.remove( name );
				
			case _:
				
		}
	}
	
	public function appendChild(newChild:DOMNode):DOMNode {
		switch (this) {
			case Keyword(Tag(_, _, _, t, _)):
				t.push( newChild );
				
			case Keyword(Ref(e)):
				e.tokens.push( newChild );
				
			case _:
				
		}
		
		return newChild;
	}
	
	public function insertChild(newChild:DOMNode, index:Int):Void {
		switch (this) {
			case Keyword(Tag(_, _, _, t, _)):
				t.insert( index, newChild );
				
			case Keyword(Ref(e)):
				e.tokens.insert( index, newChild );
				
			case _:
				
		}
	}
	
	public function insertBefore(newChild:DOMNode, refChild:DOMNode):DOMNode {
		switch (this) {
			case Keyword(Tag(_, _, _, t, _)):
				t.insert( t.indexOf( refChild ), refChild );
				
			case Keyword(Ref(e)):
				e.tokens.insert( e.tokens.indexOf( refChild ), refChild );
				
			case _:
				
		}
		
		return newChild;
	}
	
	public function removeChild(oldChild:DOMNode):DOMNode {
		switch (this) {
			case Keyword(Tag(_, _, _, t, _)):
				t.remove( oldChild );
				
			case Keyword(Ref(e)):
				e.tokens.remove( oldChild );
				
			case _:
				
		}
		
		return oldChild;
	}
	
	public function cloneNode(deep:Bool):DOMNode {
		return switch (this) {
			case Keyword(Tag(n, a, c, t, p)):
				Keyword(Tag(
					n, 
					[for (k in a.keys()) k => a.get(k)], 
					c.copy(), 
					t.copy(),
					(p:DOMNode).cloneNode( deep )
				));
				
			case Keyword(Ref(e)):
				Keyword(Ref(e.clone( deep )));
				
			case Keyword(Instruction(n, a)):
				Keyword(Instruction(n, a.copy()));
				
			case Keyword(End(n)):
				Keyword(End(n));
				
			case _:
				this;
		}
	}
	
	@:to public function toString():String {
		var result = '';
		
		for (child in (this:DOMNode).childNodes) switch (child.token()) {
			case Keyword(Tag(n, _, _, t, _)):
				result += '<$n>' + [for (i in t) (i:DOMNode).toString()] + '</$n>';
				
			case Keyword(Ref(e)):
				result += '<${e.name}>' + [for (i in e.tokens) (i:DOMNode).toString()] + '</${e.name}>';
				
			case Const(CString(s)):
				result += s;
				
			case _:
				
		}
		
		return result;
	}
	
	public inline function get_innerHTML():String {
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
	}
	
	public function get_nodeType():Int {
		return switch (this) {
			case Keyword(Tag(name, _, _, _, _)):
				switch (name) {
					case uhx.lexer.HtmlLexer.HtmlTag.Html:
						uhx.lexer.HtmlLexer.NodeType.Document;
						
					case _:
						uhx.lexer.HtmlLexer.NodeType.Element;
						
				}
				
			case Keyword(Ref(ref)):
				switch (ref.name) {
					case uhx.lexer.HtmlLexer.HtmlTag.Html:
						uhx.lexer.HtmlLexer.NodeType.Document;
						
					case _:
						uhx.lexer.HtmlLexer.NodeType.Element;
						
				}
				
			case Const(CString(_)):
				uhx.lexer.HtmlLexer.NodeType.Text;
				
			case Keyword(Instruction(_, _)):
				uhx.lexer.HtmlLexer.NodeType.Comment;
				
			case Keyword(End(_)):
				uhx.lexer.HtmlLexer.NodeType.Unknown;
				
			case _:
				uhx.lexer.HtmlLexer.NodeType.Unknown;
				
		}
	}
	
	public function get_nodeValue():String {
		return switch (this) {
			case Const(CString(s)): 
				s;
				
			case Keyword(Instruction(_, a)):
				a.join(' ');
				
			case _:
				null;
		}
	}
	
	public function set_nodeValue(value:String):String {
		switch (this) {
			case Const(CString(s)): 
				s = value;
				
			case Keyword(Instruction(_, a)):
				a = [value];
				
			case _:
				
		}
		
		return value;
	}
	
	public function get_nodeName():String {
		return switch (this) {
			case Keyword(Tag(n, _, _, _, _)),Keyword(End(n)):
				n;
				
			case Const(CString(_)):
				'#text';
				
			case Keyword(Instruction(_, _)):
				'#comment';
				
			case _:
				null;
		}
	}
	
	public function get_attributes():Iterable<{name:String, value:String}> {
		var list = new List();
		
		switch (this) {
			case Keyword(Tag(_, a, _, _, _)):
				for (k in a.keys()) {
					list.push( { name: k, value: a.get( k ) } );
				}
				
			case Keyword(Ref(e)):
				for (k in e.attributes.keys()) {
					list.push( { name: k, value: e.attributes.get( k ) } );
				}
				
			case _:
				
		}
		
		return list;
	}
	
	public inline function get_childNodes():Array<DOMNode> {
		return switch (this) {
			case Keyword(Tag(_, _, _, t, _)): 
				t;
				
			case Keyword(Ref(e)): 
				e.tokens;
				
			case _: 
				[];
		}
	}
	
	public inline function iterator():Iterator<DOMNode> {
		return get_childNodes().iterator();
	}
	
	public inline function get_parentNode():DOMNode {
		return switch (this) {
			case Keyword(Tag(_, _, _, _, p)):
				p;
				
			case Keyword(Ref(e)):
				e.parent;
				
			case _:
				null;
		}
	}
	
	public inline function get_firstChild():DOMNode {
		return switch (this) {
			case Keyword(Tag(_, _, _, t, _)):
				t[0];
				
			case Keyword(Ref(e)):
				e.tokens[0];
				
			case _:
				null;
		}
	}
	
	public inline function get_lastChild():DOMNode {
		return switch (this) {
			case Keyword(Tag(_, _, _, t, _)):
				t[t.length-1];
				
			case Keyword(Ref(e)):
				e.tokens[e.tokens.length-1];
				
			case _:
				null;
		}
	}
	
	public function get_nextSibling():DOMNode {
		var parent = (this:DOMNode).parentNode;
		return parent.childNodes[parent.childNodes.indexOf( this ) + 1];
	}
	
	public function get_previousSibling():DOMNode {
		var parent = (this:DOMNode).parentNode;
		return parent.childNodes[parent.childNodes.indexOf( this ) - 1];
	}
	
	public function get_textContent():String {
		return '';
	}
	
	public function set_textContent(text:String):String {
		return text;
	}
	
}