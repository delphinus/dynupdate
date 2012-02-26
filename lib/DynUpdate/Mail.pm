package DynUpdate::Mail;
use Moose;

use Encode;
use MIME::Entity;
#use Net::SMTP::SSL;
use Net::SMTP;

has username => (is => 'ro', isa => 'Str', required => 1);
has password => (is => 'ro', isa => 'Str', required => 1);
has server   => (is => 'ro', isa => 'Str', required => 1);
has port     => (is => 'ro', isa => 'Int', required => 1);
has from     => (is => 'ro', isa => 'Str', required => 1);
has to       => (is => 'ro', isa => 'Str', required => 1);
has subject  => (is => 'ro', isa => 'Str', required => 1);
has data     => (is => 'ro', isa => 'Str', required => 1);

has type     => (is => 'ro', isa => 'Str',
    default  => 'text/plain; charset=utf-8');
has encoding => (is => 'ro', isa => 'Str',
    default  => 'base64');

sub send { my $self = shift;
    my %mail = (
        From => $self->from,
        To => $self->to,
        Subject => $self->subject,
    );
    $_ = encode('MIME-Header-ISO_2022_JP' => $_) for values %mail;

    $mail{Type} = $self->type;
    $mail{Encoding} = $self->encoding;
    $mail{Data} = $self->data;
    my $mime = MIME::Entity->build(%mail);
    print $mime->stringify;

    #my $s = Net::SMTP::SSL->new($self->server, Port => $self->port, Debug => 1);
    my $s = Net::SMTP->new($self->server, Port => $self->port, Debug => 1);
    #$s->auth($self->username, $self->password);
    $s->mail($mail{From});
    $s->to($mail{To});
    $s->data;
    $s->datasend($mime->stringify);
    $s->dataend;
    $s->quit;
}

__PACKAGE__->meta->make_immutable;
