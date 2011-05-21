use strict;
use warnings;

use Test::More tests => 1;

use MooseX::Test::Role;
can_ok( __PACKAGE__, 'requires_ok' );
