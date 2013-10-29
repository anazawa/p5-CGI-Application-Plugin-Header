use strict;
use warnings;
use Test::More tests => 3;

package MyApp;
use parent 'CGI::Application';
use CGI::Application::Plugin::Header;

sub setup {
    my $self = shift;
    $self->run_modes( start => sub { 'Hello World' } );
}

sub cgiapp_postrun {
    my ( $self, $body_ref ) = @_;
    $self->header->set( 'Content-Length' => length $$body_ref );
}

package main;

subtest 'basic' => sub {
    my $app = MyApp->new;

    local $ENV{CGI_APP_RETURN_ONLY} = 1;

    can_ok $app, 'header';
    isa_ok $app->header, 'CGI::Header';
    is $app->query, $app->header->query;

    $app->header->type('text/html');
    is_deeply +{ $app->header_props }, { -type => 'text/html' };

    $app->header_props( -type => 'text/plain' );
    is_deeply $app->header->header, { type => 'text/plain' };

    $app->header_add( -cookie => 'foo=bar' );
    is $app->header->cookies, 'foo=bar';

    $app->header_add( -cookie => ['bar=baz'] );
    is_deeply $app->header->cookies, [ 'foo=bar', 'bar=baz' ];

    like $app->run, qr{Content-length: 11};
};

subtest '#header' => sub {
    my $app    = MyApp->new;
    my $header = CGI::Header->new( query => $app->query );

    is $app->header($header), $header, 'setter';
    is $app->header, $header, 'getter';
};

subtest '#BUILD' => sub {
    my $query  = CGI->new;
    my $header = CGI::Header->new( query => $query );
    my $app    = MyApp->new( query => $query, header => $header );

    is $app->header, $header;
};

