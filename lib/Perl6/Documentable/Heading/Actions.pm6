unit class Perl6::Documentable::Heading::Actions;

use Perl6::Documentable;

has Str  $.dname     = '';
has      $.dkind     ;
has Str  $.dsubkind  = '';
has Str  $.dcategory = '';

method name($/) {
    $!dname = $/.Str;
}

method single-name($/) {
    $!dname = $/.Str;
}

method subkind($/) {
    $!dsubkind = $/.Str.trim;
}

method operator($/) {
    $!dkind     = Kind::Routine;
    $!dcategory = "operator";
}

method routine($/) {
    $!dkind     = Kind::Routine;
    $!dcategory = $/.Str;
}

method syntax($/) {
    $!dkind     = Kind::Syntax;
    $!dcategory = $/.Str;
}
