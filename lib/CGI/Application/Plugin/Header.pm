package CGI::Application::Plugin::Header;
use 5.008_009;
use strict;
use warnings;
use parent 'Exporter';
use CGI::Header;
use Carp qw/carp croak/;

our $VERSION = '0.01';

our @EXPORT = qw( header header_add header_props );

sub import {
    my ( $class ) = @_;
    my $caller = caller;
    $caller->add_callback( init => \&BUILD );
    $class->export_to_level( 1, @_ );
}

sub BUILD {
    my $self = shift;
    my @args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    while ( my ($key, $value) = splice @args, 0, 2 ) {
        $self->{+__PACKAGE__} = $value if lc $key eq 'header';
    }

    return;
}

sub header {
    my $self = shift;
    $self->{+__PACKAGE__} ||= CGI::Header->new( query => $self->query );
}

sub header_add {
    my $self   = shift;
    my @props  = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    my $header = $self->header;

    carp "header_add called while header_type set to 'none'" if $self->header_type eq 'none';
    croak "Odd number of elements passed to header_add" if @props % 2 != 0;

    while ( my ($key, $value) = splice @props, 0, 2 ) {
        if ( ref $value eq 'ARRAY' ) {
            if ( $header->exists($key) ) {
                my $existing_value = $header->get( $key ); 
                if ( ref $existing_value eq 'ARRAY' ) {
                    $value = [ @$existing_value, @$value ];
                }
                else {
                    $value = [ $existing_value, @$value ];
                }
            }
            else {
                $value = [ @$value ];
            }
        }

        $header->set( $key => $value );
    }

    return;
}

sub header_props {
    my $self   = shift;
    my $header = $self->header;

    unless ( @_ ) {
        my %props;
        my $props = $header->header;
        @props{ map {"-$_"} keys %$props } = values %$props; # 'type' -> '-type'
        return %props;
    }

    my @props = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    carp "header_props called while header_type set to 'none'" if $self->header_type eq 'none';
    croak "Odd number of elements passed to header_props" if @props % 2 != 0;

    $header->clear;
    while ( my ($key, $value) = splice @props, 0, 2 ) {
        $header->set( $key => $value );
    }

    return;
}

1;

__END__

=head1 NAME

CGI::Application::Plugin::Header - Plugin for handling header props.

=head1 SYNOPSIS

  package MyApp;
  use parent 'CGI::Application';
  use CGI::Application::Plugin::Header;

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

