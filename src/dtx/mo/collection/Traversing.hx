package dtx.mo.collection;

import uhx.mo.Token;
import uhx.lexer.HtmlLexer;
import dtx.single.ElementManipulation;
import uhx.select.html.Element as EQSA;
import uhx.select.html.Document as DQSA;
import uhx.select.html.Collection as CQSA;

/**
 * ...
 * @author Skial Bainn
 */
class Traversing {
	
	static public inline function find(collection:DOMCollection, selector:String):DOMCollection {
		var newDOMCollection = new DOMCollection();
		if (collection != null && selector != null && selector != '') {
			for (node in collection) if (ElementManipulation.isElement( node )) {
				newDOMCollection.addCollection( EQSA.querySelectorAll( node, selector ) );
				
			} else if (ElementManipulation.isDocument( node )) {
				newDOMCollection.addCollection( DQSA.querySelectorAll( node, selector ) );
				
			}
			//newDOMCollection.addCollection( CQSA.querySelectorAll( collection.collection, selector ) );
		}
		
		return newDOMCollection;
	}
	
}