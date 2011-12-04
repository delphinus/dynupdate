package DynUpdate::Daemon;
use Moose;
use MooseX::Types::Path::Class qw!File!;

extends 'DynUpdate';
with 'MooseX::Daemonize';

use File::Basename;
use FindBin qw!$Bin!;
use HTTP::Date qw!time2iso!;

has [qw!
	+ignore_zombies   +no_double_fork   +progname               +basedir
	+stop_timeout     +pidfile          +dont_close_all_files   +agent
	+detect_uri       +scheme           +host                   +path
	+method           +protocol         +uri                    +my_ip
	+wildcard         +mx               +backmx
!] => (metaclass => 'NoGetopt');

has log_file   => (is => 'ro', isa => File, coerce => File, default    =>
	"$Bin/logs/" . basename($0, '.pl') . '.log');

has interval   => (is => 'ro', default    => 60);

sub BUILD { my $self = shift;
	-d $self->pidbase or $self->pidbase->mkpath;
}

sub _build_log_fh { my $self = shift;
	-d $self->log_file->parent or $self->log_file->parent->mkpath;
	open my $fh, '>>', $self->log_file or die;
	$fh;
}

after start => sub { my $self = shift;
	$self->is_daemon or return;
	$self->run;
};

override run => sub { my $self = shift;
	while (1) {
		super;
		sleep $self->interval;
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
