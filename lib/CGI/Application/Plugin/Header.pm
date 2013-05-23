package CGI::Application::Plugin::Header;
use strict;
use warnings;
use CGI::Header;
use Carp qw/croak/;
use parent 'Exporter';

our $VERSION = '0.01';

our @EXPORT_OK = qw( header );

sub import {
    caller->add_callback( postrun => \&before_send_headers );
    __PACKAGE__->export_to_level( 1, @_ );
}

sub header {
    my ( $self, @props ) = @_;

    my $header
        = $self->{+__PACKAGE__}
            ||= $self->delete('header') # => $args_to_new->{PARAMS}->{header}
                || CGI::Header->new( query => $self->query ); # default

    # make '__HEADER_PROPS' always refer to $header->header
    $self->{__HEADER_PROPS} = do {
        my $props = $header->header;

        if ( my $PROPS = $self->{__HEADER_PROPS} ) {
            unless ( $PROPS == $props ) { # header_props() or header_add() is used
                # replace %$props with %$PROPS, normalizing property names
                $header->clear;
                while ( my ($key, $value) = each %$PROPS ) {
                    $header->set( $key => $value );
                }
            }
        }

        $props;
    };

    if ( @props ) {
        if ( @props % 2 == 0 ) {
            # merge @props into $header
            while ( my ($key, $value) = splice @props, 0, 2 ) {
                $header->set( $key => $value );
            }
        }
        elsif ( @props == 1 ) {
            return $header->get( shift @props );
        }
        else {
            croak "Odd number of elements passed to 'header'";
        }
    }

    $header;
}

sub before_send_headers {
    my $self = shift;

    return if $self->header_type eq 'none';

    my %header;
    my $header = $self->header->header;
    @header{ map {"-$_"} keys %$header } = values %$header; # 'type' -> '-type'

    $self->header_props( \%header );

    return;
}

1;
