package ;

import uhx.lexer.*;
import uhx.parser.*;
import byte.ByteData;

class Main {

    public static function main() {
        trace( run() );
        trace( Rules.data_state );
        var uri = new uhx.parser.Uri();
        var http = new uhx.parser.HttpMessage();
        trace( uri.toTokens( ByteData.ofString('https://haxe.org'), 'uri' ) );
        trace( http.toTokens( ByteData.ofString('content-type:text/plain'), 'http-message' ) );
        var tokens = new uhx.parser.Mime().toTokens(ByteData.ofString('text/html; charset=UTF-8'), 'macro-in-macro');
        trace(tokens);
        trace(tokens.length);
    }

    public static macro function run():haxe.macro.Expr {
        var uri = new uhx.parser.Uri();
        var http = new uhx.parser.HttpMessage();
        trace( uri.toTokens( ByteData.ofString('https://haxe.org'), 'uri' ) );
        trace( http.toTokens( ByteData.ofString('content-type:text/plain'), 'http-message' ) );
        var tokens = new uhx.parser.Mime().toTokens(ByteData.ofString('text/html; charset=UTF-8'), 'macro-in-macro');
        trace(tokens);
        trace(tokens.length);
        return macro $v{tokens.length};
    }

}