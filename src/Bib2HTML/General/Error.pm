# Copyright (C) 1998-09  Stephane Galland <galland@arakhne.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

=pod

=head1 NAME

Bib2HTML::General::Error - Error functions

=head1 DESCRIPTION

Bib2HTML::General::Error is a Perl module, which proposes
a set of functions to manage the errors.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Error.pm itself.

=over

=cut

package Bib2HTML::General::Error;

@ISA = ('Exporter');
@EXPORT = qw( &warm &err &warningcount
              &syserr &syswarm &printwarningcount
	      &unsetwarningaserror
	      &setwarningaserror
	      &unsetsortwarnings
	      &setsortwarnings
	      &notempty );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Carp ;

use Bib2HTML::General::Verbose ;
use Bib2HTML::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the error functions
my $VERSION = "1.0" ;

# The quantity of warning encounted during the generation
my $WARNING_COUNT = 0 ;

# Indicates that the warnings are considered as errors
my $WARNING_HAS_ERROR = 0 ;

# Indicates if the warnings must be sorted
my $SORT_WARNINGS = 0 ;

# List of generated warning messages
my %__GENERATED_WARNINGS = () ;

#------------------------------------------------------
#
# Warning getters/setters
#
#------------------------------------------------------

=pod

=item * warningcount()

Replies the quantity of warnings.

=cut
sub warningcount() {
  return $WARNING_COUNT ;
}

=pod

=item * setwarningaserror()

Sets that the warnings will be considered as errors.

=cut
sub setwarningaserror() {
  $WARNING_HAS_ERROR = 1 ;
}

=pod

=item * unsetwarningaserror()

Sets that the warnings will not be considered as errors.

=cut
sub unsetwarningaserror() {
  $WARNING_HAS_ERROR = 0 ;
}

=pod

=item * setsortwarnings()

Sets the sorting flag of warnings

=cut
sub setsortwarnings() {
  $SORT_WARNINGS = 1 ;
}

=pod

=item * unsetsortwarnings()

Unsets the sorting flag of warnings

=cut
sub unsetsortwarnings() {
  $SORT_WARNINGS = 0 ;
}

#------------------------------------------------------
#
# Error reporting
#
#------------------------------------------------------

=pod

=item * syserr()

Displays an error and stop.
Takes 1 arg:

=over

=item * message (string)

is the error message to display.

=back

=cut
sub syserr($) {
  my $msg = $_[0] || '' ;
  $msg =~ s/\n+$// ;
  printwarningcount() ;
  die( "Error: $msg\n" ) ;
}

=pod

=item * syswarm()

Displays a warning and stop.
Takes 1 arg:

=over

=item * message (string)

is the warning message to display.

=back

=cut
sub syswarm($) {
  my $msg = $_[0] || '' ;
  $msg =~ s/^[ \t\r\n]+// ;
  $msg =~ s/[ \t\r\n]+$// ;
  if ( ! $WARNING_HAS_ERROR ) {

    if ( __is_not_logged_warning( $msg, '', 0 ) ) {

      __log_warning( $msg, '', 0 ) ;

      $WARNING_COUNT ++ ;
      if ( ( ! $SORT_WARNINGS ) &&
	   ( Bib2HTML::General::Verbose::currentlevel() >= 0 ) ) {
	print STDERR "Warning: $msg\n" ;
      }

    }
  }
  else {
    syserr( $msg ) ;
  }
}

# Replies if the specified message was already generated
# __is_not_logged_warning( text, file, lineno )
sub __is_not_logged_warning($$$) {
  return 0 unless $_[0] ;
  if ( ! exists $__GENERATED_WARNINGS{$_[0]} ) {
    return 1 ;
  }
  my $location = ( $_[1] || '' ).':'.( ( $_[1] && $_[2] ) || '' ) ;
  if ( $location eq ':' ) {
    return ( int(@{$__GENERATED_WARNINGS{$_[0]}}) > 0 ) ;
  }
  else {
    return ( ! strinarray( $location, $__GENERATED_WARNINGS{$_[0]} ) ) ;
  }
}

# Log the specified message
# __log_warning( text, file, lineno )
sub __log_warning($$$) {
  return 0 unless $_[0] ;
  if ( ! exists $__GENERATED_WARNINGS{$_[0]} ) {
    $__GENERATED_WARNINGS{$_[0]} = [] ;
  }
  my $location = ( $_[1] || '' ).':'.( ( $_[1] && $_[2] ) || '' ) ;
  if ( ( $location ne ':' ) &&
       ( ! strinarray( $location, $__GENERATED_WARNINGS{$_[0]} ) ) ) {
    push @{$__GENERATED_WARNINGS{$_[0]}}, $location ;
  }
  return 0 ;
}

=pod

=item * printwarningcount()

Displays the count of warnings.

=cut
sub printwarningcount() {
  if ( ( Bib2HTML::General::Verbose::currentlevel() >= 0 ) &&
       ( $WARNING_COUNT > 0 ) ) {

    # Display the warnings
    if ( $SORT_WARNINGS ) {
      my @msgs = () ;

      while ( my ($key, $value) = each( %__GENERATED_WARNINGS ) ) {

	if ( int(@{$value}) > 0 ) {

	  foreach my $location ( @{$value} ) {
	    my $file = extract_file_from_location( $location ) ;
	    my $lineno = extract_line_from_location( $location ) ;
	    push @msgs, { 'msg' => $key,
			  'file' => $file,
			  'line' => $lineno,
			} ;
	  }
	}
	else {

	  push @msgs, { 'msg' => $key,
			'file' => '',
			'line' => 0,
		      } ;

	}

      }

      @msgs = sort {
	return -1 if ( $a->{'file'} lt $b->{'file'} ) ;
	return 1 if ( $a->{'file'} gt $b->{'file'} ) ;
	return -1 if ( $a->{'line'} < $b->{'line'} ) ;
	return 1 if ( $a->{'line'} > $b->{'line'} ) ;
	return ( $a->{'msg'} <=> $b->{'msg'} ) ;
      } @msgs ;

      foreach my $value ( @msgs ) {
	my $msg = $value->{'msg'} || '???' ;
	my $file = $value->{'file'} || '' ;
	my $line = $value->{'line'} || 0 ;
	print STDERR "Warning".
	  (($file)?
	   (" ($file".(($line>0)?
		       ":$line":"").")"): "").
			 ": $msg\n" ;
      }

    }

    print STDERR "$WARNING_COUNT warning".(($WARNING_COUNT>1)?"s":"")."\n" ;
  }
}

=pod

=item * err()

Displays an error and stop.
Takes 3 args:

=over

=item * message (string)

is the error message to display.

=item * file (string)

is the name of the file in which the error occurs.

=item * line (integer)

is the line where the error occurs.

=back

=cut
sub err($$$) {
  my $msg = $_[0] || '' ;
  my $file = $_[1] || '' ;
  my $line = $_[2] || 0 ;
  printwarningcount() ;
  $msg =~ s/\n+$// ;
  die( "Error".
        (($file)?
        (" ($file".(($line>0)?
		    ":$line":"").")"): "").
        ": $msg\n" ) ;
}

=pod

=item * warm()

Displays a warning.
Takes 3 args:

=over

=item * message (string)

is the warning message to display.

=item * file (string)

<is the name of the file in which the warning occurs.

=item * line (integer)

is the line where the warning occurs.

=back

=cut
sub warm($$$) {
  my $msg = $_[0] || '' ;
  my $file = $_[1] || '' ;
  my $line = $_[2] || 0 ;
  if ( ! $WARNING_HAS_ERROR ) {
    $msg =~ s/\n+$// ;
    if ( __is_not_logged_warning( $msg, $file, $line ) ) {

      __log_warning( $msg, $file, $line ) ;

      $WARNING_COUNT ++ ;
      if ( ( ! $SORT_WARNINGS ) &&
	   ( Bib2HTML::General::Verbose::currentlevel() >= 0 ) ) {
	print STDERR "Warning".
	  (($file)?
	   (" ($file".(($line>0)?
		       ":$line":"").")"): "").
			 ": $msg\n" ;
      }
    }
  }
  else {
    err( $msg, $file, $line ) ;
  }
}


=pod

=item * notempty()

Replies the specified value if it was not empty.
Otherwhise, generate a exception.

Takes 2 args:

=over

=item * value (mixed)

is the value to check

=item * msg (string)

is the error message

=back

=cut
sub notempty {
  confess( 'invalid use of function notempty()' )
    unless ( $_[1] ) ;
  if ( ( ! defined( $_[0] ) ) ||
       ( length( "$_[0]" ) <= 0 ) ) {
    confess( $_[1] ) ;
  }
  return $_[0] ;
}

1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 1998-09 Stéphane Galland <galland@arakhne.org>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by Stéphane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

bib2html.pl
