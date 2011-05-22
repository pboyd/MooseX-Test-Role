package MooseX::Test::Role;

use strict;
use warnings;

use List::Util qw/first/;
use Test::Builder;
use Moose qw//;

use Exporter qw/import unimport/;
our @EXPORT = qw/requires_ok/;

sub requires_ok {
    my ( $class, @required ) = @_;
    my $msg = "$class requires " . join( ', ', @required );

    if ( !$class->can('meta') || !$class->meta->isa('Moose::Meta::Role') ) {
        ok( 0, $msg );
        return;
    }

    foreach my $req (@required) {
        unless (first { $_ eq $req } $class->meta->get_required_method_list) {
            ok(0, $msg);
            return;
        }
    }
    ok(1, $msg);
}

my $Test = Test::Builder->new;

# Done this way for easier testing
our $ok = sub { $Test->ok(@_) };
sub ok { $ok->(@_) }

1;
