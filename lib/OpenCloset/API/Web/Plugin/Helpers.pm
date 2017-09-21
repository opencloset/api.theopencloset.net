package OpenCloset::API::Web::Plugin::Helpers;

use Mojo::Base 'Mojolicious::Plugin';

=encoding utf8

=head1 NAME

OpenCloset::API::Web::Plugin::Helpers - opencloset api web mojo helper

=head1 SYNOPSIS

    # Mojolicious::Lite
    plugin 'OpenCloset::API::Web::Plugin::Helpers';

    # Mojolicious
    $self->plugin('OpenCloset::API::Web::Plugin::Helpers');

=cut

sub register {
    my ( $self, $app, $conf ) = @_;

    $app->helper( log => sub { shift->app->log } );
    $app->helper( error => \&error );
}

=head1 HELPERS

=head2 log

shortcut for C<$self-E<gt>app-E<gt>log>

    $self->app->log->debug('message');    # OK
    $self->log->debug('message');         # OK, shortcut

=head2 error( $status, $error )

    my $required = $self->param('something');
    return $self->error(400, 'Failed to validate') unless $required;

=cut

sub error {
    my ( $self, $status, $error ) = @_;

    $self->log->error($error);
    $self->render(
        status => $status,
        json   => { error => $error || q{} },
    );

    return;
}

1;
