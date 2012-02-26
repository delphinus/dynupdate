use lib '/Users/delphinus/git/dynupdate/lib';
use DynUpdate::Mail;

my $mail = DynUpdate::Mail->new(
    hostname => 'testhost',
    new_ip => 'testnew_ip',
    to => 'delphinus35@me.com',
);
$mail->send;
