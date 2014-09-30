package uhx.lexer;

import haxe.io.Eof;
import hxparse.RuleBuilder;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;

enum HaxeKeywords {
	Function;
	@entry Class;
	Var;
	If;
	Else;
	While;
	Do;
	For;
	Break;
	Continue;
	Return;
	Extends;
	Implements;
	Import;
	Switch;
	Case;
	Default;
	Static;
	Public;
	Private;
	Try;
	Catch;
	New;
	This;
	Throw;
	Extern;
	Enum;
	In;
	Interface;
	Untyped;
	Cast;
	Override;
	Typedef;
	Dynamic;
	Package;
	Inline;
	Using;
	Null;
	True;
	False;
	Abstract;
	Macro;
}

/**
 * ...
 * @author Skial Bainn
 */
class HaxeLexer extends Lexer implements RuleBuilder {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var buf = new StringBuf();
	static var ident = "_*[a-z][a-zA-Z0-9_]*|_+|_+[0-9][_a-zA-Z0-9]*";
	static var idtype = "_*[A-Z][a-zA-Z0-9_]*";
	
	public static var keywords = @:mapping(0) HaxeKeywords;
	
	public static var root = Mo.rules( [
		'\n' => Newline,
		'\r' => Carriage,
		'\t*' => Tab(lexer.current.length),
		' *' => Space(lexer.current.length),
		"0x[0-9a-fA-F]+" => Const(CInt(lexer.current)),
		"[0-9]+" => Const(CInt(lexer.current)),
		"[0-9]+\\.[0-9]+" => Const(CFloat(lexer.current)),
		"\\.[0-9]+" => Const(CFloat(lexer.current)),
		"[0-9]+[eE][\\+\\-]?[0-9]+" => Const(CFloat(lexer.current)),
		"[0-9]+\\.[0-9]*[eE][\\+\\-]?[0-9]+" => Const(CFloat(lexer.current)),
		"[0-9]+\\.\\.\\." => Interval(lexer.current.substr(0,-3)),
		"//[^\n\r]*" => CommentLine(lexer.current.substr(2)),
		"+\\+" => Unop(OpIncrement),
		"--" => Unop(OpDecrement),
		"~" => Unop(OpNegBits),
		"%=" => Binop(OpAssignOp(OpMod)),
		"&=" => Binop(OpAssignOp(OpAnd)),
		"|=" => Binop(OpAssignOp(OpOr)),
		"^=" => Binop(OpAssignOp(OpXor)),
		"+=" => Binop(OpAssignOp(OpAdd)),
		"-=" => Binop(OpAssignOp(OpSub)),
		"*=" => Binop(OpAssignOp(OpMult)),
		"/=" => Binop(OpAssignOp(OpDiv)),
		"<<=" => Binop(OpAssignOp(OpShl)),
		"==" => Binop(OpEq),
		"!=" => Binop(OpNotEq),
		"<=" => Binop(OpLte),
		"&&" => Binop(OpBoolAnd),
		"|\\|" => Binop(OpBoolOr),
		"<<" => Binop(OpShl),
		"->" => Arrow,
		"\\.\\.\\." => Binop(OpInterval),
		"=>" => Binop(OpArrow),
		"!" => Unop(OpNot),
		"<" => Binop(OpLt),
		">" => Binop(OpGt),
		";" => Semicolon,
		":" => Colon,
		"," => Comma,
		"\\." => Dot,
		"%" => Binop(OpMod),
		"&" => Binop(OpAnd),
		"|" => Binop(OpOr),
		"^" => Binop(OpXor),
		"+" => Binop(OpAdd),
		"*" => Binop(OpMult),
		"/" => Binop(OpDiv),
		"-" => Binop(OpSub),
		"=" => Binop(OpAssign),
		"[" => BracketOpen,
		"]" => BracketClose,
		"{" => BraceOpen,
		"}" => BraceClose,
		"\\(" => ParenthesesOpen,
		"\\)" => ParenthesesClose,
		"?" => Question,
		"@" => At,
		'"' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(string) catch (e:Eof) throw e;
			Const(CString(buf.toString()));
		},
		"'" => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(string2) catch (e:Eof) throw e;
			Const(CString(buf.toString()));
		},
		'/\\*' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(comment) catch (e:Eof) throw e;
			Comment(buf.toString());
		},
		"#" + ident => Conditional(lexer.current.substr(1)),
		"$" + ident => Dollar(lexer.current.substr(1)),
		ident => {
			var kwd = keywords.get(lexer.current);
			if (kwd != null)
				Keyword(kwd);
			else
				Const(CIdent(lexer.current));
		},
		idtype => Const(CIdent(lexer.current)),
	] );
	
	public static var string = Mo.rules( [
		"\\\\\\\\" => {
			buf.add("\\");
			lexer.token(string);
		},
		"\\\\n" => {
			buf.add("\n");
			lexer.token(string);
		},
		"\\\\r" => {
			buf.add("\r");
			lexer.token(string);
		},
		"\\\\t" => {
			buf.add("\t");
			lexer.token(string);
		},
		"\\\\\"" => {
			buf.add('"');
			lexer.token(string);
		},
		'"' => lexer.curPos().pmax,
		"[^\\\\\"]+" => {
			buf.add(lexer.current);
			lexer.token(string);
		}
	] );
	
	public static var string2 = Mo.rules( [
		"\\\\\\\\" => {
			buf.add("\\");
			lexer.token(string2);
		},
		"\\\\n" =>  {
			buf.add("\n");
			lexer.token(string2);
		},
		"\\\\r" => {
			buf.add("\r");
			lexer.token(string2);
		},
		"\\\\t" => {
			buf.add("\t");
			lexer.token(string2);
		},
		'\\\\\'' => {
			buf.add('"');
			lexer.token(string2);
		},
		"'" => lexer.curPos().pmax,
		'[^\\\\\']+' => {
			buf.add(lexer.current);
			lexer.token(string2);
		}
	] );
	
	public static var comment = Mo.rules( [
		"*/" => lexer.curPos().pmax,
		"*" => {
			buf.add("*");
			lexer.token(comment);
		},
		"[^\\*]" => {
			buf.add(lexer.current);
			lexer.token(comment);
		}
	] );
	
}