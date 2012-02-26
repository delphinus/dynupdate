package DynUpdate::Constants;
use Exporter qw!import!;
use Readonly;

our @EXPORT = qw!
    $UPDATE_UNNEEDED $UPDATE_SUCCESS $UPDATE_NOCHG $UPDATE_FAILED
!;

Readonly::Scalar $UPDATE_UNNEEDED => 3;
Readonly::Scalar $UPDATE_SUCCESS  => 2;
Readonly::Scalar $UPDATE_NOCHG    => 1;
Readonly::Scalar $UPDATE_FAILED   => 0;

1;
