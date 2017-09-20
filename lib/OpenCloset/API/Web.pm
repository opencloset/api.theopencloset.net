package OpenCloset::API::Web;
use Mojo::Base 'Mojolicious';

use Email::Valid ();
use Postcodify;

use OpenCloset::Schema;
use OpenCloset::DB::Plugin::Order::Sale;
use OpenCloset::API::Order;

use version; our $VERSION = qv("v0.0.1");

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

has postcodify => sub { Postcodify->new };

has api => sub {
    my $self = shift;
    return OpenCloset::API::Order->new( schema => $self->schema );
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
    $self->_extend_validator;
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
    $auth->post('/reservation')->to('reservation#create');
}

sub _extend_validator {
    my $self = shift;

    $self->validator->add_check(
        email => sub {
            my ( $v, $name, $value ) = @_;
            return not Email::Valid->address($value);
        }
    );
}

1;
