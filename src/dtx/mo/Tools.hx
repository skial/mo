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
		var elm:DOMNode = null;
		if (tagName != null) {
			// Haxe doesn't validate the name, so we should.
			// I'm going to use a simplified (but not entirely accurate) validation.  See:
			// http://stackoverflow.com/questions/3158274/what-would-be-a-regex-for-valid-xml-names
			
			// If it is valid, create, if it's not, return null
			var valid = ~/^[a-zA-Z_:]([a-zA-Z0-9_:\.])*$/;
			elm = (valid.match(tagName)) ? Keyword(Tag(tagName, new Map(), [], [], null)) : null;
		}
		return elm;
	}
	
	static var firstTag:EReg = ~/<([a-z]+)[ \/>]/;
	
	public static function parse(html:String):DOMCollection {
		var q:DOMCollection;
		if (html != null && html != "") {
			var n:DOMNode = create("div");
			
			//
			// TODO: report this bug to haxe mailing list.
			// this is allowed:
			// n.setInnerHTML("");
			// But this doesn't get swapped out to it's "using" function
			// Presumably because this class is a dependency of the Detox?
			// Either way haxe shouldn't do that...
			dtx.single.ElementManipulation.setInnerHTML(n, html);
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