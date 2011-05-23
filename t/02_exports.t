use strict;
use warnings;

use Test::More tests => 2;

use MooseX::Test::Role;
can_ok( __PACKAGE__, 'requires_ok' );
can_ok( __PACKAGE__, 'consumer_of' );
