use strict;
use warnings;

package CMGITtests;

use Config;
use Test::More tests => 11;
use Capture::Tiny qw(capture);
use Class::Mock::Generic::InterfaceTester;

# Basics: if we mock a method call fixture, it works.
correct_method_call_gets_correct_results();

# The various ways we have of adding fixtures work fine.
add_fixtures_method_not_mocked();
add_fixtures_arrayref();
add_fixtures_list();
add_fixtures_ordered_hash();
add_fixtures_input_omitted();

# mock _ok in C::M::G::IT so any reported failure is considered a success.
# That only applies to this version of the Perl interpreter; shelling out
# and calling C::M::G::IT with bad fixtures still results in a failure.
Class::Mock::Generic::InterfaceTester->_ok(sub { Test::More::ok(!shift(), shift()); });

default_ok();

sub default_ok {
    my $perl = $Config{perlpath};

    my $result;
    {
      local $ENV{PERL5LIB} = join($Config{path_sep}, @INC);
      $result = (capture {
        system(
            $perl, qw( -MClass::Mock::Generic::InterfaceTester -e ),
            " Class::Mock::Generic::InterfaceTester->new([
                { method => 'wibble', input => ['wobble'], output => 'jelly' }
              ]) "
        )
      })[0];
    }
    ok($result =~ /^not ok.*didn't run all tests/, "normal 'ok' works")
        || diag($result);
}

# Now that we've done that, we can test all sorts of ways that things can
# go wrong, and consider C::M::G::IT complaining about something as a
# test success. We list the expected test failures in the plan above,
# so just saying Test::More::done_testing at the end is insufficient:
# that wouldn't distinguish between (a) a test ran and did nothing, and
# (b) a test produced an error, which we turned into a test success,
# and counted.

run_out_of_tests();
wrong_method();
wrong_args_structure();
wrong_args_subref();
magic_for_new();
didnt_run_all_tests();

sub didnt_run_all_tests {
    { 
        Class::Mock::Generic::InterfaceTester->new([
            { method => 'foo', input => ['foo'], output => 'foo' },
        ]);
    }
}

sub correct_method_call_gets_correct_results {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'foo', input => ['foo'], output => 'foo' },
    ]);

    ok($interface->foo('foo') eq 'foo', "correct method call gets right result back");
}

sub run_out_of_tests {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'foo', input => ['foo'], output => 'foo' },
    ]);

    $interface->foo('foo'); # eat the first test
    $interface->foo('bar'); # should emit an ok(1, "run out of tests ...")
}

sub wrong_method {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'foo', input => ['foo'], output => 'foo' },
    ]);

    $interface->bar('foo'); # should emit an ok(1, "wrong method ...");
}

sub wrong_args_structure {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'foo', input => ['foo'], output => 'foo' },
    ]);

    $interface->foo('bar'); # should emit an ok(1, "wrong args to method ...");
}

sub wrong_args_subref {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'foo', input => sub { shift() eq 'foo' }, output => 'bar' },
        { method => 'foo', input => sub { shift() eq 'foo' }, output => 'foo' },
    ]);

    ok($interface->foo('foo') eq 'bar', "subref as input can pass");
    $interface->foo('bar'); # should emit an ok(1, "wrong args to method ...");
}

sub magic_for_new {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'new', input => ['foo'], output => 'foo' },
        { method => 'new', input => ['foo'], output => 'foo' },
    ]);

    ok($interface->new('foo') eq 'foo', "\$mockobject->new() returns right data");
    $interface->new('bar'); # should emit an ok(1, "wrong args to method ...");
}

sub add_fixtures_method_not_mocked {
    my $interface_tester = Class::Mock::Generic::InterfaceTester->new(
        [
            {
                method => 'add_fixtures',
                input  => ['curtain rail', 'picture hook'],
                output => 'Picture hung!',
            }
        ]
    );
    is(
        $interface_tester->add_fixtures('curtain rail', 'picture hook'),
        'Picture hung!',
        q{The method add_fixtures isn't magical if you supplied}
            . ' a list of fixtures to the constructor'
    );
}

sub add_fixtures_arrayref { } 
sub add_fixtures_list { }
sub add_fixtures_ordered_hash { }
sub add_fixtures_input_omitted { }
