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

Bib2HTML::Generator::Theme - A theme for the HTML generator

=head1 SYNOPSYS

use Bib2HTML::Generator::Theme ;

my $gen = Bib2HTML::Generator::Theme->new( generator,
                                           bib2html,
                                           target,
                                           title,
                                           lang ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::Theme is a Perl module, which proposes
a documentation theme for the HTML generator of bib2html.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use Bib2HTML::Generator::Theme;

    my $gen = Bib2HTML::Generator::Theme->new( $generator,
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

This section contains only the methods in Theme.pm itself.

=over

=cut

package Bib2HTML::Generator::Theme;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;

use Carp ;
use File::Spec ;

use Bib2HTML::General::Verbose ;
use Bib2HTML::General::Error ;
use Bib2HTML::General::HTML ;
use Bib2HTML::General::Misc ;
use Bib2HTML::Generator::FileWriter ;
use Bib2HTML::Generator::StdOutWriter ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of theme
my $VERSION = "2.0" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$$) : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { 'PARENT' => $_[0] || confess( 'you must supply the parent object' ),
	       'BIB2HTML' => $_[1] || '',
	       'TARGET_DIR' => $_[2] || confess( 'you must supply the target directory' ),
	       'TITLE' => $_[3] || '',
	       'LANG' => $_[4] || confess( 'you must supply the language object' ),
	     } ;

  my $simpleclass = $class;
  if ($class =~ /^.*::(.+?)$/) {
    $simpleclass = "$1";
  }

  # Register lang files
  if ($self->{'LANG'}) {
    $self->{'LANG'}->registerLang("Theme.$simpleclass");
  }

  bless( $self, $class );
  return $self;
}

=pod

=item * copy_files()

Copies some files from the bib2html distribution directly inside the
HTML documentation tree.

=cut
sub copy_files() : method {
  my $self = shift ;
}

=pod

=item * get_stream_writer()

Replies the instance of the output stream writer.

=cut
sub get_stream_writer() : method {
  my $self = shift ;
  if (!$self->{'STREAM_WRITER'}) {
    $self->{'STREAM_WRITER'} = new Bib2HTML::Generator::FileWriter->new();
  }
  return $self->{'STREAM_WRITER'};
}

=pod

=item * set_stream_writer($)

Set the instance of the output stream writer.
Replies the old writer.
Takes 1 arg:

=over

=item * writer (ref to Bib2HTML::Generator::Writer)

is the instance of the writer.

=back

=cut
sub set_stream_writer($) : method {
  my $self = shift ;
  my $writer = shift;
  my $old_writer = $self->{'STREAM_WRITER'};
  $self->{'STREAM_WRITER'} = $writer;
  return $old_writer;
}

#------------------------------------------------------
#
# Filename API
#
#------------------------------------------------------

=pod

=item * ext_href()

Replies a hyperlink according to the parameters
Takes 3 args:

=over

=item * section (string)

is the id of the section.

=item * label (string)

is the label of the hyperlink

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub ext_href($$$) : method {
  my $self = shift ;
  my $section = shift || confess( 'you must supply the section id' ) ;
  my $label = shift || '' ;
  my $rootdir = shift || confess( 'you must supply the root directory' ) ;
  return $self->href( htmlcatfile($rootdir,$self->filename($section,@_)),
                      $label,
                      $self->browserframe($section) ) ;
}

=pod

=item * ext_wt_href()

Replies a hyperlink according to the parameters (without target)
Takes 3 args:

=over

=item * section (string)

is the id of the section.

=item * label (string)

is the label of the hyperlink

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub ext_wt_href($$$) : method {
  my $self = shift ;
  my $section = shift || confess( 'you must supply the section id' ) ;
  my $label = shift || '' ;
  my $rootdir = shift || confess( 'you must supply the root directory' ) ;
  return $self->href( htmlcatfile($rootdir,$self->filename($section,@_)),
                      $label ) ;
}

=pod

=item * filename()

Replies the filename of the specified section.
Takes 1 arg:

=over

=item * section (string)

is the name of the section.

=back

=cut
sub filename : method {
  my $self = shift ;
  return $self->{'PARENT'}->filename(@_) ;
}

=pod

=item * browserframe()

Replies the frame used for the specified section.
Takes 1 arg:

=over

=item * section (string)

is the name of the section.

=back

=cut
sub browserframe : method {
  my $self = shift ;
  return $self->{'PARENT'}->browserframe(@_) ;
}

#------------------------------------------------------
#
# Page API
#
#------------------------------------------------------

=pod

=item * get_copyright()

Replies a string that represents the copyright of this translator.

=over

=item * rootdir (string)

is the path to the root directory

=back

=cut
sub get_copyright($) : method {
  my $self = shift ;
  my $rootdir = $_[0] ;
  return join( '',
	       $self->par( $self->small( $self->href( $self->{'BIB2HTML'}{'BUG_URL'},
						      $self->{'LANG'}->get( 'I18N_LANG_SUBMIT_BUG'), "_top" ) ) ),
	       $self->par( $self->small( $self->{'LANG'}->get( 'I18N_LANG_BIB2HTML_COPYRIGHT',
							       $self->href( $self->{'BIB2HTML'}{'URL'},
									    "bib2html ".$self->{'BIB2HTML'}{'VERSION'},
									    "_top" ),
							       $self->href( "mailto:".$self->{'BIB2HTML'}{'AUTHOR_EMAIL'},
									    $self->{'BIB2HTML'}{'AUTHOR'} ),
							       $self->href( "http://www.gnu.org/copyleft/gpl.html",
									    "GNU General Public License",
									    "_top" ) ) ) )
	     ) ;
}

=pod

=item * get_html_index()

Replies the content of the main index.html
Takes 1 arg:

=over

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub get_html_index($) {
  my $self = shift ;
  my $rootdir = $_[0] || confess( 'you must supply the root directory' ) ;
  return join( '',
	       "<FRAMESET cols=\"20%,80%\">\n",
	       "<FRAMESET rows=\"30%,70%\">\n",
	       "<FRAME src=\"",
	       htmlcatfile($rootdir,$self->filename('overview-frame')),
	       "\" name=\"",
	       $self->browserframe('overview-frame'),
	       "\">\n<FRAME src=\"",
	       htmlcatfile($rootdir,$self->filename('allelements')),
	       "\" name=\"",
	       $self->browserframe('allelements'),
	       "\">\n</FRAMESET>\n<FRAME src=\"",
	       htmlcatfile($rootdir,$self->filename('overview-summary')),
	       "\" name=\"",
	       $self->browserframe('overview-summary'),
	       "\">\n<NOFRAMES>\n",
	       $self->{'LANG'}->get('I18N_LANG_NO_FRAME_ALERT',
				    $self->filename('overview-summary'),
				    ''),
	       "</NOFRAMES>\n",
	       "</FRAMESET>\n" ) ;
}

=pod

=item * create_html_page()

Creates an HTML page without a <BODY>.
Takes 3 args:

=over

=item * filename (string)

is the name of the file in which the page
must be created.

=item * content (string)

is the content of the page.

=item * title (string)

is the title of the page.

=item * rootdir (string)

is the path to the root directory.

=item * frameset (boolean)

must be true if the generated page must respect the w3c frameset definition,
otherwhise it will respect the w3c transitional definition

=back

=cut
sub create_html_page($$$$$) : method {
  my $self = shift ;
  my $rootdir = $_[3] || confess( 'you must supply the root directory' ) ;
  confess( 'you must supply the filename' ) unless $_[0] ;
  my $filename = File::Spec->catfile( $self->{'TARGET_DIR'}, htmlpath($_[0]) ) ;
  Bib2HTML::General::Verbose::two( "Writing $filename..." ) ;

  my $writer = $self->get_stream_writer();

  $writer->openstream("$filename")
    or Bib2HTML::General::Error::syserr( "$filename: $!\n" );

  my $header ;
  if ( $_[4] ) {
    $header = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Frameset//EN\" \"http://www.w3.org/TR/REC-html40/frameset.dtd\">" ;
  }
  else {
    $header = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">" ;
  }

  $writer->out(join( '',
  		   	 $header,
			 "\n\n<!-- Generated by bib2html ".$self->{'BIB2HTML'}{'VERSION'},
			 " on ",
			 "".localtime(),
			 " -->\n\n",
  		  	 "<HTML>\n<HEAD>\n<TITLE>",
			 $_[2] || '',
			 "</TITLE>\n",
			 "<META http-equiv=\"Content-Type\" ",
			 "content=\"text/html; charset=",
			 $self->get_html_encoding(),#ISO-8859-1
			 "\">\n",
			 $self->get_html_header($rootdir),
			 "</HEAD>\n",
			 $_[1] || '',
			 "</HTML>" ) ) ;

  $writer->closestream() ;
}

=pod

=item * get_html_encoding()

Replies the HTML encoding of each page
(by default ISO-8859-1).

=cut
sub get_html_encoding() : method {
  my $self = shift ;
  return $self->{'html_encoding'} || "ISO-8859-1" ;
}

=pod

=item * set_html_encoding($)

Set the HTML encoding of each page
Takes 1 arg:

=over

=item * encoding (string)

is the new encoding

=back

=cut
sub set_html_encoding($) : method {
  my $self = shift ;
  my $encoding = shift;
  $self->{'html_encoding'} = $encoding if ($encoding) ;
}

=pod

=item * get_html_header()

Replies the HTML header of each page.
Takes 1 arg:

=over

=item * rootdir (string)

is the path to the root directory

=back

=cut
sub get_html_header($) : method {
  my $self = shift ;
  return '' ;
}

=pod

=item * create_html_body_page()

Creates an HTML page with a <BODY>.
Takes 3 args:

=over

=item * filename (string)

is the name of the file in which the page
must be created.

=item * content (string)

is the content of the page.

=item * title (string)

is the title of the page.

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub create_html_body_page($$$$@) : method {
  my $self = shift ;
  my $filename = shift ;
  my $content = shift ;
  my $title = shift ;
  my $rootdir = shift || confess( "the rootdir must be supplied" ) ;
  $content = join( '',
		   "<BODY",
		   ( $self->{'BACKGROUND_COLOR'} ?
		     " BGCOLOR=\"" .
		     $self->{'BACKGROUND_COLOR'} .
		     "\"" : '' ),
		   ">\n",
		   $content ) ;
  my $small ;
  if ((@_)&&("$_[0]" eq 'small')) {
    shift @_ ;
    $small = 1 ;
  }
  $self->mergeValidHTMLIcons($content,$rootdir,$small,@_) ;
  $content .= "\n</BODY>\n",
  $self->create_html_page( "$filename",
			   "$content",
			   "$title",
			   "$rootdir",
			   0 ) ;
}

=pod

=item * getMyValidHTML()

Replies the list of W3C protocols for which this theme
was validated. You must override this method.

=cut
sub getMyValidHTML() {
  my $self = shift ;
  return () ;
}

sub mergeValidHTMLIcons($$$@) {
  my $self = shift ;
  if (int(@_)>3) {

    #
    # A protocol is displayed as supported only if
    # the generator AND the theme support it, or
    # if the protocol was CSS and was supported
    # by the theme only (We assume that the generators
    # does not use any CSS syntax)
    #
    my @themevalid = $self->getMyValidHTML() ;
    my @valid = () ;
    for(my $i=3; $i<int(@_); $i++) {
      if (strinarray("$_[$i]",\@themevalid)) {
	push @valid, "$_[$i]" ;
      }
    }
    if (strinarray('css',\@themevalid)) {
      push @valid, 'css' ;
    }

    if ($_[2]) {
      setAsValidHTML_small($_[0],$_[1],@valid) ;
    }
    else {
      setAsValidHTML($_[0],$_[1],@valid) ;
    }
  }
}

#------------------------------------------------------
#
# Paragraph API
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
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * frame_window()

Replies a frame
Takes 3 args:

=over

=item * title (string)

is the title of the frame.

=item * text (string)

is the content of the frame.

=item * prefix (optional string)

is a string which is put before the title

=back

=cut
sub frame_window($$) : method {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * partseparator()

Replies a part separator.

=cut
sub partseparator($) {
  my $self = shift ;
  return "<HR>\n" ;
}

=pod

=item * title()

Formats a page title
Takes 2 args:

=over

=item * text (string)

=item * text_before (optional boolean)

indicates if some text are before this title

=back

=cut
sub title($) {
  my $self = shift ;
  my $text = $_[0] || confess( 'you must specify the text' ) ;
  return
    ($_[1] ? $self->partseparator() : '') .
      "<center><h2>$text</h2></center>\n\n" ;
}

=pod

=item * subtitle()

Formats a page subtitle
Takes 1 arg:

=over

=item * text (string)

=item * text_before (optional boolean)

indicates if some text are before this title

=back

=cut
sub subtitle($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  if ( ! $text ) {
    Bib2HTML::General::Error::syswarm( 'a title was expected' ) ;
  }
  return
    ($_[1] ? "<hr>\n" : '').
      "<h2>$text</h2>\n" ;
}

=pod

=item * strong()

Formats a keyword
Takes 2 args:

=over

=item * text (string)

=back

=cut
sub strong($) {
  my $self = shift ;
  my $text = $_[0] || confess( 'you must specify the text' ) ;
  return "<b>$text</b>" ;
}

=pod

=item * entry_title()

Formats the title of an BibTeX entry.
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub entry_title($) {
  my $self = shift ;
  my $title = $_[0] || '' ;
  if ( ! $title ) {
    Bib2HTML::General::Error::syswarm( 'a title was expected' ) ;
  }
  return join( '',
	       "&quot;<i><b>",
	       $title,
	       "</b></i>&quot;" ) ;
}

=pod

=item * format_date()

Formats a date.
Takes 2 args:

=over

=item * month (string)

=item * year (string)

=back

=cut
sub format_date($$) {
  my $self = shift ;
  my $month = $_[0] || '' ;
  my $year = $_[1] || confess( 'you must supply the year' ) ;
  return ($month?"$month&nbsp;":"")."$year" ;
}

=pod

=item * href()

Replies a hyperlink.
Takes 3 args:

=over

=item * url (string)

is the URL to link to

=item * label (string)

is the label of the hyperlink

=item * target (optional string)

is the frame target.

=back

=cut
sub href($$) {
  my $self = shift ;
  my $url = $_[0] || confess( 'you must specify the URL' ) ;
  my $label = $_[1] ;
  return '' unless ($label) ;
  return join( '',
	       "<A HREF=\"",
	       $url,
	       "\"",
	       ( $_[2] ? " target=\"$_[2]\"" : "" ),
	       ">",
	       $label,
	       "</A>" ) ;
}

=pod

=item * small()

Replies a text with a small size.
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub small($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  return join( '',
	       "<FONT SIZE=\"-1\">",
	       $text,
	       "</FONT>\n" ) ;
}

=pod

=item * tiny()

Replies a text with a tiny size.
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub tiny($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  return join( '',
	       "<FONT SIZE=\"-2\">",
	       $text,
	       "</FONT>\n" ) ;
}

=pod

=item * par()

Replies a paragraph.
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub par($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  return join( '',
	       "<P>",
	       $text,
	       "</P>\n" ) ;
}

=pod

=item * get_tree_node()

Replues the HTML string for the specified tree.
a list.
Takes 2 args:

=over

=item * node (string)

is the string that is the root of the tree.

=item * subs (string)

is an HTML string that describes the children.

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub get_tree_node($$$) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my $sub = $_[1] || '' ;
  $sub = "<ul>$sub</ul>" ;
  if ( $text ) {
    return "<li type=\"circle\">".$text.$sub."</li>\n" ;
  }
  else {
    return "$sub\n" ;
  }
}

=pod

=item * get_tree_leaf()

Replies a line of a tree which will be displayed inside
a list.
Takes 1 args:

=over

=item * node (string)

is the string that is the root of the tree.

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub get_tree_leaf($$) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  return join( '',
               "<li type=\"circle\">",
               $text,
               "</li>\n" ) ;
}

=pod

=item * get_tree()

Creates a tree.
Takes 2 or 3 args:

=over

=item * tree (hash)

is the tree

=item * rootdir (string)

is the path to the root directory

=item * root label (optional string)

is the label of the root node

=back

=cut
sub get_tree($$;$) : method {
  my $self = shift ;
  my $tree = $_[0] || confess( "you must supply the tree" ) ;
  my $rootdir = $_[1] || confess( 'you must supply the root directory' ) ;
  my $content = $self->__get_default_tree__($tree,$rootdir) ;
  if ( $content ) {
    return "<ul>$content</ul>\n" ;
  }
  else {
    return "$content" ;
  }
}

sub __get_default_tree__($$) {
  my $self = shift ;
  my $tree = $_[0] || confess( "you must supply the tree" ) ;
  my $rootdir = $_[1] || confess( 'you must supply the root directory' ) ;
  my $content = '' ;

  my @c = keys %{$tree};
  @c = sortbyletters(@c);
  foreach my $children (@c) {

    if ( isemptyhash($tree->{"$children"}) ) {
      # leaf
      $content .= $self->get_tree_leaf("$children",$rootdir) ;
    }
    else {
      # node
      my $sub = $self->__get_default_tree__($tree->{"$children"},$rootdir) ;
      $content .= $self->get_tree_node("$children",$sub,$rootdir) ;
    }

  }

  return $content ;
}

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
  confess( 'you must overwrite this method' ) ;
}

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
  confess( 'you must overwrite this method' ) ;
}

#------------------------------------------------------
#
# Array API
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
  confess( 'you must overwrite this method' ) ;
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
  confess( 'you must overwrite this method' ) ;
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
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * build_tiny_array()

Replies a tiny one-column array.
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
  confess( 'you must overwrite this method' ) ;
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
  confess( 'you must overwrite this method' ) ;
}

#------------------------------------------------------
#
# Index API
#
#------------------------------------------------------

=pod

=item * format_index_page()

Replies a formatted page for the index.
Takes 3 args:

=over

=item * letterlist (string)

is the list of letters of the index.

=item * letter (string)

is the current letter.

=item * content (array ref)

is the content of the page.

=back

=cut
sub format_index_page($$$) : method {
  my $self = shift ;
  my $letterlist = $_[0] || '' ;
  my $letter = notempty( $_[1], 'you must supply the index letter for this page' ) ;

  my $content = join( '',
		      ( $letterlist ?
			$letterlist.$self->partseparator() : '' ),
		      "<H2>",
		      uc($letter),
		      "</H2>\n",
		      "<DL>" ) ;

  my $previouslabel = '' ;
  my @currententry = () ;

  foreach my $entry (@{$_[2]}) {
    if ( "$previouslabel" eq $entry->{'label'} ) {
      # Caching this entry for futher display
      push @currententry, $entry ;
    }
    else {
      # Generate the page content
      $self->__generate_index_entry(\@currententry,$content,$entry);
    }

    $previouslabel = $entry->{'label'} ;
  }

  if ( @currententry ) {
    $self->__generate_index_entry(\@currententry,$content);
  }

  $content .= join( '',
		    "</DL>",
		    ( $letterlist ?
		      $self->partseparator().$letterlist : '' ) ) ;

  return $content ;
}

sub __generate_index_entry($$;$) {
  my $self = shift ;

  # Generates the previous entries
  if ( @{$_[0]} == 1 ) {
    $_[1] .= join( '',
		   "<DT>",
		   $self->href( $_[0]->[0]{'url'},
				$_[0]->[0]{'label'} ),
		   ( $_[0]->[0]{'short_comment'} ?
		     " - ".$_[0]->[0]{'short_comment'} :
		     '' ),
		   "</DT><DD>",
		   $_[0]->[0]{'comment'},
		   "&nbsp;</DD>\n" ) ;
  }
  elsif ( @{$_[0]} > 1 ) {
    $_[1] .= join( '',
		   "<DT>",
		   $_[0]->[0]{'label'},
		   "</DT><DD><UL>" ) ;
    foreach my $entry_to_display (@{$_[0]}) {
      $_[1] .= join( '',
		     "<LI>",
		     $entry_to_display->{'comment'},
		     $self->href( $entry_to_display->{'url'},
				  "<IMG src=\"./loupe.gif\" alt=\"\" ".
				  "border=\"0\" align=\"center\">" ),
		     "</LI>\n"
		   ) ;
    }
    $_[1] .= "</UL></DD>\n" ;
  }
  # Prepare the caching for this entry
  if ( $_[2] ) {
    @{$_[0]} = ( $_[2] ) ;
  }
}

#------------------------------------------------------
#
# Filename API
#
#------------------------------------------------------

=pod

=item * get_math_start_tag()

Replies the HTML balise which starts the math mode.

=cut
sub get_math_start_tag() : method {
  my $self = shift ;
  return "<math>" ;
}

=pod

=item * get_math_stop_tag()

Replies the HTML balise which stops the math mode.

=cut
sub get_math_stop_tag() : method {
  my $self = shift ;
  return "</math>" ;
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
