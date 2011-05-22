use strict;
use warnings;

use Test::More tests => 7;

use MooseX::Test::Role;

use Moose qw//;

my $role = Moose::Meta::Role->create_anon_role();
$role->add_required_methods(qw/a b c/);

my $ok;
$MooseX::Test::Role::ok = sub {
    $ok = shift;
};

requires_ok($role->name, 'a');
ok($ok, 'should match single items');

requires_ok($role->name, 'a', 'b');
ok($ok, 'should match 2 items');

requires_ok($role->name, 'a', 'b', 'c');
ok($ok, 'should match 3 items');

requires_ok($role->name, 'd');
ok(!$ok, 'can fail on single items');

requires_ok($role->name, 'b', 'd');
ok(!$ok, 'can fail with one passing and one missing method');

requires_ok('asdf', 'a');
ok(!$ok, 'fails on non-classes');

my $class = Moose::Meta::Class->create_anon_class();
requires_ok($class->name, 'a');
ok(!$ok, 'fails on non-roles');
