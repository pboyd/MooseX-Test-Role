package MooseX::Test::Role;

our $VERSION = '0.04';

use strict;
use warnings;

use Carp qw( confess );
use Class::Load qw( try_load_class );
use List::Util qw( first );
use Test::Builder;

use Exporter qw( import unimport );
our @EXPORT = qw( requires_ok consumer_of );

sub requires_ok {
    my ( $role, @required ) = @_;
    my $msg = "$role requires " . join( ', ', @required );

    my $role_type = _derive_role_type($role);
    if (!$role_type) {
        ok( 0, $msg );
        return;
    }

    foreach my $req (@required) {
        unless ( first { $_ eq $req } _required_methods($role_type, $role) ) {
            ok( 0, $msg );
            return;
        }
    }
    ok( 1, $msg );
}

sub consumer_of {
    my $role = shift;

    # If the second argument is an arrayref, pass it to new() below
    my @args = ref $_[0] eq 'ARRAY' ? @{ +shift } : ();
    my %methods = @_;

    my $role_type = _derive_role_type($role);
    confess 'first argument to consumer_of should be a role' unless $role_type;

    # Inline stubs for everything that's required so it'll pass the requires check.
    my @default_subs = map { "sub $_ { }" } _required_methods($role_type, $role);

    my $package = _build_consuming_package(
        role_type => $role_type,
        role => $role,
        inline_subs => \@default_subs,
    );

    # Now replace the stubs with any methods we were passed.
    while (my ($method, $subref) = each(%methods)) {
        no strict 'refs';
        no warnings 'redefine';
        *{$package . '::' . $method} = $subref;
    }

    # Moose and Moo can be instantiated and should be. Role::Tiny however isn't
    # a full OO implementation and so doesn't provide a "new" method.
    return $package->can('new') ? $package->new(@args) : $package;
}

sub _required_methods {
    my ($role_type, $role) = @_;
    my @methods;

    if ($role_type eq 'Moose::Role') {
        @methods = $role->meta->get_required_method_list();
    }
    elsif ($role_type eq 'Role::Tiny') {

        # This seems brittle, but there aren't many options to get this data.
        # Moo relies on %INFO too, so it seems like it would be a hard thing
        # for to move away from.
        my $info = $Role::Tiny::INFO{$role};
        if ($info && ref($info->{requires}) eq 'ARRAY') {
            @methods = @{$info->{requires}};
        }
    }

    return wantarray ? @methods : \@methods;
}

sub _derive_role_type {
    my $role = shift;

    if ($role->can('meta') && $role->meta()->isa('Moose::Meta::Role')) {
        # Also covers newer Moo::Roles
        return 'Moose::Role';
    }

    if (try_load_class('Role::Tiny') && Role::Tiny->is_role($role)) {
        # Also covers older Moo::Roles
        return 'Role::Tiny';
    }

    return;
}

my $package_counter = 0;
sub _build_consuming_package {
    my %args = @_;

    my $role_type = $args{role_type};
    my $role = $args{role};
    my $inline_subs = $args{inline_subs} || [];

    # We'll need a thing that exports a "with" sub
    my $with_exporter;
    if ($role_type eq 'Moose::Role') {
        $with_exporter = 'Moose';
    }
    elsif ($role_type eq 'Role::Tiny') {
        $with_exporter = 'Role::Tiny::With';
    }
    else {
        confess "Unknown role type $role_type";
    }

    my $package = 'MooseX::Test::Role::Consumer' . $package_counter++;
    my $source = qq{
        package $package;

        use $with_exporter;
        with('$role');
    };

    $source .= join("\n", @{$inline_subs});

    #warn $source;

    eval($source);
    die $@ if $@;

    return $package;
}

my $Test = Test::Builder->new();

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

Provides functions for testing roles. Supports roles created with
L<Moose::Role>, L<Moo::Role> or L<Role::Tiny>.

=head1 BACKGROUND

Unit testing a role can be hard. A major problem is creating classes that
consume the role.

One could side-step the problem entirely and just call the subroutines in the
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

Moose can create anonymous classes which consume roles:

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

=item C<consumer_of ($role, [$init_args_ref], %methods)>

Creates a class which consumes the role.

C<$role> must be the package name of a role. L<Moose::Role>, L<Moo::Role> and
L<Role::Tiny> are supported.

Returns an instance of the consuming class where possible. However, if the
class does not have a C<new()> method (which is commonly the case for
L<Role::Tiny>), then the package name will be returned instead.

Any method required by the role will be stubbed. To override the default stub
methods, or to add additional methods, specify the name and a coderef:

    consumer_of('MyRole',
        method1 => sub { 'one' },
        method2 => sub { 'two' },
        required_method => sub { 'required' },
    );

To provide initial arguments to the C<new()> constructor method (if it exists),
the second argument should be an array reference with those arguments.  This
is helpful if the role has attributes that are required at construction time.
Example:

    consumer_of('MyRoleWithArgs',
        [arg1 => 'foo', arg2 => 'bar],
        method1 => sub { 'one' },
        ...
    );

=item C<requires_ok ($role, @methods)>

Tests if role requires one or more methods.

=back

=head1 GITHUB

Patches, comments or mean-spirited code reviews are all welcomed on GitHub:

L<https://github.com/pboyd/MooseX-Test-Role>

=head1 AUTHORS

Paul Boyd <boyd.paul2@gmail.com>

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Boyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
