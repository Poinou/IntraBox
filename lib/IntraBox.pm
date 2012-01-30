package IntraBox;
use Dancer ':syntax';
use Digest::SHA1;
use strict;
use warnings;
use subroutine;
use subroutine3;

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
	template 'admin', { isAdmin => $isAdmin };
};

post '/upload' => sub {
	upload_file();
};

get '/download' => sub {
	my $param_file = "iF87pzYbxcmSsr";
	download_file($param_file);
};

get '/downloadFile' => sub {
	my $param_file = "iF87pzYbxcmSsr";
	sendFile($param_file);
};

get '/test' => sub {
	template 'test', {};
};

#--------- /ROUTEES -------


#--- /Infos User ---
true;
