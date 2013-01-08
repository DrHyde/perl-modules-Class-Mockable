package SomePackage;

use Class::Mockable
    _returnvalue => 94
    methods => {
        _some_method => 'some_method',
    };

sub get_returnvalue {
    my $class = shift;
    return _returnvalue();
}

sub some_method {
    my $class = shift;
    return "some method";
}

1;
