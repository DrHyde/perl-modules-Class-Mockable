package SomePackage;

use Class::Mockable
    _returnvalue => 94;

sub get_returnvalue {
    my $class = shift;
    return _returnvalue();
}

1;
