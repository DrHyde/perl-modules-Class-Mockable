use strict;
use warnings;
use lib 't/lib';

use Test::More tests => 3;

use SomePackage;

is(SomePackage->get_returnvalue(), 94, "default works");

SomePackage->_returnvalue('lemon');
is(SomePackage->get_returnvalue(), 'lemon', "overriding the default works");

SomePackage->_reset_returnvalue();
is(SomePackage->get_returnvalue(), 94, "reset works");
