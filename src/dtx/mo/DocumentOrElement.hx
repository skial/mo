package dtx.mo;

import dtx.DOMNode;

abstract DocumentOrElement(DOMNode) to DOMNode {
	public inline function new(v:DOMNode) this = v;
	
	@:from public static inline function fromToken(v:DOMNode):DocumentOrElement {
		return new DocumentOrElement( v );
	}
}