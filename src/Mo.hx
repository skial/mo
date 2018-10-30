package ;

import hxparse.Lexer;
import hxparse.Ruleset;

/**
 * ...
 * @author Skial Bainn
 * Haitian Creole for Words
 */
class Mo {

	public static function rules<T>(rules:Map<String, Lexer->T>):Ruleset<T> {
		var results = [for (key in rules.keys()) {
			rule: key,
			func: rules.get(key),
		}];
		return Lexer.buildRuleset(results, '');
	}

}