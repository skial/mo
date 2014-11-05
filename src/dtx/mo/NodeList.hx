package dtx.mo;

import uhx.mo.Token;
import uhx.lexer.HtmlLexer;

private typedef Tokens = Array<Token<HtmlKeywords>>;

/**
 * ...
 * @author Skial Bainn
 */
@:forward abstract NodeList(Array<DOMNode>) from Tokens from Array<DOMNode> to Array<DOMNode> {
	public inline function new(v:Array<DOMNode>) this = v;
	
	@:arrayAccess @:noCompletion public inline function get(i:Int):DOMNode return this[i];
	@:arrayAccess @:noCompletion public inline function set(i:Int, v:DOMNode):DOMNode {
		this[i] = v;
		return v;
	}
	
	public inline function iterator():Iterator<DOMNode> return this.iterator();
	
	public function indexOf(x:DOMNode, ?fromIndex:Int = 0):Int {
		var result = -1;
		
		for (i in fromIndex...this.length) if (this[i].equals( x )) {
			result = i;
			break;
		}
		
		return result;
	}
}