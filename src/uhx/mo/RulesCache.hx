package uhx.mo;

#if !(eval || macro)
@:autoBuild(uhx.mo.macro.RuleCache.build())
#end
@:remove interface RulesCache {}