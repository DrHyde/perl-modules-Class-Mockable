use strict;
use warnings;

# very similar pre-amble to class-mock-generic-interfacetester.t
# how about some Test::Class and inheritance?

use Config;
use Test::More tests => 10;
use Capture::Tiny qw(capture);
use Class::Mock::Method::InterfaceTester;

# mock _ok in C::M::M::IT
Class::Mock::Method::InterfaceTester->_ok(sub { Test::More::ok(!shift(), shift()); });

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
