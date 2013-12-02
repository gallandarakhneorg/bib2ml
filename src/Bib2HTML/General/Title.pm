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

Bib2HTML::General::Title - Utility functions for titles

=head1 SYNOPSYS

use Bib2HTML::General::Title ;

=head1 DESCRIPTION

Bib2HTML::General::Title is a Perl module, which proposes
functions to support the titles

=head1 GETTING STARTED

=head2 Initialization

To use this package, say something like this:

    use Bib2HTML::General::Title;

...or something similar.

=cut

package Bib2HTML::General::Title;

@ISA = ('Exporter');
@EXPORT = qw( &get_title_keywords );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

use Bib2HTML::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the parser
my $VERSION = "1.0" ;

# The keywords that could be ignored
my @IGNORABLE_WORDS = ( # English
		       'the', 'a', 'an', 'in', 'on', 'inside', 'to',
		       'and', 'by', 'for', 'based', 'of', 'his', 'her',
		        # French
		       'la', 'le', 'les', 'dans', 'de', 'd', 'un', 'une',
		       'vers', 'sur', 'et', 'pour', 'par', 'en',
		      ) ;

# The forms of words that could be ignored
my @IGNORABLE_WORD_FORMS = ( # English
			    '.*ing',
			    # French
			   ) ;

#------------------------------------------------------
#
# Keyword API
#
#------------------------------------------------------

=pod

=item * get_title_keywords()

Replies the keywords of the specified title
Takes 1 arg:

=over

=item * text (string)

is the text to parse.

=back

=cut
sub get_title_keywords($) : method {
  my $text = $_[0] || '' ;
  my @keywords = () ;
  foreach my $word (split /[^a-zA-Z0-9\-\&\;]+/, $text) {
    if ( ( ! strinarray( lc($word), \@keywords ) ) &&
	 ( ! strinarray( lc($word), \@IGNORABLE_WORDS ) ) ) {
      my $i = $#IGNORABLE_WORD_FORMS ;
      while ($i>=0) {
	my $form = $IGNORABLE_WORD_FORMS[$i] ;
	if ( lc($word) !~ /^$form$/ ) {
	  push @keywords, $word ;
	  $i = -1 ;
	}
	$i -- ;
      }
    }
  }
  return @keywords ;
}

1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 1998-09 Stéphane Galland E<lt>galland@arakhne.orgE<gt>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by Stéphane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

bib2html.pl
