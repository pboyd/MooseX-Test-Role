package MooseX::Test::Role;

use strict;
use warnings;

use Test::Builder;
use Moose qw//;

use Exporter qw/import unimport/;
our @EXPORT = qw/requires_ok/;

sub requires_ok {
    my ($class, @required) = @_;
}

1;
