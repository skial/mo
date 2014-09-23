package uhx.mo;

import haxe.macro.Type;
import haxe.macro.Expr;

/**
 * ...
 * @author Skial Bainn
 */
enum Token<Kwd> {
	Ignore;
	@sub(1) @loop Const(c:Constant);
	@sub(2) @loop Unop(op:Unop);
	@sub(2) @loop Binop(op:Binop);
	@loop Keyword(v:Kwd);
	EOF;
	Newline;				//	\n
	Carriage;				//	\r
	Tab(len:Int);			//	\t
	Space(len:Int);
	Dot;					//	.
	Colon;					//	:
	Interval(s:String);
	Comment(s:String);
	CommentOpen;
	CommentClose;
	@split CommentLine(s:String);
	Arrow;					//	->
	Semicolon;				//	;
	Comma;					//	,
	@split BracketOpen;		//	[
	@split BracketClose;	//	]
	@split BraceOpen;		//	{
	@split BraceClose;		//	}
	@split ParenthesesOpen;//	(
	@split ParenthesesClose;//	)
	Question;				//	?
	At;						//	@
	Hash;					//	#
	Conditional(s:String);
	Dollar(s:String);		//	$
	SingleQuote;			//	'
	DoubleQuote;			//	"
	Hyphen(len:Int);		//	-
	Asterisk;				//	*
	Underscore;				//	_
	Tilde;					//	~
	GraveAccent;			//	`
	GreaterThan;			//	>
	LessThan;				//	<
}