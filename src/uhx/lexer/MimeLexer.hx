package uhx.lexer;

import haxe.ds.StringMap;

/**
 * ...
 * @author Skial Bainn
 * @see https://en.wikipedia.org/wiki/Internet_media_type
 * ---
 * top-level type name / subtype name [ ; parameters ]
 * top-level type name / [ tree. ] subtype name [ +suffix ] [ ; parameters ]
 */

class Mime {
	
	public var name:MimeToplevel;
	public var tree:Null<MimeTree>;
	public var subtype:Null<String>;
	public var suffix:Null<MimeSuffix>;
	public var parameters:Null<StringMap<Array<String>>>;
	
	public inline function new(n:MimeToplevel, t:Null<MimeTree>, st:Null<String>, su:Null<MimeSuffix>, p:Null<StringMap<Array<String>>>) {
		name = n;
		t = t;
		subtype = st;
		suffix = su;
		parameters = p;
	}
}

@:enum abstract MimeToplevel(String) from String to String {
	public var Application = 'application';
	public var Audio = 'audio';
	public var Example = 'example';
	public var Image = 'image';
	public var Message = 'message';
	public var Model = 'model';
	public var Multipart = 'multipart';
	public var Text = 'text';
	public var Video = 'video';
}

@:enum abstract MimeTree(Int) from Int to Int {
	public var Standard = 0;
	public var Vendor = 1;
	public var Vanity = 2;
	public var Unregistered = 3;
}

@:enum abstract MimeSuffix(String) from String to String {
	public var Xml = 0;
	public var Json = 1;
	public var Ber = 2;
	public var Der = 3;
	public var FastInfoSet = 4;
	public var WbXml = 5;
	public var Zip = 6;
	public var Cbor = 7;
}

@:enum abstract MimeSubtype(String) from String to String {
	
}

class MimeLexer {

	public function new() {
		
	}
	
	public static var root = Mo.rules( [
	
	] );
	
}