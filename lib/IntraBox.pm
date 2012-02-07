package IntraBox;
use Dancer ':syntax';
use Digest::SHA1;
use strict;
use warnings;
use subroutine;
use subroutine3;
use Class::Date qw(:errors date localdate gmdate now -DateParse);

use lib '.';
use DB::intrabox;
use DBI;

use Data::FormValidator;

use DBIx::Class::FromValidators;
our $VERSION = '0.1';

# Connexion à la base de données
my $dsn = "dbi:mysql:intrabox";
my $schema = DB::intrabox->connect( $dsn, "root", "cabernet" )
  or die "problem";

#Récupération du nom
my $user = $ENV{'REMOTE_USER'};
$user = "abourgan";

#Vérification si il est admin
#Récupération du groupe dans lequel il est
#Récupération de la taille maximale de son espace personnel et fichier
my $id_user;
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

my $sess;
hook 'before' => sub {
	#get the remote user login - must be $ENV{'REMOTE_USER'}
	my $login = "jgirault";
	my $user;

	#if there is no session, log the user
	if (not session 'id_user') {
		#try to find user in DB, else create it
	    $user = $schema->resultset('User')->find_or_create(
	    	{
	      		login => $login,
	      		admin  => false,
	    	},
	    	{ key => 'login_UNIQUE' }
	  	);

	  	#store the session
	  	session id_user => $user->id_user;
	  	session	login => $user->login;
	  	session	isAdmin => $user->admin;
	}
	  	#calculate the space used by the user
		my $usedSpace = 0;
		my $deposits = $schema->resultset('Deposit')->search({ id_user =>  $user->id_user });
  		while (my $deposit = $deposits->next) {
  			my @files = $deposit->files;
  			for my $file (@files) {
    			if ($file->on_server) {
    				$usedSpace += $file->size;
    			}
  			}
  		}
	  	session usedSpace => $usedSpace;
	  	$sess = session;
  	return 0;
};

#--------- ROUTEES -------
get '/' => sub {
	my $info_color = "info-vert";
	my $message    =
"Vous pouvez uploader vos fichiers en renseignant tous les champs nécessaires";
	template 'index',
	  {
	  	sess				  => $sess,
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
	template 'admin/download', { sess => $sess };
};

get '/admin/admin' => sub {
	my @admins = $schema->resultset('User')->search( { admin => true } )->all;
	template 'admin/admin', { sess => $sess, admins => \@admins };
};

post '/admin/admin/new' => sub {

	# validation des paramètres
	my $params = request->params;
	my $msgs;

	# recherche de l'admin à ajouter
	my $admin =
	  $schema->resultset('User')->search( { login => param('login') } )
	  ->first();
	if ( not defined $admin ) {
		my $login = param('login');
		$msgs =
		  { alert =>
"Il n'y a pas d'utilisateur correspondant au login <strong>$login</strong>"
		  };
	}
	else {
		my $login = $admin->login;
		$msgs =
		  { info =>
			  "Vous venez d'ajouter l'administrateur <strong>$login</strong>" };
		$admin->update( { admin => true } );
	}

	my @admins = $schema->resultset('User')->search( { admin => true } )->all;
	template 'admin/admin',
	  {
		sess => $sess,
		msgs    => $msgs,
		admins  => \@admins
	  };
};

get qr{/admin/admin/delete/(?<id>\d+)} => sub {

	my $msgs;
	my $id = captures->{'id'};    # le paramètre id est dans l'URL
	delete params->{captures};

	# recherche de l'admin à supprimer
	my $admin = $schema->resultset('User')->find($id);
	if ( not defined $admin ) {
		$msgs =
		  { alert =>
			  "Il n'y a pas d'utilisateur à l'ID <strong>$id</strong>" };
	}
	else {
		my $login = $admin->login;
		$msgs =
		  { warning =>
			  "Vous venez de retirer l'administrateur <strong>$login</strong>"
		  };
		$admin->update( { admin => false } );
	}

	my @admins = $schema->resultset('User')->search( { admin => true } )->all;
	template 'admin/admin',
	  {
		sess => $sess,
		msgs    => $msgs,
		admins  => \@admins
	  };
};

post '/upload' => sub {
	upload_file();
};

get '/download/:file_name' => sub {
	my $param_file = param("file_name");
	download_file($param_file);
};

post '/downloadFile' => sub {

	my $name_on_disk = param("name_on_disk");
	my $name = param("name");
	donwload_file_user($name_on_disk,$name);
	
};

get '/test' => sub {
	template 'test', {};
};

#--------- /ROUTEES -------

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
		my $id_deposit;

		my $controle_valid = 1;

		my $expiration_days;
		my $downloads_report;
		my $acknowlegdement;
		my $password_protection;
		my $password;
		my $comment_option;
		my $comment;
		my $current_date;
		my $expiration_date;
		my $expiration_days_date;
		my $id_status;

		#------- Phase de récupération de tous les paramètres -------
		$expiration_days  = param("expiration_days");
		$downloads_report = param("downloads_report");
		if ( $downloads_report eq "on" ) { $downloads_report = true }
		else { $downloads_report = false }
		$acknowlegdement = param("acknowlegdement");
		if ( $acknowlegdement eq "on" ) { $acknowlegdement = true }
		else { $acknowlegdement = false }
		$password_protection = param("password_protection");
		if ( $password_protection eq "on" ) { $password_protection = true }
		else { $password_protection = false }
		if ($password_protection) { $password = param("password"); }
		$comment_option = param("comment_option");
		if ( $comment_option eq "on" ) { $comment_option = true }
		else { $comment_option = false }
		if ($comment_option) { $comment = param("comment"); }
		$current_date         = Class::Date->new;
		$current_date         = now;
		$expiration_date      = Class::Date->new;
		$expiration_days_date =
		  Class::Date->new( [ 0000, 00, "$expiration_days", 00, 00, 00 ] );
		$expiration_date = $current_date + $expiration_days_date;

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

				$hash_names[$i] = generate_aleatoire_key(15);

				#Vérification de l'unicité de la clé du fichier
				my @liste_file =
				  $schema->resultset('File')
				  ->search( { name_on_disk => "$hash_names[$i]", } );
				while (@liste_file) {
					$hash_names[$i] = generate_aleatoire_key(15);
					@liste_file =
					  $schema->resultset('File')
					  ->search( { name_on_disk => "$hash_names[$i]", } );
				}

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

				#Création d'une clé de dépôt
				my $deposit_key = generate_aleatoire_key(19);

				#Vérification de l'unicité de la clé
				my @liste_deposit =
				  $schema->resultset('Deposit')
				  ->search( { download_code => "$deposit_key", } );
				while (@liste_deposit) {
					$deposit_key   = generate_aleatoire_key(19);
					@liste_deposit =
					  $schema->resultset('Deposit')
					  ->search( { download_code => "$deposit_key", } );
				}

				#Ecriture dans la base de données
				my @liste_user =
				  $schema->resultset('User')->search( { login => "$user", } );
				for my $user_liste (@liste_user) {
					$id_user = $user_liste->id_user;
				}

				my @liste_status =
				  $schema->resultset('Status')
				  ->search( { name => "disponible", } );
				for my $status_liste (@liste_status) {
					$id_status = $status_liste->id_status;
				}

				my $new_deposit = $schema->resultset('Deposit')->create(
					{
						id_user              => $id_user,
						download_code        => $deposit_key,
						id_status            => $id_status,
						expiration_date      => $expiration_date,
						expiration_days      => $expiration_days,
						opt_acknowledgement  => $acknowlegdement,
						opt_downloads_report => $downloads_report,
						created_date         => $current_date,
						created_ip           => "192.45.12.12",
						created_useragent    => "Mozilla",
						opt_comment          => $comment,
						opt_password         => $password,
					}
				);

				#Recherche de l'id_deposit
				my @liste_deposit2 =
				  $schema->resultset('Deposit')
				  ->search( { download_code => "$deposit_key", } );
				for my $deposit_liste (@liste_deposit2) {
					$id_deposit = $deposit_liste->id_deposit;
				}

				#Ecriture dans la base de données des fichiers
				my $k;
				for ( $k = 1 ; $k <= $number_files ; $k++ ) {
					my $new_file = $schema->resultset('File')->create(
						{
							id_deposit   => $id_deposit,
							name         => $name_files[$k],
							size         => $size_files[$k],
							name_on_disk => $hash_names[$k],
							on_server    => "1",
						}
					);
				}

			}
		}
	}

	template 'index', {
		message    => $message,
		info_color => $info_color,

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

#--- /Infos User ---
true;
