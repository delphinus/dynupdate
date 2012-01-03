package DynUpdate;
use Moose;
use MooseX::Types::IPv4 qw!ip4!;

use HTTP::Date qw!time2iso!;
use HTTP::Request;
use LWP::UserAgent;
use Path::Class;
use URI;
use YAML qw!Dump!;

our $VERSION = '0.4.2012010201';

has agent      => (is => 'ro',
    default    => "delphinus\@remora.cx - dynupdate.pl - $VERSION");

has scheme     => (is => 'ro', default    => 'https');
has host       => (is => 'ro', default    => 'members.dyndns.org');
has path       => (is => 'ro', default    => '/nic/update');
has method     => (is => 'ro', default    => 'GET');
has protocol   => (is => 'ro', default    => 'HTTP/1.0');

has username   => (is => 'ro', isa => 'Str',  required => 1);
has password   => (is => 'ro', isa => 'Str',  required => 1);
has hostname   => (is => 'ro', isa => 'Str',  required => 1);
has wildcard   => (is => 'ro', isa => 'Str',  default  => 'NOCHG');
has mx         => (is => 'ro', isa => 'Str',  default  => 'NOCHG');
has backmx     => (is => 'ro', isa => 'Str',  default  => 'NOCHG');
has offline    => (is => 'ro', isa => 'Str',  default  => 'NOCHG');
has detect_uri => (is => 'ro', isa => 'Str',
    default    => 'http://checkip.dyndns.org/');
has debug_flg  => (is => 'ro', isa => 'Bool', default => 0);
has my_ip      => (is => 'rw', isa => ip4,    default => undef);

sub run { my $self = shift;
    return $self->update;
}

sub update { my $self = shift;
    my $uri = URI->new;
    $uri->scheme($self->scheme);
    $uri->host($self->host);
    $uri->path($self->path);
    $uri->query_form(
        hostname => $self->hostname,
        myip     => $self->get_my_ip,
        wildcard => $self->wildcard,
        mx       => $self->mx,
        backmx   => $self->backmx,
        offline  => $self->offline,
    );

    $self->debug($uri);

    my $req = HTTP::Request->new;
    $req->method($self->method);
    $req->uri($uri);
    $req->protocol($self->protocol);
    $req->header(Host => $self->host);
    $req->header('User-Agent' => $self->lwp->agent);
    $req->authorization_basic($self->username, $self->password);

    $self->debug($req);

    my $res = $self->lwp->request($req);
    $res->is_success or return $self->_die($res->status_line);

    $self->debug($res);

    my $content = $res->content;

    my ($status, $ip_address) = $content =~ /(\w+)(?: (\d+\.\d+\.\d+\.\d+))?/;

    if ($status eq 'good') {
        $self->log(Success =>
            "ip address has been updated successfully. => $ip_address");
        return 1;

    } elsif ($status eq 'nochg') {
        $self->log(Success => 'ip address does not need to be updated.');
        return 1;

    } else {
        $self->log(Failed => "ip address update failed. => '$content'");
        return 0;
    }
}

sub get_my_ip { my $self = shift;
    defined $self->my_ip and return $self->my_ip;

    my $res = $self->lwp->get($self->detect_uri);
    $res->is_success or return $self->_die($res->status_line);

    $self->debug($res->content);

    my ($ip_address) = $res->content =~
        m!Current IP Address: (\d+\.\d+\.\d+\.\d+)!;
    defined $ip_address or return $self->_die($res->status_line);

    return $ip_address;
}

*lwp = _lwp();
sub _lwp {
    my $lwp;
    return sub { my $self = shift;
        unless ($lwp) {
            $lwp = LWP::UserAgent->new;
            $lwp->env_proxy;
            $lwp->agent($self->agent);
            $self->debug('LWP instance created');
        }
        return $lwp;
    };
}

sub _die { my $self = shift;
    $self->log(Error => shift);
}

sub debug { my ($self, $msg) = @_;
    $self->debug_flg or return;
    if (ref $msg) {
        $msg = Dump $msg;
    } else {
        chomp $msg;
    }
    $self->log(Debug => $msg);
}

sub log { my $self = shift;
    printf "%s [%s] %s\n", time2iso(time), @_;
}

__PACKAGE__->meta->make_immutable;

