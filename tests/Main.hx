package ;

import uhx.lexer.*;
import uhx.parser.*;
import byte.ByteData;

class Main {

    public static function main() {
        trace( run() );
        var tokens = new uhx.parser.Mime().toTokens(ByteData.ofString('text/html; charset=UTF-8'), 'macro-in-macro');
        trace(tokens);
        trace(tokens.length);
    }

    public static macro function run():haxe.macro.Expr {
        var tokens = new uhx.parser.Mime().toTokens(ByteData.ofString('text/html; charset=UTF-8'), 'macro-in-macro');
        trace( tokens );
        return macro $v{tokens.length};
    }

}