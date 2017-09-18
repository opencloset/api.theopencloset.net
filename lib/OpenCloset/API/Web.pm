package OpenCloset::API::Web;
use Mojo::Base 'Mojolicious';

use version; our $VERSION = qv("v0.0.1");

use OpenCloset::Schema;

has schema => sub {
    my $self = shift;
    my $conf = $self->config->{database};
    OpenCloset::Schema->connect(
        {
            dsn => $conf->{dsn}, user => $conf->{user}, password => $conf->{pass},
            %{ $conf->{opts} },
        }
    );
};

=head1 METHODS

=head2 startup

This method will run once at server start

=cut

sub startup {
    my $self = shift;

    $self->plugin('Config');
    $self->plugin('OpenCloset::API::Web::Plugin::Helpers');

    $self->_public_routes;
    $self->_private_routes;
}

sub _public_routes {
    my $self = shift;
    my $r    = $self->routes;
}

sub _private_routes {
    my $self = shift;
    my $r    = $self->routes;

    my $auth = $r->under('/')->to('user#auth')->name('auth');
    $auth->get('/')->to('root#index');
}

1;
