package Devel::Mockable;

use our::way;
no strict 'refs';

our %mocks;

sub import {
    my $class = shift;
    my %args  = @_;

    my $caller = (caller())[0];

    foreach my $mock (keys %args) {
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

1;

=head1 NAME

Devel::Mockable

=head1 DESCRIPTION

A handy mix-in for making stuff mockable.

Use this so that when testing your code you can easily mock how your
code talks to other bits of code, thus making it possible to test
your code in isolation, and without relying on third-party services.

=head1 SYNOPSIS

    use Devel::Mockable
        _email_sender         => 'Email::Sender::Simple',
        _email_sent_storage   => 'MyApp::Storage::EmailSent';

is equivalent to:

    # Make the email sender mockable
    my $email_sender;
    _reset_email_sender();
    sub _reset_email_sender { $email_sender = 'Email::Sender::Simple' };
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

Then anywhere that your code would want to refer to the class
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
    ok(My::Module->send_email(...), "email sending stuff works (without mocking)");

to restore the default functionality.

=cut
