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

Bib2HTML::Generator::Theme::Simple - A theme for the HTML generator

=head1 SYNOPSYS

use Bib2HTML::Generator::Theme::Simple ;

my $gen = Bib2HTML::Generator::Theme::Simple->new( generator,
                                           bib2html,
                                           target,
                                           title,
                                           lang ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::Theme::Simple is a Perl module, which proposes
a documentation theme for the HTML generator of bib2html.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use Bib2HTML::Generator::Theme::Simple;

    my $gen = Bib2HTML::Generator::Theme::Simple->new( $generator,
					       { 'VERSION' => '0.11' },
						'./bib_output',
						'Title',
					        $lang ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * parent (object ref)

is a reference to the current HTML generator.

=item * bib2html (hash)

contains some data about bib2html.

=item * target (string)

The directory in which the documentation must be put.

=item * title (string)

is the title of the documentation.

=item * lang (object ref)

is a reference to the language object.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Simple.pm itself.

=over

=cut

package Bib2HTML::Generator::Theme::Simple;

@ISA = ('Bib2HTML::Generator::Theme');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;

use Carp ;
use File::Spec ;

use Bib2HTML::Generator::Theme ;
use Bib2HTML::General::Verbose ;
use Bib2HTML::General::Error ;
use Bib2HTML::General::Misc ;
use Bib2HTML::General::HTML ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of theme
my $VERSION = "5.0" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$$) : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = $class->SUPER::new( @_ ) ;

  $self->{'BACKGROUND_COLOR'} = '#FFFFFF' ;

  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Validation
#
#------------------------------------------------------

=pod

=item * getMyValidHTML()

Replies the list of W3C protocols for which this theme
was validated. You must override this method.

=cut
sub getMyValidHTML() {
  my $self = shift ;
  return ( 'html' ) ;
}

#------------------------------------------------------
#
# Sectioning
#
#------------------------------------------------------

=pod

=item * section()

Replies a section
Takes 3 args:

=over

=item * title (string)

is the title of the new section.

=item * content (string)

is the content of the new section

=item * root (string)

is the root directory for the generated documentation.

=back

=cut
sub section($$$) : method {
  my $self = shift ;
  my $title = $_[0] || confess( 'you must specify the title' ) ;
  my $content = $_[1] || '' ;
  my $rootdir = $_[2] || confess( 'you must specify the root directory' ) ;
  return $self->par( join( '',
			   "<table BORDER=\"0\" WIDTH=\"100%\" ",
			   "CELLPADDING=\"1\" CELLSPACING=\"0\">\n",
			   "<tr>\n",
			   "<td BGCOLOR=\"#EEEEFF\">\n",
			   $title,
			   "</td>",
			   "</tr>\n",
			   "</table><br>\n",
			   $content ) ) ;
}

#------------------------------------------------------
#
# Right Frames
#
#------------------------------------------------------


=pod

=item * frame_subpart()

Replies a subpart of a frame
Takes 3 args:

=over

=item * title (string)

is the title of the part.

=item * text (array)

is the content of the frame.

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub frame_subpart($$$) : method {
  my $self = shift ;
  my $title = $_[0] || '' ;
  my $content = "<P>" ;
  if ( $title ) {
    $content .= "<FONT size=\"+1\">$title</FONT><BR>\n" ;
  }
  if ( isarray( $_[1] ) ) {
    foreach my $line (@{$_[1]}) {
      $content .= $line."<BR>\n" ;
    }
  }
  return $content."</P>\n" ;
}

=pod

=item * frame_window()

Replies a frame
Takes 3 args:

=over

=item * title (string)

is the title of the frame (could be empty).

=item * text (string)

is the content of the frame.

=item * prefix (optional string)

is a string which is put before the title

=back

=cut
sub frame_window($$) : method {
  my $self = shift ;
  my $title = $_[0] || '' ;
  my $text = $_[1] || '' ;
  return join( '',
	       ( $_[2] ? $self->par($_[2]) : '' ),
	       ($title ? "<FONT size=\"+1\"><B>$title</B></FONT>":''),
	       "<TABLE BORDER=\"0\" WIDTH=\"100%\">\n<TR>\n",
	       "<TD NOWRAP>",
               $text,
               "</TD></TR></TABLE><BR>\n" ) ;
}

#------------------------------------------------------
#
# Navigation
#
#------------------------------------------------------

=pod

=item * get_navigation_bar()

Replies the navigation bar.
Takes 3 args:

=over

=item * url (string)

is the url of the generated page.

=item * params (hash ref)

is a set of parameters used to generate the bar.

=item * root (string)

is the root directory for the generated documentation.

=back

=cut
sub get_navigation_bar($$$) : method {
  my $self = shift ;
  my $thispage = $_[0] || confess( 'the url must be provided' ) ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;
  confess( 'params is not an associative aray' ) unless (ishash($_[1])) ;

  my $overview = "<b>".$self->{'LANG'}->get('I18N_LANG_OVERVIEW')."</b>" ;
  my $tree = "<b>".$self->{'LANG'}->get('I18N_LANG_TREE')."</b>" ;
  my $index = "" ;
  my $newbuttons = '';

  my $prev = html_uc( $self->{'LANG'}->get('I18N_LANG_PREV') ) ;
  my $next = html_uc( $self->{'LANG'}->get('I18N_LANG_NEXT') ) ;

  if ( ! $_[1]{'overview'} ) {
    $overview = $self->ext_wt_href('overview-summary',$overview,$rootdir) ;
  }
  if ( ! $_[1]{'tree'} ) {
    $tree = $self->ext_wt_href('overview-tree',$tree,$rootdir) ;
  }
  if ( $_[1]{'index'} ) {
    $index = $self->href( htmlcatfile( $rootdir,
				       $self->filename('index',0) ),
			  "<b>".$self->{'LANG'}->get('I18N_LANG_INDEX')."</b>",
			  $self->browserframe('index') ) ;
    if ($index) {
      $index = "<td BGCOLOR=\"#EEEEFF\">&nbsp;$index&nbsp;</td>\n";
    }
  }
  if ( $_[1]{'previous'} ) {
    $prev = $self->href($_[1]{'previous'},$prev) ;
  }
  if ( $_[1]{'next'} ) {
    $next = $self->href($_[1]{'next'},$next) ;
  }

  if ( $_[1]{'notree'} ) {
    $tree = "" ;
  }
  else {
    $tree = "<td BGCOLOR=\"#EEEEFF\">&nbsp;$tree&nbsp;</td>\n" ;
  }

  # new buttons
  if ( ( $_[1]{'userdef'} ) &&
       ( ! isemptyarray($_[1]->{'userdef'}) ) ) {
    foreach my $button (@{$_[1]->{'userdef'}}) {
      if ( ($button->{'url'}) && ($button->{'label'}) ) {
	my $str = $self->href($button->{'url'},
			      $self->{'LANG'}->get($button->{'label'})) ;
	$newbuttons .= "<td BGCOLOR=\"#EEEEFF\">&nbsp;<B>$str</B>&nbsp;</td>\n" ;
      }
    }
  }

  my $content = join( '',
		      "<table BORDER=\"0\" WIDTH=\"100%\" ",
		      "CELLPADDING=\"1\" CELLSPACING=\"0\">\n",
		      "<tr>\n",
		      "<td COLSPAN=2 BGCOLOR=\"#EEEEFF\">\n",
		      # First row
		      "<table BORDER=\"0\" CELLPADDING=\"0\" ",
		      "CELLSPACING=\"3\">\n",
		      "<tr ALIGN=\"center\" VALIGN=\"top\">\n",
		      "<td BGCOLOR=\"#EEEEFF\">&nbsp;$overview&nbsp;</td>\n",
		      $tree,
		      $newbuttons,
		      $index,
		      "</tr>\n</table>\n",
		      "</td>\n",
		      # Name of the doc
		      "<td ALIGN=\"right\" VALIGN=\"top\" ROWSPAN=3><em><b>",
		      $self->{'TITLE'},
		      "</b></em></td>\n</tr>\n",
		      # Second row
		      "<tr>\n",
		      "<td BGCOLOR=\"white\"><font SIZE=\"-2\">",
		      "$prev&nbsp;&nbsp;$next",
		      "</font></td>\n",
		      "<td BGCOLOR=\"white\"><font SIZE=\"-2\">",
		      $self->ext_href('main_index',"<b>".
				      html_uc( $self->{'LANG'}->get('I18N_LANG_FRAMES') ).
				      "</b>",$rootdir),
		      "&nbsp;&nbsp;",
		      $self->href($thispage,"<b>".
				  html_uc( $self->{'LANG'}->get('I18N_LANG_NO_FRAME') ).
				  "</b>",
				  $self->browserframe('main_index')),
		      "&nbsp;</font></td>\n",
		      "</tr>\n",
		      "</table>\n"
		    ) ;
}

#------------------------------------------------------
#
# Tabulars
#
#------------------------------------------------------

=pod

=item * build_onecolumn_array()

Replies an one-column array.
Takes 2 args:

=over

=item * title (string)

is the title of the array

=item * cells (array ref)

is the content of the returned cells.

=back

=cut
sub build_onecolumn_array($$) : method {
  my $self = shift ;
  my $content = join( '',
               	      "<DIV><TABLE BORDER=\"1\" ",
		      "CELLPADDING=\"3\" CELLSPACING=\"0\" ",
		      "WIDTH=\"100%\">\n",
               	      "<TR BGCOLOR=\"#CCCCFF\">\n",
               	      "<TD COLSPAN=2><FONT SIZE=\"+2\"><B>",
		      $_[0] || '',
		      "</B></FONT></TD>\n",
               	      "</TR>\n" ) ;
  confess( 'cells is not an array' ) unless (isarray($_[1])) ;
  foreach my $case (@{$_[1]}) {
    $content .= join( '',
                      "<TR BGCOLOR=\"white\">",
                      "<TD WIDTH=\"20%\" ALIGN=\"left\" VALIGN=\"top\">",
		      $case,
		      "</TD>",
                      "</TR>\n" ) ;
  }
  $content .= "</TABLE><BR></DIV>\n" ;
  return $content ;
}

=pod

=item * build_small_array()

Replies an small one-column array.
Takes 2 args:

=over

=item * title (string)

is the title of the array

=item * cells (array ref)

is the content of the returned cells.

=back

=cut
sub build_small_array($$) : method {
  my $self = shift ;
  my $content = join( '',
               	      "<P><TABLE BORDER=\"1\" CELLPADDING=\"3\" ",
		      "CELLSPACING=\"0\" WIDTH=\"100%\">\n",
               	      "<TR BGCOLOR=\"#EEEEFF\">\n",
               	      "<TD><B>",
		      $_[0] || '',
		      "</B></TD>\n",
               	      "</TR>\n" ) ;
  confess( 'cells is not an array' ) unless (isarray($_[1])) ;
  foreach my $case (@{$_[1]}) {
    $content .= join( '',
                      "<TR BGCOLOR=\"white\">",
                      "<TD ALIGN=\"left\" VALIGN=\"top\">",
		      $case,
                      "</TD></TR>\n" ) ;
  }
  $content .= "</TABLE></P>\n" ;
  return $content ;
}

=pod

=item * build_tiny_array()

Replies an small one-column array.
Takes 2 args:

=over

=item * title (string)

is the title of the array

=item * cells (array ref)

is the content of the returned cells.

=back

=cut
sub build_tiny_array($$) : method {
  my $self = shift ;
  my $content = join( '',
               	      "<P><TABLE BORDER=\"1\" CELLPADDING=\"3\" ",
		      "CELLSPACING=\"0\" WIDTH=\"100%\">\n",
               	      "<TR BGCOLOR=\"#EEEEEFF\">\n",
               	      "<TD><FONT SIZE=\"-1\"><B>",
		      $_[0] || '',
		      "</B></FONT></TD>\n",
               	      "</TR>\n" ) ;
  confess( 'cells is not an array' ) unless (isarray($_[1])) ;
  foreach my $case (@{$_[1]}) {
    $content .= join( '',
                      "<TR BGCOLOR=\"white\">",
                      "<TD ALIGN=\"left\" VALIGN=\"top\">",
		      "<FONT SIZE=\"-1\">",
		      $case,
		      "</FONT>",
                      "</TD></TR>\n" ) ;
  }
  $content .= "</TABLE></P>\n" ;
  return $content ;
}

=pod

=item * build_twocolumn_array()

Replies an two-column array.
Takes 2 args:

=over

=item * title (string)

is the title of the array

=item * cells (array ref)

is the content of the returned cells.

=back

=cut
sub build_twocolumn_array($$) : method {
  my $self = shift ;
  my $content = join( '',
               "<P></P><TABLE BORDER=\"1\" ",
	       "CELLPADDING=\"3\" CELLSPACING=\"0\" ",
	       "WIDTH=\"100%\">\n",
               "<TR BGCOLOR=\"#CCCCFF\">\n",
               "<TD COLSPAN=2><FONT SIZE=\"+2\"><B>",
	       $_[0] || '',
	       "</B></FONT></TD>\n",
               "</TR>\n" ) ;
  confess( 'cells is not an array' ) unless (isarray($_[1])) ;
  foreach my $cellule (@{$_[1]}) {
    my $name = $cellule->{name} ;
    my $explanation = $cellule->{explanation} || '' ;
    if ( $name ) {
      if ( ! $explanation ) {
        $explanation = "&nbsp;" ;
      }
      $content = join( '', 
                       $content,
                       "<TR BGCOLOR=\"white\">",
                       "<TD WIDTH=\"20%\" ALIGN=\"left\" VALIGN=\"top\">",
                       $name,
                       "</TD><TD>",
                       $explanation,
                       "</TD></TR>\n" ) ;
    }
  }
  $content .= "</TABLE>\n" ;
  return $content ;
}

=pod

=item * build_threecolumn_array()

Replies an two-column array.
Takes 3 args:

=over

=item * title (string)

is the title of the array

=item * cells (array ref)

is the content of the returned cells.

=item * anchor (string)

is the name of the anchor.

=back

=cut
sub build_threecolumn_array($$$) : method {
  my $self = shift ;
  my $content = join( '',
		      "<P>",
		      ( $_[2] ? "<A NAME=\"$_[2]\"></A>" : '' ),
		      "<TABLE BORDER=\"1\" ",
		      "CELLPADDING=\"3\" CELLSPACING=\"0\" ",
		      "WIDTH=\"100%\">\n",
		      "<TR BGCOLOR=\"#CCCCFF\">\n",
		      "<TD COLSPAN=2><FONT SIZE=\"+2\"><B>",
		      $_[0] || '' ,
		      "</B></FONT></TD>\n",
		      "</TR>\n" ) ;
  confess( 'cells is not an array' ) unless (isarray($_[1])) ;
  foreach my $cellule (@{$_[1]}) {
    my $name = ${%{$cellule}}{name} ;
    my $explanation = ${%{$cellule}}{explanation} || '' ;
    my $type = ${%{$cellule}}{type} ;
    if ( $name ) {
      if ( ! $explanation ) {
        $explanation = "&nbsp;" ;
      }
      $content = join( '', 
                       $content,
                       "<TR BGCOLOR=\"white\"><TD WIDTH=\"1%\" ",
		       "VALIGN=\"top\"><FONT SIZE=\"-1\"><CODE>",
                       $type,
                       "</CODE></FONT></TD>",
                       "<TD ALIGN=\"left\" VALIGN=\"top\"><CODE>",
                       $name,
                       "</CODE><BR>\n",
                       $explanation,
                       "</TD></TR>\n" ) ;
    }
  }
  $content .= "</TABLE></P>\n" ;
  return $content ;
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
