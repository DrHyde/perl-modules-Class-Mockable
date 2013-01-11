use strict;
use warnings;

# just for convenience
package CMMIT;
use base qw(Class::Mock::Method::InterfaceTester);

package CMMITTests;

use lib 't/lib';
use CMMITTests::Subclass;

use Class::Mockable
    methods => { _test_method => 'test_method' };

# very similar pre-amble to class-mock-generic-interfacetester.t
# how about some Test::Class and inheritance?

use Config;
use Test::More tests => 26;
use Scalar::Util qw(blessed);
use Capture::Tiny qw(capture);
use Class::Mock::Method::InterfaceTester;

# mock _ok in C::M::M::IT
sub _setup_mock {
    Class::Mock::Method::InterfaceTester->_ok(sub {
        my($result, $message) = @_;
        return ($result ? '' : 'not ')."ok 94 $message";
    });
}

_setup_mock();

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
invocant_class_and_object();
invocant_class();
invocant_object_string();
invocant_object_subref();

sub _check_result {
    my($expected, $got, $message) = @_;
    $expected =~ s/%s/.*?/g;
    $expected = qr/$expected/s;
    like($got, $expected, $message);
}

sub wrong_args_structure {
    CMMITTests->_reset_test_method();
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );

    _check_result(
        CMMIT->WRONG_ARGS_W_EXPECTED,
        CMMITTests->_test_method('bar'),
        "detects wrong args to method"
    );
}

sub wrong_args_subref {
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => sub { $_[0] eq 'foo' } , output => 'foo' },
            { input => sub { $_[0] eq 'foo' } , output => 'foo' },
        ])
    );

    ok(CMMITTests->_test_method('foo') eq 'foo', "correct method call gets right result back (checking with a subref)");
    _check_result(
        CMMIT->WRONG_ARGS,
        CMMITTests->_test_method('bar'),
        "detects wrong args to method (checking with a subref)"
    );
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
    _check_result(
        CMMIT->RUN_OUT,
        CMMITTests->_test_method('bar'),
        "run out of tests"
    );
}

sub didnt_run_all_tests {
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );
    # the DESTROY spits out a test, so we need to do this
    # because we can't capture its return value
    Class::Mock::Method::InterfaceTester->_ok(sub { Test::More::ok(!shift(), shift()); });

    CMMITTests->_reset_test_method();
    _setup_mock(); # restore _ok to what we normally use
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
    _check_result(
        CMMIT->RUN_OUT,
        CMMITTests::Subclass->_test_method('foo'),
        "run out of tests (using inheritance)"
    );
}

sub invocant_class_and_object {
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { invocant_class => 'CMMITTests', invocant_object => 'CMMITTests', input => ['foo'], output => 'foo' },
        ])
    );
    _check_result(
        CMMIT->BOTH_INVOCANTS,
        CMMITTests->_test_method('foo'),
        "can't have both of _invocant_{class,object}"
    );
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

    _check_result(
        CMMIT->EXP_CLASS_GOT_OBJECT,
        bless({}, 'CMMITTests')->_test_method('foo'),
        "called method on object, not class"
    );

    ok(CMMITTests->_test_method('foo') eq 'foo', "called on right class");
    _check_result(
        CMMIT->WRONG_CLASS,
        CMMITTests::Subclass->_test_method('foo'),
        "called on wrong class, via inheritance"
    );
    _check_result(
        CMMIT->WRONG_CLASS,
        CMMITTests->_test_method('foo'),
        "called on wrong class"
    );
    ok(CMMITTests::Subclass->_test_method('foo') eq 'foo', "called on right class via inheritance");
}

# re-factor these two
sub invocant_object_string {
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { invocant_object => 'CMMITTests',           input => ['foo'], output => 'foo' },
            { invocant_object => 'CMMITTests',           input => ['foo'], output => 'foo' },
            { invocant_object => 'CMMITTests',           input => ['foo'], output => 'foo' },
            { invocant_object => 'CMMITTests::Subclass', input => ['foo'], output => 'foo' },
            { invocant_object => 'CMMITTests::Subclass', input => ['foo'], output => 'foo' },
        ])
    );

    _check_result(
        CMMIT->EXP_OBJECT_GOT_CLASS,
        CMMITTests->_test_method('foo'),
        "called method on class, not object"
    );

    ok(bless({}, 'CMMITTests')->_test_method('foo') eq 'foo', "called on object of right class");
    _check_result(
        CMMIT->WRONG_OBJECT,
        bless({}, 'CMMITTests::Subclass')->_test_method('foo'),
        "called method on object of wrong class, via inheritance"
    );
    _check_result(
        CMMIT->WRONG_OBJECT,
        bless({}, 'CMMITTests')->_test_method('foo'),
        "called method on object of wrong class"
    );
    ok(bless({}, 'CMMITTests::Subclass')->_test_method('foo') eq 'foo', "called on object of right class via inheritance");
}

sub invocant_object_subref {
    CMMITTests->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { invocant_object => sub { blessed($_[0]) eq 'CMMITTests' },           input => ['foo'], output => 'foo' },
            { invocant_object => sub { blessed($_[0]) eq 'CMMITTests' },           input => ['foo'], output => 'foo' },
            { invocant_object => sub { blessed($_[0]) eq 'CMMITTests::Subclass' }, input => ['foo'], output => 'foo' },
            { invocant_object => sub { blessed($_[0]) eq 'CMMITTests::Subclass' }, input => ['foo'], output => 'foo' },
        ])
    );

    ok(bless({}, 'CMMITTests')->_test_method('foo') eq 'foo', "called on object that matches sub-ref");
    _check_result(
        CMMIT->WRONG_OBJECT_SUBREF,
        bless({}, 'CMMITTests::Subclass')->_test_method('foo'),
        "called on object that doesn't match sub-ref, via inheritance"
    );
    _check_result(
        CMMIT->WRONG_OBJECT_SUBREF,
        bless({}, 'CMMITTests')->_test_method('foo'),
        "called on object that doesn't match sub-ref"
    );
    ok(bless({}, 'CMMITTests::Subclass')->_test_method('foo') eq 'foo', "called on object that matches sub-ref, via inheritance");
}
