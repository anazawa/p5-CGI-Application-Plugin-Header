package CGI::Application::Plugin::Header;
use 5.008_009;
use strict;
use warnings;
use parent 'Exporter';
use CGI::Header;
use Carp qw/croak/;

our $VERSION = '0.01';

our @EXPORT_OK = qw( header );

sub import {
    my $caller = caller;
    $caller->new_hook('before_finalize_headers');
    $caller->add_callback( postrun => \&finalize_headers );
    __PACKAGE__->export_to_level( 1, @_ );
}

sub header {
    my ( $self, @props ) = @_;

    my $header
        = $self->{+__PACKAGE__}
            ||= $self->delete('header') # => $self->param('header')
                || CGI::Header->new( query => $self->query ); # default

    # make '__HEADER_PROPS' always refer to $header->header
    $self->{__HEADER_PROPS} = do {
        my $props = $header->header;
        my $PROPS = $self->{__HEADER_PROPS}; # buffer

        if ( $PROPS and $PROPS != $props ) { # 'header_props' or 'header_add' was used
            # replace %$props with %$PROPS, normalizing property names
            $header->clear;
            while ( my ($key, $value) = each %$PROPS ) {
                $header->set( $key => $value );
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

sub finalize_headers {
    my $self = shift;

    $self->call_hook( 'before_finalize_headers', @_ );

    my %header;
    my $header = $self->header->header;
    @header{ map {"-$_"} keys %$header } = values %$header; # 'type' -> '-type'

    $self->{__HEADER_PROPS} = \%header;

    return;
}

1;

__END__

=head1 NAME

CGI::Application::Plugin::Header - Plugin for handling header props.

=head1 SYNOPSIS

  package MyApp;
  use parent 'CGI::Application';
  use CGI::Application::Plugin::Header 'header';

  sub do_something {
      my $self = shift;

      my $header = $self->header; # => CGI::Header object

      # get header props.
      my $type = $self->header('type'); # => "text/plain"

      # set header props.
      $self->header( type => "text/html" );

      # compatible with the core methods of CGI::Application
      $self->header_props( type => "text/plain" );
      $self->header_add( type => "text/plain" );

      ...
  }

  ...

  use CGI;
  use CGI::Header;
  use MyApp;

  # you can define your CGI::Header object
  my $app = MyApp->new(
      PARAMS => {
          header => CGI::Header->new( query => CGI->new ),
      }
  );

=head1 DESCRIPTION

=head2 METHODS

This plugin exports the C<header> method to your application on demand:

  use CGI::Application::Plugin::Header 'header';

C<header> can be used as follows, where C<$cgiapp> denotes the instance
of your application which inherits from L<CGI::Application>:

=over 4

=item $header = $cgiapp->header

Returns a L<CGI::Header> object associated with C<$cgiapp>.

=item $value = $cgiapp->header( $prop )

Returns the value of the specified property.

=item $header = $cgiapp->header( $prop => $value )

=item $header = $cgiapp->header( $p1 => $v1, $p2 => $v2, ... )

Given key-value pairs of header props., merges them into the existing
properties.

=back

=head2 HOOKS

=over 4

=item before_finalize_headers

This plugin finalizes header props. just before sending headers,
and so C<header> can't be updated by the C<cgiapp_postrun> hook.
This hook allows you add a callback which is called just before finalizing
header props. This hook receives a reference to the output from your
run mode method, in addition to C<$cgiapp>.

  __PACKAGE__->add_callback(
      before_finalize_headers => sub {
          my ( $self, $body_ref ) = @_;
          $self->header( 'Content-Length' => length $$body_ref );
      }
  );

=back

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

