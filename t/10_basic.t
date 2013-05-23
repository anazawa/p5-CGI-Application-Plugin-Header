use strict;
use warnings;
use Test::More tests => 1;

package MyApp;
use parent 'CGI::Application';
use CGI::Application::Plugin::Header 'header';

sub setup {
    my $self = shift;
    $self->run_modes( start => sub { 'Hello World' } );
}

package main;

local $ENV{CGI_APP_RETURN_ONLY} = 1;

my $app = MyApp->new;

can_ok $app, 'header';
isa_ok $app->header, 'CGI::Header';

is $app->header( type => 'text/html' ), $app->header;
is_deeply +{ $app->header_props }, { type => 'text/html' };

is $app->header('type'), 'text/html';

$app->header_props( type => 'text/plain' );
is_deeply $app->header->header, { type => 'text/plain' };

like $app->run, qr{^Content-Type: text/plain; charset=ISO-8859-1};

