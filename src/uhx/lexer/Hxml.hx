package uhx.lexer;

import haxe.ds.IntMap;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;

/**
 * ...
 * @author Skial Bainn
 */
typedef Tokens = Array<Token<HxmlKeywords>>;
 
enum HxmlKeywords {
	Known(cmd:RecognisedHxml);
	Unknown(cmd:String, value:Null<String>);
	Each(tokens:Tokens);
	Next(tokens:Tokens);
}

/**
 * @see http://blog.stroep.nl/2015/08/biwise-operations-made-easy-with-haxe/
 */
@:enum RecognisedHxml(Int) from Int to Int {
	
	var SourcePath = 0;
	var Target = value(0);
	var Main = value(1);
	var Library = value(2);
	var Define = value(3);
	var DeadCode = value(4);
	var Verbose = value(5);
	var Debug = value(6);
	var Cmd = value(7);
	//var Each = value(8);
	//var Next = value(9);
	
	static inline function value(index:Int) {
    	return 1 << index;
	}

	inline public function remove(mask:RecognisedHxml):RecognisedHxml {
		return new RecognisedHxml(this & ~mask.toInt());
	}
    
	inline public function add(mask:RecognisedHxml):RecognisedHxml {
		return new RecognisedHxml(this | mask.toInt());
	}
    
	inline public function contains(mask:RecognisedHxml):Bool {
		return this & mask.toInt() != 0;
	}
    
    inline function new(v:Int) {
        this = v;
	}

    /*inline function toInt():Int {
    	return this;
	}*/
	
}



class Hxml extends Lexer {
	
	public static var root = Mo.rules([
	'' => {}
	]);
	
	public var values:IntMap<Array<String>> = new IntMap();
	
	public function new(input:ByteData, name:String) {
		super( input, name );
	}
	
}