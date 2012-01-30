package subroutine;

use Dancer ':syntax';
use warnings;
#use strict;
use Exporter;
use base 'Exporter';

our $user_size_file_limit  = 100 * 1024 * 1024;
#----------Sub Routines --------





#--- DOWNLOAD ----

sub download_file {
	my $file_name_disk = $_[0];
	my $file_exist     = true;
	my $file_available = true;

	my $file_author;
	$file_author = "abourgan";
	my $file_size;
	my $file_name;

	my $message;

	#- Initialisations des messages d'erreurs -
	my $message_inexistant =
"Le fichier que vous avez demandé n\'existe pas. Vérifier que l'URL que vous avez indiqué est bonne";

	my $message_indispo =
	  "Le fichier que vous avez demandé n'est plus disponible.
 Après un temps déterminé, le fichier est automatiquement supoprimé de nos serveurs.
 Vous pouvez contacter l'utilisateur $file_author afin qu'il redépose le fichier";

	#Vérification de la présence dans la base de données
	#Vérification de la présence dans les fichiers encore existants

	#Envoi d'un message d'erreur si fichier inexistant
	if ( !$file_exist ) {
		$message = $message_inexistant;
		template 'download', { message => $message };

	}

	#Envoi d'un message d'erreur si fichier non disponible
	elsif ( !$file_available ) {
		$message = $message_indispo;
		template 'download', { message => $message };
	}
	else {

#On récupère toutes les informations du fichiers présent dans la base de données

		$file_size   = "1001000";
		$file_name   = "Le language des fleurs.pdf";
		$file_author = "abourgan";

		my $file_URL =
"<a href=\"/cgi-bin/IntraBox/public/Upload/$file_name_disk\">Lien du fichier</a>";
		$message =
"Le téléchargement du fichier $file_name déposé par $file_author est sur le point de commencer. Si rien ne se passe, vous pouvez cliquer sur le lien suivant : $file_URL";

		template 'download', { message => $message };


	}
}

sub donwload_file_user {
	my $file_name_disk = $_[0];
	my $file_name = "truck.png";
		send_file(
			"/Upload/$file_name_disk",
			filename => "$file_name"
		);
}


our @EXPORT = qw(download_file donwload_file_user);
#our @EXPORT = qw(recuperation_donnees_session_user calcul_used_space download_file randomposition generate_aleatoire_key count_files upload_file);
1;