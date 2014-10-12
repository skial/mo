package dtx.mo.collection;

/**
 * ...
 * @author Skial Bainn
 */
class Traversing {

	static public inline function find(collection:DOMCollection, selector:String):DOMCollection {
		var newDOMCollection = new DOMCollection();
		
		if (collection != null && selector != null && selector != "") {
			for (node in collection) {
				if (dtx.single.ElementManipulation.isElement(node) || dtx.single.ElementManipulation.isDocument(node)) {
					
				}
				
			}
			
		}
		
		return newDOMCollection;
	}
	
}