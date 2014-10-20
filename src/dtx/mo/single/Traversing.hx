package dtx.mo.single;

import dtx.DOMNode;
import uhx.mo.Token;
import uhx.lexer.HtmlLexer;
import dtx.single.ElementManipulation;

/**
 * ...
 * @author Skial Bainn
 */

class Traversing {

	static public inline function find(node:DOMNode, selector:String):DOMCollection {
		var newDOMCollection = new DOMCollection();
		
		if (node != null && ElementManipulation.isElement( node ) || ElementManipulation.isDocument( node )) {
			newDOMCollection.addCollection( uhx.select.Html.find( (node.childNodes:Array<Token<HtmlKeywords>>), selector ) );
		}
		
		return newDOMCollection;
	}
	
}