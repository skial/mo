package dtx.mo;

import uhx.mo.Token;
import dtx.mo.DOMNode;
import uhx.lexer.Html;

abstract DocumentOrElement(DOMNode) to DOMNode to Token<HtmlKeywords> {
	public inline function new(v:DOMNode) this = v;
	
	@:from public static inline function fromToken(v:Token<HtmlKeywords>):DocumentOrElement {
		return new DocumentOrElement( v );
	}
	
	@:from public static inline function fromDOMNode(v:DOMNode):DocumentOrElement {
		return new DocumentOrElement( v );
	}
}