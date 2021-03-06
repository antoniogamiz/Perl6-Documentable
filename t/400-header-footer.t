use Test; # -*- mode: perl6 -*-


use Perl6::Documentable::Config;
use Perl6::Documentable::Utils::IO;
use Perl6::Documentable::To::HTML::Wrapper; # -*- mode: perl6 -*-

plan *;

my $config  = Perl6::Documentable::Config.new(:filename("config.json"));
my $wrapper = Perl6::Documentable::To::HTML::Wrapper.new(:$config);

subtest "HTML header" => {
    for <language type routine programs> {
        test-selection($_);
    }
}

subtest "Type submenu" => {
    my $fragment = $wrapper.menu("type", "podtest");
    for <basic composite domain-specific exception> {
        is so $fragment ~~ /$_/, True, "$_ submenu found";
    }
}

subtest "Routine submenu" => {
    my $fragment = $wrapper.menu("routine", "podtest");
    for <sub method term operator trait submethod> {
        is so $fragment ~~ /$_/, True, "$_ submenu found";
    }
}

subtest "URL substitution in footer" => {
    my $new-pod-path = "type/Associative";
    like $wrapper.footer( $new-pod-path ), /"https://github.com/perl6/doc/blob/master/doc/Type/Associative.pod6"/, "Footer generated";
}

sub test-selection($selection) {
    my $fragment = $wrapper.menu($selection, "podtest");
    is so $fragment ~~ /:s selected darker\-green/, True,
    "$selection selection found";
}


done-testing;
