use strict;
use warnings;

package CMGITtests;

use Config;
use Test::More tests => 6;
use Class::Mock::Generic::InterfaceTester;

# mock _ok in C::M::G::IT
Class::Mock::Generic::InterfaceTester->_ok(sub { Test::More::ok(!shift(), shift()); });

correct_method_call_gets_correct_results();
run_out_of_tests();
wrong_method();
wrong_args_structure();
wrong_args_subref();

# and un-mock for a sanity-check
Class::Mock::Generic::InterfaceTester->_reset_ok();
default_ok();

sub default_ok {
    my $perl = $Config{perlpath};
    # what a lot of faff to portably (I hope) hide STDERR
    open(OLD_STDERR, '>&', \*STDERR) || die("Can't dup STDERR\n");
    close(STDERR);
    $ENV{PERL5LIB} = join($Config{path_sep}, @INC);
    my $result = qx(
        $perl -MClass::Mock::Generic::InterfaceTester -e '
        Class::Mock::Generic::InterfaceTester->new([
            { method => 'wibble', input => ['wobble'], output => 'jelly' }
        ])
        '
    );
    open(STDERR, '>&', \*OLD_STDERR) || die("Can't restore STDERR\n");
    my $current_fh = select(STDERR);
    $| = 1;
    select($current_fh);
    close(OLD_STDERR);
    ok($result =~ /^not ok.*didn't run all tests/, "normal 'ok' works")
        || diag($result);
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
        { method => 'foo', input => sub { shift() eq 'foo' }, output => 'foo' },
    ]);

    $interface->foo('bar'); # should emit an ok(1, "wrong args to method ...");
}
