use strict;
use warnings;

use Test::More tests => 14;

use MooseX::Test::Role;

use Moose qw//;

my $role = Moose::Meta::Role->create_anon_role();
$role->add_required_methods(qw/a b c/);

my $ok;
my $msg;
$MooseX::Test::Role::ok = sub {
    ($ok, $msg) = @_;
};

requires_ok($role->name, 'a');
ok($ok, 'should match single items');
is($msg, $role->name . ' requires a', 'single match test name');

requires_ok($role->name, 'a', 'b');
ok($ok, 'should match 2 items');
is($msg, $role->name . ' requires a, b', '2 methods test name');

requires_ok($role->name, 'a', 'b', 'c');
ok($ok, 'should match 3 items');
is($msg, $role->name . ' requires a, b, c', '3 methods test name');

requires_ok($role->name, 'd');
ok(!$ok, 'can fail on single items');
is($msg, $role->name . ' requires d', 'single match failure test name');

requires_ok($role->name, 'b', 'd');
ok(!$ok, 'can fail with one passing and one missing method');
is($msg, $role->name . ' requires b, d', '2 methods match failure test name');

requires_ok('asdf', 'a');
ok(!$ok, 'fails on non-classes');
is($msg, 'asdf requires a', 'test name for non-class failure');

my $class = Moose::Meta::Class->create_anon_class();
requires_ok($class->name, 'a');
ok(!$ok, 'fails on non-roles');
is($msg, $class->name . ' requires a', 'test name for non-role failure');
