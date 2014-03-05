package util;

use strict;
use warnings;

my $role_sequence = 0;
sub make_role {
    my %args = @_;

    my $type             = $args{type};
    my $required_methods = $args{required_methods};
    my $methods          = $args{methods} || [];
    my $attributes_ref   = $args{attributes} || [];

    my $required_source = '';

    if ( $required_methods && @{$required_methods} ) {
        $required_source = 'requires qw( ';
        $required_source .= join( ' ', @{$required_methods} );
        $required_source .= ' );';
    }

    if ($type eq 'Moose::Role' or $type eq 'Moo::Role') {
        $required_source .= join "\n" =>
            map {"has $_ => (is => 'ro');"} @{$attributes_ref};
    }

    my $package = 'TestRole' . $role_sequence++;

    my $source = qq{
        package $package;
    
        use $type;
        $required_source
    };

    $source .= join( "\n", @{$methods} );

    #warn $source;

    eval($source);
    die $@ if $@;

    return $package;
}

1;
