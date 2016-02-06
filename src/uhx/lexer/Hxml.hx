package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import haxe.ds.IntMap;

using StringTools;
using uhx.lexer.Hxml;

/**
 * ...
 * @author Skial Bainn
 */
typedef Tokens = Array<Token<HxmlKeywords>>;

enum HxmlKeywords {
	Unknown(cmd:String, value:Null<String>);
}
 
/**
 * @see http://blog.stroep.nl/2015/08/biwise-operations-made-easy-with-haxe/
 */
@:enum abstract RecognisedHxml(Int) from Int to Int {
	
	var SourcePath = value(1);
	var Main = value(2);
	var Library = value(3);
	var Define = value(4);
	var DeadCode = value(5);
	var Verbose = value(6);
	var Debug = value(7);
	var Cmd = value(8);
	
	var Js = value(9);
	var Swf = value(10);
	var As3 = value(11);
	var Neko = value(12);
	var Php = value(13);
	var Cpp = value(14);
	var Cs = value(15);
	var Java = value(16);
	var Python = value(17);
	var Xml = value(18);
	
	public static inline function all():Array<RecognisedHxml> {
		return [SourcePath, Main, Library, Define, DeadCode, Verbose, Debug, Cmd, Js, Swf, As3, Neko, Php, Cpp, Cs, Java, Python, Xml];
	}
	
	public inline function asString():String {
		return switch (this) {
			case SourcePath: 'cp';
			case Main: 'main';
			case Library: 'lib';
			case Define: '-D';
			case DeadCode: 'dce';
			case Verbose: '-v';
			case Debug: 'debug';
			case Cmd: 'cmd';
			case _: '$this';
		}
	}
	
	static inline function value(index:Int) {
    	return 1 << index;
	}

	inline public function remove(mask:RecognisedHxml):RecognisedHxml {
		return new RecognisedHxml(this & ~mask);
	}
    
	inline public function set(mask:RecognisedHxml):RecognisedHxml {
		return new RecognisedHxml(this | mask);
	}
    
	inline public function exists(mask:RecognisedHxml):Bool {
		return this & mask != 0;
	}
    
    inline function new(v:Int) {
        this = v;
	}
	
}

class Hxml extends Lexer {
	
	@:access(uhx.lexer.Hxml) public static var root = Mo.rules([
	'[\t\r\n]+' => lexer.token( root ),
	'-(-)?[^\t\r\n]+' => {
		var parts = lexer.current.substr( lexer.current.lastIndexOf('-') +1 ).trackAndSplit(' '.code, ['"'.code => '"'.code]);
		switch (parts[0]) {
			case 'js': lexer.set( Js, parts[1] );
			case 'swf': lexer.set( Swf, parts[1] );
			case 'as3': lexer.set( As3, parts[1] );
			case 'neko': lexer.set( Neko, parts[1] );
			case 'php': lexer.set( Php, parts[1] );
			case 'cpp': lexer.set( Cpp, parts[1] );
			case 'cs': lexer.set( Cs, parts[1] );
			case 'java': lexer.set( Java, parts[1] );
			case 'python': lexer.set( Python, parts[1] );
			case 'xml': lexer.set( Xml, parts[1] );
			case 'cp':
				lexer.set( SourcePath, parts[1] );
				lexer.token( root );
				
			case 'main':
				lexer.set( Main, parts[1] );
				lexer.token( root );
				
			case 'lib':
				lexer.set( Library, parts[1] );
				lexer.token( root );
				
			case 'D':
				lexer.set( Define, parts[1] );
				lexer.token( root );
				
			case 'dce':
				lexer.set( DeadCode, parts[1] );
				lexer.token( root );
				
			case 'v':
				lexer.latest.keys = lexer.latest.keys.set( Verbose );
				lexer.token( root );
				
			case 'next':
				lexer.makeSection();
				lexer.token( root );
				
			case 'each':
				if (lexer.global == null) {
					lexer.global = lexer.latest;
					lexer.makeSection();
					lexer.token( root );
					
				} else {
					throw 'You can only have one `--each` in your hxml file';
					
				}
				
			case _:
				lexer.latest.unknowns.push( Keyword(Unknown(parts[0], parts[1])) );
				
		}
		
		lexer.sections;
	}
	]);
	
	public static function trackAndConsume(value:String, until:Int, track:IntMap<Int>):String {
		var result = '';
		var length = value.length;
		var index = 0;
		var character = -1;
		
		while (index < length) {
			character = value.fastCodeAt( index );
			if (character == until) {
				break;
				
			}
			if (track.exists( character )) {
				var _char = track.get( character );
				var _value = value.substr( index + 1 ).trackAndConsume( _char, track );
				result += String.fromCharCode( character ) + _value + String.fromCharCode( _char );
				index += _value.length + 1;
				
			} else {
				result += String.fromCharCode( character );
				index++;
				
			}
			
		}
		
		return result;
	}
	
	public static function trackAndSplit(value:String, split:Int, track:IntMap<Int>):Array<String> {
		var pos = 0;
		var results = [];
		var length = value.length;
		var index = 0;
		var character = -1;
		var current = '';
		
		while (index < length) {
			character = value.fastCodeAt( index );
			if (character == split) {
				
				if (results.length == 0) {
					results.push( value.substr(0, index) );
					
				} else if (current != '') {
					results.push( current );
					
				}
				pos = index;
				index++;
				current = '';
				continue;
				
			}
			if (track.exists( character )) {
				var _char = track.get( character );
				var _value = value.substr( index + 1 ).trackAndConsume( _char, track );
				current += String.fromCharCode( character ) + _value + String.fromCharCode( _char );
				index += _value.length + 2;
				
			} else {
				current += String.fromCharCode( character );
				index++;
				
			}
			
		}
		
		if (current != '') results.push( current );
		
		return results;
	}
	
	private var global:Null<Section> = null;
	private var sections:Array<Section> = [];
	private var latest:Section = new Section();
	
	private function set(key:RecognisedHxml, value:String):Void {
		latest.keys = latest.keys.set( key );
		
		if (latest.knowns.exists( key )) {
			latest.knowns.get( key ).push( value );
			
		} else {
			latest.knowns.set( key, [value] );
			
		}
		
	}
	
	private inline function makeSection():Void {
		latest = new Section();
		if (global != null) latest.inherit = global.index;
		latest.index = sections.push( latest );
	}
	
	public function new(input:ByteData, name:String) {
		latest.index = sections.push( latest );
		super( input, name );
	}
	
}

class Section {
	
	public var index:Int;
	public var inherit:Int;
	public var keys:RecognisedHxml;
	public var knowns:IntMap<Array<String>>;
	public var unknowns:Array<Token<HxmlKeywords>>;
	
	public function new() {
		keys = 0;
		index = -1;
		inherit = -1;
		knowns = new IntMap();
		unknowns = [];
	}
	
}