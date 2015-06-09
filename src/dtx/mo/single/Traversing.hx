package dtx.mo.single;

import dtx.DOMNode;
import uhx.mo.Token;
import uhx.lexer.HtmlLexer;
import dtx.single.ElementManipulation;
import uhx.select.html.Element as EQSA;
import uhx.select.html.Document as DQSA;

/**
 * ...
 * @author Skial Bainn
 */

class Traversing {
	
	static public inline function find(node:DOMNode, selector:String):DOMCollection {
		var newDOMCollection = new DOMCollection();
		if (node != null && selector != null && selector != '') if (ElementManipulation.isElement( node )) {
			newDOMCollection.addCollection( EQSA.querySelectorAll( node, selector ) );
			
		} else if (ElementManipulation.isDocument( node )) {
			newDOMCollection.addCollection( DQSA.querySelectorAll( node, selector ) );
			
		}
		
		return newDOMCollection;
	}
	
}