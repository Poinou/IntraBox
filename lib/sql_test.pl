package intrabox99;

use strict;
use lib '.';
use DB::intrabox;

# Connexion à la base de données
my $dsn           = "dbi:mysql:intrabox";
my $user_database = "root";
my $password      = "tnwadt22";
my $schema = DB::intrabox->connect( $dsn, $user_database, $password) or die "problem";


my @admins = $schema->resultset('Admin')->search({})->all;
for my $admin (@admins) {
		my $id_admin = $admin->id_admin;
		my $id_user    = $admin->id_user;
		print "$id_admin, $id_user\n";
	}

