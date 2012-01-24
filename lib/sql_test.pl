package IntraBox99;
use Dancer ':syntax';
use base 'CGI::Application';

# ----- le module GestCli.pm definit les ResultSources correspondant aux tables
use intrabox;
my $schema = intrabox->connect( 'dbi:mysql:intrabox', 'lfoucher', 'tnwadt22' );

my $cgiapp     = shift;
my $admin = $cgiapp->query->param('id_admin', 'id_user');
my $client     = $schema->resultset('admins')->find($admin);
