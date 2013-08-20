package DynUpdate::Mail;
use Moose;

use Email::MIME;
use Email::MIME::Creator::ISO_2022_JP;
use Email::Sender::Simple qw!sendmail!;
use Email::Sender::Transport::SMTP::TLS;
use Try::Tiny;

has username => (is => 'ro', isa => 'Str');
has password => (is => 'ro', isa => 'Str');
has server   => (is => 'ro', isa => 'Str', required => 1);
has port     => (is => 'ro', isa => 'Int', default => 587);
has from     => (is => 'ro', isa => 'Str', required => 1);
has to       => (is => 'ro', isa => 'Str', required => 1);
has subject  => (is => 'ro', isa => 'Str', required => 1);
has data     => (is => 'ro', isa => 'Str', required => 1);

has dyn => (is => 'ro');

sub send { my $self = shift;
    my $email = Email::MIME->create(
        header_str => [
            From => $self->from,
            To => $self->to,
            Subject => $self->subject,
        ],
        body_str => $self->data,
    );

    my $transport = Email::Sender::Transport::SMTP::TLS->new(
        host => $self->server,
        port => $self->port,
        username => $self->username,
        password => $self->password,
    );

    try {
        sendmail(
            $email,
            +{transport => $transport},
        );
    } catch {
        die "send failed: $_";
    };
}

__PACKAGE__->meta->make_immutable;
