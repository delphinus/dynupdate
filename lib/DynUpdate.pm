package DynUpdate;
use Moose;

use HTTP::Date qw!time2iso!;
use HTTP::Request;
use LWP::UserAgent;
use Path::Class;
use URI;

has agent      => (is => 'ro',
	default    => 'delphinus@remora.cx - dynUpdate.pl - 1.0');
has detect_uri => (is => 'ro', default    => 'http://checkip.dyndns.org/');

has scheme     => (is => 'ro', default    => 'https');
has host       => (is => 'ro', default    => 'members.dyndns.org');
has path       => (is => 'ro', default    => '/nic/update');
has method     => (is => 'ro', default    => 'GET');
has protocol   => (is => 'ro', default    => 'HTTP/1.0');
has uri        => (is => 'ro', lazy_build => 1);

has my_ip      => (is => 'rw', default    => '');

has username   => (is => 'ro', required   => 1);
has password   => (is => 'ro', required   => 1);
has hostname   => (is => 'ro', required   => 1);
has wildcard   => (is => 'ro', default    => 'NOCHG');
has mx         => (is => 'ro', default    => 'NOCHG');
has backmx     => (is => 'ro', default    => 'NOCHG');

sub run { my $self = shift;
	if ($self->detect) {
		$self->log('Changed', 'ip address need to be updated.');
		$self->update;
	} else {
		$self->log('Unchanged', 'ip address has not changed.');
	}
}

sub detect { my $self = shift;
	my $old = $self->my_ip;
	$self->my_ip($self->_get_my_ip);

	return $old ne $self->my_ip
}

sub update { my $self = shift;
	my $ua = $self->_get_ua();

	my $req = HTTP::Request->new;
	$req->method($self->method);
	$req->uri($self->uri);
	$req->protocol($self->protocol);
	$req->header(Host => $self->host);
	$req->header('User-Agent' => $ua->agent);
	$req->authorization_basic($self->username, $self->password);

	my $res = $ua->request($req);
	$res->is_success or $self->_die($res->status_line);

	my $content = $res->content;
	if ($content eq 'good') {
		$self->log('Success',
			"ip address has been updated successfully. => $content");
	} else {
		$self->log('Failed', "ip address update failed. => $content");
	}
}

sub _build_uri { my $self = shift;
	my $uri = URI->new;
	$uri->scheme($self->scheme);
	$uri->host($self->host);
	$uri->path($self->path);
	$uri->query_form(
		hostname => $self->hostname,
		myip     => $self->my_ip,
		wildcard => $self->wildcard,
		mx       => $self->mx,
		backmx   => $self->backmx,
	);

	return $uri;
}

sub _get_my_ip { my $self = shift;
	my $ua = $self->_get_ua();
	my $res = $ua->get($self->detect_uri);
	$res->is_success or $self->_die($res->status_line);

	my ($ip_address) = $res->content =~
		m!Current IP Address: (\d+\.\d+\.\d+\.\d+)!;
	defined $ip_address or $self->_die($res->estatus_line);

	return $ip_address;
}

sub _get_ua { my $self = shift;
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

