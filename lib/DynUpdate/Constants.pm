package DynUpdate::Constants;
use Exporter qw!import!;
use Readonly;

our @EXPORT = qw!
    $UPDATE_UNNEEDED $UPDATE_SUCCESS $UPDATE_NOCHG $UPDATE_FAILED
!;

Readonly my $UPDATE_UNNEEDED => 3;
Readonly my $UPDATE_SUCCESS => 2;
Readonly my $UPDATE_NOCHG => 1;
Readonly my $UPDATE_FAILED => 0;

1;
