package dtx.mo;

import dtx.DOMNode;
import uhx.mo.Token;
import uhx.lexer.HtmlLexer;

@:access(dtx.std)
class Tools {
	
	public static var document(get_document,null):DocumentOrElement;

	static inline function get_document():DocumentOrElement {
		if (document == null) {
			document = Keyword(Tag('html', new Map(), [], [], null));
		}
		return document;
	}
	
	public static function toCollection(n:DOMNode):DOMCollection {
		return new DOMCollection([n]);
	}
	
	public static function find(selector:String):DOMCollection {
		return dtx.single.Traversing.find(document, selector);
	}
	
	public static function create(tagName:String):DOMNode {
		return new DOMNode(Keyword(Tag(tagName, new Map(), [], [], null)));
	}
	
	static var firstTag:EReg = ~/<([a-z]+)[ \/>]/;
	
	public static function parse(html:String):DOMCollection {
		var q:DOMCollection;
		if (html != null && html != "") {
			var n:DOMNode = create("div");
			n = dtx.single.ElementManipulation.setInnerHTML(n, html);
			q = dtx.single.Traversing.children(n, false);
		}
		else
		{
			q = new DOMCollection();
		}
		return q;
	}
	
	public static function setDocument(newDocument:DOMNode):Void
	{
		// Only change the document if it has the right NodeType
		if (newDocument != null)
		{
			if (newDocument.nodeType == dtx.DOMType.DOCUMENT_NODE
				|| newDocument.nodeType == dtx.DOMType.ELEMENT_NODE)
			{
				// Because of the NodeType we can safely use this node as our document
				document = cast newDocument;
			}
		}
	}
	
}