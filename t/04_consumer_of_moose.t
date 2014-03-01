use strict;
use warnings;

use Test::More tests => 8;

use MooseX::Test::Role;
use Test::Moose qw( does_ok );

use Moose qw//;

my $role = Moose::Meta::Role->create_anon_role();
$role->add_method( 'a', sub { 'return a' } );

my $consumer = consumer_of( $role->name );
does_ok( $consumer, $role->name,
    'consumer_of should return an object that consumes the role' );
is( $consumer->a, 'return a', 'role methods can be called on the object' );

$consumer = consumer_of( $role->name, b => sub { 'from b' } );
is( $consumer->b, 'from b',
    'extra object methods can be passed to consumer_of' );

$role->add_required_methods('c');
$consumer = consumer_of( $role->name );
can_ok( $consumer, 'c' );
is( $consumer->c, undef, 'default required methods return undef' );

$consumer = consumer_of( $role->name, c => sub { 'custom c' } );
is( $consumer->c, 'custom c', 'explicit methods override the default' );

eval { consumer_of('asdf'); };
like(
    $@,
    qr/first argument to consumer_of should be a role/,
    'consumer_of should die when passed something that\'s not a role'
);

my $class = Moose::Meta::Class->create_anon_class();
eval { consumer_of( $class->name ); };
like(
    $@,
    qr/first argument to consumer_of should be a role/,
    'consumer_of should die when passed something that\'s not a role'
);
