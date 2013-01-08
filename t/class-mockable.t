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


# Method mocking tests.
ok(SomePackage->can('_some_method', 'Mock method accessor created ok');
ok(SomePackage->can('_set_some_method', 'Mock method setter created ok');
ok(SomePackage->can('_reset_some_method', 'Mock method resetter created ok');

is(SomePackage->_some_method(), 'some method', 'Default mock method calls correct sub');

SomePackage->_set_some_method(sub{ return 'other method' });
is(SomePackage->_some_method(), 'other method', 'Method mocking works correctly');

SomePackage->_reset_some_method();
is(SomePackage->_some_method(), 'some method', 'Method mocking reset works correctly');

