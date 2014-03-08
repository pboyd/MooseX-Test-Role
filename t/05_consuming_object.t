use strict;
use warnings;

use FindBin qw( $Bin );
use lib $Bin;
require util;

use Test::More tests => 4;
use Class::Load qw( try_load_class );
use Scalar::Util qw( blessed );

use MooseX::Test::Role;

subtest 'Moose'      => sub { test_role_type('Moose::Role') };
subtest 'Moo'        => sub { test_role_type('Moo::Role') };
subtest 'Role::Tiny' => sub { test_role_type('Role::Tiny') };
subtest 'Bad arguments' => \&test_bad_arguments;

sub test_role_type {
    my $type = shift;

  SKIP: {
        if ( !try_load_class($type) ) {
            skip "$type not installed", 7;
        }

        my $role = util::make_role(
            type             => $type,
            required_methods => ['c'],
            methods          => [ 'sub a { "return a" }', ]
        );

        my $consumer = consuming_object($role);

        if ($type ne 'Role::Tiny') {
            ok(blessed($consumer), 'should return a a blessed reference');
        }

        ok( $consumer, 'consuming_object should return something' );
        ok( $consumer->does($role),
            'consuming_object should return an object that consumes the role' );
        is( $consumer->a, 'return a',
            'role methods can be called on the object' );

        $consumer = consuming_object(
            $role,
            methods => {
                b => sub { 'from b' }
            }
        );
        is( $consumer->b, 'from b',
            'extra object methods can be passed to consuming_object' );

        $consumer = consuming_object($role);
        can_ok( $consumer, 'c' );
        is( $consumer->c, undef, 'default required methods return undef' );

        $consumer = consuming_object(
            $role,
            methods => {
                c => sub { 'custom c' }
            }
        );
        is( $consumer->c, 'custom c', 'explicit methods override the default' );
    }
}

sub test_bad_arguments {
    eval { consuming_object('asdf'); };
    like(
        $@,
        qr/first argument should be a role/,
        'consuming_object should die when passed something that\'s not a role'
    );

    eval { consuming_object(__PACKAGE__); };
    like(
        $@,
        qr/first argument should be a role/,
        'consuming_object should die when passed something that\'s not a role'
    );
}

