package dtx.mo.collection;

import uhx.mo.Token;
import uhx.lexer.HtmlLexer;
import dtx.single.ElementManipulation;

#if macro
import haxe.macro.Expr;
#end

using uhx.select.Html;

/**
 * ...
 * @author Skial Bainn
 */
class Traversing {

	public static macro function find(node:ExprOf<DOMNode>, selector:ExprOf<String>):ExprOf<DOMCollection> {
		return macro dtx.mo.collection.Traversing._find($node, $selector);
	}
	
	static public inline function _find(collection:DOMCollection, selector:String):DOMCollection {
		var newDOMCollection = new DOMCollection();
		
		if (collection != null && selector != null && selector != '') {
			for (node in collection) if (ElementManipulation.isElement( node )) {
				newDOMCollection.addCollection( node.querySelectorAll( selector ) );
				
			} else if (ElementManipulation.isDocument( node )) {
				newDOMCollection.addCollection( (node:DocumentOrElement).querySelectorAll( selector ) );
				
			}
		}
		
		return newDOMCollection;
	}
	
}