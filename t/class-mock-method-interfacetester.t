use strict;
use warnings;

package CMMITTests;

use lib 't/lib';
use CMMITTests::Subclass;

use Class::Mockable
    methods => { _test_method => 'test_method' };

# very similar pre-amble to class-mock-generic-interfacetester.t
# how about some Test::Class and inheritance?

use Config;
use Test::More tests => 11;
use Capture::Tiny qw(capture);
use Class::Mock::Method::InterfaceTester;

# mock _ok in C::M::M::IT
Class::Mock::Method::InterfaceTester->_ok(sub { Test::More::ok(!shift(), shift()); });

sub test_method { return "called test_method on $_[0] with [".join(', ', @_[1 .. $#_])."]\n"; }

default_ok();

sub default_ok {
    my $perl = $Config{perlpath};

    my $result;
    {
      local $ENV{PERL5LIB} = join($Config{path_sep}, @INC);
      $result = (capture {
        system(
            $perl, qw( -MClass::Mock::Method::InterfaceTester -e ),
            " Class::Mock::Method::InterfaceTester->new([
                { input => ['wobble'], output => 'jelly' }
              ]) "
        )
      })[0];
    }
    ok($result =~ /^not ok.*didn't run all tests/, "normal 'ok' works")
        || diag($result);
}

correct_method_call_gets_correct_results();
run_out_of_tests();
wrong_args_structure();
wrong_args_subref();
didnt_run_all_tests();
inheritance();
invocant_class();

sub wrong_args_structure {
    CMMITTests->_reset_test_method();
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );

    CMMITTests->_test_method('bar'); # should emit an ok(1, "wrong args to method ...");
}

sub wrong_args_subref {
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => sub { $_[0] eq 'foo' } , output => 'foo' },
            { input => sub { $_[0] eq 'foo' } , output => 'foo' },
        ])
    );

    ok(CMMITTests->_test_method('foo') eq 'foo', "correct method call gets right result back (checking with a subref)");
    CMMITTests->_test_method('bar'); # should emit an ok(1, "wrong args to method ...");
}

sub correct_method_call_gets_correct_results {
    CMMITTests->_reset_test_method();
    ok(CMMITTests->_test_method('foo') eq "called test_method on CMMITTests with [foo]\n",
        "calling a method after _reset()ing works"
    );

    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );

    ok(CMMITTests->_test_method('foo') eq 'foo', "correct method call gets right result back");
}

sub run_out_of_tests {
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );

    CMMITTests->_test_method('foo'); # eat the first test
    CMMITTests->_test_method('bar'); # should emit an ok(1, "run out of tests ...")
}

sub didnt_run_all_tests {
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );
    CMMITTests->_reset_test_method();
}

sub inheritance {
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );
    ok(CMMITTests::Subclass->test_method('foo') eq "called test_method on CMMITTests::Subclass with [foo]\n",
        "yup, subclass is good (sanity check)");
    ok(CMMITTests::Subclass->_test_method('foo') eq 'foo', "called mock on subclass OK");
    CMMITTests::Subclass->_test_method('foo'); # should spit out a 'ran out of tests' error
}

sub invocant_class {
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { invocant_class => 'CMMITTests',           input => ['foo'], output => 'foo' },
            { invocant_class => 'CMMITTests',           input => ['foo'], output => 'foo' },
            { invocant_class => 'CMMITTests',           input => ['foo'], output => 'foo' },
            { invocant_class => 'CMMITTests::Subclass', input => ['foo'], output => 'foo' },
            { invocant_class => 'CMMITTests::Subclass', input => ['foo'], output => 'foo' },
        ])
    );

    bless({}, 'CMMITTests')->_test_method('foo'); # called on object, not class

    ok(CMMITTests->_test_method('foo') eq 'foo', "called on right class");
    CMMITTests::Subclass->_test_method('foo'); # called on wrong class, via inheritance
    CMMITTests->_test_method('foo');           # called on wrong class
    ok(CMMITTests::Subclass->_test_method('foo') eq 'foo', "called on right class via inheritance");
}
