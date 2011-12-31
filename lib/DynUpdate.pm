package DynUpdate;
use Moose;

use HTTP::Date qw!time2iso!;
use HTTP::Request;
use LWP::UserAgent;
use Path::Class;
use URI;

our $VERSION = '0.4.2011123101';

has agent      => (is => 'ro',
	default    => "delphinus\@remora.cx - dynUpdate.pl - $VERSION");

has scheme     => (is => 'ro', default    => 'https');
has host       => (is => 'ro', default    => 'members.dyndns.org');
has path       => (is => 'ro', default    => '/nic/update');
has method     => (is => 'ro', default    => 'GET');
has protocol   => (is => 'ro', default    => 'HTTP/1.0');
has uri        => (is => 'ro', lazy_build => 1);

has username   => (is => 'ro', isa => 'Str', required   => 1);
has password   => (is => 'ro', isa => 'Str', required   => 1);
has hostname   => (is => 'ro', isa => 'Str', required   => 1);
has wildcard   => (is => 'ro', isa => 'Str', default    => 'NOCHG');
has mx         => (is => 'ro', isa => 'Str', default    => 'NOCHG');
has backmx     => (is => 'ro', isa => 'Str', default    => 'NOCHG');
has detect_uri => (is => 'ro', isa => 'Str',
	default    => 'http://checkip.dyndns.org/');

sub run { my $self = shift;
	return $self->update;
}

sub update { my $self = shift;
	my $ua = $self->get_ua();

	my $req = HTTP::Request->new;
	$req->method($self->method);
	$req->uri($self->uri);
	$req->protocol($self->protocol);
	$req->header(Host => $self->host);
	$req->header('User-Agent' => $ua->agent);
	$req->authorization_basic($self->username, $self->password);

	my $res = $ua->request($req);
	$res->is_success or return $self->_die($res->status_line);

	my $content = $res->content;

	my ($status, $ip_address) = $content =~ /(\w+)(?: (\d+\.\d+\.\d+\.\d+))?/;

	if ($status eq 'good') {
		$self->log('Success',
			"ip address has been updated successfully. => $ip_address");
		return 1;

	} elsif ($status eq 'nochg') {
		$self->log('Success', 'ip address does not need to be updated.');
		return 1;

	} else {
		$self->log('Failed', "ip address update failed. => '$content'");
		return 0;
	}
}

sub _build_uri { my $self = shift;
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
	);

	return $uri;
}

sub get_my_ip { my $self = shift;
	my $ua = $self->get_ua();
	my $res = $ua->get($self->detect_uri);
	$res->is_success or return $self->_die($res->status_line);

	my ($ip_address) = $res->content =~
		m!Current IP Address: (\d+\.\d+\.\d+\.\d+)!;
	defined $ip_address or return $self->_die($res->status_line);

	return $ip_address;
}

sub get_ua { my $self = shift;
	my $ua = LWP::UserAgent->new;
	$ua->env_proxy;
	$ua->agent($self->agent);

	return $ua;
}

sub _die { my $self = shift;
	$self->log('Error', shift);
}

sub log { my $self = shift;
	printf "%s [%s] %s\n", time2iso(time), @_;
}

__PACKAGE__->meta->make_immutable;

