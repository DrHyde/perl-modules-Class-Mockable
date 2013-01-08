package Class::Mockable;

use strict;
use warnings;
no strict 'refs';

our $VERSION = '1.0002';

our %mocks;

sub import {
    my $class = shift;
    my %args  = @_;

    my $caller = (caller())[0];

    mock:
    foreach my $mock (keys %args) {

        # For the special mock key 'methods', add mockability to the class
        # methods defined.
        if (lc $mock eq 'methods') {
            _add_method_mocking($caller, $args{$mock});
            next mock;
        }

        # And add mocking for classes.
        my $singleton_name = "${caller}::$mock";
        $mocks{$singleton_name} = $args{$mock};
        *{"${caller}::_reset$mock"} = sub {
            $mocks{$singleton_name} = $args{$mock};
        };
        *{"${caller}::$mock"} = sub {
            shift;
            if(exists($_[0])) { $mocks{$singleton_name} = shift; }
            $mocks{$singleton_name}
        };
    }
}

# Method mocking is slightly different, in that we need to create a setter, so
# that the method can be replaced with a method mocker test interface or
# code ref to do something else, as well as setting up the actual mock method
# accessor to be used. Hurrah for Voodoo!!

sub _add_method_mocking {
    my $caller       = shift;
    my $method_mocks = shift;

    for my $mock (keys %$method_mocks) {
        my $singleton_name = "${caller}::$mock";
        $mocks{$singleton_name} = "${caller}::$method_mocks->{$mock}";

        *{"${caller}::_reset$mock"} = sub {
            $mocks{$singleton_name} = "${caller}::$method_mocks->{$mock}";
        };

        *{"${caller}::_set$mock"} = sub {
            shift;
            if (exists($_[0])) { $mocks{$singleton_name} = shift; }
        };

        *{"${caller}::$mock"} = sub {
            shift;
            $mocks{$singleton_name}->(@_);
        };
    }
}

1;

=head1 NAME

Class::Mockable

=head1 DESCRIPTION

A handy mix-in for making stuff mockable.

Use this so that when testing your code you can easily mock how your
code talks to other bits of code, thus making it possible to test
your code in isolation, and without relying on third-party services.

=head1 SYNOPSIS

    use Class::Mockable
        _email_sender         => 'Email::Sender::Simple',
        _email_sent_storage   => 'MyApp::Storage::EmailSent';

is equivalent to:

    {
        my $email_sender;
        _reset_email_sender();
        sub _reset_email_sender {
            $email_sender = 'Email::Sender::Simple'
        };
        sub _email_sender {
            my $class = shift;
            if (exists($_[0])) { $email_sender = shift; }
            return $email_sender;
        }

        my $email_sent_storage;
        _reset_email_sent_storage();
        sub _reset_email_sent_storage {
            $email_sent_storage = 'MyApp::Storage::EmailSent'
        };
        sub _email_sent_storage {
            my $class = shift;
            if (exists($_[0])) { $email_sent_storage = shift; }
            return $email_sent_storage;
        }
    }

=head1 HOW TO USE IT

After setting up as above, the anywhere that your code would want to refer to the class
'Email::Sender::Simple', for example, you would do this:

    my $sender = $self->_email_sender();

In your tests, you would do this:

    My::Module->_email_sender('MyApp::Tests::Mocks::EmailSender');
    ok(My::Module->send_email(...), "email sending stuff works");

where 'MyApp::Tests::Mocks::EmailSender' pretends to be the real email
sending class, only without spamming everyone every time you run the tests.
And of course, if you do want to really send email from a test - perhaps
you want to do an end-to-end test before releasing - you would do this:

    My::Module->_reset_email_sender() if($ENV{RELEASE_TESTING});
    ok(My::Module->send_email(...),
        "email sending stuff works (without mocking)");

to restore the default functionality.


=head2 METHOD MOCKING

In order to isolate a method from others in the same class, you can also provide
Class::Mockable with a list of class methods you'd like to be able to mock and
it's accessor name.  This allows you to test each class method once without
calling others during testing.

    use Class::Mockable
        methods => {
            _foo => 'foo',
        };

Note, that the methods special key can be appended to the synopsis code example
as it will work along side other object mocking.

The above will create a _foo sub on your class that by default will call your
classes foo() subroutine.  This behaviour can be changed by calling the setter
function _set_foo (where _foo is your identifier).  The default behaviour can be
restored by calling _reset_foo (again, where _foo is your identifier)

For example:

    package Test;

    use strict;
    use lib 'lib';
    use Class::Mockable
        methods => {
            _bar => 'bar',
        };

    sub bar {
        my $self = shift;
        return "Bar";
    }

    sub foo {
        my $self = shift;
        return $self->_bar();
    }

    package main;

    use strict;

    TestStuff->_set_bar(
        sub {
            my $self = shift;
            return "Foo";
        }
    );

    print Test->bar();         # Prints "Bar"
    print Test->foo();         # Prints "Foo"

    TestStuff->_reset_bar();

    print Test->bar();         # Prints "Bar"
    print Test->foo();         # Prints "Bar"


=head1 AUTHOR

Copyright 2012 UK2 Ltd and David Cantrell E<lt>david@cantrell.org.ukE<gt>

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
