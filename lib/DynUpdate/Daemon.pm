package DynUpdate::Daemon;
use Moose;
use MooseX::Types::Path::Class qw!File!;

extends 'DynUpdate';
with 'MooseX::Daemonize';

use DynUpdate::Constants;
use DynUpdate::Mail;

use utf8;
use File::Basename;
use FindBin qw!$Bin!;
use HTTP::Date qw!time2iso!;

our $VERSION = '0.5.2012010801';

has [qw!
    +ignore_zombies +no_double_fork +progname +basedir
    +stop_timeout   +pidfile        +agent    +dont_close_all_files
    +scheme         +host           +path     +method
    +protocol
!] => (traits => ['NoGetopt']);

has '+pidbase'    => (documentation => 'path to pidfile dir');
has '+foreground' => (documentation => 'foreground execution');

has '+username'   => (traits => ['Getopt'], cmd_aliases => 'u',
    documentation => 'username registered in Dyn.com');
has '+password'   => (traits => ['Getopt'], cmd_aliases => 'p',
    documentation => 'password registered in Dyn.com');
has '+hostname'   => (traits => ['Getopt'], cmd_aliases => 'n',
    documentation => 'hostname to be updated');
has '+detect_uri' => (traits => ['Getopt'], cmd_aliases => 'e',
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
    documentation => 'interval seconds between checks',
    is => 'ro', isa => 'Int', default => 900);

has my_ip         => (traits => ['Getopt'], cmd_aliases => 'm',
    documentation => 'ip address to update',
    is => 'rw', isa => 'Str');
has once          => (traits => ['Getopt'], cmd_aliases => '1',
    documentation => 'run once, and exit',
    is => 'ro', isa => 'Bool', default => 0);

has '+wildcard'   => (traits => ['Getopt'],
    documentation => '(currently ignored)');
has '+mx'         => (traits => ['Getopt'],
    documentation => '(currently ignored)');
has '+backmx'     => (traits => ['Getopt'],
    documentation => '(currently ignored)');
has '+offline'    => (traits => ['Getopt'],
    documentation => 'set to offline mode');

has mail          => (is => 'ro', isa => 'Bool', default => 0);
has mail_username => (is => 'ro', isa => 'Str',  default => '');
has mail_password => (is => 'ro', isa => 'Str',  default => '');
has mail_server   => (is => 'ro', isa => 'Str',  default => '');
has mail_port     => (is => 'ro', isa => 'Int',  default => 25);
has mail_from     => (is => 'ro', isa => 'Str',  default => '');
has mail_to       => (is => 'ro', isa => 'Str',  default => '');

sub BUILD { my $self = shift;
    defined $self->my_ip and !$self->once
        and die "--my_ip and --once must be specified together\n";
    -d $self->pidbase or $self->pidbase->mkpath;
}

after start => sub { my $self = shift;
    $self->is_daemon or return;

    $self->log(Info => 'START!');
    $self->mail_send('[DynUpdate] 開始しました',
        sprintf <<EOM, $self->hostname);
監視を開始しました

サーバー : %s
EOM
    $self->run;
};

override run => sub { my $self = shift;
    while (1) {
        super;
        $self->once and last;
        $self->debug('sleeping...');
        sleep $self->interval;
    }
};

override update => sub { my $self = shift;
    my $new;

    if ($self->once) {
        $new = $self->my_ip;
        $self->debug("new IP Address : $new");
    } else {
        $new = $self->get_my_ip;
        $self->debug(sprintf 'old : %s, new : %s',
            ($self->my_ip || 'NONE'), $new);
    }

    if ($self->my_ip eq $new) {
        $self->log(Unchanged => 'ip address has not changed.');
        return $UPDATE_UNNEEDED;

    } else {
        $self->log(Changed => 'ip address needs to be updated.');
        $self->my_ip($new);
        my $v = super;
        if ($v == $UPDATE_SUCCESS) {
            my $subject = sprintf '[%s] IP アドレスが変更されました', $new;
            my $data = sprintf <<EOM, $self->hostname, $new;
IP アドレスが次のように変更されました。

ホスト名 : %s
IP アドレス : %s
EOM
            $self->mail_send($subject, $data);
        }
        return $v;
    }
};

override log => sub { my $self = shift;
    if ($self->foreground) {
        super;
    } else {
        $self->log_fh->print(sprintf "%s [%s] %s\n", time2iso(time), @_);
    }
};

{
    no warnings 'once';
    *log_fh = _log_fh();
}
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

sub mail_send { my $self = shift;
    return unless $self->mail;

    my ($subject, $data) = @_;

    my $mail = DynUpdate::Mail->new(
        username => $self->mail_username,
        password => $self->mail_password,
        server   => $self->mail_server,
        port     => $self->mail_port,
        from     => $self->mail_from,
        to       => $self->mail_to,
        subject  => $subject,
        data     => $data,
    );

    $mail->send;
}

__PACKAGE__->meta->make_immutable;

