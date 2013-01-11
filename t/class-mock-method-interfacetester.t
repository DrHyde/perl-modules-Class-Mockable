use strict;
use warnings;

package CMMITTests;

use Class::Mockable
    methods => { _test_method => 'test_method' };

# very similar pre-amble to class-mock-generic-interfacetester.t
# how about some Test::Class and inheritance?

use Config;
use Test::More tests => 10;
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

run_out_of_tests();

sub run_out_of_tests {
    __PACKAGE__->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );

    __PACKAGE__->_test_method('foo'); # eat the first test
    __PACKAGE__->_test_method('bar'); # should emit an ok(1, "run out of tests ...")
}
