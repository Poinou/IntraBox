package subroutine;

use Dancer ':syntax';
use warnings;
#use strict;
use Exporter;
use base 'Exporter';

our $user_size_file_limit  = 100 * 1024 * 1024;
#----------Sub Routines --------



#--- UPLOAD ----
sub upload_file {

	my $message;
	my $info_color;

	my $number_files = count_files();

	if ( $number_files == 0 ) {
		$info_color = "info-rouge";
		$message    = "Aucun fichier renseigné. Veuillez indiquer un fichier";
	}
	else {

		#------- Initialisation variables ---------
		my $i;
		my @upload_files;
		my @size_files;
		my @name_files;
		my @hash_names;
		my $total_size;

		my $controle_valid = 1;

		#------- Phase d'upload de tous les fichiers -------
		for ( $i = 1 ; $i <= $number_files ; $i++ ) {

			$upload_files[$i] = upload("file$i");

			#Verification validité de chaque fichier
			if ( not defined $upload_files[$i] ) {

				#Si un fichier invalide, sorti de boucle et
				#passage du paramètre de contrôle à 0
				$info_color = "info-rouge";
				my $temp_name_fic_prob = param("file$i");
				$message = "Le fichier $temp_name_fic_prob n'est 
								pas valide ou n'existe pas";
				$controle_valid = 0;
				last;
			}
			else {

				$size_files[$i] = $upload_files[$i]->size;
				$name_files[$i] = $upload_files[$i]->basename;

				#				my $sha1 = Digest::SHA1->new;
				#				$sha1->add("$name_files[$i]");
				#				$hash_names[$i] = $sha1->hexdigest;
				my $key = generate_aleatoire_key(15);
				$hash_names[$i] = $key;

				$total_size = $total_size + $size_files[$i];
				#print $user_size_file_limit;
				if ( $size_files[$i] >= $user_size_file_limit ) {
					$info_color = "info-rouge";
					my $temp_name_fic_prob = param("file$i");
					$message = "Le fichier $temp_name_fic_prob 
									est trop volumineux";
					$controle_valid = 0;
					last;
				}
			}
		}

		#------- Phase de contrôle -------
		if ( $controle_valid == 1 ) {
			if ( $total_size > 100 * 1024 * 1024 ) {
				$info_color = "info-rouge";
				$message    = "Les fichiers sont trop volumineux";

				#Contrôle compte perso
			}
			else {

				#Vérification présence base données
				#--
				#Insertion dans base de données
				#--

				for ( $i = 1 ; $i <= $number_files ; $i++ ) {
					$upload_files[$i]->copy_to(
"/Program Files (x86)/Apache Software Foundation/Apache2.2/cgi-bin/IntraBox/public/Upload/$hash_names[$i]"
					);
				}
				my $j;
				my $temp_message = "$name_files[1] ($size_files[1])";
				for ( $j = 2 ; $j <= $number_files ; $j++ ) {
					$temp_message =
					  "$temp_message, $name_files[$j] ($size_files[$j])";
				}
				$info_color = "info-vert";

				$message = "Upload terminé des fichiers : $temp_message";

			}
		}
	}

	template 'index',
	  {
		message    => $message,
		info_color => $info_color
	  };
}

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

		send_file(
			"/Upload/$file_name_disk",
			filename => "$file_name"
		);
	}
}





our @EXPORT = qw(download_file upload_file);
#our @EXPORT = qw(recuperation_donnees_session_user calcul_used_space download_file randomposition generate_aleatoire_key count_files upload_file);
1;