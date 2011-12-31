package DynUpdate::Daemon;
use Moose;
use MooseX::Types::IPv4 qw!ip4!;
use MooseX::Types::Path::Class qw!File!;

extends 'DynUpdate';
with 'MooseX::Daemonize';

use File::Basename;
use FindBin qw!$Bin!;
use HTTP::Date qw!time2iso!;

has [qw!
	+ignore_zombies   +no_double_fork   +progname               +basedir
	+stop_timeout     +pidfile          +dont_close_all_files   +agent
	+scheme           +host             +path                   +method
	+protocol         +uri
!] => (metaclass => 'NoGetopt');

has log_file   => (is => 'ro', isa => File, coerce => File, default    => sub {
		my $name = fileparse($0, qr!\.[^.]*!);

		return "$Bin/logs/$name.log";
	});

has my_ip      => (is => 'rw', isa => ip4, default    => '0.0.0.0');

has interval => (is => 'ro', isa => 'Int', default => 900);

sub BUILD { my $self = shift;
	-d $self->pidbase or $self->pidbase->mkpath;
}

after start => sub { my $self = shift;
	$self->is_daemon or return;

	$self->log('Info', 'START!');
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
		$self->log('Unchanged', 'ip address has not changed.');
		return 1;

	} else {
		$self->log('Changed', 'ip address need to be updated.');
		$self->my_ip($new);
		return super;
	}
};

override log => sub { my $self = shift;
	my $fh = $self->get_log_fh;
	$fh->print(sprintf "%s [%s] %s\n", time2iso(time), @_);
	$fh->close;
};

sub get_log_fh { my $self = shift;
	-d $self->log_file->parent or $self->log_file->parent->mkpath;
	open my $fh, '>>', $self->log_file or die;
	$fh;
}

__PACKAGE__->meta->make_immutable;

