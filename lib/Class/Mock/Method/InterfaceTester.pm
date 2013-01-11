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
        if(!@tests) { # no tests left
            __PACKAGE__->_ok()->(0, sprintf("run out of tests on mock method defined in %s", $called_from));
            return;
        }

        my $this_test = shift(@tests);
        my $invocant = shift;
        my @params = @_;

        # check arguments
        if(ref($this_test->{input}) eq 'CODE') {
            if(!$this_test->{input}->(@params)) {
                __PACKAGE__->_ok()->(0, sprintf("wrong args to mock method defined on $invocant defined in %s. Got %s.", $called_from, Dumper(\@params)));
                return;
            }
        } elsif(!Compare($this_test->{input}, \@params)) {
            __PACKAGE__->_ok()->(0, sprintf("wrong args to mock method defined on $invocant defined in %s. Got %s.", $called_from, Dumper(\@params)));
            return;
        }

        # check invocant
        if($this_test->{invocant_class}) { # must be called as class method on right class
            if(ref($invocant)) {
                __PACKAGE__->_ok()->(0, sprintf("expected call as class method, but object method called, defined in %s.", $called_from));
                return;
            } elsif($invocant ne $this_test->{invocant_class}) {
                __PACKAGE__->_ok()->(0, sprintf("class method called on wrong class, defined in %s - got %s expected %s.", $called_from, $invocant, $this_test->{invocant_class}));
                return;
            }
        }

        return $this_test->{output};
    }, $class);
}

# re-factor this and C::M::G::IT::DESTROY
sub DESTROY {
  my $self = shift;
  my %closure = %{(closed_over($self))[0]};

  if(@{$closure{'@tests'}}) {
    __PACKAGE__->_ok()->( 0,
        sprintf (
            "didn't run all tests in mock method defined in %s (remaining tests: %s)",
            ${$closure{'$called_from'}},
            Dumper( $closure{'@tests'} )
        )
    );
  }
}

1;

=head1 NAME

Class::Mock::Method::InterfaceTester

=head1 DESCRIPTION

A helper for Class::Mockable's method mocking

=head1 SYNOPSIS

In the class under test:

    # create a '_foo' wrapper around method 'foo'
    use Class::Mockable
        methods => { _foo => 'foo' };

And then in the tests:

    Some::Module->_set_foo(
        Class::Mock::Method::InterfaceTester->new([
            {
                input  => ...
                output => ...
            }
        ])
    );

=head1 METHODS

=head2 new

This is the constructor.  It returns a blessed sub-ref.  Class::Mockable's
method mocking expects a sub-ref, so will Just Work (tm).

The sub-ref will behave similarly to the method calls defined in
Class::Mock::Generic::InterfaceTester.  That is, it will validate
that the method is being called correctly and emit a test failure if it
isn't, or if called correctly will return the specified value.  If the
method is ever called with the wrong parameters - including if defined
method calls are made in the wrong order, then that's a test failure.

It is also a test failure to call the method fewer or more times than
expected.

C<new()> takes an arrayref or hashrefs as its argument.  Those hashes
must have keys 'input' and 'output' whose values define the ins and
outs of each method call in turn.  'input' is always an arrayref which
will get compared to all the method's arguments (excluding the first
one, the object or class itself) but For validating very complex inputs
you may specify a subroutine reference for the input, which will get
executed with the actual input as its argument.  If you want to check
that the method is being invoked on the right object or class (if you
are paranoid about inheritance, for example) then use the optional
'invocant_class' string to check that it's being called as a class method
on the right class (not on a subclass, *the right class*), or
invocant_object' string to check that it's being called on an object of
the right class (again, not a subclass), or 'invocant_object' subref to
check that it's being called on an object that, when passed to the sub-ref,
returns true.

=head1 SEE ALSO

L<Class::Mockable>

L<Class::Mock::Generic::InterfaceTester>

=head1 AUTHOR

Copyright 2013 UK2 Ltd and David Cantrell E<lt>david@cantrell.org.ukE<gt>

This software is free-as-in-speech software, and may be used, distributed,
and modified under the terms of either the GNU General Public Licence
version 2 or the Artistic Licence.  It's up to you which one you use.  The
full text of the licences can be found in the files GPL2.txt and
ARTISTIC.txt, respectively.

=head1 SOURCE CODE REPOSITORY

E<lt>git://github.com/DrHyde/perl-modules-Class-Mockable.gitE<gt>

=head1 BUGS/FEEDBACK

Please report bugs at Github
E<lt>https://github.com/DrHyde/perl-modules-Class-Mockable/issuesE<gt>

=head1 CONSPIRACY

This software is also free-as-in-mason.

=cut
