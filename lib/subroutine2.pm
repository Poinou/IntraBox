use Dancer ':syntax';
use warnings;

use lib '.';
use DB::intrabox;
use DBI;

#use strict;
use Exporter;
use base 'Exporter';

# Connexion à la base de données
my $dsn = "dbi:mysql:intrabox";
my $schema = DB::intrabox->connect( $dsn, "", "" )
  or die "problem";

my $downloads_report;
my $acknowlegdement;
my $password;
my $comment;
my $created_date;
my $expiration_date;
my $id_deposit;

my $deposit_liste;
my $files_liste;

my $id_status;
my $status;
my $id_status2;
my $download_code;

sub gestion_all_fichiers {

	my $login_user = "abourgan";
	my $id_user;

	my @liste_user =
	  $schema->resultset('User')->search( { login => "$login_user", } );

	for my $user_liste (@liste_user) {
		$id_user = $user_liste->id_user;
	}

	my @liste_deposit = $schema->resultset('Deposit')->search(
		{
			-and => [
				id_user   => "$id_user",
				id_status => "1",
			],
		}
	);

	for my $deposit_liste (@liste_deposit) {
		$id_deposit = $deposit_liste->id_deposit;

	}

	template 'gestionFichiers',
	  {
		liste_deposit => \@liste_deposit,
	  };

}

sub afficher_depot {
	my $deposit = $_[0];

	my @liste_deposit =
	  $schema->resultset('Deposit')
	  ->search( { download_code => $deposit, } );

#	for my $deposit_liste (@liste_deposit) {
#		$id_deposit = $deposit_liste->id_deposit;
#		$id_status  = $deposit_liste->id_status;
#
#		$id_status2 = $id_status->id_status;
#		$status     = $id_status->name;
#
#		$expiration_date  = $deposit_liste->expiration_date;
#		$acknowlegdement  = $deposit_liste->opt_acknowledgement;
#		$downloads_report = $deposit_liste->opt_downloads_report;
#		$created_date     = $deposit_liste->created_date;
#		$comment          = $deposit_liste->opt_comment;
#		$password         = $deposit_liste->opt_password;
#	}

	template 'voirDepot',
	  {
		liste_deposit => \@liste_deposit,
	  };

}

our @EXPORT = qw(gestion_all_fichiers gestion_fichier);
1;
