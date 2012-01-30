package IntraBox;
use Dancer ':syntax';
use Digest::SHA1;
use strict;
use warnings;

use lib '.';
use Data::FormValidator;
use DB::intrabox;
use DBIx::Class::FromValidators;
our $VERSION = '0.1';

#Récupération du nom
my $user = $ENV{'REMOTE_USER'};

#Vérification si il est admin
#Récupération du groupe dans lequel il est
#Récupération de la taille maximale de son espace personnel et fichier
my $isAdmin;
my $user_group;
my $user_size_file_limit;
my $user_size_space_limit;
( $isAdmin, $user_group, $user_size_file_limit, $user_size_space_limit ) =
  recuperation_donnees_session_user($user);

#Récupération de la taille actuelle utilisée de son espace personnel
my $user_space_used;
$user_space_used = calcul_used_space($user);

#Calcul de l'espace libre de user
my $user_space_free = $user_size_space_limit - $user_space_used;


# Connexion à la base de données
my $dsn           = "dbi:mysql:intrabox";
my $schema = DB::intrabox->connect( $dsn, "root", "") or die "problem";


#--------- ROUTEES -------
get '/' => sub {
	my $info_color = "info-vert";
	my $message    =
"Vous pouvez uploader vos fichiers en renseignant tous les champs nécessaires";
	template 'index',
	  {
		info_color            => $info_color,
		message               => $message,
		user_space_used       => ( $user_space_used / ( 1024 * 1024 ) ),
		user_size_space_limit => ( $user_size_space_limit / ( 1024 * 1024 ) )
	  };
};

get '/admin' => sub {
	redirect 'admin/download';
};
get '/admin/download' => sub {
	template 'admin/download', { isAdmin => $isAdmin };
};

get '/admin/admin' => sub {
	my @admins = $schema->resultset('User')->search({admin => true})->all;
	template 'admin/admin', { isAdmin => $isAdmin, admins => \@admins };
};

post '/admin/admin/new' => sub {

  # validation des paramètres
  my $params = request->params;
  my $msgs;
  # recherche de l'admin à ajouter
	my $admin = $schema->resultset('User')->search({login => param('login') })->first();
	if (not defined $admin) {
	    my $login = param('login');
	    $msgs = {
			alert => "Il n'y a pas d'utilisateur correspondant au login <strong>$login</strong>"
		};
	}
	else {
	    my $login = $admin->login;
	    $msgs = {
			info => "Vous venez d'ajouter l'administrateur <strong>$login</strong>"
		};
		$admin->update({ admin => true });
	}
	
	my @admins = $schema->resultset('User')->search({admin => true})->all;
	template 'admin/admin', 
		{ isAdmin => $isAdmin, 
			msgs => $msgs,
			admins => \@admins 
		};
};

get qr{/admin/admin/delete/(?<id>\d+)} => sub {
	
  	my $msgs;
	my $id = captures->{'id'}; # le paramètre id est dans l'URL
	delete params->{captures};
	
	# recherche de l'admin à supprimer
	my $admin = $schema->resultset('User')->find($id);
	if (not defined $admin) {
	    $msgs = {
			alert => "Il n'y a pas d'utilisateur à l'ID <strong>$id</strong>"
		};
	}
	else {
	    my $login = $admin->login;
	    $msgs = {
			warning => "Vous venez de retirer l'administrateur <strong>$login</strong>"
		};
		$admin->update({ admin => false });
	}
	
	my @admins = $schema->resultset('User')->search({admin => true})->all;
	template 'admin/admin', 
		{ isAdmin => $isAdmin, 
			msgs => $msgs,
			admins => \@admins 
		};
};

post '/upload' => sub {
	upload_file();
};

get '/download/:file' => sub {
	my $param_file = "params->{file}";
	download_file($param_file);
};

get '/test' => sub {
	template 'test', {};
};

#--------- /ROUTEES -------

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

sub count_files {
	my $cpt = 1;

	#Première itération
	my $temp_fic = param("file$cpt");
	if ( not defined $temp_fic ) {
		return 0;
	}
	else {

		#Tant qu'il existe un paramètre on continue la boucle
		while ( defined $temp_fic ) {
			$cpt++;
			$temp_fic = param("file$cpt");
		}
		my $number_files = $cpt - 1;
		return $number_files;
	}
}

sub randomposition {
	my $chaine = $_[0];
	return int rand length $chaine;
}

sub generate_aleatoire_key {
	my $lenght = $_[0];
	my $key;
	my $i;
	my $list_char =
	  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
	for ( $i = 1 ; $i < $lenght ; ++$i ) {
		my $temp_key = substr( $list_char, randomposition($list_char), 1 );
		$key = "$key$temp_key";
	}
	return $key;
}

#sub verif_taille {
#	my $chemin_fic = param('file1');
#	my $size_file = -s "/$chemin_fic";
#	return $size_file;
#}

#--- /UPLOAD ----

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

#--- /DOWNLOAD ----

#--- Infos User ---

sub recuperation_donnees_session_user {
	my $user = $_[0];
	my $isAdmin;
	$user = "abourgan";
	if ( $user eq "abourgan" ) {
		$isAdmin = true;

	}
	else { $isAdmin = false; }

	my $user_group            = "eleves";
	my $user_size_file_limit  = 100 * 1024 * 1024;
	my $user_size_space_limit = 400 * 1024 * 1024;
	return ( $isAdmin, $user_group, $user_size_file_limit,
		$user_size_space_limit );
}

sub calcul_used_space {
	my $user            = $_[0];
	my $user_space_used = 10 * 1024 * 1024;
	return $user_space_used;
}

#--- /Infos User ---
true;
