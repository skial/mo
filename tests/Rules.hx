package ;

import uhx.mo.Token;
import hxparse.Lexer;
import hxparse.Ruleset;

enum abstract Consts(String) to String from String {
    public var NUL = '\u0000';
    public var NULL = NUL;
}

//@:disable.rules.cache 
class Rules implements uhx.mo.RulesCache {

    public static var data_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'&' => lexer -> null,
		'<' => lexer -> null,
		NUL => lexer -> null,
		'' => lexer -> null,
		'[^&<]' => lexer -> null,
	] );

    public static var plaintext_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		NUL => lexer -> null,
		'' => lexer -> null,
		'[^&<]' => lexer -> null,
	] );

    // Entity rules

    // @see https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state
	public static var character_reference_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[0-9a-zA-Z]' => lexer -> null,
		'#' => lexer -> null,
		'[^0-9a-zA-Z#]' => lexer -> null,
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#named-character-reference-state
	public static var named_character_reference_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#ambiguous-ampersand-state
	public static var ambiguous_ampersand_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-state
	public static var numeric_character_reference_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-start-state
	public static var hexadecimal_character_reference_start_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-start-state
	public static var decimal_character_reference_start_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-state
	public static var hexadecimal_character_reference_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-state
	public static var decimal_character_reference_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-end-state
	public static var numeric_character_reference_end_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

    // Tag rules

    public static var tag_open_state:Ruleset<Lexer, Token<String>>= Mo.rules( [
		'!' => lexer -> null,
		'/' => lexer -> null,
		'[a-zA-Z]' => lexer -> null,
		'?' => lexer -> null,
		'' => lexer -> null,
		'[^!\\/a-zA-Z\\?]' => lexer -> null,
	] );

    public static var end_tag_open_state:Ruleset<Lexer, Token<String>>= Mo.rules( [
		'[a-zA-Z]' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^a-zA-Z>]' => lexer -> null,
	] );

    public static var tag_name_state:Ruleset<Lexer, Token<String>>= Mo.rules( [
		'[\t\n \u000C]' => lexer -> null,
		'/' => lexer -> null,
		'>' => lexer -> null,
		'[A-Z]' => lexer -> null,
		NULL => lexer -> null,
		'' => lexer -> null,
		'[^\t\n \u000C/>A-Z]' => lexer -> null,
	] );

    public static var self_closing_start_tag_state:Ruleset<Lexer, Token<String>>= Mo.rules( [
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^>]' => lexer -> null,
	] );

    // Comment rules

    // @see https://html.spec.whatwg.org/multipage/parsing.html#comment-start-state
	public static var comment_start_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u002D' => lexer -> null,
		'>' => lexer -> null,
		'[^\\->]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-start-dash-state
	public static var comment_start_dash_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u002D' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^\\->]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-state
	public static var comment_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-state
	public static var comment_less_than_sign_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'!' => lexer -> null,
		'<' => lexer -> null,
		'[^!<]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-state
	public static var comment_less_than_sign_bang_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u002D' => lexer -> null,
		'[^\\-]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-state
	public static var comment_less_than_sign_bang_dash_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u002D' => lexer -> null,
		'[^\\-]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-dash-state
	public static var comment_less_than_sign_bang_dash_dash_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^>]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-end-dash-state
	public static var comment_end_dash_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u002D' => lexer -> null,
		'' => lexer -> null,
		'[^-]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-end-state
	public static var comment_end_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-end-bang-state
	public static var comment_end_bang_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u002D' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^->]' => lexer -> null,
	] );

	public static var bogus_comment_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'>' => lexer -> null,
		'' => lexer -> null,
		NULL => lexer -> null,
		'[^>$NULL]' => lexer -> null,
	] );

	public static var markup_declaration_open_state:Ruleset<Lexer, Token<String>> = Mo.rules( [] );

    // Attribute rules

    public static var attribute_name_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C />]' => lexer -> null,
		'' => lexer -> null,
		'=' => lexer -> null,
		'[A-Z]' => lexer -> null,
		NUL => lexer -> null,
		'["\u0027<]' => lexer -> null,
		'[^\t\n\u000C />=A-Z$NUL"\u0027<]' => lexer -> null,
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(double-quoted)-state
	public static var attribute_value_double_quoted_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'"' => lexer -> null,
		'&' => lexer -> null,
		NUL => lexer -> null,
		'' => lexer -> null,
		'[^"&$NUL]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(single-quoted)-state
	public static var attribute_value_single_quoted_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u0027' => lexer -> null,
		'&' => lexer -> null,
		NUL => lexer -> null,
		'' => lexer -> null,
		'[^\u0027&$NUL]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(unquoted)-state
	public static var attribute_value_unquoted_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'&' => lexer -> null,
		'>' => lexer -> null,
		NUL => lexer -> null,
		'["\u0027<=`]' => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\u000C &$NUL"\u0027<=`]' => lexer -> null,
	] );

	public static var before_attribute_name_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'[/>]' => lexer -> null,
		'' => lexer -> null,
		'=' => lexer -> null,
		'[^\t\n\u000C />=]' => lexer -> null,
	] );

	public static var after_attribute_name_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C]' => lexer -> null,
		'/' => lexer -> null,
		'=' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> /* error */ EOF,
		'[^\t\n\u000C /=>]' => lexer -> null,
	] );

	public static var before_attribute_value_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'"' => lexer -> null,
		'\u0027' => lexer -> null,
		'>' => lexer -> null,
		'[^\t\n\u000C "\u0027>]' => lexer -> null,
	] );

	public static var after_attribute_value_quoted_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'/' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> EOF,
		'[^\t\n\u000C />]' => lexer -> null,
	] );

    // CDATA rules

    // @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-state
	public static var cdata_section_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u005D' => lexer -> null,
		'' => lexer -> null,
		'[^\u005D]' => lexer -> null,
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-bracket-state
	public static var cdata_section_bracket_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u005D' => lexer -> null,
		'[^\u005D]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-end-state
	public static var cdata_section_end_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u005D' => lexer -> null,
		'\u003E' => lexer -> null,
		'[^\u005D\u003E]' => lexer -> null,
	] );

    // DOCTYPE rules

    // @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-state
	public static var doctype_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\uFFFD ]' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\uFFFD >]' => lexer -> null,
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-name-state
	public static var doctype_name_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'>' => lexer -> null,
		'[A-Z]' => lexer -> null,
		NUL => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\u000C >A-Z$NUL]' => lexer -> null,
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(double-quoted)-state
	public static var doctype_public_identifier_double_quoted_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'"' => lexer -> null,
		NUL => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^"$NUL>]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(single-quoted)-state
	public static var doctype_public_identifier_single_quoted_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u0027' => lexer -> null,
		NUL => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^\u0027$NUL>]' => lexer -> null,
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(double-quoted)-state
	public static var doctype_system_identifier_double_quoted_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'"' => lexer -> null,
		NUL => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^"$NUL>]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(single-quoted)-state
	public static var doctype_system_identifier_single_quoted_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'\u0027' => lexer -> null,
		NUL => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^\u0027$NUL>]' => lexer -> null,
	] );

	public static var before_doctype_name_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\uFFFD ]' => lexer -> null,
		'[A-Z]' => lexer -> null,
		NUL => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\uFFFD A-Z>]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-name-state
	public static var after_doctype_name_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		/** see Anything section **/
		'(p|P)(u|U)(b|B)(l|L)(i|I)(c|C)' => lexer -> null,
		'(s|S)(y|Y)(s|S)(t|T)(e|E)(m|M)' => lexer -> null,
		'[^\t\n\u000C >]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-keyword-state
	public static var after_doctype_public_keyword_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\n\t\u000C ]' => lexer -> null,
		'"' => lexer -> null,
		'\u0027' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\u000C "\u0022>]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-public-identifier-state
	public static var before_doctype_public_identifier_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'"' => lexer -> null,
		'\u0027' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\u000C "\u0027>]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-identifier-state
	public static var after_doctype_public_identifier_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'>' => lexer -> null,
		'"' => lexer -> null,
		'\u0027' => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\u000C >"\u0027]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#between-doctype-public-and-system-identifiers-state
	public static var between_doctype_public_and_system_identifiers_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'>' => lexer -> null,
		'"' => lexer -> null,
		'\u0027' => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\u000C >"\u0027]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-keyword-state
	public static var after_doctype_system_keyword_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'"' => lexer -> null,
		'\u0027' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\u000C "\u0027>]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-system-identifier-state
	public static var before_doctype_system_identifier_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'"' => lexer -> null,
		'\u0027' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\u000C "\u0027>]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-identifier-state
	public static var after_doctype_system_identifier_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^\t\n\u000C >]' => lexer -> null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#bogus-doctype-state
	public static var bogus_doctype_state:Ruleset<Lexer, Token<String>> = Mo.rules( [
		'>' => lexer -> null,
		NUL => lexer -> null,
		'' => lexer -> null,
		'[^>$NULL]' => lexer -> null,
	] );

    // Tag rules

    public static var TAG_tag_open_state:Ruleset<Lexer, Token<String>>= Mo.rules( [
		'!' => lexer -> null,
		'/' => lexer -> null,
		'[a-zA-Z]' => lexer -> null,
		'?' => lexer -> null,
		'' => lexer -> null,
		'[^!\\/a-zA-Z\\?]' => lexer -> null,
	] );

    public static var TAG_end_tag_open_state:Ruleset<Lexer, Token<String>>= Mo.rules( [
		'[a-zA-Z]' => lexer -> null,
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^a-zA-Z>]' => lexer -> null,
	] );

    public static var TAG_tag_name_state:Ruleset<Lexer, Token<String>>= Mo.rules( [
		'[\t\n \u000C]' => lexer -> null,
		'/' => lexer -> null,
		'>' => lexer -> null,
		'[A-Z]' => lexer -> null,
		NULL => lexer -> null,
		'' => lexer -> null,
		'[^\t\n \u000C/>A-Z]' => lexer -> null,
	] );

    public static var TAG_self_closing_start_tag_state:Ruleset<Lexer, Token<String>>= Mo.rules( [
		'>' => lexer -> null,
		'' => lexer -> null,
		'[^>]' => lexer -> null,
	] );

}