package DB::IntraBox::Result::Admin;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("FromValidators", "InflateColumn::DateTime", "Core");

=head1 NAME

DB::IntraBox::Result::Admin

=cut

__PACKAGE__->table("admins");

=head1 ACCESSORS

=head2 id_admin

  data_type: 'integer'
  is_nullable: 0

=head2 id_user

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=cut

__PACKAGE__->add_columns(
  "id_admin",
  { data_type => "integer", is_nullable => 0 },
  "id_user",
  { data_type => "varchar", is_nullable => 0, size => 45 },
);
__PACKAGE__->set_primary_key("id_admin");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-24 11:41:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yb9iTXbJoQSUaDMz/wgGaw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
