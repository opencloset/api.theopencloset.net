package OpenCloset::API::Web::Controller::Reservation;
use Mojo::Base 'Mojolicious::Controller';

use OpenCloset::Constants::Category ();

has schema => sub { shift->app->schema };

=encoding utf8

=head1 METHODS

=head2 index

    POST /reservation

=over

=item *

datetime - YYYY-MM-DDThh:mm:ss formatted string.

=item *

name - 예약자 이름

=item *

email

=item *

phone - 01012345678

=item *

gender - male or female

=item *

birth-year - 태어난 해

=item *

purpose - 대여목적

=item *

category - 자켓,팬츠,셔츠

아래의 각 품목을 C<,> 로 구분해서 연결된 문자열

=over

=item *

자켓

=item *

팬츠

=item *

스커트

=item *

셔츠

=item *

블라우스

=item *

구두

=item *

타이

=item *

벨트

=back

=item *

color - dark,brown

아래의 각 선호색상을 C<,> 로 구분해서 연결된 문자열

=over

=item *

staff - 직원추천

=item *

dark - 어두운색

=item *

black - 검정

=item *

navy - 감색

=item *

charcoalgray - 챠콜그레이

=item *

gray - 회색

=item *

brown - 갈색

=item *

etc - 기타

=back

=item *

address - 집 주소

=item *

address-detail - 집 주소상세

=item *

wearon-date - 의류 착용일 C<YYYY-MM-DD> formatted string.

=item *

purpose-detail - 대여목적 상세

=back

=cut

sub create {
    my $self = shift;
    my $v    = $self->validation;

    $v->required('datetime')->like(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/);
    $v->required('name');
    $v->required('email')->email;
    $v->required('phone')->like(qr/^01\d{8,9}$/);
    $v->required('gender')->in( 'male', 'female' );
    $v->required('birth-year')->like(qr/^\d{4}$/);
    $v->required('purpose');
    $v->required('category');
    $v->required('address');
    $v->required('address-detail');

    $v->optional('wearon-date')->like(qr/^\d{4}-\d{2}-\d{2}$/);
    $v->optional('purpose-detail');
    $v->optional('color');

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $datetime       = $v->param('datetime');
    my $name           = $v->param('name');
    my $email          = $v->param('email');
    my $phone          = $v->param('phone');
    my $gender         = $v->param('gender');
    my $birth_year     = $v->param('birth-year');
    my $purpose        = $v->param('purpose');
    my $category       = $v->param('category');
    my $color          = $v->param('color') || '';
    my $address        = $v->param('address');
    my $address_detail = $v->param('address-detail');
    my $wearon_date    = $v->param('wearon-date');
    my $purpose_detail = $v->param('purpose-detail');

    my $postcodify = $self->app->postcodify;
    my $result     = $postcodify->search($address);
    return $self->error( 400, "Wrong address: $address" ) unless @{ $result->data };

    my $address_dbid = $result->data->[0]{road_id};   # address1
    my $address_base = $result->data->[0]{ko_common};
    my $address_new  = $result->data->[0]{ko_doro};   # address2
    my $address_old  = $result->data->[0]{ko_jibeon}; # address3

    $category = $self->_categories($category);
    $color    = $self->_colors($color);

    my $user = $self->schema->resultset('User')->find_or_create(
        {
            name  => $name,
            email => $email,
        }
    );

    return $self->error( 500, "Failed to create a new user" ) unless $user;

    my $user_info        = $user->user_info;
    my %user_info_params = (
        phone        => $phone,
        gender       => $gender,
        birth        => $birth_year,
        wearon_date  => $wearon_date,
        purpose      => $purpose,
        purpose2     => $purpose_detail,
        pre_category => $category,
        pre_color    => $color,

        address1 => $address_dbid,
        address2 => "$address_base $address_new",
        address3 => "$address_base $address_old",
        address4 => $address_detail
    );

    if ($user_info) {
        $user_info->update( \%user_info_params )->discard_changes;
    }
    else {
        $user_info = $user->create_related( 'user_info', \%user_info_params );
    }

    my $order = $self->app->api->reservated( $user, $datetime );
    return $self->error( 500, "Reservation failed" ) unless $order;

    my %success = (
        booking_datetime => $order->booking->date,
        create_date      => $order->create_date,
    );

    $self->render( json => \%success, status => 201 );
}

sub _categories {
    my ( $self, $categories ) = @_;
    $categories =~ s/ //g;
    my @categories = split /,/, $categories;
    for my $category (@categories) {
        # 벨트 허리띠
        $category =~ s/허리띠/$OpenCloset::Constants::Category::LABEL_BELT/;
        # 블라우스 브라우스
        $category =~ s/브라우스/$OpenCloset::Constants::Category::LABEL_BLOUSE/;
        # 자켓 쟈켓 재킷
        $category =~ s/쟈켓/$OpenCloset::Constants::Category::LABEL_JACKET/;
        $category =~ s/재킷/$OpenCloset::Constants::Category::LABEL_JACKET/;
        $category =~ s/상의/$OpenCloset::Constants::Category::LABEL_JACKET/;
        # 팬츠 바지 하의
        $category =~ s/바지/$OpenCloset::Constants::Category::LABEL_PANTS/;
        $category =~ s/하의/$OpenCloset::Constants::Category::LABEL_PANTS/;
        # 셔츠 와이셔츠
        $category =~ s/와이셔츠/$OpenCloset::Constants::Category::LABEL_SHIRT/;
        # 구두 신발
        $category =~ s/신발/$OpenCloset::Constants::Category::LABEL_SHOES/;
        # 스커트 치마
        $category =~ s/치마/$OpenCloset::Constants::Category::LABEL_SKIRT/;
        # 타이 넥타이
        $category =~ s/넥타이/$OpenCloset::Constants::Category::LABEL_TIE/;
    }

    @categories = map { $OpenCloset::Constants::Category::REVERSE_MAP{$_} } @categories;
    return join( ',', @categories );
}

our @VALID_COLORS = qw/staff dark black navy charcoalgray gray brown etc/;

sub _colors {
    my ( $self, $colors ) = @_;
    $colors =~ s/ //g;
    my @colors = split /,/, $colors;

    my @values;
    my $cnt = 0;
    for my $color (@colors) {
        next unless "@VALID_COLORS" =~ m/\b$color\b/;
        push @values, $color;
        last if ++$cnt == 2;
    }

    return 'staff' unless @values;
    return join( ',', @values );
}

1;
