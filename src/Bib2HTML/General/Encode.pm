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

Bib2HTML::General::Encode - String encoding functions

=head1 DESCRIPTION

Bib2HTML::General::Encode is a Perl module, which proposes
a set of functions for string encoding.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Encode.pm itself.

=over

=cut

package Bib2HTML::General::Encode;

@ISA = ('Exporter');
@EXPORT = qw( &set_default_encoding &get_default_encoding &get_encoded_str );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Encode;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the encode functions
my $VERSION = "1.0" ;

# Default encoding
my $DEFAULT_ENCODING = "utf-8";

#------------------------------------------------------
#
# Functions
#
#------------------------------------------------------

=pod

=item * set_default_encoding($)

Set the default encoding
Takes 1 arg:

=over

=item * name (string)

is a I<string> which correspond to the name of the encoding.

=back

=cut
sub set_default_encoding($) {
  $DEFAULT_ENCODING = $_[0];
}

=pod

=item * get_default_encoding()

Replies the default encoding.

=cut
sub get_default_encoding() {
  return $DEFAULT_ENCODING;
}

=pod

=item * get_encode_str($)

Replies the specified string in the current string encoding.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub get_encoded_str($) {
  return encode($DEFAULT_ENCODING, $_[0]);
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
