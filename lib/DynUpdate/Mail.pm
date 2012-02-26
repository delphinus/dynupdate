package DynUpdate::Mail;
use Moose;

use utf8;
use Encode;
use MIME::Entity;
use Net::SMTP::SSL;

has hostname => (is => 'ro', isa => 'Str', required => 1);
has new_ip => (is => 'ro', isa => 'Str', required => 1);

has username => (is => 'ro', isa => 'Str', default => 'delphinus@remora.cx');
has password => (is => 'ro', isa => 'Str', default => '');
has server => (is => 'ro', isa => 'Str', default => 'smtp.gmail.com');
has port => (is => 'ro', isa => 'Int', default => 465);
has from => (is => 'ro', isa => 'Str', default => 'delphinus@remora.cx');
has to => (is => 'ro', isa => 'Str', default => 'delphinus@remora.cx');
has subject => (is => 'ro', isa => 'Str', lazy_build => 1);
sub _build_subject { my $self = shift;
    return sprintf '[%s] IP アドレスが変更されました', $self->hostname;
}
has type => (is => 'ro', isa => 'Str', default => 'text/plain; charset=utf-8');
has encoding => (is => 'ro', isa => 'Str', default => 'base64');
has data => (is => 'ro', isa => 'Str', lazy_build => 1);
sub _build_data { my $self = shift;
    return sprintf <<EOM, $self->hostname, $self->new_ip;
IP アドレスが次のように変更されました。

ホスト名 : %s
IP アドレス : %s
EOM
}

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

    my $s = Net::SMTP::SSL->new($self->server, Port => $self->port);
    $s->auth($self->username, $self->password);
    $s->mail($mail{From});
    $s->to($mail{To});
    $s->data;
    $s->datasend($mime->stringify);
    $s->datasend;
    $s->quit;
}

__PACKAGE__->meta->make_immutable;
