#!rsc by RouterOS
# Run after languages/runtime.rsc in an isolated RouterOS test environment.
# Does not send notifications, change networking, or invoke LanguageUpdate.
:global Translate;
:global ScriptLanguage "en";
:global LanguageActive "pt-BR";
:global LanguageEnglish {
  "test.message"="The CPU on {identity} is at {percent}%!";
  "test.empty"="";
  "test.literal"="Hello";
};
:global LanguageMessages {
  "test.message"="{percent}% de CPU em {identity}!";
};

:if ([ $Translate "test.message" { identity="router"; percent=75 } ] != \
     "The CPU on router is at 75%!") do={ :error "English default failed"; }
:set ScriptLanguage "pt-BR";
:if ([ $Translate "test.message" { identity="roteador"; percent=75 } ] != \
     "75% de CPU em roteador!") do={ :error "Translation/reordered parameters failed"; }
:if ([ $Translate "test.literal" ] != "Hello") do={ :error "Missing key fallback failed"; }
:if ([ $Translate "test.empty" ] != "") do={ :error "Empty English message failed"; }
:if ([ $Translate "test.unknown" ] != "test.unknown") do={ :error "Unknown key failed"; }
:if ([ $Translate "test.message" { identity="{percent}"; percent=75 } ] != \
     "75% de CPU em {percent}!") do={ :error "Parameter was recursively expanded"; }
:set ($LanguageMessages->"test.message") "{unexpected}";
:if ([ $Translate "test.message" { identity="router"; percent=75 } ] != \
     "The CPU on router is at 75%!") do={ :error "Invalid placeholder fallback failed"; }
:set ($LanguageMessages->"test.message") "CPU";
:if ([ $Translate "test.message" { identity="router"; percent=75 } ] != \
     "The CPU on router is at 75%!") do={ :error "Omitted placeholder fallback failed"; }
:set ($LanguageMessages->"test.message") "{unexpected}: {percent}";
:if ([ $Translate "test.message" { identity="router"; percent=75 } ] != \
     "The CPU on router is at 75%!") do={ :error "Same-count placeholder fallback failed"; }
:set ($LanguageMessages->"test.message") "{identity}: {percent}% ({identity})";
:if ([ $Translate "test.message" { identity="router"; percent=75 } ] != \
     "router: 75% (router)") do={ :error "Repeated placeholder failed"; }
:set LanguageActive "de";
:if ([ $Translate "test.message" { identity="router"; percent=75 } ] != \
     "The CPU on router is at 75%!") do={ :error "Language switch fallback failed"; }
:put "Language translation tests passed.";
