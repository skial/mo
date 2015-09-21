package byte;

import unifill.Unifill;
import unifill.CodePoint;
import unifill.Exception;
import unifill.InternalEncoding;

#if (neko || php || cpp || macro)
	private typedef UtfX = unifill.Utf8;
#elseif python
	private typedef UtfX = unifill.Utf32;
#else
	private typedef UtfX = unifill.Utf16;
#end

/*abstract ByteData(UtfX) from UtfX to UtfX {

	public var length(get,never):Int;
	inline function get_length() {
		return this.length;
	}

	inline public function readByte(i:Int) {
		return this.codePointAt(i);
	}

	inline function new(data) {
		this = data;
	}

	static public function ofString(s:String):ByteData {
		return UtfX.fromString(s);
	}

	public function readString(pos:Int, len:Int) {
		return this.substr(pos, len).toString();
	}
}*/

abstract ByteData(UtfX) from UtfX to UtfX {
	
	public var length(get,never):Int;
	inline function get_length() {
		return this.codePointCount(0, this.length);
	}

	inline public function readByte(i:Int) {
		return this.codePointAt( this.offsetByCodePoints(0, i) );
	}

	inline function new(data) {
		this = data;
	}

	static public function ofString(s:String):ByteData {
		return UtfX.fromString(s);
	}

	public function readString(pos:Int, len:Int) {
		var result = '';
		var i = pos;
		var max = pos + len;
		while (i < max) {
			//trace( this.codeUnitAt( this.offsetByCodePoints(0, i) ) );
			result += (readByte( i++ ):CodePoint).toString();
		}
		return result;
	}
	
}