package ;

import hxparse.Lexer;
import hxparse.Ruleset;

/**
 * ...
 * @author Skial Bainn
 * Haitian Creole for Words
 */
class Mo {

	@:generic public static function rules<L:Lexer, T>(rules:Map<String, L->T>):Ruleset<L, T> {
		var results:Array<{rule:String, func:L->T}> = [for (key in rules.keys()) {
			rule: key,
			func: rules.get(key),
		}];
		return Lexer.buildRuleset(results, '');
	}

}