package OpenCloset::API::Web::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 index

    GET /

=cut

sub index {
    my $self = shift;

    $self->render( json => { hello => 'world' } );
}

1;
