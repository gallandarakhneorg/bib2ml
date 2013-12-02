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

Bib2HTML::General::Verbose - Verbosing functions

=head1 DESCRIPTION

Bib2HTML::General::Verbose is a Perl module, which permits to display
messages in a verbose mode.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Verbose.pm itself.

=over

=cut

package Bib2HTML::General::Verbose;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the verbosing functions
my $VERSION = "1.0" ;
# The current verbosing level ;
my $CURRENT_VERBOSE_LEVEL = 0 ;

#------------------------------------------------------
#
# Level management functions
#
#------------------------------------------------------

#-------------
=pod

=item * setlevel()

Changes the verbosing level.
Takes 1 arg:

=over

=item  * level (integer)

is an I<integer> which is the requested verbose level.

=back

=cut
sub setlevel($) {
  $CURRENT_VERBOSE_LEVEL = $_[0] || 0 ;
}


#-------------
=pod

=item * currentlevel()

Replies the current verbosing level.

=cut
sub currentlevel() {
  return $CURRENT_VERBOSE_LEVEL ;
}

#------------------------------------------------------
#
# Output functions
#
#------------------------------------------------------

#-------------
=pod

=item * verb()

Displays the specified message if in verbose mode.
Takes 2 args:

=over

=item  * message (string)

is an I<string> which is the message to display.

=item  * level (integer)

is an I<integer> which is the required level of the message.

=item  * cr (optional boolean)

indicates if the carriage return will be printed (default is true)

=back

=cut
sub verb {
  my $level = $_[1] || $CURRENT_VERBOSE_LEVEL ;
  if ( Bib2HTML::General::Verbose::currentlevel() >= $level ) {
    my $msg = $_[0] || '' ;
    my $cr = defined($_[2]) ? $_[2] : 1 ;
    $msg =~ s/\n$// ;
    print $msg ;
    print "\n" if $cr ;
  }
}

#-------------
=pod

=item * one()

Displays the specified message if in verbosing level
greater or equal to 1.
Takes 2 args:

=over

=item  * message (string)

is an I<string> which is the message to display.

=item * ...

optional parameters passed to verb()

=back

=cut
sub one($) {
  my $msg = $_[0] || '' ;
  Bib2HTML::General::Verbose::verb($msg,1,$_[1]) ;
}

#-------------
=pod

=item * two()

Displays the specified message if in verbosing level
greater or equal to 2.
Takes 2 args:

=over

=item  * message (string)

is an I<string> which is the message to display.

=item * ...

optional parameters passed to verb()

=back

=cut
sub two($) {
  my $msg = $_[0] || '' ;
  Bib2HTML::General::Verbose::verb($msg,2,$_[1]) ;
}

#-------------
=pod

=item * three()

Displays the specified message if in verbosing level
greater or equal to 3.
Takes 2 args:

=over

=item  * message (string)

is an I<string> which is the message to display.

=item * ...

optional parameters passed to verb()

=back

=cut
sub three($) {
  my $msg = $_[0] || '' ;
  Bib2HTML::General::Verbose::verb($msg,3,$_[1]) ;
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
