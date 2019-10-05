package uhx.mo;

#if !(eval || macro)
@:autoBuild(uhx.mo.macro.RulesCache.build())
#end
@:remove interface RulesCache {}