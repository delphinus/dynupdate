package DynUpdate::Daemon;
use Moose;
use MooseX::Types::IPv4 qw!ip4!;
use MooseX::Types::Path::Class qw!File!;

extends 'DynUpdate';
with 'MooseX::Daemonize';

use File::Basename;
use FindBin qw!$Bin!;
use HTTP::Date qw!time2iso!;

our $VERSION = '0.4.2012010101';

has [qw!
    +ignore_zombies +no_double_fork +progname +basedir
    +stop_timeout   +pidfile        +agent    +dont_close_all_files 
    +scheme         +host           +path     +method
    +protocol       +uri
!] => (traits => ['NoGetopt']);

has '+pidbase'    => (documentation => 'path to pidfile dir');
has '+foreground' => (documentation => 'foreground execution');

has '+username'   => (traits => ['Getopt'], cmd_aliases => 'n',
    documentation => 'username registered in Dyn.com');
has '+password'   => (traits => ['Getopt'], cmd_aliases => 'p',
    documentation => 'password registered in Dyn.com');
has '+hostname'   => (traits => ['Getopt'], cmd_aliases => 'h',
    documentation => 'hostname to be updated');
has '+wildcard'   => (traits => ['Getopt'], cmd_aliases => 'w',
    documentation => '(currently ignored)');
has '+mx'         => (traits => ['Getopt'], cmd_aliases => 'm',
    documentation => '(currently ignored)');
has '+backmx'     => (traits => ['Getopt'], cmd_aliases => 'b',
    documentation => '(currently ignored)');
has '+offline'    => (traits => ['Getopt'], cmd_aliases => 'o',
    documentation => 'set to offline mode');
has '+detect_uri' => (traits => ['Getopt'], cmd_aliases => 'u',
    documentation => 'url for detecting ip address');

has '+debug_flg'  => (traits => ['Getopt'], cmd_aliases => 'd',
    cmd_flag    => 'debug', documentation => 'debug mode');

has log_file      => (traits => ['Getopt'], cmd_aliases => 'l',
    documentation => 'log filename',
    is => 'ro', isa => File, coerce => File,
    default       => sub {
        my $name = fileparse($0, qr!\.[^.]*!);
        return "$Bin/logs/$name.log";
    });

has interval      => (traits => ['Getopt'], cmd_aliases => 'i',
    documentation => 'interval seconds between updates',
    is => 'ro', isa => 'Int', default => 900);

has my_ip         => (traits => ['NoGetopt'],
    is => 'rw', isa => ip4, default  => '0.0.0.0');

sub BUILD { my $self = shift;
    -d $self->pidbase or $self->pidbase->mkpath;
}

after start => sub { my $self = shift;
    $self->is_daemon or return;

    $self->log(Info => 'START!');
    $self->run;
};

override run => sub { my $self = shift;
    while (1) {
        super;
        sleep $self->interval;
    }
};

override update => sub { my $self = shift;
    my $new = $self->get_my_ip;

    if ($self->my_ip eq $new) {
        $self->log(Unchanged => 'ip address has not changed.');
        return 1;

    } else {
        $self->log(Changed => 'ip address need to be updated.');
        $self->my_ip($new);
        return super;
    }
};

override log => sub { my $self = shift;
    $self->log_fh->print(sprintf "%s [%s] %s\n", time2iso(time), @_);
};

*log_fh = _log_fh();
sub _log_fh {
    my $fh;
    return sub { my $self = shift;
        unless ($fh) {
            -d $self->log_file->parent or $self->log_file->parent->mkpath;
            open $fh, '>>', $self->log_file or die;
            $fh->autoflush(1);
        }
        return $fh;
    };
}

__PACKAGE__->meta->make_immutable;

