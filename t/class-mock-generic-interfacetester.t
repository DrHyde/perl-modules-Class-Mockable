use strict;
use warnings;

use Test::More tests => 94;

use Config;
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
select(STDERR);
$| = 1;
close(OLD_STDERR);

ok($result =~ /^not ok/, "normal 'ok' works") || diag($result);
diag("from now on we mock it");
