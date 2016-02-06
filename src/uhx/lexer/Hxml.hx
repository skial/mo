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
	Known(cmd:RecognisedHxml);
	Unknown(cmd:String, value:Null<String>);
	Each(tokens:Tokens);
}

/**
 * @see http://blog.stroep.nl/2015/08/biwise-operations-made-easy-with-haxe/
 */
@:enum abstract RecognisedHxml(Int) from Int to Int {
	
	var SourcePath = value(1);
	var Target = value(2);
	var Main = value(3);
	var Library = value(4);
	var Define = value(5);
	var DeadCode = value(6);
	var Verbose = value(7);
	var Debug = value(8);
	var Cmd = value(9);
	//var Each = value(10);
	//var Next = value(11);
	
	public static inline function all():Array<RecognisedHxml> {
		return [SourcePath, Target, Main, Library, Define, DeadCode, Verbose, Debug, Cmd];
	}
	
	public inline function asString():String {
		return switch (this) {
			case SourcePath: 'cp';
			case Target: 'target';
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
			case 'js', 'swf', 'as3', 'neko', 'php', 'cpp', 'cs', 'java', 'python', 'xml':
				lexer.set( Target, parts[1] );
				lexer.latest.unknowns.push( Const(CString(parts[0])) );
				
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