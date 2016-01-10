package dtx;

/**
	A collection of static variables used to identify node type.

	Because these are different underlying types on different platforms, and because they are not constant, we cannot use an enum or a fake "abstract enum".

	Instead you can compare a `nodeType` from a `dtx.DOMNode` with one of these values.
	This will work with both `js.html.Node` and `Xml`.
**/
class DOMType {
	public static inline var DOCUMENT_NODE = #if js js.html.Node.DOCUMENT_NODE #else uhx.lexer.Html.NodeType.Document #end;
	public static inline var ELEMENT_NODE = #if js js.html.Node.ELEMENT_NODE #else uhx.lexer.Html.NodeType.Element #end;
	public static inline var TEXT_NODE = #if js js.html.Node.TEXT_NODE #else uhx.lexer.Html.NodeType.Text #end;
	public static inline var COMMENT_NODE = #if js js.html.Node.COMMENT_NODE #else uhx.lexer.Html.NodeType.Comment #end;
}