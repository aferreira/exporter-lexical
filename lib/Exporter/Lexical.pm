package Exporter::Lexical;
use strict;
use warnings;
use 5.018;
# ABSTRACT: exporter for lexical subs

use XSLoader;
XSLoader::load(
    __PACKAGE__,
    # we need to be careful not to touch $VERSION at compile time, otherwise
    # DynaLoader will assume it's set and check against it, which will cause
    # fail when being run in the checkout without dzil having set the actual
    # $VERSION
    exists $Exporter::Lexical::{VERSION}
        ? ${ $Exporter::Lexical::{VERSION} } : (),
);

sub import {
    my $package = shift;
    my %opts = @_;

    my $caller = caller;

    my $import = sub {
        my $caller_stash = do {
            no strict 'refs';
            \%{ $caller . '::' };
        };
        my @exports = @{ $opts{'-exports'} };
        my %exports = map { $_ => \&{ $caller_stash->{$_} } } @exports;

        for my $export (keys %exports) {
            lexical_import($export, $exports{$export});
        }

        # XXX there is a bug with lexical_import where the pad entry sequence
        # numbers are incorrect when used with 'use', so the first statement
        # after the 'use' statement doesn't see the lexical. hack around this
        # for now by injecting a dummy statement right after the 'use'.
        _lex_stuff(";1;");
    };

    {
        no strict 'refs';
        *{ $caller . '::import' } = $import;
    }
}

=begin Pod::Coverage

  lexical_import

=end Pod::Coverage

1;
