# api.theopencloset.net #

https://api.theopencloset.net

### examples ###

``` perl
use strict;
use warnings;

use HTTP::Tiny;
use MIME::Base64;

my $email         = 'youremail@example.com';
my $password      = 'v3ry s3cr3t';
my $authorization = encode_base64( $email . ':' . $password, '' );
my $http          = HTTP::Tiny->new(
    default_headers => {
        authorization => $authorization,
        accept        => 'application/json',
    }
);

my $res = $http->get('https://api.theopencloset.net/');
print "$res->{status} $res->{reason}\n";
print "$res->{content}\n";
```
