package Class::Mock::Method::InterfaceTester;

use strict;
use warnings;

our $VERSION = '1.0';

# all this pre-amble is damned near identical to C::M::G::IT. Re-factor.
use Test::More ();
use Data::Compare;
use Scalar::Util;
use PadWalker qw(closed_over);
use Data::Dumper;
local $Data::Dumper::Indent = 1;

use Class::Mockable
    _ok => sub { Test::More::ok($_[0], @_[1..$#_]) };

sub new {
    my $class = shift;
    my $called_from = (caller(1))[3];
    my @tests = @{shift()};

    return bless(sub {
        @tests; $called_from;
    }, $class);
}

# re-factor this and C::M::G::IT::DESTROY
sub DESTROY {
  my $self = shift;
  my %closure = %{(closed_over($self))[0]};

  if($closure{'@tests'}) {
    __PACKAGE__->_ok()->( 0,
        sprintf (
            "didn't run all tests in mock object defined in %s (remaining tests: %s)",
            $closure{'$called_from'},
            Dumper( $closure{'@tests'} )
        )
    );
  }
}

1;
