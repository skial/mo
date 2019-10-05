package uhx.lexer;

class Consts {

    public static final CR:String = '\r';
    public static final LF:String = '\n';
    public static final HT:String = '\t';

}

@:forward
@:forwardStatics
enum abstract Consts2(String) from String to String {
    public var SP:String = ' ';
    public var DQ:String = '"';
}