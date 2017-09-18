package OpenCloset::API::Web::Controller::User;
use Mojo::Base 'Mojolicious::Controller';

use Digest::SHA1 qw/sha1_hex/;
use MIME::Base64 qw/decode_base64/;

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 auth

    under /

=cut

sub auth {
    my $self = shift;

    my $authorization = $self->req->headers->authorization;
    unless ($authorization) {
        $self->error( 401, "Authorization header required" );
        return;
    }

    $authorization = decode_base64($authorization);
    my ( $email, $password ) = split /:/, $authorization;

    my $user = $self->schema->resultset('User')->find( { email => $email } );
    unless ($user) {
        $self->error( 404, "User not found: $email" );
        return;
    }

    unless ( $user->check_password($password) ) {
        $self->error( 401, "Authorization failed: wrong password" );
        return;
    }

    return 1;
}

1;
