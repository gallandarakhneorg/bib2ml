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

Bib2HTML::General::HTML - HTML support definitions

=head1 DESCRIPTION

Bib2HTML::General::HTML is a Perl module, which permits to support
some HTML definitions. This is a fork of PhpDocGen::General::HTML.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in HTML.pm itself.

=over

=cut

package Bib2HTML::General::HTML;

@ISA = ('Exporter');
@EXPORT = qw(&get_html_entities &get_restricted_html_entities &translate_html_entities
	     &htmlcatdir &htmlcatfile &htmldirname &htmlfilename &htmltoroot &htmlpath
	     &htmlsplit &strip_html_tags &html_add_unsecable_spaces &html_uc &html_lc
	     &html_sc &split_html_tags &html_extract_tag_params &htmltolocalpath
	     &nl2br &br2nl &setAsValidHTML_small &setAsValidHTML &html_getinitiales
             &html_ucwords &html_ucfirst &html_substr &html_split_to_chars &sortbyletters
	     &remove_html_accents );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Bib2HTML::General::Misc ;
use Bib2HTML::General::Encode ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the HTML support functions
my $VERSION = "4.0" ;

# Translation table
my %HTML_ENTITY_CODES = ( 'nbsp'       => 160, #no-break space = non-breaking space
			  'iexcl'      => 161, #inverted exclamation mark, U+00A1 ISOnum
			  'cent'       => 162, #cent sign
			  'pound'      => 163, #pound sign
			  'curren'     => 164, #currency sign
			  'yen'        => 165, #yen sign = yuan sign
			  'brvbar'     => 166, #broken bar = broken vertical bar
			  'sect'       => 167, #section sign
			  'uml'        => 168, #diaeresis = spacing diaeresis,
			  'copy'       => 169, #copyright sign
			  'ordf'       => 170, #feminine ordinal indicator
			  'laquo'      => 171, #left-pointing double angle quotation mark
			  'not'        => 172, #not sign
			  'shy'        => 173, #soft hyphen = discretionary hyphen
			  'reg'        => 174, #registered sign = registered trade mark sign
			  'macr'       => 175, #macron = spacing macron = overline = APL overbar
			  'deg'        => 176, #degree sign
			  'plusmn'     => 177, #plus-minus sign = plus-or-minus sign
			  'sup2'       => 178, #superscript two = superscript digit two = squared
			  'sup3'       => 179, #superscript three = superscript digit three = cubed
			  'acute'      => 180, #acute accent = spacing acute
			  'micro'      => 181, #micro sign
			  'para'       => 182, #pilcrow sign = paragraph sign
			  'middot'     => 183, #middle dot = Georgian comma = Greek middle dot
			  'cedil'      => 184, #cedilla = spacing cedilla
			  'sup1'       => 185, #superscript one = superscript digit one
			  'ordm'       => 186, #masculine ordinal indicator
			  'raquo'      => 187, #right-pointing double angle quotation mark = right pointing guillemet
			  'frac14'     => 188, #vulgar fraction one quarter = fraction one quarter
			  'frac12'     => 189, #vulgar fraction one half = fraction one half
			  'frac34'     => 190, #vulgar fraction three quarters = fraction three quarters
			  'iquest'     => 191, #inverted question mark = turned question mark
			  'Agrave'     => 192, #latin capital letter A with grave = latin capital letter A grave
			  'Aacute'     => 193, #latin capital letter A with acute
			  'Acirc'      => 194, #latin capital letter A with circumflex
			  'Atilde'     => 195, #latin capital letter A with tilde
			  'Auml'       => 196, #latin capital letter A with diaeresis
			  'Aring'      => 197, #latin capital letter A with ring above = latin capital letter A ring
			  'AElig'      => 198, #latin capital letter AE = latin capital ligature AE
			  'Ccedil'     => 199, #latin capital letter C with cedilla
			  'Egrave'     => 200, #latin capital letter E with grave
			  'Eacute'     => 201, #latin capital letter E with acute
			  'Ecirc'      => 202, #latin capital letter E with circumflex
			  'Euml'       => 203, #latin capital letter E with diaeresis
			  'Igrave'     => 204, #latin capital letter I with grave
			  'Iacute'     => 205, #latin capital letter I with acute
			  'Icirc'      => 206, #latin capital letter I with circumflex
			  'Iuml'       => 207, #latin capital letter I with diaeresis
			  'ETH'        => 208, #latin capital letter ETH
			  'Ntilde'     => 209, #latin capital letter N with tilde
			  'Ograve'     => 210, #latin capital letter O with grave
			  'Oacute'     => 211, #latin capital letter O with acute
			  'Ocirc'      => 212, #latin capital letter O with circumflex
			  'Otilde'     => 213, #latin capital letter O with tilde
			  'Ouml'       => 214, #latin capital letter O with diaeresis
			  'times'      => 215, #multiplication sign
			  'Oslash'     => 216, #latin capital letter O with stroke = latin capital letter O slash
			  'Ugrave'     => 217, #latin capital letter U with grave
			  'Uacute'     => 218, #latin capital letter U with acute
			  'Ucirc'      => 219, #latin capital letter U with circumflex
			  'Uuml'       => 220, #latin capital letter U with diaeresis
			  'Yacute'     => 221, #latin capital letter Y with acute
			  'THORN'      => 222, #latin capital letter THORN
			  'szlig'      => 223, #latin small letter sharp s = ess-zed
			  'agrave'     => 224, #latin small letter a with grave = latin small letter a grave
			  'aacute'     => 225, #latin small letter a with acute
			  'acirc'      => 226, #latin small letter a with circumflex
			  'atilde'     => 227, #latin small letter a with tilde
			  'auml'       => 228, #latin small letter a with diaeresis
			  'aring'      => 229, #latin small letter a with ring above = latin small letter a ring
			  'aelig'      => 230, #latin small letter ae = latin small ligature ae
			  'ccedil'     => 231, #latin small letter c with cedilla
			  'egrave'     => 232, #latin small letter e with grave
			  'eacute'     => 233, #latin small letter e with acute
			  'ecirc'      => 234, #latin small letter e with circumflex
			  'euml'       => 235, #latin small letter e with diaeresis
			  'igrave'     => 236, #latin small letter i with grave
			  'iacute'     => 237, #latin small letter i with acute
			  'icirc'      => 238, #latin small letter i with circumflex
			  'iuml'       => 239, #latin small letter i with diaeresis
			  'eth'        => 240, #latin small letter eth
			  'ntilde'     => 241, #latin small letter n with tilde
			  'ograve'     => 242, #latin small letter o with grave
			  'oacute'     => 243, #latin small letter o with acute
			  'ocirc'      => 244, #latin small letter o with circumflex
			  'otilde'     => 245, #latin small letter o with tilde
			  'ouml'       => 246, #latin small letter o with diaeresis
			  'divide'     => 247, #division sign
			  'oslash'     => 248, #latin small letter o with stroke = latin small letter o slash
			  'ugrave'     => 249, #latin small letter u with grave
			  'uacute'     => 250, #latin small letter u with acute
			  'ucirc'      => 251, #latin small letter u with circumflex
			  'uuml'       => 252, #latin small letter u with diaeresis
			  'yacute'     => 253, #latin small letter y with acute
			  'thorn'      => 254, #latin small letter thorn
			  'yuml'       => 255, #latin small letter y with diaeresis
			  'quot'       => 34, #quotation mark = APL quote
			  'amp'        => 38, #ampersand
			  'lt'         => 60, #less-than sign
			  'gt'         => 62, #greater-than sign
			  'OElig'      => 338, #latin capital ligature OE
			  'oelig'      => 339, #latin small ligature oe
			  'Scedil'     => 'x015e', #latin capital letter S with cedil
			  'scedil'     => 'x015f', #latin small letter s with cedil
			  'Tcedil'     => 'x0162', #latin capital letter T with cedil
			  'tcedil'     => 'x0163', #latin small letter t with cedil
			  'Yuml'       => 376, #latin capital letter Y with diaeresis
			  'circ'       => 710, #modifier letter circumflex accent
			  'tilde'      => 732, #small tilde
			  'Aucircle'   => 'x0102', #latin capital letter A with small u on top
			  'aucircle'   => 'x0103', #latin small letter a with small u on top
			  'Cacute'     => 'x262', #latin capital letter C with acute
			  'cacute'     => 'x263', #latin small letter c with acute
			  'Scaron'     => 352, #latin capital letter S with caron
			  'scaron'     => 353, #latin small letter s with caron
			  'Ccaron'     => 268, #latin capital letter C with caron
			  'ccaron'     => 269, #latin small letter c with caron
			  'Dcaron'     => 270, #latin capital letter D with caron
			  'dcaron'     => 271, #latin small letter d with caron
			  'Ecaron'     => 282, #latin capital letter E with caron
			  'ecaron'     => 283, #latin small letter e with caron
			  'Lcaron'     => 317, #latin capital letter L with caron
			  'lcaron'     => 318, #latin small letter l with caron
			  'Ncaron'     => 327, #latin capital letter N with caron
			  'ncaron'     => 328, #latin small letter n with caron
			  'Rcaron'     => 344, #latin capital letter R with caron
			  'rcaron'     => 345, #latin small letter r with caron
			  'Tcaron'     => 356, #latin capital letter T with caron
			  'tcaron'     => 357, #latin small letter t with caron
			  'Zcaron'     => 381, #latin capital letter Z with caron
			  'zcaron'     => 382, #latin small letter z with caron
			) ;

# The characters which are displayed for each HTML entity (except &amp; &gt; &lt; &quot; )
my %HTML_ENTITY_CHARS = (  'Ocirc'        => 'Ô',
			   'szlig'        => 'ß',
			   'micro'        => 'µ',
			   'para'         => '¶',
			   'not'          => '¬',
			   'sup1'         => '¹',
			   'oacute'       => 'ó',
			   'Uacute'       => 'Ú',
			   'middot'       => '·',
			   'ecirc'        => 'ê',
			   'pound'        => '£',
			   'scaron'       => 'š',
			   'ntilde'       => 'ñ',
			   'igrave'       => 'ì',
			   'atilde'       => 'ã',
			   'thorn'        => 'þ',
			   'Euml'         => 'Ë',
			   'Ntilde'       => 'Ñ',
			   'Auml'         => 'Ä',
			   'plusmn'       => '±',
			   'raquo'        => '»',
			   'THORN'        => 'Þ',
			   'laquo'        => '«',
			   'Eacute'       => 'É',
			   'divide'       => '÷',
			   'Uuml'         => 'Ü',
			   'Aring'        => 'Å',
			   'ugrave'       => 'ù',
			   'Egrave'       => 'È',
			   'Acirc'        => 'Â',
			   'oslash'       => 'ø',
			   'ETH'          => 'Ð',
			   'iacute'       => 'í',
			   'Ograve'       => 'Ò',
			   'Oslash'       => 'Ø',
			   'frac34'       => '3/4',
			   'Scaron'       => 'Š',
			   'eth'          => 'ð',
			   'icirc'        => 'î',
			   'ordm'         => 'º',
			   'ucirc'        => 'û',
			   'reg'          => '®',
			   'tilde'        => '~',
			   'aacute'       => 'á',
			   'Agrave'       => 'À',
			   'Yuml'         => 'Ÿ',
			   'times'        => '×',
			   'deg'          => '°',
			   'AElig'        => 'Æ',
			   'Yacute'       => 'Ý',
			   'Otilde'       => 'Õ',
			   'circ'         => '^',
			   'sup3'         => '³',
			   'oelig'        => 'œ',
			   'frac14'       => '1/4',
			   'Ouml'         => 'Ö',
			   'ograve'       => 'ò',
			   'copy'         => '©',
			   'shy'          => '­',
			   'iuml'         => 'ï',
			   'acirc'        => 'â',
			   'iexcl'        => '¡',
			   'Iacute'       => 'Í',
			   'Oacute'       => 'Ó',
			   'ccedil'       => 'ç',
			   'frac12'       => '1/2',
			   'Icirc'        => 'Î',
			   'eacute'       => 'é',
			   'egrave'       => 'è',
			   'euml'         => 'ë',
			   'Ccedil'       => 'Ç',
			   'OElig'        => 'Œ',
			   'Atilde'       => 'Ã',
			   'ouml'         => 'ö',
			   'cent'         => '¢',
			   'Aacute'       => 'Á',
			   'sect'         => '§',
			   'Ugrave'       => 'Ù',
			   'aelig'        => 'æ',
			   'ordf'         => 'ª',
			   'yacute'       => 'ý',
			   'Ecirc'        => 'Ê',
			   'auml'         => 'ä',
			   'macr'         => '¯',
			   'iquest'       => '¿',
			   'sup2'         => '²',
			   'Ucirc'        => 'Û',
			   'aring'        => 'å',
			   'Igrave'       => 'Ì',
			   'yen'          => '¥',
			   'uuml'         => 'ü',
			   'otilde'       => 'õ',
		   	   'uacute'       => 'ú',
			   'yuml'         => 'ÿ',
			   'ocirc'        => 'ô',
			   'Iuml'         => 'Ï',
			   'agrave'       => 'à',
			) ;


# The mapping between the accentuated characters and the non-accentuated characters
my %HTML_NO_ACCENT_ENTITY_CHARS = (
			   'aacute'       => 'a',
			   'Aacute'       => 'A',
			   'aelig'        => 'ae',
			   'AElig'        => 'ae',
			   'acirc'        => 'a',
			   'Acirc'        => 'A',
			   'agrave'       => 'a',
			   'Agrave'       => 'A',
			   'atilde'       => 'a',
			   'Atilde'       => 'A',
			   'Aring'        => 'A',
			   'aring'        => 'a',
			   'aucircle'     => 'a',
			   'Aucircle'     => 'A',
			   'auml'         => 'a',
			   'Auml'         => 'A',
			   'Cacute'       => 'C',
			   'cacute'       => 'c',
			   'Ccaron'       => 'C',
			   'ccaron'       => 'C',
			   'ccedil'       => 'c',
			   'Ccedil'       => 'C',
			   'Dcaron'       => 'D',
			   'dcaron'       => 'd',
			   'Eacute'       => 'E',
			   'eacute'       => 'e',
			   'Ecaron'       => 'E',
			   'ecaron'       => 'e',
			   'ecirc'        => 'e',
			   'Ecirc'        => 'E',
			   'Egrave'       => 'E',
			   'egrave'       => 'e',
			   'eth'          => 'd',
			   'ETH'          => 'D',
			   'Euml'         => 'E',
			   'euml'         => 'e',
			   'Iacute'       => 'i',
			   'iacute'       => 'i',
			   'icirc'        => 'i',
			   'Icirc'        => 'i',
			   'Igrave'       => 'I',
			   'igrave'       => 'i',
			   'Iuml'         => 'I',
			   'iuml'         => 'i',
			   'Lcaron'       => 'L',
			   'lcaron'       => 'l',
			   'Ncaron'       => 'N',
			   'ncaron'       => 'n',
			   'ntilde'       => 'n',
			   'Ntilde'       => 'N',
			   'Oacute'       => 'O',
			   'oacute'       => 'o',
			   'ocirc'        => 'o',
			   'Ocirc'        => 'O',
			   'oelig'        => 'oe',
			   'OElig'        => 'OE',
			   'ograve'       => 'o',
			   'Ograve'       => 'O',
			   'Oslash'       => 'O',
			   'oslash'       => 'o',
			   'otilde'       => 'o',
			   'Otilde'       => 'O',
			   'Ouml'         => 'O',
			   'ouml'         => 'o',
			   'Rcaron'       => 'R',
			   'rcaron'       => 'r',
			   'scaron'       => 's',
			   'Scaron'       => 'S',
			   'scedil'       => 's',
			   'Scedil'       => 'S',
			   'szlig'        => 'S',
			   'Tcaron'       => 'T',
			   'tcaron'       => 't',
			   'tcedil'       => 't',
			   'Tcedil'       => 'T',
			   'thorn'        => 't',
			   'THORN'        => 'T',
		   	   'uacute'       => 'u',
			   'Uacute'       => 'U',
			   'Ucirc'        => 'U',
			   'ucirc'        => 'u',
			   'ugrave'       => 'U',
			   'Ugrave'       => 'U',
			   'uuml'         => 'u',
			   'Uuml'         => 'U',
			   'Yacute'       => 'Y',
			   'yacute'       => 'y',
			   'Yuml'         => 'Y',
			   'yuml'         => 'y',
			   'Zcaron'       => 'Z',
			   'zcaron'       => 'z',
			) ;

#------------------------------------------------------
#
# Predefined PHP variables support
#
#------------------------------------------------------

=pod

=item * get_restricted_html_entities()

Replies the specified string in which some characters have been
replaced by the corresponding HTML entities except for &amp;
&quot; &lt; and &gt;
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub get_restricted_html_entities($) {
  my $text = $_[0] || '' ;
  foreach my $entity (keys %HTML_ENTITY_CHARS) {
    if (($entity ne 'amp')&&
        ($entity ne 'quot')&&
        ($entity ne 'lt')&&
        ($entity ne 'gt')) {
      my $validchar = get_encoded_str($HTML_ENTITY_CHARS{$entity});
      $text =~ s/\Q&#$HTML_ENTITY_CODES{$entity};\E/&$entity;/g ;
      $text =~ s/\Q$validchar\E/&$entity;/g ;
    }
  }
  return $text ;
}

=pod

=item * get_html_entities()

Replies the specified string in which some characters have been
replaced by the corresponding HTML entities
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub get_html_entities($) {
  my $text = $_[0] || '' ;

  $text =~ s/\Q&\E/&amp;/g ;
  $text =~ s/\Q<\E/&lt;/g ;
  $text =~ s/\Q>\E/&gt;/g ;
  $text =~ s/\Q\"\E/&quot;/g ;

  return get_restricted_html_entities($text) ;
}

=pod

=item * translate_html_entities()

Replies the specified string in which each HTML entity was replaced
by the corresponding character.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub translate_html_entities($) {
  my $text = $_[0] || '' ;
  $text =~ s/\Q&nbsp;\E/ /g ;
  $text =~ s/\Q&quot;\E/\"/g ;
  $text =~ s/\Q&lt;\E/</g ;
  $text =~ s/\Q&gt;\E/>/g ;
  $text =~ s/\Q&amp;\E/&/g ;
  while (my ($entity,$charcode) = each(%HTML_ENTITY_CODES)) {
    my $validchar = get_encoded_str($HTML_ENTITY_CHARS{$entity});
    if ($validchar) {
      $text =~ s/\Q&#$charcode;\E/$validchar/g ;
    }
  }
  foreach my $entity (keys %HTML_ENTITY_CHARS) {
    my $validchar = get_encoded_str($HTML_ENTITY_CHARS{$entity});
    $text =~ s/\Q&$entity;\E/$validchar/g ;
  }
  return $text ;
}

=pod

=item * htmlcatdir()

Concatenate two or more directory names to form a complete path ending
with a directory. But remove the trailing slash from the resulting
string.
Takes 2 args or more:

=over

=item * dir... (string)

is a I<string> which correspond to a directory name to merge

=back

=cut
sub htmlcatdir {
  my $path = '' ;
  $path = join('/', @_ ) if ( @_ ) ;
  $path =~ s/\/{2,}/\//g ;
  $path =~ s/\/$// ;
  return $path ;
}

=pod

=item * htmlcatfile()

Concatenate one or more directory names and a filename to form a
complete path ending with a filename
Takes 2 args or more:

=over

=item * dir... (string)

is a I<string> which correspond to a directory name to merge

=item * file (string)

is a I<string> which correspond to a file name to merge

=back

=cut
sub htmlcatfile {
  return '' unless @_ ;
  my $file = pop @_;
  return $file unless @_;
  my $dir = htmlcatdir(@_);
  $dir .= "/" unless substr($file,0,1) eq "/" ;
  return $dir.$file;
}

=pod

=item * htmldirname()

Replies the path of the from the specified file
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path from which
the dirname but be extracted

=back

=cut
sub htmldirname($) {
  my $dirname = $_[0] || '' ;
  $dirname =~ s/\/+\s*$// ;
  if ( $dirname =~ /^(.*?)\/[^\/]+$/ ) {
    $dirname = ($1) ? $1 : "/" ;
  }
  else {
    $dirname = "" ;
  }
  return $dirname ;
}

=pod

=item * htmlfilename()

Replies the filename of the from the specified file
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path from which
the filename but be extracted

=back

=cut
sub htmlfilename($) {
  my $filename = $_[0] || '' ;
  $filename =~ s/\/+\s*$// ;
  if ( $filename =~ /^.*?\/([^\/]+)$/ ) {
    $filename = $1 ;
  }
  return $filename ;
}

=pod

=item * htmltoroot()

Replies a relative path in wich each directory of the
specified parameter was replaced by ..
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path to translate

=back

=cut
sub htmltoroot($) {
  my $dir = $_[0] || '' ;
  $dir =~ s/\/\s*$// ;
  $dir =~ s/[^\/]+/../g ;
  return $dir ;
}

=pod

=item * htmlpath()

Replies a path in which all the OS path separators were replaced
by the HTML path separator '/'
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path to translate

=back

=cut
sub htmlpath($) {
  my $path = $_[0] || '' ;
  my $os_sep = "/" ;
  my $p = File::Spec->catdir("a","b") ;
  if ( $p =~ /a(.+)b/ ) {
    $os_sep = $1 ;
  }
  $path =~ s/\Q$os_sep\E/\//g ;
  return $path ;
}

=pod

=item * htmltolocalpath()

Replies a path in which all the HTML path separators '/' were replaced
by the OS path separator
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path to translate

=back

=cut
sub htmltolocalpath($) {
  my $path = $_[0] || '' ;
  my $os_sep = "/" ;
  my $p = File::Spec->catdir("a","b") ;
  if ( $p =~ /a(.+)b/ ) {
    $os_sep = $1 ;
  }
  $path =~ s/\//$os_sep/g ;
#  if ( ( "$^O" ne 'MSWin32' ) &&
#       ( "$^O" ne 'os2' ) &&
#       ( "$^O" ne 'NetWare' ) &&
#       ( "$^O" ne 'dos' ) &&
#       ( "$^O" ne 'cygwin' ) &&
#       ( "$^O" ne 'MacOS' ) ) {
#    $path =~ s/\ /\\ /g ;
#  }
  return $path ;
}

=pod

=item * htmlsplit()

Replies an array of directories which correspond to each
parts of the specified path.
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path to split

=back

=cut
sub htmlsplit($) {
  my $path = $_[0] || '' ;
  return split( /\//, $path ) ;
}

=pod

=item * strip_html_tags()

Removes the HTML tags from the specified string.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub strip_html_tags($) {
  my $text = $_[0] || '' ;
  my $res = '' ;
  while ( ( $text ) &&
          ( $text =~ /^(.*?)<(.*)$/ ) ) {
    my ($prev,$next) = ($1,$2) ;
    $res .= "$prev" ;
    $text = $next ;
    my $inside = 1 ;
    while ( ( $inside ) && ( $text ) &&
            ( $text =~ /^.*?(>|\"|\')(.*)$/ ) ) {
      my ($sep,$next) = ($1,$2) ;
      $text = $next ;
      if ( $sep eq ">" ) {
        $inside = 0 ;
      }
      else {
        my $insidetext = 1 ;
        while ( ( $insidetext ) && ( $text ) &&
                ( $text =~ /^.*?((?:\\)|$sep)(.*)$/ ) ) {
          my ($sepi,$rest) = ($1,$2) ;
          if ( $sepi eq '\\' ) {
            $text = substr($rest,1) ;
          }
          else {
            $text = $rest ;
            $insidetext = 0 ;
          }
        }
      }
    }
  }
  if ( $text ) {
    $res .= $text ;
  }
  return $res ;
}

=pod

=item * html_extract_tag_params()

Replies the tag parameters that are given
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to parse.

=back

=cut
sub html_extract_tag_params($) : method {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my %params = ( ) ;
  my @strings = () ;
  remove_strings( \@strings, $text ) ;
  $text =~ s/\s*=\s*/=/gm ;
  my @parts = split( /\s+/, $text ) ;
  foreach my $part ( @parts ) {
    my @elts = split( /=/, $part ) ;
    if ( @elts > 1 ) {
      restore_strings( \@strings, $elts[1] ) ;
      $params{lc($elts[0])} = removeslashes( $elts[1] ) ;
    }
  }
  return \%params ;
}

=pod

=item * split_html_tags()

Replies an array in which each element
is text or HTML tag.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to parse.

=back

=cut
sub split_html_tags($) {
  my $text = $_[0] || '' ;
  my %res = () ;
  while ( ( $text ) &&
          ( $text =~ /^(.*?)<(.*)$/ ) ) {
    my ($prev,$next) = ($1,$2) ;

    add_value_entry( \%res, 'result', "$prev" ) ;

    $text = $next ;
    my $inside = 1 ;
    my $tagcontent = '<' ;

    while ( ( $inside ) && ( $text ) &&
            ( $text =~ /^(.*?)(>|\"|\')(.*)$/ ) ) {
      my ($inprev,$sep,$next) = ($1,$2,$3) ;

      $tagcontent .= "$inprev$sep" ;
      $text = $next ;
      if ( $sep eq ">" ) {
        $inside = 0 ;
      }
      else {
        my $insidetext = 1 ;
        while ( ( $insidetext ) && ( $text ) &&
                ( $text =~ /^(.*?)((?:\\)|$sep)(.*)$/ ) ) {
          my ($intprev,$sepi,$rest) = ($1,$2,$3) ;
	  $tagcontent .= "$intprev$sepi" ;
          if ( $sepi eq '\\' ) {
            $text = substr($rest,1) ;
          }
          else {
            $text = $rest ;
            $insidetext = 0 ;
          }
        }
      }
    }
    add_value_entry( \%res, 'result', $tagcontent ) ;
  }
  if ( $text ) {
    add_value_entry( \%res, 'result', $text ) ;
  }
  return $res{'result'} ;
}

sub __scan_html_text_and_apply($&) {
  my $text = $_[0] || '' ;
  my $res = '' ;
  while ( ( $text ) &&
          ( $text =~ /^(.*?)<(.*)$/ ) ) {
    my ($prev,$next) = ($1,$2) ;

    # Replacement
    &{$_[1]}( $prev ) ;

    $res .= "$prev<" ;
    $text = $next ;
    my $inside = 1 ;
    while ( ( $inside ) && ( $text ) &&
            ( $text =~ /^(.*?)(>|\"|\')(.*)$/ ) ) {
      my ($inprev,$sep,$next) = ($1,$2,$3) ;
      $res .= "$inprev$sep" ;
      $text = $next ;
      if ( $sep eq ">" ) {
        $inside = 0 ;
      }
      else {
        my $insidetext = 1 ;
        while ( ( $insidetext ) && ( $text ) &&
                ( $text =~ /^(.*?)((?:\\)|$sep)(.*)$/ ) ) {
          my ($intprev,$sepi,$rest) = ($1,$2,$3) ;
	  $res .= "$intprev$sepi" ;
          if ( $sepi eq '\\' ) {
            $text = substr($rest,1) ;
          }
          else {
            $text = $rest ;
            $insidetext = 0 ;
          }
        }
      }
    }
  }
  if ( $text ) {

    # Replacement
    &{$_[1]}( $text ) ;

    $res .= $text ;
  }
  return $res ;
}

=pod

=item * html_add_unsecable_spaces()

Replaces the spaces by unsecable spaces inside an HTML string
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub html_add_unsecable_spaces($) {
  return __scan_html_text_and_apply( $_[0],
				     sub { $_[0] =~ s/[ \t\n\r]+/&nbsp;/g ;
					 } ) ;
}

=pod

=item * html_uc()

Upper cases the specified text.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub html_uc($) {
  return __scan_html_text_and_apply( $_[0],
				     sub { $_[0] = __html_uc($_[0]) ;
					 } ) ;
}

sub __html_uc($) {
  my $text = $_[0] || '' ;
  my $res = '' ;
  if ( $text ) {
    while ( ( $text ) &&
	    ( $text =~ /^(.*?)&([^;]+);(.*)$/ ) ) {
      (my $prev,my $tag,$text) = ($1,$2,$3) ;
      $res .= uc( $prev ) ;
      if ( ( $tag =~ /^[a-z]/ ) &&
	   ( exists $HTML_ENTITY_CODES{$tag} ) &&
	   ( exists $HTML_ENTITY_CODES{ucfirst($tag)} ) ) {
	$tag = ucfirst($tag) ;
      }
      $res .= "&".$tag.";" ;
    }
    if ( $text ) {
      $res .= uc( $text ) ;
    }
  }
  return $res ;
}

=pod

=item * html_lc()

Lower cases the specified text.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub html_lc($) {
  return __scan_html_text_and_apply( $_[0],
				     sub { $_[0] = __html_lc($_[0]) ;
					 } ) ;
}

sub __html_lc($) {
  my $text = $_[0] || '' ;
  my $res = '' ;
  if ( $text ) {
    while ( ( $text ) &&
	    ( $text =~ /^(.*?)&([^;]+);(.*)$/ ) ) {
      (my $prev,my $tag,$text) = ($1,$2,$3) ;
      $res .= lc( $prev ) ;
      if ( ( $tag =~ /^[a-z]/ ) &&
	   ( exists $HTML_ENTITY_CODES{$tag} ) &&
	   ( exists $HTML_ENTITY_CODES{lcfirst($tag)} ) ) {
	$tag = lcfirst($tag) ;
      }
      $res .= "&".$tag.";" ;
    }
    if ( $text ) {
      $res .= lc( $text ) ;
    }
  }
  return $res ;
}

=pod

=item * html_ucwords()

Upper cases the first letters of each words.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub html_ucwords($) {
  return __scan_html_text_and_apply( $_[0],
				     sub { $_[0] = __html_ucwords($_[0]) ;
					 } ) ;
}

sub __html_ucwords($) {
  my $text = $_[0] || '' ;
  my $res = '' ;
  while ( $text ) {
    if ( $text =~ /^([_\-\s]*)&([^;]+);([^_\-\s]*)(.*)$/ ) {
      (my $prev,my $tag,my $after,$text) = ($1,$2,$3,$4);
      $res .= $1;
      if ( ( $tag =~ /^[a-z]/ ) &&
	   ( exists $HTML_ENTITY_CODES{$tag} ) &&
	   ( exists $HTML_ENTITY_CODES{ucfirst($tag)} ) ) {
	$tag = ucfirst($tag) ;
      }
      $res .= "&".$tag.";".$after ;
    }
    elsif ( $text =~ /^([_\-\s]*)([^_\-\s]+)(.*)$/ ) {
      (my $prev,my $tag,$text) = ($1,$2,$3);
      $res .= $1;
      $res .= ucfirst($tag);
    }
    else {
      $res .= ucwords($text);
      $text = '';
    }
  }
  return $res ;
}

=pod

=item * html_ucfirst()

Upper cases the first letters of the first word.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub html_ucfirst($) {
  my $found = 0;
  return __scan_html_text_and_apply( $_[0],
				     sub { $_[0] = __html_ucfirst($_[0],\$found) ;
					 } ) ;
}

sub __html_ucfirst($$) {
  my $text = $_[0] || '' ;
  if( !$_[1] ) {
    return $text;
  }
  else {
    my $res = '' ;
    if ( $text =~ /^([_\-\s]*)&([^;]+);([^_\-\s]*)(.*)$/ ) {
      (my $prev,my $tag,my $after,$text) = ($1,$2,$3,$4);
      $res .= $1;
      if ( ( $tag =~ /^[a-z]/ ) &&
	   ( exists $HTML_ENTITY_CODES{$tag} ) &&
	   ( exists $HTML_ENTITY_CODES{ucfirst($tag)} ) ) {
	$tag = ucfirst($tag) ;
      }
      $res .= "&".$tag.";".$after.$text ;
    }
    elsif ( $text =~ /^([_\-\s]*)([^_\-\s]+)(.*)$/ ) {
      (my $prev,my $tag,$text) = ($1,$2,$3);
      $res .= $1;
      $res .= ucfirst($tag).$text;
    }
    else {
      $res .= ucwords($text);
    }
    $_[1] = 1;
    return $res ;
  }
}

=pod

=item * html_sc()

Translates the specified text into small caps
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub html_sc($) {
  my $text = __scan_html_text_and_apply( $_[0],
					 sub { $_[0] = __html_sc($_[0]) ;
					     } ) ;
  $text =~ s/<small><\/small>//g ;
  $text =~ s/<\/small><small>//g ;
  return $text ;
}

sub __html_sc($) {
  my $text = $_[0] || '' ;
  my $res = '' ;
  if ( $text ) {
    while ( ( $text ) &&
	    ( $text =~ /^(.*?)&([^;]+);(.*)$/ ) ) {
      (my $prev,my $tag,$text) = ($1,$2,$3) ;
      $prev =~ s/([a-z]+)/"<small>".uc($1)."<\/small>";/eg ;
      $res .= $prev ;
      if ( ( $tag =~ /^([a-z])/ ) &&
	   ( exists $HTML_ENTITY_CODES{$tag} ) &&
	   ( exists $HTML_ENTITY_CODES{ucfirst($tag)} ) ) {
	$tag = ucfirst($tag) ;
      }
      $res .= "<small>&".$tag.";</small>" ;
    }
    if ( $text ) {
      $text =~ s/([a-z]+)/"<small>".uc($1)."<\/small>";/eg ;
      $res .= $text ;
    }
  }
  return $res ;
}

=pod

=item * nl2br()

Translates newline characters into tags <BR>.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub nl2br($) {
  my $text = $_[0] || '' ;
  $text =~ s/[\n\r]/<BR>\n/g ;
  return $text ;
}

=pod

=item * br2nl()

Translates tags <BR> into newline characters.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub br2nl($) {
  my $text = $_[0] || '' ;
  $text =~ s/<BR\s*\/?>[\n\r]*/\n/g ;
  return $text ;
}

=pod

=item * setAsValidHTML_small()

Merge the "Valid HTML 4.1" small icon to the specified content.
This icon must be copied by the calling generator as the file
'path_to_root/valid-html401.gif'.
Takes 3 args:

=over

=item * text (string)

is a I<string> which correspond to the text to update.

=item * rootdir (string)

is the relative path to the root directory.

=item * valid (array)

is an associative array which content all the validation flags.
The keys are the validated formats: 'html', 'xhtml', 'css'.

=back

=cut
sub setAsValidHTML_small($$@) {
  my $t = \$_[0] ; shift ;
  my $rootdir = shift ;
  my ($html,$xhtml,$css) ;
  foreach my $p (@_) {
    $html = 1 if ( "$p" eq 'html') ;
    $xhtml = 1 if ( "$p" eq 'xhtml') ;
    $css = 1 if ( "$p" eq 'css') ;
  }

  if (($html)||($xhtml)||($css)) {
    $$t .= "<p align=\"right\">" ;
    if ($html) {
      $$t .= join( '',
		   "<a href=\"http://validator.w3.org/check?uri=referer\">",
		   "<img border=\"0\" src=\"",
		   htmlcatfile($rootdir,"valid-html401.gif"),
		   "\" ",
		   "alt=\"Valid HTML 4.01!\" height=\"15\" width=\"44\">",
		   "</a>" ) ;
    }
    if ($css) {
      $$t .= join( '',
		   "<a href=\"http://jigsaw.w3.org/css-validator/\">",
		   "<img style=\"border:0;width:44px;height:15px\" ",
		   "src=\"",
		   htmlcatfile($rootdir,"valid-css.gif"),
		   "\" alt=\"Valid CSS!\">",
		   "</a>" ) ;
    }
    $$t .= "</p>" ;
  }
}

=pod

=item * setAsValidHTML()

Merge the "Valid HTML 4.1" small icon to the specified content.
This icon must be copied by the calling generator as the directory
'path_to_root/'.
Takes 3 args:

=over

=item * text (string)

is a I<string> which correspond to the text to update.

=item * rootdir (string)

is the relative path to the root directory.

=item * valid (array)

is an associative array which content all the validation flags.
The keys are the validated formats: 'html', 'xhtml', 'css'.

=back

=cut
sub setAsValidHTML($$@) {
  my $t = \$_[0] ; shift ;
  my $rootdir = shift ;
  my ($html,$xhtml,$css) ;
  foreach my $p (@_) {
    $html = 1 if ( "$p" eq 'html') ;
    $xhtml = 1 if ( "$p" eq 'xhtml') ;
    $css = 1 if ( "$p" eq 'css') ;
  }

  if (($html)||($xhtml)||($css)) {
    $$t .= "<p align=\"right\">" ;
    if ($html) {
      $$t .= join( '',
		   "<a href=\"http://validator.w3.org/check?uri=referer\">",
		   "<img border=\"0\" src=\"",
		   htmlcatfile($rootdir,"valid-html401.gif"),
		   "\" ",
		   "alt=\"Valid HTML 4.01!\" height=\"31\" width=\"88\">",
		   "</a>" ) ;
    }
    if ($css) {
      $$t .= join( '',
		   "<a href=\"http://jigsaw.w3.org/css-validator/\">",
		   "<img style=\"border:0;width:88px;height:31px\" ",
		   "src=\"",
		   htmlcatfile($rootdir,"valid-css.gif"),
		   "\" alt=\"Valid CSS!\">",
		   "</a>" ) ;
    }
    $$t .= "</p>" ;
  }
}

=pod

=item * html_getinitiales()

Replies the initiales of the specified text
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub html_getinitiales($) {
  my $text = $_[0] || '' ;
  return __scan_html_text_and_apply( $text,
				     sub { $_[0] = __html_getinitiales($_[0]) ;
					 } ) ;
}

# TODO: leave the '-' inside the returned initials.
sub __html_getinitiales($) {
  my $text = $_[0] || '' ;
  my $res = '' ;
  while ( $text ) {
    if ( $text =~ /^[_\.\-\s]*&([^;]+);([\.\-])(.*)$/ ) {
      # Name's initial starting with an accentuated letter
      (my $tag,my $sep,$text) = ($1,$2,$3);
      if ( exists $HTML_ENTITY_CODES{$tag} ) {
        $res .= "&".$tag.";$sep" ;
      }
    }
    elsif ( $text =~ /^[_\.\-\s]*([^&\s\-\._])([\.\-])(.*)$/ ) {
      # Name's initial starting with an accentuated letter
      (my $tag,my $sep,$text) = ($1,$2,$3);
      $res .= "$tag$sep";
    }
    elsif ( $text =~ /^[_\.\-\s]*&([^;]+);[^\s\-\._]*(.*)$/ ) {
      # Long name starting with an accentuated letter
      (my $tag,$text) = ($1,$2);
      if ( exists $HTML_ENTITY_CODES{$tag} ) {
        $res .= "&".$tag.";." ;
      }
    }
    elsif ( $text =~ /^[_\.\-\s]*([^&\s\-\._])[^\s\-\._]*(.*)$/ ) {
      # Long name starting with a not-accentuated letter
      (my $tag,$text) = ($1,$2);
      $res .= $tag.".";
    }
    else {
      $text = '';
    }
  }
  return $res ;
}

=pod

=item * html_substr()

Replies a substring of the specified text
Takes 3 args:

=over

=item * text (string)

=item * start (optional integer)

=item * length (optional integer)

=back

=cut
sub html_substr($;$$) {
  my $text = $_[0] || '' ;
  my $startpos = $_[1] || 0;
  my $length = $_[2] || -1;
  return __scan_html_text_and_apply( $text,
				     sub { $_[0] = __html_substr($_[0],$startpos,$length) ;
					 } ) ;
}

sub __html_substr($$$) {
  my ($text,$pos,$length) = ($_[0],$_[1],$_[2]);
  my @chars = html_split_to_chars($text);
  $pos = @chars + $pos if ($pos<0);
  $pos = @chars if ($pos>@chars);
  $length = @chars if ($length<0);
  my @res = ();
  for(my $i=$pos; ($i<@chars)&&($i<($pos+$length)); $i++) {
    push @res, $chars[$i];
  }
  return join('',@res);
}

=pod

=item * html_split_chars()

Replies an array of the characters in the given HTML string.
Takes 1 arg:

=over

=item * text (string)

an HTML string without HTML tags

=back

=cut

sub html_split_to_chars($) {
  my @chars = ();
  while ($_[0] =~ /((?:&[^;]+;)|(?:[^&]))/g) {
    push @chars, "$1";
  }
  return @chars;
}

=pod

=item * sortbyletters(@)

Sort by letter the specified parameter and
replies it.
Takes 1 arg:

=over

=item * array (string)

=back

=cut
sub sortbyletters(\@) {
  return sort {
    my $elt1 = remove_html_accents($a || "");
    my $elt2 = remove_html_accents($b || "");
    $elt1 =~ s/[^a-zA-Z0-9]//g;
    $elt2 =~ s/[^a-zA-Z0-9]//g;
    return ($elt1 cmp $elt2);
  } @{$_[0]};
}

=pod

=item * remove_html_accents($)

Remove the accents from the given html strings.
Takes 1 arg:

=over

=item * str (string)

=back

=cut
sub remove_html_accents($) {
  my $orig = shift | '';
  my $trans = "$orig";
  while (my ($html,$code) = each(%HTML_ENTITY_CODES)) {
	$trans =~ s/\&\#\Q$code\E;/$HTML_NO_ACCENT_ENTITY_CHARS{$html}/gs;
  }
  while (my ($html,$letter) = each(%HTML_NO_ACCENT_ENTITY_CHARS)) {
	$trans =~ s/\&\Q$html\E;/$letter/gs;
  }
  return "$trans";
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

phpdocgen.pl
