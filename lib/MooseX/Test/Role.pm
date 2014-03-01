package MooseX::Test::Role;

our $VERSION = '0.04';

use strict;
use warnings;

use List::Util qw/first/;
use Test::Builder;
use Moose qw//;
use Carp;

use Exporter qw/import unimport/;
our @EXPORT = qw/requires_ok consumer_of/;

sub requires_ok {
    my ( $role, @required ) = @_;
    my $msg = "$role requires " . join( ', ', @required );

    if ( !$role->can('meta') || !$role->meta->isa('Moose::Meta::Role') ) {
        ok( 0, $msg );
        return;
    }

    foreach my $req (@required) {
        unless ( first { $_ eq $req } $role->meta->get_required_method_list ) {
            ok( 0, $msg );
            return;
        }
    }
    ok( 1, $msg );
}

sub consumer_of {
    my ( $role, %methods ) = @_;

    if ( !$role->can('meta') || !$role->meta->isa('Moose::Meta::Role') ) {
        confess 'first argument to consumer_of should be a role';
    }

    $methods{$_} ||= sub { undef }
      for $role->meta->get_required_method_list;

    my $meta = Moose::Meta::Class->create_anon_class(
        roles   => [$role],
        methods => \%methods,
    );

    return $meta->new_object;
}

my $Test = Test::Builder->new;

# Done this way for easier testing
our $ok = sub { $Test->ok(@_) };
sub ok { $ok->(@_) }

1;

=pod

=head1 NAME

MooseX::Test::Role - Test functions for Moose roles

=head1 SYNOPSIS

  use MooseX::Test::Role;
  use Test::More tests => 2;

  requires_ok('MyRole', qw/method1 method2/);

  my $consumer = consumer_of('MyRole', method1 => sub { 1 });
  ok($consumer->myrole_method);
  is($consumer->method1, 1);

=head1 DESCRIPTION

Provides functions for testing Moose roles.

=head1 BACKGROUND

Unit testing a Moose role can be hard. A major problem is creating classes that
consume the role.

One could side-step the problem entirely and just call the sub-routines in the
role's package directly. For example,

  Fooable->bar();

That only works until C<Fooable> calls another method in the consuming class
though. Mock objects are a tempting way to solve that problem:

  my $consumer = Test::MockObject->new();
  $consumer->set_always('baz', 1);
  Fooable::bar($consumer);

But if C<Fooable::bar> happens to call another method in the role then
the mock consumer will have to mock that method too.

A better way is to create a class to consume the role:

  package FooableTest;

  use Moose;
  with 'Fooable';

  sub required_method {}

  package main;

  my $consumer = FooableTest->new();
  $consumer->bar();

This can work well for some roles. Unfortunately, if several variations have to
be tested, it may be necessary to create several consuming test classes, which
gets tedious.

Fortunately, Moose can create anonymous classes which consume roles:

    my $consumer = Moose::Meta::Class->create_anon_class(
        roles   => ['Fooable'],
        methods => {
            required_method => sub {},
        }
    )->new_object();
    $consumer->bar();

This can still be tedious, especially for roles that require lots of methods.
C<MooseX::Test::Role::consumer_of> simply makes this easier to do.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<consumer_of ($role, %methods)>

Creates an instance of a class which consumes the role. Required methods are
stubbed, they return undef by default.

To add additional methods to the instance specify the name and coderef:

  consumer_of('MyRole',
      method1 => sub { 'one' },
      method2 => sub { 'two' },
      required_method => sub { 'required' },
  );

=item B<requires_ok ($role, @methods)>

Tests if role requires one or more methods.

=back

=head1 GITHUB

Patches, comments or mean-spirited code reviews are all welcomed on GitHub:

https://github.com/pboyd/MooseX-Test-Role

=head1 AUTHOR

Paul Boyd <pboyd@dev3l.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Paul Boyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
