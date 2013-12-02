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

Bib2HTML::Translator::TeX - A translator from TeX to HTML

=head1 SYNOPSYS

use Bib2HTML::Translator::BibTeX ;

my $gen = Bib2HTML::Translator::TeX->new( filename ) ;

=head1 DESCRIPTION

Bib2HTML::Translator::TeX is a Perl module, which translate a
TeX string into an HTML string

=head1 GETTING STARTED

=head2 Initialization

To create a parser, say something like this:

    use Bib2HTML::Translator::TeX;

    my $parser = Bib2HTML::Translator::TeX->new( 'toto.bib', '<math>', '</math>' ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * filename (string)

is the filename under parsing.

=item * start_math (optional string)

is the HTML balise which permits to start the math mode

=item * stop_math (optional string)

is the HTML balise which permits to stop the math mode

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Parser.pm itself.

=over

=cut

package Bib2HTML::Translator::TeX;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw( &addtrans_char &gettrans_char
		 &addtrans_cmd_noparam &addtrans_cmd
		 &addtrans_cmd_func &gettrans_cmd
		 &display_supported_commands );

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

use Bib2HTML::General::Misc ;
use Bib2HTML::General::HTML ;
use Bib2HTML::General::Error ;
use Bib2HTML::General::Verbose ;
use Bib2HTML::Translator::BibTeXEntry ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the parser
my $VERSION = "3.0" ;

###############################################################
# This is the list of characters which will be automatically
# and directly translatable into a HTML entity
#
my %TEX_HTML_CHAR_TRANS = ( '~' => '&nbsp;', #unsecable space
			    '£' => '&pound;', #pound sign
			    '¤' => '&curren;', #currency sign
			    '|' => '&brvbar', #broken bar = broken vertical bar
			    '§' => '&sect;', #section sign
			    '°' => '&deg;', #degree sign
			    '²' => '&sup2;', #superscript two = superscript digit two = squared
			    'µ' => '&micro;', #micro sign
			    'À' => '&Agrave;', #latin capital letter A with grave = latin capital letter A grave
			    'Á' => '&Aacute;', #latin capital letter A with acute
			    'Â' => '&Acirc;', #latin capital letter A with circumflex
			    'Ã' => '&Atilde;', #latin capital letter A with tilde
			    'Ä' => '&Auml;', #latin capital letter A with diaeresis
			    'Å' => '&Aring;', #latin capital letter A with ring above = latin capital letter A ring
			    'Æ' => '&AElig;', #latin capital letter AE = latin capital ligature AE
			    'Ç' => '&Ccedil;', #latin capital letter C with cedilla
			    'È' => '&Egrave;', #latin capital letter E with grave
			    'É' => '&Eacute;', #latin capital letter E with acute
			    'Ê' => '&Ecirc;', #latin capital letter E with circumflex
			    'Ë' => '&Euml;', #latin capital letter E with diaeresis
			    'Ì' => '&Igrave;', #latin capital letter I with grave
			    'Í' => '&Iacute;', #latin capital letter I with acute
			    'Î' => '&Icirc;', #latin capital letter I with circumflex
			    'Ï' => '&Iuml;', #latin capital letter I with diaeresis
			    'Ñ' => '&Ntilde;', #latin capital letter N with tilde
			    'Ò' => '&Ograve;', #latin capital letter O with grave
			    'Ó' => '&Oacute;', #latin capital letter O with acute
			    'Ô' => '&Ocirc;', #latin capital letter O with circumflex
			    'Õ' => '&Otilde;', #latin capital letter O with tilde
			    'Ö' => '&Ouml;', #latin capital letter O with diaeresis
			    'Ø' => '&Oslash;', #latin capital letter O with stroke = latin capital letter O slash
			    'Ù' => '&Ugrave;', #latin capital letter U with grave
			    'Ú' => '&Uacute;', #latin capital letter U with acute
			    'Û' => '&Ucirc;', #latin capital letter U with circumflex
			    'Ü' => '&Uuml;', #latin capital letter U with diaeresis
			    'Ý' => '&Yacute;', #latin capital letter Y with acute
			    'à' => '&agrave;', #latin small letter a with grave = latin small letter a grave
			    'á' => '&aacute;', #latin small letter a with acute
			    'â' => '&acirc;', #latin small letter a with circumflex
			    'ã' => '&atilde;', #latin small letter a with tilde
			    'ä' => '&auml;', #latin small letter a with diaeresis
			    'å' => '&aring;', #latin small letter a with ring above = latin small letter a ring
			    'æ' => '&aelig;', #latin small letter ae = latin small ligature ae
			    'ç' => '&ccedil;', #latin small letter c with cedilla
			    'è' => '&egrave;', #latin small letter e with grave
			    'é' => '&eacute;', #latin small letter e with acute
			    'ê' => '&ecirc;', #latin small letter e with circumflex
			    'ë' => '&euml;', #latin small letter e with diaeresis
			    'ì' => '&igrave;', #latin small letter i with grave
			    'í' => '&iacute;', #latin small letter i with acute
			    'î' => '&icirc;', #latin small letter i with circumflex
			    'ï' => '&iuml;', #latin small letter i with diaeresis
			    'ñ' => '&ntilde;', #latin small letter n with tilde
			    'ò' => '&ograve;', #latin small letter o with grave
			    'ó' => '&oacute;', #latin small letter o with acute
			    'ô' => '&ocirc;', #latin small letter o with circumflex
			    'õ' => '&otilde;', #latin small letter o with tilde
			    'ö' => '&ouml;', #latin small letter o with diaeresis
			    'ø' => '&oslash;', #latin small letter o with stroke = latin small letter o slash
			    'ù' => '&ugrave;', #latin small letter u with grave
			    'ú' => '&uacute;', #latin small letter u with acute
			    'û' => '&ucirc;', #latin small letter u with circumflex
			    'ü' => '&uuml;', #latin small letter u with diaeresis
			    'ý' => '&yacute;', #latin small letter y with acute
			    'ÿ' => '&yuml;', #latin small letter y with diaeresis
			    '"' => '&quot;', #quotation mark = APL quote
			    '^' => '&circ;', #modifier letter circumflex accent
			    '<' => '&lt;', #less-than sign
			    '>' => '&gt;', #greater-than sign
			  ) ;

###############################################################
# This is the list of text-mode commands.
# The commands must respect one of the following formats:
# 1) 'TeXCmdName' => "HTML code"
#       permits to translate the LaTeX command \TeXCmdName
#       into the specified "HTML code".
# 2) 'TeXCmdName' => { 'params' => params
#                      'html' => "HTML code"
#                    }
#         replaces the command \TeXCmdName by the specified
#         "HTML code". This last could contains a parameter
#         number (eg, #1 for the first, #2 for the second,
#         etc.) which will be replaced by the value
#         passed to the LaTeX command. The params specifies
#         the parameter prototype of the LaTeX command. It
#         must contains one (or more) of:
#         {}     for a needed parameter
#         [d]    for an optional parameter. d
#                is the default value given to this parameter
#                if it was not provided inside the LaTeX code
#         \\     for a LaTeX command name
#         !      indicates that the following sign ({} or[])
#                must not be interpreted by the LaTeX
#                translator. It must be used for verbatim
#                output
#         -      to read the text until the end of the current
#                LaTeX context
# 3) 'TeXCmdName' => { 'params' => params
#                      'latex' => "LaTeX code"
#                    }
#         replaces the command \TeXCmdName by the specified
#         "LaTeX code". This last could contains a parameter
#         number (eg, #1 for the first, #2 for the second,
#         etc.)  which will be replaced by the value
#         passed to the LaTeX command. The params specifies
#         the parameter prototype of the LaTeX command. It
#         must contains one (or more) of the macros defined
#         in the point 2).
# 4) 'TeXCmdName' => { 'params' => params
#                      'func' => "callback_function_name"
#                    }
#         replaces the command \TeXCmdName by the result of
#         the specified callback function. This callback
#         function must take, at least, 1 parameters:
#         the current line number. The parameters of the
#         LaTeX command will be passed to this callback
#         function after this line number.
#         Example: for \newcommand{\cmdname}[4][default]{code #2}
#                  we implements the callback function:
#                  sub texcommand_newcommand {
#                    my $lineno = shift || 0 ;
#                    my ($cmdname,$nb_params) =
#                       ( $_[0], $_[1] || 0 ) ;
#                    my ($default,$code) =
#                       ($_[2] || '', $_[3] || '') ;
#                    ...
#                    return '' ;
#                  }
#         The params specifies the parameter prototype of
#         the LaTeX command. It must contains one (or more)
#         of the macros defined in the point 2).
# 5) 'TeXCmdName' => { 'params' => params
#                      'texfunc' => "callback_function_name"
#                    }
#         replaces the command \TeXCmdName by the result of
#         the specified callback function. The callback
#         must assume that its result was some LaTeX expression
#         which will be evaluated (this is the major difference
#         between a 'func' and a 'texfunc', VERY IMPORTANT point).
#         The callback function works same as for 'func' (point 4).
#
my %TEX_HTML_COMMANDS = (

			 ' '                 => ' ',
			 '_'                 => '_', # underline sign
			 '-'                 => '', # hyphenation sign
			 '$'                 => '\$',
			 ','                 => '&nbsp;',
			 ';'                 => '&nbsp;',
			 '%'                 => '%',
			 '}'                 => '}',
			 '{'                 => '{',
			 '&'                 => '&amp;',
			 '\\'                => '<br>',
			 '&'                 => '&amp;', #ampersand
			 # Patch by Norbert Preining added the 2003/03/17
			 '#'		     => '#',
			 '\''                => { 'params' => '{}',
						  'func' => 'texcommand_acute',
						},
			 '`'                 => { 'params' => '{}',
						  'func' => 'texcommand_grave',
						},
			 '~'                 => { 'params' => '{}',
						  'func' => 'texcommand_tilde',
						},
			 '"'                 => { 'params' => '{}',
						  'func' => 'texcommand_uml',
						},
			 '^'                 => { 'params' => '{}',
						  'func' => 'texcommand_circ',
						},
			 '='                 => { 'params' => '{}', # One parameter
						  'func' => 'texcommand_bar',
						},
			 'AA'                => '&Aring;',
			 'aa'                => '&aring;',
			 'AE'                => '&AElig;', #latin small letter ae = latin small ligature ae
			 'ae'                => '&aelig;', #latin small letter ae = latin small ligature ae
			 'begin'             => { 'params' => '!{}', # Start environment
						  'texfunc' => 'texcommand_beginenv',
						},
			 'backslash'         => '\\',
			 'beginblock'        => '', # Ignored
			 'bf'                => { 'params' => '-', # Bold font
						  'func' => 'texcommand_font_bold',
						},
			 'bfseries'          => { 'params' => '-', # Bold font
						  'func' => 'texcommand_font_bold',
						},
			 'BibtoHTML'         => 'B<small>IB</small>2HTML', # Bib2HTML logo
			 'bibtohtml'         => 'B<small>IB</small>2HTML', # Bib2HTML logo
			 'BibTeX'            => 'B<small>IB</small>T<small>E</small>X', # BibTeX logo
			 'c'                 => { 'params' => '{}',
					          'func' => 'texcommand_cedil',
						},
			 'cdot'              => '&middot;', #middle dot = Georgian comma = Greek middle dot
			 'cite'              => { 'params' => '[]{}',
						  'func' => 'texcommand_cite',
						},
			 'def'               => { 'params' => '\\{}',
						  'func' => 'texcommand_def',
						},
			 'degree'            => '&deg;', #degree sign
			 'dg'                => '&eth;', #latin small letter eth
			 'DH'                => '&ETH;', #latin capital letter ETH
			 'div'               => '&divide;', #division sign
			 'edef'              => { 'params' => '\\{}',
						  'func' => 'texcommand_edef',
						},
			 'Emph'              => { 'params' => '{}',
						  'html' => '<strong>#1</strong>',
						},
			 'em'                => { 'params' => '-', # Emphasis
						  'html' => "<em>#1</em>",
						},
			 'emph'              => { 'params' => '{}', # Emphasis
						  'html' => '<em>#1</em>',
						},
			 'end'               => { 'params' => '!{}', # End environment
						  'texfunc' => 'texcommand_endenv',
						},
			 'enditemize'        => '</UL>',
			 'ensuremath'        => { 'params' => '{}',
						  'func' => 'texcommand_ensuremath',
						},
			 'footnotesize'      => { 'params' => '-',
						  'html' => "<font size=\"-2\">#1</font>",
						},
			 'gdef'              => { 'params' => '\\{}',
						  'func' => 'texcommand_def',
						},
			 'global'            => '', # ignored
			 'guillemotleft'     => '&laquo;', #left-pointing double angle quotation mark
			 'guillemotright'    => '&raquo;', #right-pointing double angle quotation mark = right pointing guillemet
			 'Huge'              => { 'params' => '-',
						  'html' => "<font size=\"+5\">#1</font>",
						},
			 'html'              => { 'params' => '!{}', # verbatim HTML code
						  'html' => '#1',
						},
			 'huge'              => { 'params' => '-',
						  'html' => "<font size=\"+4\">#1</font>",
						},
			 'i'                 => 'i',
			 'it'                => { 'params' => '-', # Italic font
						  'func' => 'texcommand_font_italic',
						},
			 'item'              => '<LI>',
			 'itshape'           => { 'params' => '-', # Italic font
						  'func' => 'texcommand_font_italic',
						},
			 # Patch by Norbert Preining added the 2003/03/17
			 'L'		     => 'L', # L bar
			 'LARGE'             => { 'params' => '-',
						  'html' => "<font size=\"+3\">#1</font>",
						},
			 'Large'             => { 'params' => '-',
						  'html' => "<font size=\"+2\">#1</font>",
						},
			 'LaTeX'             => 'L<sup><small>A</small></sup>T<small>E</small>X', # LaTeX logo
			 'large'             => { 'params' => '-',
						  'html' => "<font size=\"+1\">#1</font>",
						},
			 'latex'             => { 'params' => '{}', # Ignore the LaTeX commands
						  'html' => '',
						},
			 'lnot'              => '&not;', #not sign
			 'mdseries'          => { 'params' => '-', # Unbold Font
						  'func' => 'texcommand_font_medium',
						},
			 'newcommand'        => { 'params' => '{}[][]{}',
						  'func' => 'texcommand_newcommand',
						},
			 'normalfont'        => { 'params' => '-',
						  'func' => 'texcommand_font_normal',
						},
			 'normalsize'        => { 'params' => '-',
						  'html' => "<font size=\"+0\">#1</font>",
						},
			 'O'                 => '&Oslash;',
			 'o'                 => '&oslash;',
			 'OE'                => '&OElig;', #latin capital ligature OE
			 'oe'                => '&oelig;', #latin small ligature oe
			 'P'                 => '&para;', #pilcrow sign = paragraph sign
			 'pm'                => '&plusmn;', #plus-minus sign = plus-or-minus sign
			 'pounds'            => '&pounds;', #pound sign
			 'renewcommand'      => { 'params' => '{}[][]{}',
						  'func' => 'texcommand_newcommand',
						},
			 'rm'                => { 'params' => '-', # Roman font
						  'func' => "texcommand_font_roman",
						},
			 'rmfamily'          => { 'params' => '-', # Roman font
						  'func' => "texcommand_font_roman",
						},
			 'S'                 => '&sect;', #section sign
			 'sc'                => { 'params' => '-', # Small-caps font
						  'func' => "texcommand_font_smallcap",
						},
			 'scriptsize'        => { 'params' => '-',
						  'html' => "<font size=\"-3\">#1</font>",
						},
			 'scshape'           => { 'params' => '-', # Small-caps font
						  'func' => "texcommand_font_smallcap",
						},
			 'sf'                => { 'params' => '-', # Sans Serif font
						  'func' => "texcommand_font_serif",
						},
			 'sffamily'          => { 'params' => '-', # Sans Serif font
						  'func' => "texcommand_font_serif",
						},
			 'sl'                => { 'params' => '-', # Slanted font
						  'func' => "texcommand_font_slanted",
						},
			 'slshape'           => { 'params' => '-', # Slanted font
						  'func' => "texcommand_font_slanted",
						},
			 'small'             => { 'params' => '-',
						  'html' => "<font size=\"-1\">#1</font>",
						},
			 'ss'                => '&szlig;', #latin small letter sharp s = ess-zed
			 'startblock'        => '', # Ignored
			 'startitemize'      => '<UL>',
			 'string'            => { 'params' => '{}',
						  'html' => "#1",
						},
			 'TeX'               => 'T<small>E</small>X', # TeX logo
			 'text'              => { 'params' => '{}',
						  'func' => 'texcommand_ensuretext',
						},
			 'textasciicircum'   => '&circ;', # circumflex accent sign
			 'textasciitilde'    => '~', # tilde sign
			 'textbackslash'     => '\\',
			 'textbf'            => { 'params' => '{}', # Bold font
						  'func' => 'texcommand_font_bold',
						},
			 'textbrokenbar'     => '&brvbar;', #broken bar = broken vertical bar
			 'textcent'          => '&cent;', #cent sign
			 'textcopyright'     => '&copy;', #copyright sign
			 'textcurrency'      => '&curren;', #currency sign
			 'textexcladown'     => '&iexcl;', #inverted exclamation mark, U+00A1 ISOnum
			 'textit'            => { 'params' => '{}', # Italic Font
						  'func' => 'texcommand_font_italic',
						},
			 'textmd'            => { 'params' => '{}', # Unbold Font
						  'func' => 'texcommand_font_medium',
						},
			 'textnormal'        => { 'params' => '{}',
						  'func' => 'texcommand_font_normal',
						},
			 'textonehalf'       => '&frac12;', #vulgar fraction one half = fraction one half
			 'textonequarter'    => '&frac14;', #vulgar fraction one quarter = fraction one quarter
			 'textordfeminine'   => '&ordf;', #feminine ordinal indicator
			 'textordmasculine'  => '&ordm;', #masculine ordinal indicator
			 'textquestiondown'  => '&iquest;', #inverted question mark = turned question mark
			 'textregistered'    => '&reg;', #registered sign = registered trade mark sign
			 'textrm'            => { 'params' => '{}', # Roman Font
						  'func' => 'texcommand_font_roman',
						},
			 'textsc'            => { 'params' => '{}', # Small-caps Font
						  'func' => 'texcommand_font_smallcap',
						},
			 'textsf'            => { 'params' => '{}', # Sans Serif Font
						  'func' => 'texcommand_font_serif',
						},
			 'textsl'            => { 'params' => '{}', # Slanted Font
						  'func' => 'texcommand_font_slanted',
						},
			 'textthreequarters' => '&frac34;', #vulgar fraction three quarters = fraction three quarters
			 'texttt'            => { 'params' => '{}',
						  'func' => 'texcommand_font_typewriter',
						},
			 'textup'            => { 'params' => '{}', # Up right font
						  'func' => 'texcommand_font_upright',
						},
			 'textyen'           => '&yen;', #yen sign = yuan sign
			 'times'             => '&times;', #multiplication sign
			 'tiny'              => { 'params' => '-',
						  'html' => "<font size=\"-4\">#1</font>",
						},
			 'TH'                => '&THORN;', #latin capital letter THORN
			 'th'                => '&thorn;', #latin small letter thorn
			 'tt'                => { 'params' => '-', # Typewriter font
						  'func' => "texcommand_font_typewriter",
						},
			 'ttfamily'          => { 'params' => '-', # Type writer font
						  'func' => 'texcommand_font_typewriter',
						},
			 'u'                 => { 'params' => '{}', # added by Tobia
					          'func' => 'texcommand_ucircle',
						},
			 'uline'             => { 'params' => '{}', # Underline font
						  'html' => "<u>#1</u>",
						},
			 'upshape'           => { 'params' => '{}', # Up right font
						  'func' => 'texcommand_font_upright',
						},
			 'url'               => { 'params' => '{}', # URL hyperlink
						  'html' => "<a=\"#1\">#1</a>",
						},
			 'v'                 => { 'params' => '{}',
						  'func' => 'texcommand_caron',
						},
			 'xdef'              => { 'params' => '\\{}',
						  'func' => 'texcommand_edef',
						},

			) ;

###############################################################
# This is the list of math-mode commands.
# The commands must respect one of the following formats:
# 1) 'TeXCmdName' => "HTML code"
#       permits to translate the LaTeX command \TeXCmdName
#       into the specified "HTML code".
# 2) 'TeXCmdName' => { 'params' => params
#                      'html' => "HTML code"
#                    }
#         replaces the command \TeXCmdName by the specified
#         "HTML code". This last could contains a parameter
#         number (eg, #1 for the first, #2 for the second,
#         etc.) which will be replaced by the value
#         passed to the LaTeX command. The params specifies
#         the parameter prototype of the LaTeX command. It
#         must contains one (or more) of:
#         {}     for a needed parameter
#         [d]    for an optional parameter. d
#                is the default value given to this parameter
#                if it was not provided inside the LaTeX code
#         \\     for a LaTeX command name
#         !      indicates that the following sign ({} or[])
#                must not be interpreted by the LaTeX
#                translator. It must be used for verbatim
#                output
#         -      to read the text until the end of the current
#                LaTeX context
# 3) 'TeXCmdName' => { 'params' => params
#                      'latex' => "LaTeX code"
#                    }
#         replaces the command \TeXCmdName by the specified
#         "LaTeX code". This last could contains a parameter
#         number (eg, #1 for the first, #2 for the second,
#         etc.)  which will be replaced by the value
#         passed to the LaTeX command. The params specifies
#         the parameter prototype of the LaTeX command. It
#         must contains one (or more) of the macros defined
#         in the point 2).
# 3) 'TeXCmdName' => { 'params' => params
#                      'func' => "callback_function_name"
#                    }
#         replaces the command \TeXCmdName by the result of
#         the specified callback function. This callback
#         function must take, at least, 1 parameters:
#         the current line number. The parameters of the
#         LaTeX command will be passed to this callback
#         function after this line number.
#         Example: for \newcommand{\cmdname}[4][default]{code #2}
#                  we implements the callback function:
#                  sub texcommand_newcommand {
#                    my $lineno = shift || 0 ;
#                    my ($cmdname,$nb_params) =
#                       ( $_[0], $_[1] || 0 ) ;
#                    my ($default,$code) =
#                       ($_[2] || '', $_[3] || '') ;
#                    ...
#                    return '' ;
#                  }
#         The params specifies the parameter prototype of
#         the LaTeX command. It must contains one (or more)
#         of the macros defined in the point 2).
# 4) 'TeXCmdName' => { 'params' => params
#                      'texfunc' => "callback_function_name"
#                    }
#         replaces the command \TeXCmdName by the result of
#         the specified callback function. The callback
#         must assume that its result was some LaTeX expression
#         which will be evaluated (this is the major difference
#         between a 'func' and a 'texfunc', VERY IMPORTANT point).
#         The callback function works same as for 'func' (point 3).
#
my %MATH_TEX_HTML_COMMANDS = (

			      '}'                 => '}',
			      '{'                 => '{',
			      '&'                 => '&amp;',
			      '_'                 => { 'params' => "{}",
						       'html' => "<sub>#1</sub>",
						       'special' => 1,
						     },
			      '^'                 => { 'params' => "{}",
						       'html' => "<sup class=\"exponent\">#1</sup>",
						       'special' => 1,
						     },

			      'mathmicro'         => '&micro;', #micro sign
			      'maththreesuperior' => '&sup3;', #superscript three = superscript digit three = cubed
			      'mathtwosuperior'   => '&sup2;', #superscript two = superscript digit two = squared

			      # MATH-ML commands
			      'alpha' => "&alpha;",
			      'angle' => "&ang;",
			      'approx' => "&asymp;",
			      'ast' => "&lowast;",
			      'beta' => "&beta;",
			      'bot' => "&perp;",
			      'bullet' => "&bull;",
			      'cap' => "&cap;",
			      'cdots' => "&hellip;",
			      'chi' => "&chi;",
			      'clubsuit' => "&clubs;",
			      'cong' => "&cong;",
			      'cup' => "&cup;",
			      'dagger' => "&dagger;",
			      'ddagger' => "&Dagger;",
			      'delta' => "&delta;",
			      'Delta' => "&Delta;",
			      'diamondsuit' => "&loz;",
			      'div' => "&divide;",
			      'downarrow' => "&darr;",
			      'Downarrow' => "&dArr;",
			      'emptyset' => "&empty;",
			      'epsilon' => "&epsilon;",
			      'Epsilon' => "&Epsilon;",
			      'equiv' => "&equiv;",
			      'eta' => "&eta;",
			      'exists' => "&exist;",
			      'forall' => "&forall;",
			      'gamma' => "&gamma;",
			      'Gamma' => "&Gamma;",
			      'geq' => "&ge;",
			      'heartsuit' => "&hearts;",
			      'Im' => "&image;",
			      'in' => "&isin;",
			      'infty' => "&infin;",
			      'infinity' => "&infin;",
			      'int' => "&int;",
			      'iota' => "&iota;",
			      'kappa' => "&kappa;",
			      'lambda' => "&lambda;",
			      'Lambda' => "&Lambda;",
			      'langle' => "&lang;",
			      'lceil' => "&lceil;",
			      'ldots' => "&hellip;",
			      'leftarrow' => "&larr;",
			      'Leftarrow' => "&lArr;",
			      'leftrightarrow' => "&harr;",
			      'Leftrightarrow' => "&hArr;",
			      'leq' => "&le;",
			      'lfloor' => "&lfloor;",
			      'mathbb'  => { 'params' => '{}', # Math Set characters
					     'func' => 'texcommand_font_mathset',
					   },
			      'mathbf'  => { 'params' => '{}', # Bold font
					     'func' => 'texcommand_font_bold',
					   },
			      'mathit'  => { 'params' => '{}', # Italic Font
				 	     'func' => 'texcommand_font_italic',
				    	   },
			      'mathrm'  => { 'params' => '{}', # Roman Font
				             'func' => 'texcommand_font_roman',
					   },
			      'mathsf'	=> { 'params' => '{}', # Sans Serif Font
			                     'func' => 'texcommand_font_serif',
			                   },
			      'mathtt'  => { 'params' => '{}',
			                     'func' => 'texcommand_font_typewriter',
					   },
			      'mathnormal'  => { 'params' => '{}',
					         'func' => 'texcommand_font_normal',
						},
			      'mu' => "&mu;",
			      'nabla' => "&nabla;",
			      'neg' => "&not;",
			      'neq' => "&ne;",
			      'ni' => "&ni;",
			      'not\in' => "&notin;",
			      'not\subset' => "&nsub;",
			      'nu' => "&nu;",
			      'omega' => "&omega;",
			      'Omega' => "&Omega;",
			      'ominus' => "&ominus;",
			      'oplus' => "&oplus;",
			      'oslash' => "&oslash;",
			      'Oslash' => "&Oslash;",
			      'otimes' => "&otimes;",
			      'partial' => "&part;",
			      'phi' => "&phi;",
			      'Phi' => "&Phi;",
			      'pi' => "&pi;",
			      'Pi' => "&Pi;",
			      'pm' => "&plusmn;",
			      'prime' => "&prime;",
			      'prod' => "&prod;",
			      'propto' => "&prop;",
			      'psi' => "&psi;",
			      'Psi' => "&Psi;",
			      'rangle' => "&rang;",
			      'rceil' => "&rceil;",
			      'Re' => "&real;",
			      'rfloor' => "&rfloor;",
			      'rho' => "&rho;",
			      'rightarrow' => "&rarr;",
			      'Rightarrow' => "&rArr;",
			      'sigma' => "&sigma;",
			      'Sigma' => "&Sigma;",
			      'sim' => "&sim;",
			      'spadesuit' => "&spades;",
			      'sqrt' => "&radic;",
			      'subseteq' => "&sube;",
			      'subset' => "&sub;",
			      'sum' => "&sum;",
			      'supseteq' => "&supe;",
			      'supset' => "&sup;",
			      'surd' => "&radic;",
			      'tau' => "&tau;",
			      'theta' => "&theta;",
			      'Theta' => "&Theta;",
			      'times' => "&times;",
			      'to' => "&rarr;",
			      'uparrow' => "&uarr;",
			      'Uparrow' => "&uArr;",
			      'upsilon' => "&upsilon;",
			      'Upsilon' => "&Upsilon;",
			      'varpi' => "&piv;",
			      'vee' => "&or;",
			      'wedge' => "&and;",
			      'wp' => "&weierp;",
			      'xi' => "&xi;",
			      'Xi' => "&Xi;",
			      'zeta' => "&zeta;",

			     ) ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($;$$) : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto ;

  my $self ;
  if ( $parent ) {
    %{$self} = %{$parent} ;
  }
  else {
    $self = { 'FILENAME' => $_[0] || '',
	      'DATABASE' => undef,
	      'MATH_MODE' => 0,
	      'MATH_MODE_START' => $_[2] || "<math>",
	      'MATH_MODE_STOP' => $_[3] || "</math>",
	      'FONTS' => { 'ALLS' => [],
			   'SERIES' => [],
			   'FAMILIES' => [],
			   'SHAPES' => [],
			 },
	      'ENVIRONMENTS' => [],
	    } ;
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Translation API
#
#------------------------------------------------------

=pod

=item * translate()

Translate the specified string from a TeX string to
an HTML string
Takes 3 args:

=over

=item * text (string)

is the text to translate

=item * database (hash)

is the complee database content.

=item * lineno (optional integer)

is the line number where the text can be found

=back

=cut
sub translate($$;$) : method {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my $lineno = $_[2] || 0 ;
  my $html = '' ;

  if ( $_[1] ) {
    $self->{'DATABASE'} = $_[1] ;
  }

  # Search the first separator
  my ($eaten,$sep,$tex) = $self->eat_to_separator($text) ;

  while ($sep) {

    # Translate the already eaten string
    $eaten = $self->translate_chars( $eaten, $lineno ) ;

    if ( ( $sep eq '{' ) || ( $sep eq '}' ) ) {
      # Ignore braces
    }
    elsif ( $sep eq '\\' ) {
      (my $eaten2,$tex) = $self->translate_cmd($tex, $lineno, '\\') ;
      $eaten .= $eaten2 ;
    }
    elsif ( $sep eq '$' ) {
      # Math mode
      if ( ! $self->is_math_mode() ) {
	$eaten .= $self->start_math_mode(1) ;
      }
      elsif ( $self->is_inline_math_mode() ) {
	$eaten .= $self->stop_math_mode() ;
      }
      else {
	Bib2HTML::General::Error::warm( "you try to close with a '\$' a mathematical mode opened with '\\['",
					$self->{'FILENAME'},
					$lineno ) ;
      }
    }
    elsif ( ( $sep eq '_' ) ||
	    ( $sep eq '^' ) ) {
      # Special math mode commands
      (my $eaten2,$tex) = $self->translate_cmd($sep.$tex, $lineno ) ;
      $eaten .= $eaten2 ;
    }
    else { # Unknow separator, treat as text
      $eaten .= $self->translate_chars( $sep, $lineno ) ;
    }

    # Translate the text before the separator
    $html .= $eaten ;

    # Search the next separator
    ($eaten,$sep,$tex) = $self->eat_to_separator($tex) ;
  }

  if ( $eaten ) {
    $html .= $self->translate_chars( $eaten, $lineno ) ;
  }

  # Remove multiple white spaces
  $html =~ s/ +/ /g ;

  return $html ;
}

=pod

=item * eat_to_separator()

Eats the specified text until the first separator.
Takes 2 args:

=over

=item * text (string)

is the text to eat

=item * seps (optional string)

is the list of additional separators

=back

=cut
sub eat_to_separator($;$) : method {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my $separators = $_[1] || '' ;
  my ($before,$sep,$after) ;

  $separators .= "_^{}\$\\\\" ;

  if ( $text =~ /^(.*?)([$separators])(.*)$/ ) {
    ($before,$sep,$after) = ($1,$2,$3) ;
  }
  else {
    $before = $text ;
    $sep = $after = '' ;
  }
  return ($before,$sep,$after) ;
}

=pod

=item * translate_chars()

Translate the chars inside the specified string.
Takes 2 args:

=over

=item * text (string)

is the text to translate

=item * lineno (integer)

=back

=cut
sub translate_chars($$) : method {
  my $self = shift ;
  my $html = $_[0] || '' ;
  my $lineno = $_[1] || 0 ;
  my @parts = split( /\&/, $html ) ;
  for(my $i=0; $i<@parts; $i++) {
    # Translate from the trans table
    while ( my ($char,$hstr) = each( %TEX_HTML_CHAR_TRANS ) ) {
      if ( $i > 0 ) {
	Bib2HTML::General::Error::warm( "you type a '\&'. It could be a LaTeX syntax error. Assume '\\&'.",
					$self->{'FILENAME'}, $lineno ) ;
      }
      $parts[$i] =~ s/\Q$char\E/$hstr/g ;
    }
  }
  $html = join( '&amp;', @parts ) ;
  return  get_restricted_html_entities( $html ) ;
}

=pod

=item * translate_cmd()

Translate a TeX command.
Takes 3 args:

=over

=item * text (string)

is the text, which follows the backslash, to scan

=item * lineno (integer)

=item * prefix (optional string)

is a prefix merged to the command name. Use carefully.

=back

=cut
sub translate_cmd($$;$) : method {
  my $self = shift ;
  my ($eaten,$tex,$lineno) = ('',
			      $_[0] || '',
			      $_[1] || 0 ) ;
  my $cmd_prefix = $_[2] || '' ;

  # Gets the command name
  if ( $tex =~ /^\[(.*)/ ) { # Starts multi-line math mode
    $tex = $1 ;
    if ( ! $self->is_math_mode() ) {
      $eaten .= $self->start_math_mode(2) ;
    }
    else {
      Bib2HTML::General::Error::warm( "you try to open twice a mathematical mode with '".$cmd_prefix."['",
				      $self->{'FILENAME'},
				      $lineno ) ;
    }
  }
  elsif ( $tex =~ /^\](.*)/ ) { # Stop multi-line math mode
    $tex = $1 ;
    if ( $self->is_multiline_math_mode() ) {
      $eaten .= $self->stop_math_mode() ;
    }
    elsif ( $self->is_math_mode() ) {
      Bib2HTML::General::Error::warm( "you try to close with a '".$cmd_prefix."[' a mathematical mode opened with '\$'",
				      $self->{'FILENAME'},
				      $lineno ) ;
    }
    else {
      Bib2HTML::General::Error::warm( "you try to close with '".$cmd_prefix."]' a mathematical mode which was not opened",
				      $self->{'FILENAME'},
				      $lineno ) ;
    }
  }
  elsif ( $tex =~ /^((?:[a-zA-Z]+)|.)(.*)/ ) { # default LaTeX command
    (my $cmdname,$tex) = ($1,$2) ;
    if ( $cmdname ) {
      my $trans = $self->search_cmd_trans( $cmdname, $lineno, ($cmd_prefix ne "\\") ) ;
      if ( defined( $trans ) ) {
	# Seach the command inside the translation table
	($eaten,$tex) = $self->run_cmd( $cmd_prefix.$cmdname, $trans, $tex, $lineno ) ;
      }
      elsif ( $self->is_math_mode() ) {
	Bib2HTML::General::Error::warm( "unrecognized TeX command in mathematical mode: ".
					$cmd_prefix.$cmdname,
					$self->{'FILENAME'},
					$lineno ) ;
	$eaten = "<font color=\"gray\">[$cmdname]</font>" ;
      }
      else {
	Bib2HTML::General::Error::warm( "unrecognized TeX command: ".
					$cmd_prefix.$cmdname,
					$self->{'FILENAME'},
					$lineno ) ;
	$eaten = "<font color=\"gray\">[$cmdname]</font>" ;
      }
    }
    else {
      Bib2HTML::General::Error::warm( "invalid syntax for the TeX command: ".
				      $cmd_prefix.$_[0],
				      $self->{'FILENAME'},
				      $lineno ) ;
      $eaten = $cmd_prefix ;
    }
  }
  else {
    Bib2HTML::General::Error::warm( "invalid syntax for the TeX command: ".
				    $cmd_prefix.$_[0],
                                    $self->{'FILENAME'},
				    $lineno ) ;
    $eaten = $cmd_prefix ;
  }

  return ($eaten,$tex) ;
}

=pod

=item * search_cmd_trans()

Replies the translation entry that corresponds to
the specified TeX command.
Takes 3 args:

=over

=item * name (string)

is the name of the TeX command to search.

=item * lineno (integer)

=item * special (optional boolean)

indicates if the searched command has a special purpose
(example: _ in math mode)

=back

=cut
sub search_cmd_trans($$;$) : method {
  my $self = shift ;
  my $lineno = $_[1] || 0 ;
  my $special = $_[2] ;
  my ($math, $text) ;
  my ($found_math,$found_text) = (0,0) ;
  if ( ( $_[0] ) &&
       ( exists $MATH_TEX_HTML_COMMANDS{$_[0]} ) ) {
    $found_math = ( ( ( !$special ) &&
		      ( ( ! ishash( $MATH_TEX_HTML_COMMANDS{$_[0]} ) ) ||
			( ! exists $MATH_TEX_HTML_COMMANDS{$_[0]}{'special'} ) ||
			( ! $MATH_TEX_HTML_COMMANDS{$_[0]}{'special'} ) ) ) ||
		    ( ( $special ) &&
		      ( ishash( $MATH_TEX_HTML_COMMANDS{$_[0]} ) ) &&
		      ( exists $MATH_TEX_HTML_COMMANDS{$_[0]}{'special'} ) &&
		      ( $MATH_TEX_HTML_COMMANDS{$_[0]}{'special'} ) ) ) ;
    $math = $MATH_TEX_HTML_COMMANDS{$_[0]}
      if ( $found_math ) ;
  }
  if ( ( $_[0] ) &&
       ( exists $TEX_HTML_COMMANDS{$_[0]} ) ) {
    $found_text = ( ( ( !$special ) &&
		      ( ( ! ishash( $TEX_HTML_COMMANDS{$_[0]} ) ) ||
			( ! exists $TEX_HTML_COMMANDS{$_[0]}{'special'} ) ||
			( ! $TEX_HTML_COMMANDS{$_[0]}{'special'} ) ) ) ||
		    ( ( $special ) &&
		      ( ishash( $TEX_HTML_COMMANDS{$_[0]} ) ) &&
		      ( exists $TEX_HTML_COMMANDS{$_[0]}{'special'} ) &&
		      ( $TEX_HTML_COMMANDS{$_[0]}{'special'} ) ) ) ;
    $text = $TEX_HTML_COMMANDS{$_[0]}
      if ( $found_text ) ;
  }

  if ( $found_math || $found_text ) {
    if ( $self->is_math_mode() ) {
      if ( ! $found_math ) {
	Bib2HTML::General::Error::warm( "the command ".
					( $special ? '' : '\\' ).
					$_[0].
					" was not defined for math-mode, assumes to use the text-mode version instead",
					$self->{'FILENAME'}, $lineno ) ;
	return $text ;
      }
      else {
	return $math ;
      }
    }
    elsif ( ! $found_text ) {
      Bib2HTML::General::Error::warm( "the command ".
				      ( $special ? '' : '\\' ).
				      $_[0].
				      " was not defined for text-mode, assumes to use the math-mode version instead",
				      $self->{'FILENAME'}, $lineno ) ;
      return $math ;
    }
    else {
      return $text ;
    }
  }
  return undef ;
}

=pod

=item * run_cmd()

Eaten the specified tex according to the specified command.
Takes 4 args:

=over

=item * name (string)

is the name of the TeX command.

=item * trans (mixed)

is the translation for the command.

=item * text (string)

is the text from which some data must be extracted to
treat the command.

=item * lineno(integer)

is le line number where the text starts

=back

=cut
sub run_cmd($$$$) : method {
  my $self = shift ;
  my ($eaten,$cmdname,$tex,$lineno) = ('',
				       $_[0] || confess( 'you must supply the TeX command name'),
				       $_[2] || '',
				       $_[3] || 0 ) ;
  if ( ( ishash( $_[1] ) ) &&
       ( exists $_[1]->{'params'} ) ) {
    # This command has params
    ($tex,my @params) = $self->eat_cmd_parameters( $_[1]->{'params'}, $tex, $lineno ) ;
    # Apply the command
    if ( exists $_[1]->{'html'} ) {
      # Replace by the HTML translation
      $eaten = $_[1]->{'html'} ;
      for(my $i=1; $i<=@params; $i++) {
	if ( $eaten =~ /\#$i/ ) {
	  my $p = ($params[$i-1])->{'text'} ;
	  if ( ($params[$i-1])->{'eval'} ) {
	    $p = $self->translate( $p, undef, $lineno ) ;
	  }
	  $eaten =~ s/\#$i/$p/g ;
	}
      }
    }
    elsif ( exists $_[1]->{'latex'} ) {
      # Replace by the LaTeX commands
      my $cmd = $_[1]->{'latex'} ;
      for(my $i=1; $i<=@params; $i++) {
	if ( $cmd =~ /\#$i/ ) {
	  my $p = ($params[$i-1])->{'text'} ;
	  if ( ($params[$i-1])->{'eval'} ) {
	    $p = $self->translate( $p, undef, $lineno ) ;
	  }
	  $cmd =~ s/\#$i/$p/g ;
	}
      }
      $tex = $cmd.$tex ;
    }
    elsif ( exists $_[1]->{'func'} ) {
      # Replace by the string replied by the callback function
      my $reffunc = $self->can($_[1]->{'func'}) ;
      if ( $reffunc ) {
	$eaten = $self->$reffunc( $lineno, @params ) ;
      }
      elsif ( issub( $_[1]->{'func'} ) ) {
	$eaten = $_[1]->{'func'}( $lineno, @params ) ;
      }
      else {
        Bib2HTML::General::Error::warm( "unable to find the callback function 'sub ".
                                        $_[1]->{'func'}.
                                        "{}' for the TeX command $cmdname",
                                        $self->{'FILENAME'},
					$lineno ) ;
      }
    }
    elsif ( exists $_[1]->{'texfunc'} ) {
      # Replace by the string replied by the callback function
      my $reffunc = $self->can($_[1]->{'texfunc'}) ;
      if ( $reffunc ) {
	my $result = $self->$reffunc( $lineno, @params ) ;
	$tex = $result . $tex ;
      }
      elsif ( issub( $_[1]->{'texfunc'} ) ) {
	my $result = $_[1]->{'texfunc'}( $lineno, @params ) ;
	$tex = $result . $tex ;
      }
      else {
        Bib2HTML::General::Error::warm( "unable to find the callback function 'sub ".
                                        $_[1]->{'func'}.
                                        "{}' for the TeX command $cmdname",
                                        $self->{'FILENAME'},
					$lineno ) ;
      }
    }
  }
  else {
    # No param, put the HTML string inside the output stream
    $eaten = $_[1] ;
  }
  return ($eaten,$tex) ;
}

=pod

=item * eat_cmd_parameters()

Eaten the specified command parameters.
Takes 3 args:

=over

=item * params (string)

is the description of the parameters to eat.

=item * text (string)

is the text from which some data must be extracted.

=item * lineno (integer)

=back

=cut
sub eat_cmd_parameters($$$) : method {
  my $self = shift ;
  my $p_params = $_[0] || '' ;
  my $tex = $_[1] || '' ;
  my $lineno = $_[2] || 0 ;
  my @params = () ;
  while ( $p_params =~ /((?:\!?\{\})|(?:\!?\[[^\]]*\])|-|\\)/g ) {
    my $p = $1 ;
    # Eats no significant white spaces
    $tex =~ s/^ +// ;
    if ( $p =~ /^(\!?)\{\}/ ) { # Eates a needed parameter
      my $optional = $1 || '' ;
      my $prem = substr($tex,0,1) ;
      $tex = substr($tex,1) ;
      if ( $prem eq '{' ) {
	(my $context,$tex) = $self->eat_context( $tex, '\\}' ) ;
	push @params, { 'eval' => ($optional ne '!'),
			'text' => $context,
		      } ;
      }
      elsif ( $prem eq '\\' ) {
	(my $eaten,$tex) = $self->translate_cmd($tex, $lineno, '\\') ;
	push @params, { 'eval' => 0,
			'text' => $eaten,
		      } ;
      }
      else {
	push @params, { 'eval' => ($optional ne '!'),
			'text' => $prem,
		      } ;
      }
    }
    elsif( $p =~ /^(\!?)\[([^\]]*)\]/ ) { # Eates an optional parameter
      my ($optional,$default_val) = ( $1 || '', $2 || '' ) ;
      my $prem = substr($tex,0,1) ;
      if ( $prem eq '[' ) {
	(my $context,$tex) = $self->eat_context( substr($tex,1), '\\]' ) ;
	push @params, { 'eval' => ($optional ne '!'),
			'text' => $context,
		      } ;
      }
      else {
	push @params, { 'eval' => ($optional ne '!'),
			'text' => $default_val,
		      } ;
      }
    }
    elsif( $p eq '\\' ) { # Eates a TeX command name
      if ( $tex =~ /^\\((?:[a-zA-Z]+|.))(.*)$/ ) {
	$tex = $2 ;
	push @params, { 'eval' => 1,
			'text' => $1,
		      } ;
      }
      else {
        Bib2HTML::General::Error::warm( "expected a TeX command name: ".$tex,
                                        $self->{'FILENAME'},
					$lineno ) ;
	push @params, { 'eval' => 1,
			'text' => '',
		      } ;	
      }
    }
    elsif ( $p eq '-' ) { # Eates until the end of the current context
      (my $context,$tex) = $self->eat_context( $tex, '\\}' ) ;
      push @params, { 'eval' => 1,
		      'text' => $context,
		    } ;
    }
    else {
      confess( "unable to recognize the following argument specification: $p" ) ;
    }
  }
  return ($tex,@params) ;
}

=pod

=item * eat_context()

Eaten the current context.
Takes 2 args:

=over

=item * text (string)

is the text from which some data must be extracted.

=item * end (string)

is the ending separator

=back

=cut
sub eat_context($$) : method {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my $enddelim = $_[1] || confess( 'you must supply the closing delimiter' ) ;
  my $context = '' ;
  my $contextlevel = 0 ;

  # Search the first separator
  my ($eaten,$sep,$tex) = $self->eat_to_separator($text,$enddelim) ;

  while ($sep) {

    if ( $sep eq '{' )  { # open a context
      $contextlevel ++ ;
      $eaten .= $sep ;
    }
    elsif ( $sep eq '}' ) { # close a context
      if ( $contextlevel <= 0 ) {
	return ($context.$eaten,$tex) ;
      }
      $eaten .= $sep ;
      $contextlevel -- ;
    }
    elsif ( $sep eq '\\' ) {
      $tex =~ /^([a-zA-Z]+|.)(.*)$/ ;
      $eaten .= "\\$1";
      $tex = $2 ;
    }
    elsif ( ( $contextlevel <= 0 ) &&
	    ( $sep =~ /$enddelim/ ) ) { # The closing delemiter was found
      return ($context.$eaten,$tex) ;
    }
    else { # Unknow separator, treat as text
      $eaten .= $sep ;
    }

    # Translate the text before the separator
    $context .= $eaten ;

    # Search the next separator
    ($eaten,$sep,$tex) = $self->eat_to_separator($tex,$enddelim) ;
  }

  return ($context.$eaten,$tex) ;
}

#------------------------------------------------------
#
# Translation table updates
#
#------------------------------------------------------

=pod

=item * start_math_mode()

Starts the mathematical mode.
Takes 1 arg:

=over

=item * mode (integer)

is the math mode to start (1: inline, 2: multi-line)

=back

=cut
sub start_math_mode($) {
  my $self = shift ;
  if ( $self->is_math_mode() ) {
    return '' ;
  }
  else {
    $self->{'MATH_MODE'} = ( $_[0] % 3 ) ;
    my $tag = '' ;
    if ( $self->{'MATH_MODE'} == 2 ) {
      $tag .= "<blockquote>" ;
    }
    return $tag.$self->{'MATH_MODE_START'} ;
  }
}

=pod

=item * stop_math_mode()

Stops the mathematical mode.

=cut
sub stop_math_mode() {
  my $self = shift ;
  if ( $self->is_math_mode() ) {
    my $tag = $self->{'MATH_MODE_STOP'} ;
    if ( $self->{'MATH_MODE'} == 2 ) {
      $tag .= "</blockquote>" ;
    }
    $self->{'MATH_MODE'} = 0 ;
    return $tag ;
  }
  else {
    return '' ;
  }
}

=pod

=item * is_math_mode()

Replies if inside a mathematical mode.

=cut
sub is_math_mode() {
  my $self = shift ;
  return ( $self->{'MATH_MODE'} != 0 ) ;
}

=pod

=item * is_inline_math_mode()

Replies if inside a inlined mathematical mode.

=cut
sub is_inline_math_mode() {
  my $self = shift ;
  return ( $self->{'MATH_MODE'} == 1 ) ;
}

=pod

=item * is_multiline_math_mode()

Replies if inside a multi-lined mathematical mode.

=cut
sub is_multiline_math_mode() {
  my $self = shift ;
  return ( $self->{'MATH_MODE'} == 2 ) ;
}

#------------------------------------------------------
#
# Information
#
#------------------------------------------------------

=pod

=item * display_supported_commands()

Display the list of supported LaTeX commands.
Takes 1 arg:

=over

=item * perldir (string)

is the path to the directory where the Perl packages
are stored.

=back

=cut
sub display_supported_commands($) {
  my $path = $_[0] || confess( 'you must specify the pm path' ) ;
  my (@c1,@c2) = ((),()) ;
  foreach my $cmd ( keys %TEX_HTML_COMMANDS ) {
    my $prefix = '' ;
    if ( ( !ishash( $TEX_HTML_COMMANDS{$cmd} ) ) ||
	 ( ! exists $TEX_HTML_COMMANDS{$cmd}{'special'} ) ||
	 ( ! $TEX_HTML_COMMANDS{$cmd}{'special'} ) ) {
      $prefix = "\\" ;
    }
    if ( $cmd =~ /^[a-zA-Z0-9]/ ) {
      push @c2, $prefix.$cmd ;
    }
    else {
      push @c1, $prefix.$cmd ;
    }
  }
  foreach my $cmd ( keys %MATH_TEX_HTML_COMMANDS ) {
    if ( ! exists $TEX_HTML_COMMANDS{$cmd} ) {
      my $prefix = '' ;
      if ( ( !ishash( $TEX_HTML_COMMANDS{$cmd} ) ) ||
	   ( ! exists $TEX_HTML_COMMANDS{$cmd}{'special'} ) ||
	   ( ! $TEX_HTML_COMMANDS{$cmd}{'special'} ) ) {
	$prefix = "\\" ;
      }
      if ( $cmd =~ /^[a-zA-Z0-9]/ ) {
	push @c2, $prefix.$cmd ;
      }
      else {
	push @c1, $prefix.$cmd ;
      }
    }
  }
  foreach my $cmd ( sort @c1 ) {
    print "$cmd\n" ;
  }
  foreach my $cmd ( sort @c2 ) {
    print "$cmd\n" ;
  }
}

#------------------------------------------------------
#
# Translation table updates
#
#------------------------------------------------------

=pod

=item * addtrans_char()

Static method which permits to add a translation entry
for a character.
Takes 2 args:

=over

=item * char (string)

is the character to translate

=item * html (string)

is the HTML translation of the character.

=back

=cut
sub addtrans_char($$) {
  confess( 'you must supply the character to translate' ) unless $_[0] ;
  Bib2HTML::General::Verbose::three( "\tadd the HTML translation for '".$_[0]."'" ) ;
  $TEX_HTML_CHAR_TRANS{$_[0]} = ( $_[1] || '' ) ;
}

=pod

=item * gettrans_char()

Static method which replies the translation table from a character to HTML string.

=cut
sub gettrans_char() {
  return \%TEX_HTML_CHAR_TRANS ;
}

=pod

=item * addtrans_cmd_noparam()

Static method which permits to add a translation entry
for a TeX command. The new TeX command does not have any
parameter.
Takes 3 args:

=over

=item * cmd (string)

is the name od the TeX command

=item * html (string)

is the HTML translation of the character.

=item * tex_content (optional boolean)

indicates if the content contains LaTeX code (if true)
or HTML code (if false - default).

=back

=cut
sub addtrans_cmd_noparam($$;$) {
  confess( 'you must supply the character to translate' ) unless $_[0] ;
  Bib2HTML::General::Verbose::three( "\tadd the TeX translation for {\\".$_[0]."}" ) ;
  if ( $_[2] ) {
    $TEX_HTML_COMMANDS{$_[0]} = { 'params' => '',
				  'latex' => ( $_[1] || '' ),
				} ;
  }
  else {
    $TEX_HTML_COMMANDS{$_[0]} = ( $_[1] || '' ) ;
  }
}

=pod

=item * addtrans_cmd_html()

Static method which permits to add a translation entry
for a TeX command. The new TeX command has parameters, but
it can be directly translated as HTML code.
Takes 4 args:

=over

=item * cmd (string)

is the name od the TeX command

=item * params (string)

is the description of the parameters:

=over

=item {} for a parameter

=item [val] for an optional parameter where val is the default value

=item \ for a TeX command name

=item ! will avoid the LaTeX interpretation of the following sign ({} or [])

=item - for all the text until the end of the current context

=back

=item * html (string)

is the HTML translation of the character. #n means the n-th parameter,
where n is an integer greater or equal to 1.

=item * tex_content (optional boolean)

indicates if the content contains LaTeX code (if true)
or HTML code (if false - default).

=back

=cut
sub addtrans_cmd_html($$$;$) {
  confess( 'you must supply the TeX command name' ) unless $_[0] ;
  my $params = $_[1] || confess( 'you must supply the parameter description' ) ;
  my $html = $_[2] || '' ;
  if ( ( $params eq '-' ) ||
       ( $params =~ /(?:(?:\{\})|(?:\[[^\]]*\])|\\)+/ ) ) {
    Bib2HTML::General::Verbose::three( "\tadd the TeX translation for \\".$_[0].$params ) ;
    if ( $_[3] ) {
      %{$TEX_HTML_COMMANDS{$_[0]}} = ( 'params' => $params,
				       'latex' => $html,
				     ) ;
    }
    else {
      %{$TEX_HTML_COMMANDS{$_[0]}} = ( 'params' => $params,
				       'html' => $html,
				     ) ;
    }
  }
  else {
    Bib2HTML::General::Error::syserr( "invalid syntax for the parameters of the ".
                                      "TeX command '".$_[0]."': ".$params ) ;
  }
}

=pod

=item * addtrans_cmd_func()

Static method which permits to add a translation entry
for a TeX command. The new TeX command has parameters, but
a callback function must be called to treat this command.
Takes 3 args:

=over

=item * cmd (string)

is the name od the TeX command

=item * params (string)

is the description of the parameters:

=over

=item {} for a parameter

=item [val] for an optional parameter where val is the default value

=item \ for a TeX command name

=item ! will avoid the LaTeX interpretation of the following sign ({} or [])

=item - for all the text until the end of the current context

=back

=item * func (string)

is the name of the method to call.

=back

=cut
sub addtrans_cmd_func($$$) {
  confess( 'you must supply the TeX command name' ) unless $_[0] ;
  my $params = $_[1] || confess( 'you must supply the parameter description' ) ;
  my $func = $_[2] || confess( 'you must supply the callback function' ) ;
  if ( ( $params eq '-' ) ||
       ( $params =~ /(?:(?:\{\})|(?:\[[^\]]*\])|\\)+/ ) ) {
    Bib2HTML::General::Verbose::three( "\tadd the TeX translation for \\".$_[0].$params ) ;
    %{$TEX_HTML_COMMANDS{$_[0]}} = ( 'params' => $params,
				     'func' => $func,
				   ) ;
  }
  else {
    Bib2HTML::General::Error::syserr( "invalid syntax for the parameters of the ".
                                      "TeX command '".$_[0]."': ".$params ) ;
  }
}

=pod

=item * gettrans_cmd()

Replies the translation table from a TeX command to HTML string.

=cut
sub gettrans_cmd() {
  return \%TEX_HTML_COMMANDS ;
}

=pod

=item * __texcommand_map_to()

Makes the specified mapping of a TeX command.
Takes at least 4 args:

=over

=item * map (hash)

is the mapping associative array

=item * default (string)

is the default value return if the mapping was unavailable

=item * lineno (integer)

=item * params (array)

is the list of parameters

=back

=cut
sub __texcommand_map_to($$$) {
  my $self = shift ;
  my $lineno = $_[2] || 0 ;
  if ( ( $_[3] ) &&
       ( $_[3]->{'text'} ) ) {
    if ( $_[0]->{$_[3]->{'text'}} ) {
      return "&".$_[0]->{$_[3]->{'text'}}.";" ;
    }
    else {
      # Patch by Norbert Preining added the 2003/03/17
	Bib2HTML::General::Error::warm( "An accentuation command was found, but the corresponding character '".
					$_[3]->{'text'}.
					"' is not supported. Assume '".
					$_[1].$_[3]->{'text'}."'.",
					$self->{'FILENAME'}, $lineno ) ;
    }
  }
  else {
    Bib2HTML::General::Error::warm( "no command name after a slash. Assume '".$_[1].$_[3]->{'text'}."'.",
				    $self->{'FILENAME'}, $lineno ) ;
  }
  # Patch by Norbert Preining added the 2003/03/17
  return "$_[1]$_[3]->{'text'}";
}

=pod

=item * __texcommand_font_series()

Apply the specified font series (Medium or Bold).
Takes at least 4 args:

=over

=item * start_balise (hash)

is the HTML balise used to start this style

=item * end_balise (hash)

is the HTML balise used to end this style

=item * fontset (string)

is the name of the font set to manage (eg, SERIES, SHAPES...)

=item * lineno (integer)

=item * params (array)

is the list of parameters

=back

=cut
sub __texcommand_font_style($$$$;@) {
  my $self = shift ;
  my $lineno = $_[2] || 0 ;
  my ($begin,$end) = ( $_[0] || '', $_[1] || '' ) ;
  my ($set,$text) = ( $_[2] || '', '' ) ;

  confess( "You must supply a valid fontset name (from ".
	   join( ', ', keys %{$self->{'FONTS'}} ).
	   ")." ) unless ( exists $self->{'FONTS'}{$set} ) ;

  my $last = ( int(@{$self->{'FONTS'}{$set}}) > 0 ) ?
    $self->{'FONTS'}{$set}->[$#{$self->{'FONTS'}{$set}}] : '' ;

  my $elt = { 'begin' => $begin,
	      'end' => $end,
	    } ;
  push @{$self->{'FONTS'}{$set}}, $elt ;
  push @{$self->{'FONTS'}{'ALLS'}}, $elt ;

  if ( ( ! $last ) ||
       ( ! ishash( $last ) ) ||
       ( $last->{'begin'} ne $begin ) ) {
    $text .= ( ( $last && ( ishash($last) ) ) ? $last->{'end'} : '' ).$begin ;
  }

  if ( ( $_[4] ) && ( ishash( $_[4] ) ) ) {
    if ( $_[4]->{'eval'} ) {
      $text .= $self->translate( $_[4]->{'text'}, undef, $lineno ) ;
    }
    else {
      $text .= $_[4] ;
    }
  }

  if ( ( ! $last ) ||
       ( ! ishash( $last ) ) ||
       ( $last->{'begin'} ne $begin ) ) {
    $text .= $end.( ( $last && ( ishash($last) ) ) ? $last->{'begin'} : '' ) ;
  }

  pop @{$self->{'FONTS'}{'ALLS'}} ;
  pop @{$self->{'FONTS'}{$set}} ;

  if ( $begin || $end ) {
    $text =~ s/\Q$begin$end\E//g ;
    $text =~ s/\Q$end$begin\E//g ;
  }

  return $text ;
}

#------------------------------------------------------
#
# TeX command callbacks
#
#------------------------------------------------------

=pod

=item * texcommand_font_medium()

Treats \textmd or \mdseries

=cut
sub texcommand_font_medium {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_font_style( '',
					 '',
					 'SERIES',
					 $lineno, @_ ) ;
}

=pod

=item * texcommand_font_mathset()

Treats \mathbb

=cut
sub texcommand_font_mathset {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_font_style( '<i>',
					 '</i>',
					 'SERIES',
					 $lineno, @_ ) ;
}

=pod

=item * texcommand_font_bold()

Treats \bf or \textbf

=cut
sub texcommand_font_bold {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_font_style( '<b>',
					 '</b>',
					 'SERIES',
					 $lineno, @_ ) ;
}

=pod

=item * texcommand_font_roman()

Treats \rm or \textrm

=cut
sub texcommand_font_roman {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_font_style( '',
					 '',
					 'FAMILIES',
					 $lineno, @_ ) ;
}

=pod

=item * texcommand_font_serif()

Treats \sf or \textsf

=cut
sub texcommand_font_serif {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_font_style( '<font face="Sans Serif">',
					 '<!-- /fontSF --></font>',
					 'FAMILIES',
					 $lineno, @_ ) ;
}

=pod

=item * texcommand_font_typewriter()

Treats \tt or \texttt

=cut
sub texcommand_font_typewriter {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_font_style( '<tt>',
					 '</tt>',
					 'FAMILIES',
					 $lineno, @_ ) ;
}

=pod

=item * texcommand_font_upright()

Treats \upshape or \textup

=cut
sub texcommand_font_upright {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_font_style( '',
					 '',
					 'SHAPES',
					 $lineno, @_ ) ;
}

=pod

=item * texcommand_font_italic()

Treats \it or \textit

=cut
sub texcommand_font_italic {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_font_style( '<i>',
					 '</i>',
					 'SHAPES',
					 $lineno, @_ ) ;
}

=pod

=item * texcommand_font_slanted()

Treats \sl or \textsl

=cut
sub texcommand_font_slanted {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_font_style( '<i><tt>',
					 '</tt></i>',
					 'SHAPES',
					 $lineno, @_ ) ;
}

=pod

=item * texcommand_font_smallcap()

Treats \sc or \textsc

=cut
sub texcommand_font_smallcap {
  my $self = shift ;
  my $lineno = shift || 0 ;
  my $text =  $self->__texcommand_font_style( '<!-- SMALL CAPS -->',
					      '<!-- /SMALL CAPS -->',
					      'SHAPES',
					      $lineno, @_ ) ;
  my $r = '' ;
  while ( ( $text ) &&
	  ( $text =~ /^(.*?)<!-- SMALL CAPS -->(.*?)<!-- \/SMALL CAPS -->(.*)$/ ) ) {
    (my $prev, my $sc, $text) = ($1,$2,$3) ;
    $r .= $prev . html_sc( $sc ) ;
  }
  if ( $text ) {
    $r .= $text ;
  }
  return $r ;
}

=pod

=item * texcommand_font_normal()

Treats \textnormal or \normalfont

=cut
sub texcommand_font_normal {
  my $self = shift ;
  my $lineno = shift || 0 ;
  my ($begin,$end)=('','');
  foreach my $envs ( @{$self->{'FONTS'}{'ALLS'}} ) {
    if ( $envs ) {
      $begin .= $envs->{'begin'} ;
      $end = $envs->{'end'} . $end ;
    }
  }
  return $end.($_[0]->{'text'}||'').$begin ;
}

=pod

=item * texcommand_cedil()

Treats \c{}

=cut
sub texcommand_cedil {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_map_to( { 'C' => 'Ccedil',
				       'c' => 'ccedil',
				       'S' => '#x015e',
				       's' => '#x015f',
				       'T' => '#x0162',
				       't' => '#x0163',
				     },
				     "&cedil;",
				     $lineno, @_ ) ;
}

=pod

=item * texcommand_ucircle()

Treats \u{}

=cut
sub texcommand_ucircle { # added by Tobia
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_map_to( { 'A' => '#x0102',
				       'a' => '#x0103',
				     },
				     "&#x0306;",
				     $lineno, @_ ) ;
}

=pod

=item * texcommand_acute()

Treats \'{}

=cut
sub texcommand_acute {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_map_to( { 'A' => 'Aacute',
				       'E' => 'Eacute',
				       'I' => 'Iacute',
				       'O' => 'Oacute',
				       'U' => 'Uacute',
				       'Y' => 'Yacute',
				       'a' => 'aacute',
				       'e' => 'eacute',
				       'i' => 'iacute',
				       'o' => 'oacute',
				       'u' => 'uacute',
				       'y' => 'yacute',
				       '\\i' => 'iacute',
  #Patched by Gasper Jaklic <gasper.jaklic@fmf.uni-lj.si>
				       'C' => '#262',
				       'c' => '#263',
				     },
				     "&acute;",
				     $lineno, @_ ) ;
}

=pod

=item * texcommand_grave()

Treats \'{}

=cut
sub texcommand_grave {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_map_to( { 'A' => 'Agrave',
				       'E' => 'Egrave',
				       'I' => 'Igrave',
				       'O' => 'Ograve',
				       'U' => 'Ugrave',
				       'a' => 'agrave',
				       'e' => 'egrave',
				       'i' => 'igrave',
				       'o' => 'ograve',
				       'u' => 'ugrave',
				       '\\i' => 'igrave',
				     },
				     "&grave;",
				     $lineno, @_ ) ;
}

=pod

=item * texcommand_tilde()

Treats \~{}

=cut
sub texcommand_tilde {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_map_to( { 'A' => 'Atilde',
				       'N' => 'Ntilde',
				       'O' => 'Otilde',
				       'a' => 'atilde',
				       'n' => 'ntilde',
				       'o' => 'otilde',
				     },
				     "&tilde;",
				     $lineno, @_ ) ;
}

=pod

=item * texcommand_uml()

Treats \"{}

=cut
sub texcommand_uml {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_map_to( { 'A' => 'Auml',
				       'E' => 'Euml',
				       'I' => 'Iuml',
				       'O' => 'Ouml',
				       'U' => 'Uuml',
				       'Y' => 'Yuml',
				       'a' => 'auml',
				       'e' => 'euml',
				       'i' => 'iuml',
				       'o' => 'ouml',
				       'u' => 'uuml',
				       'y' => 'yuml',
				       '\\i' => 'iuml',
				     },
				     "&uml;",
				     $lineno, @_ ) ;
}

=pod

=item * texcommand_circ()

Treats \^{}

=cut
sub texcommand_circ {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_map_to( { 'A' => 'Acirc',
				       'E' => 'Ecirc',
				       'I' => 'Icirc',
				       'O' => 'Ocirc',
				       'U' => 'Ucirc',
				       'a' => 'acirc',
				       'e' => 'ecirc',
				       'i' => 'icirc',
				       'o' => 'ocirc',
				       'u' => 'ucirc',
				       '\\i' => 'icirc',
				     },
				     "&circ;",
				     $lineno, @_ ) ;
}

=pod

=item * texcommand_caron()

Treats \v{}

=cut
sub texcommand_caron {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return $self->__texcommand_map_to( { 'S' => 'Scaron',
				       's' => 'scaron',
  #Patched by Luca Paolini <paolini@di.unito.it>
  #Patched by Gasper Jaklic <gasper.jaklic@fmf.uni-lj.si>
				       'C' => '#268',
				       'c' => '#269',
				       'D' => '#270',
				       'd' => '#271',
				       'E' => '#282',
				       'e' => '#283',
				       'L' => '#317',
				       'l' => '#318',
				       'N' => '#327',
				       'n' => '#328',
				       'R' => '#344',
				       'r' => '#345',
				       'T' => '#356',
				       't' => '#357',
				       'Z' => '#381',
				       'z' => '#382',
				     },
				     "",
				     $lineno, @_ ) ;
}

=pod

=item * texcommand_bar()

Treats \={}

=cut
sub texcommand_bar {
  my $self = shift ;
  my $lineno = shift || 0 ;
  return "&macr;" unless $_[0] ;
  return $self->__texcommand_map_to( { },
				     "&macr;",
				     $lineno, @_ ) ;
}

=pod

=item * texcommand_def()

Treats \def and \gdef

=cut
sub texcommand_def {
  my $self = shift ;
  my $lineno = shift || 0 ;
  Bib2HTML::General::Error::warm( "command name expected after a \\def or a \\gdef",
                                  $self->{'FILENAME'},
				  $lineno )
      unless $_[0]->{'text'} ;
  # The command definition is never evaluated
  my $trans_txt = $_[1]->{'text'} ;
  addtrans_cmd_noparam( $_[0]->{'text'}, $trans_txt, 1 ) ;
  return '' ;
}

=pod

=item * texcommand_edef()

Treats \edef and \xdef

=cut
sub texcommand_edef {
  my $self = shift ;
  my $lineno = shift || 0 ;
  Bib2HTML::General::Error::warm( "command name expected after a \\edef or a \\xdef",
                                  $self->{'FILENAME'},
				  $lineno )
      unless $_[0]->{'text'} ;
  # The command definition is always evaluated
  my $trans_txt = $self->translate( $_[1]->{'text'} || '', undef, $lineno ) ;
  addtrans_cmd_noparam( $_[0]->{'text'}, $trans_txt, 0 ) ;
  return '' ;
}

=pod

=item * texcommand_newcommand()

Treats \newcommand and \renewcommand

=cut
sub texcommand_newcommand {
  my $self = shift ;
  my $lineno = shift || 0 ;
  # Check for command name
  my $name = $_[0]->{'text'} || '' ;
  $name =~ s/^\\// ;
  if ( ! $name ) {
    Bib2HTML::General::Error::warm( "command name expected after a \\def",
				    $self->{'FILENAME'},
				    $lineno ) ;
    return '' ;
  }
  # Builds the parameter definition
  my $params = "" ;
  if ( ( $_[1]->{'text'} ) && ( $_[1]->{'text'} > 0 ) ) {
    my $count = $_[1]->{'text'} ;
    if ( $_[2]->{'text'} ) {
      $count -- ;
      $params .= '['.$_[2]->{'text'}.']' ;
    }
    while ( $count > 0 ) {
      $count -- ;
      $params .= '{}' ;
    }
  }

  # The command definition is never evaluated
  my $trans = $_[3]->{'text'} || '' ;

  # Adds the command definition
  if ( $params ) {
    addtrans_cmd_html( $name, $params, $trans, 1 ) ;
  }
  else {
    addtrans_cmd_noparam( $name, $trans, 1 ) ;
  }
  return '' ;
}

=pod

=item * texcommand_ensuremath()

Treats \ensuremath

=cut
sub texcommand_ensuremath {
  my $self = shift ;
  my $lineno = shift || 0 ;
  my $trans = '' ;
  my $math = $self->is_math_mode() ;

  $trans = $self->start_math_mode(1) unless ( $math ) ;

  if ( $_[0]->{'eval'} ) {
    $trans .= $self->translate( $_[0]->{'text'} || '', undef, $lineno ) ;
  }
  else {
    $trans .= $_[0]->{'text'} || '' ;
  }

  $trans .= $self->stop_math_mode() unless ( $math ) ;

  return $trans ;
}

=pod

=item * texcommand_ensuretext()

Treats \text

=cut
sub texcommand_ensuretext {
  my $self = shift ;
  my $lineno = shift || 0 ;
  my $trans = '' ;
  my $math ;
  if ( $self->is_inline_math_mode() ) {
    $math = 1 ;
  }
  elsif ( $self->is_multiline_math_mode() ) {
    $math = 2 ;
  }
  else {
    $math = 0 ;
  }

  $trans = $self->stop_math_mode() if ( $math ) ;

  if ( $_[0]->{'eval'} ) {
    $trans .= $self->translate( $_[0]->{'text'} || '', undef, $lineno ) ;
  }
  else {
    $trans .= $_[0]->{'text'} || '' ;
  }

  $trans .= $self->start_math_mode( $math ) if ( $math ) ;

  return $trans ;
}

=pod

=item * texcommand_cite()

Treats \cite

=cut
sub texcommand_cite {
  my $self = shift ;
  my $lineno = shift || 0 ;
  my $key = $_[1]->{'text'} || '' ;
  my $label = $_[0]->{'text'} || '' ;
  my $cite = $label || '?' ;
  if ( ($key) &&
       ( ishash($self->{'DATABASE'}) ) &&
       ( ! isemptyhash( $self->{'DATABASE'} ) ) &&
       ( exists $self->{'DATABASE'}{$key} ) ) {
    $cite = "<BIB2HTML action=CITE key=\"$key\"" ;
    if ( $label ) {
      my $bibtex = new Bib2HTML::Translator::BibTeXEntry() ;
      $bibtex->save_citation_label( $key, $label ) ;
      $cite .= " label=\"".addslashes( $label )."\"" ;
    }
    $cite .= ">". ( $label || '?' ) . "</BIB2HTML>" ;
  }
  return "[".$cite."]" ;
}

=pod

=item * texcommand_beginenv()

Treats \begin

=cut
sub texcommand_beginenv {
  my $self = shift ;
  my $lineno = shift || 0 ;
  my $env = $_[0]->{'text'} || '' ;

  if ( ! $env ) {
    Bib2HTML::General::Error::warm( "environment name not found for a command \\begin",
				    $self->{'FILENAME'},
				    $lineno ) ;
    return '' ;
  }

  # register the environment opening here to
  # prevent error during the closing
  push @{$self->{'ENVIRONMENTS'}}, $env ;

  return "\\start$env" ;
}

=pod

=item * texcommand_endenv()

Treats \end

=cut
sub texcommand_endenv {
  my $self = shift ;
  my $lineno = shift || 0 ;
  my $env = $_[0]->{'text'} || '' ;

  if ( ! $env ) {
    Bib2HTML::General::Error::warm( "environment name not found for a command \\end",
				    $self->{'FILENAME'},
				    $lineno ) ;
    return '' ;
  }

  # Pop the environment contex
  # and warm if the closed environment
  # does not match the opened
  if ( isemptyarray($self->{'ENVIRONMENTS'}) ) {
    Bib2HTML::General::Error::warm( "found \\end{$env} without \\begin{$env}",
				    $self->{'FILENAME'},
				    $lineno ) ;
    return '' ;
  }

  my $opened = $self->{'ENVIRONMENTS'}->[$#{$self->{'ENVIRONMENTS'}}] ;
  if ( ( !$opened ) ||
       ( $opened ne $env ) ) {
    Bib2HTML::General::Error::warm( "found \\end{$env} instead of \\end{$opened}",
				    $self->{'FILENAME'},
				    $lineno ) ;
    return '' ;
  }

  pop @{$self->{'ENVIRONMENTS'}} ;

  return "\\end$env" ;
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
Some TeX commands are added by Dimitris Michail E<lt>michail@mpi-sb.mpg.deE<gt>
and Tobias Loew E<lt>loew@mathematik.tu-darmstadt.deE<gt>

=back

=head1 SEE ALSO

bib2html.pl
