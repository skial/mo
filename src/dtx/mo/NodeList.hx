package dtx.mo;

import uhx.mo.Token;
import uhx.lexer.Html;

private typedef Tokens = Array<Token<HtmlKeywords>>;
private typedef DOMNodes = Array<DOMNode>;

/**
 * ...
 * @author Skial Bainn
 */
@:forward abstract NodeList(DOMNodes) from Tokens from DOMNodes to DOMNodes {
	
	public var length(get, never):Int;
	
	@:noCompletion public inline function new(v:DOMNodes) this = v;
	
	@:arrayAccess @:noCompletion public inline function get(i:Int):DOMNode return this[i];
	@:arrayAccess @:noCompletion public inline function set(i:Int, v:DOMNode):DOMNode {
		this[i] = v;
		return v;
	}
	
	public function indexOf(x:DOMNode, ?fromIndex:Int = 0):Int {
		var result = -1;
		
		for (i in fromIndex...this.length) if (this[i].equals( x )) {
			result = i;
			break;
		}
		
		return result;
	}
	
	public function lastIndexOf(x:DOMNode, ?fromIndex:Int):Int {
		var result = -1;
		var i = fromIndex == null ? this.length - 1 : fromIndex;
		while (i >= 0) if (this[i].equals( x )) {
			result = i;
			break;
		} else {
			i--;
		}
		
		return result;
	}
	
	private function get_length():Int return this.length;
	
}