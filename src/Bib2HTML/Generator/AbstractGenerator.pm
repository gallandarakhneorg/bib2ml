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

Bib2HTML::Generator::AbstractGenerator - An abstract generator

=head1 DESCRIPTION

Bib2HTML::Generator::AbstractGenerator is a Perl module, which permits to
generate some document for a BibTeX database. This class must be
overwrite.

=head1 SYNOPSYS

Bib2HTML::Generator::AbstractGenerator->new( content, output, info, titles,
                                             lang, [params] ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::AbstractGenerator is a Perl module, which permits to
generate some documents for a BibTeX database.

=head1 GETTING STARTED

=head2 Initialization

Acceptable parameters to the constructor are:

=over

=item * content (hash)

is the content of the bibliography to output.

=item * output (string)

is the output directory in which the HTML page must be put.

=item * bib2html_data (hash)

contains some information on Bib2HTML :

=over

=item VERSION

is the version of Bib2HTML.

=item BUG_URL

is the URL where to submit a bug.

=item URL

is the URL of the main page of Bib2HTML.

=item AUTHOR_EMAIL

is the email of the author of Bib2HTML.

=item AUTHOR

is the nmae of the author of Bib2HTML.


=item PERLSCRIPTDIR

is the dorectory where is the Bib2HTML perl script.

=back

=item * titles (hash)

is the titles of the pages:

=over

=item SHORT

is the title shown in the window bar.

=item LONG

is the title shown in the default HTML pag.

=back

=item * lang (string)

is the name of the language to use

=item * show_bibtex (boolean)

indicates if this parser must generate a verbatim of the BibTeX code

=item * params (optional array)

is the set of parameters passed to the generator.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in AbstractGenerator.pm itself.

=over

=cut

package Bib2HTML::Generator::AbstractGenerator;

@ISA = ('Exporter');
@EXPORT = qw( &display_supported_generators
	      &display_supported_languages
	      &display_supported_themes );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use File::Basename ;
use File::Spec;

use Bib2HTML::General::Misc;
use Bib2HTML::General::HTML;
use Bib2HTML::Generator::LangManager;
use Bib2HTML::Generator::FileWriter;
use Bib2HTML::Generator::StdOutWriter;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of abstract generator
my $VERSION = "6.0" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$$$;$) : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { 'TARGET' => $_[1] || File::Spec->curdir(),
               'TARGET_NOT_REMOVABLE' => [],
	       'CONTENT' => $_[0] || { },
	       'BIB2HTML' => { 'VERSION' => $_[2]{'VERSION'} || "???",
			       'BUG_URL' => $_[2]{'BUG_URL'} || "",
                               'URL' => $_[2]{'URL'} || "",
	                       'AUTHOR_EMAIL' => $_[2]{'AUTHOR_EMAIL'} || "",
                               'AUTHOR' => $_[2]{'AUTHOR'} || "",
                               'PERLSCRIPTDIR' => $_[2]{'PERLSCRIPTDIR'} || "",
			     },
	       'SHORT_TITLE' => $_[3]{'SHORT'},
	       'LONG_TITLE' => $_[3]{'LONG'},
	       'SHOW_BIBTEX' => $_[5],
	       'CACHE' => { 'BUILT_ENTRY_AUTHOR_LIST' => {},
			  },
	     } ;

  # Creates the language support
  confess( 'you must supply the language' ) unless ($_[4]) ;
  $self->{'LANG'} = Bib2HTML::Generator::LangManager->new($_[4]) ;

  # Sets the constants according to the language
  if ( ! $self->{'LONG_TITLE'} ) {
    $self->{'LONG_TITLE'} = ( $self->{'SHORT_TITLE'} ?
			      $self->{'SHORT_TITLE'} :
			      $self->{'LANG'}->get('I18N_LANG_DEFAULT_TITLE') ) ;
  }
  if ( ! $self->{'SHORT_TITLE'} ) {
    $self->{'SHORT_TITLE'} = $self->{'LONG_TITLE'} ;
  }
  $self->{'PLURIAL_TYPE_LABELS'} = { 'article' => $self->{'LANG'}->get('I18N_LANG_P_ARTICLE'),
				     'inproceedings' => $self->{'LANG'}->get('I18N_LANG_P_INPROCEEDINGS'),
				     'incollection' => $self->{'LANG'}->get('I18N_LANG_P_INCOLLECTION'),
				     'book' => $self->{'LANG'}->get('I18N_LANG_P_BOOK'),
				     'techreport' => $self->{'LANG'}->get('I18N_LANG_P_TECHREPORT'),
				     'unpublished' => $self->{'LANG'}->get('I18N_LANG_P_UNPUBLISHED'),
				     'booklet' => $self->{'LANG'}->get('I18N_LANG_P_BOOKLET'),
				     'conference' => $self->{'LANG'}->get('I18N_LANG_P_PROCEEDINGS'),
				     'proceedings' => $self->{'LANG'}->get('I18N_LANG_P_PROCEEDINGS'),
				     'inbook' => $self->{'LANG'}->get('I18N_LANG_P_INBOOK'),
				     'manual' => $self->{'LANG'}->get('I18N_LANG_P_MANUAL'),
				     'mastersthesis' => $self->{'LANG'}->get('I18N_LANG_P_MASTERTHESIS'),
				     'misc' => $self->{'LANG'}->get('I18N_LANG_P_MISC'),
				     'phdthesis' => $self->{'LANG'}->get('I18N_LANG_P_PHDTHESIS'),
				   } ;
  $self->{'SINGULAR_TYPE_LABELS'} = { 'article' => $self->{'LANG'}->get('I18N_LANG_S_ARTICLE'),
				      'inproceedings' => $self->{'LANG'}->get('I18N_LANG_S_INPROCEEDINGS'),
				      'incollection' => $self->{'LANG'}->get('I18N_LANG_S_INCOLLECTION'),
				      'book' => $self->{'LANG'}->get('I18N_LANG_S_BOOK'),
				      'techreport' => $self->{'LANG'}->get('I18N_LANG_S_TECHREPORT'),
				      'unpublished' => $self->{'LANG'}->get('I18N_LANG_S_UNPUBLISHED'),
				      'booklet' => $self->{'LANG'}->get('I18N_LANG_S_BOOKLET'),
				      'conference' => $self->{'LANG'}->get('I18N_LANG_S_PROCEEDINGS'),
				      'proceedings' => $self->{'LANG'}->get('I18N_LANG_S_PROCEEDINGS'),
				      'inbook' => $self->{'LANG'}->get('I18N_LANG_S_INBOOK'),
				      'manual' => $self->{'LANG'}->get('I18N_LANG_S_MANUAL'),
				      'mastersthesis' => $self->{'LANG'}->get('I18N_LANG_S_MASTERTHESIS'),
				      'misc' => $self->{'LANG'}->get('I18N_LANG_S_MISC'),
				      'phdthesis' => $self->{'LANG'}->get('I18N_LANG_S_PHDTHESIS'),
				    } ;
  $self->{'FORMATS'} = { 'name' => $self->{'LANG'}->get('I18N_LANG_FORMAT_NAME'),
			 'names' => $self->{'LANG'}->get('I18N_LANG_FORMAT_NAMES'),
		       } ;

  bless( $self, $class );

  # Params
  $self->{'GENERATOR_PARAMS'} = {} ;
  if ( ( $_[6] ) && ( ! isemptyhash($_[6]) ) ) {
    foreach my $param ( keys %{$_[6]} ) {
      # Format the parameter's name
      my $norm_param = lc($param) ;
      $norm_param =~ s/_/-/g ;

      # Get the current value and call the function to save it (eventually)
      my $value = $self->last_param($_[6]->{"$param"} || '') ;
      Bib2HTML::General::Error::syserr("unsupported generator parameter: ".lc("$norm_param"))
	  unless ($self->save_generator_parameter("$norm_param", $value));

      # If this parameter was not saved, save it
      $self->{'GENERATOR_PARAMS'}{"$norm_param"} = $value
	unless ( exists $self->{'GENERATOR_PARAMS'}{"$norm_param"} ) ;

    }
  }
  return $self;
}

#------------------------------------------------------
#
# Generation API
#
#------------------------------------------------------

=pod

=item * generate()

Generates the HTML pages.
You must NOT overwrite this method.

=cut
sub generate() : method {
  my $self = shift ;
  $self->pre_processing() ;
  $self->do_processing() ;
  $self->post_processing() ;
}

=pod

=item * pre_processing()

Pre_processing.

=cut
sub pre_processing() : method {
  my $self = shift ;
  my $rootdir = "." ;
  Bib2HTML::General::Verbose::three( "Doing the pre-processing...\n" ) ;
  Bib2HTML::General::Verbose::verb( "\tReplace all <BIB2HTML>...\n", 4 ) ;
  my $count = 0 ;
  if ( ! isemptyhash( $self->{'CONTENT'}{'entries'} ) ) {
    my @keys = keys %{$self->{'CONTENT'}{'entries'}} ;
    foreach my $key ( @keys ) {

      if ( ! isemptyhash( $self->{'CONTENT'}{'entries'}{$key}{'fields'} ) ) {

	my @fields = keys %{$self->{'CONTENT'}{'entries'}{$key}{'fields'}} ;

	foreach my $field ( @fields ) {
	  ( my $cnt,
	    $self->{'CONTENT'}{'entries'}{$key}{'fields'}{$field} ) =
	      $self->translate_bib2html_tags( $self->{'CONTENT'}{'entries'}{$key}{'fields'}{$field},
					      $key, $field, $rootdir ) ;
	  $count += $cnt ;
	}

      }

    }
  }

  # Create the stream writer
  my $writer;
  if ($self->genparam('stdout')) {
    $writer = Bib2HTML::Generator::StdOutWriter->new();
  }
  else {
    $writer = Bib2HTML::Generator::FileWriter->new();
  }
  $self->set_stream_writer($writer);
}

=pod

=item * create_output_directory()

Create the output directory.

=cut
sub create_output_directory() : method {
  my $self = shift;
  my $writer = $self->get_stream_writer();
  confess("no writer specified") unless ($writer);
  $self->{'TARGET'} = $writer->create_output_directory($self->{'TARGET'},@{$self->{'TARGET_NOT_REMOVABLE'}});
}

=pod

=item * set_unremovable_files(@)

Force this generator to not remove the specified
files when the output directory will be generated.

=cut
sub set_unremovable_files(@) : method {
  my $self = shift;
  @{$self->{'TARGET_NOT_REMOVABLE'}} = @_;
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

=pod

=item * do_processing()

Main processing.

=cut
sub do_processing() : method {
  my $self = shift ;
}

=pod

=item * post_processing()

Post_processing.

=cut
sub post_processing() : method {
  my $self = shift ;
}

=pod

=item * translate_bib2html_tags()

Replaces the Bib2HTML tags.
Takes 4 args.

=cut
sub translate_bib2html_tags($$$$) : method {
  my $self = shift ;
  my $rootdir = $_[3] || confess( 'you must supply the root directory' );
  my $text = $_[0] || '' ;
  my $count = 0 ;
  my $split = split_html_tags( $text ) ;
  if ( defined( $split ) ) {
    if ( isarray( $split ) ) {
      $text = '' ;
      my $inbib2html = undef ;
      foreach my $case ( @{$split} ) {
	if ( $case =~ /^<BIB2HTML\s*(.*)\s*>$/im ) {
	  $inbib2html = $self->html_extract_tag_params( $1 ) ;
	}
	elsif ( $case =~ /^<BIB2HTML\s*(.*)\s*\/>$/im ) {
	  $text .= $self->run_bib2html_post_action( $self->html_extract_tag_params( $1 ),
						    $_[1], $_[2], $rootdir ) ;
	  $count ++ ;
	}
	elsif ( $case =~ /^<\/BIB2HTML.*?>$/im ) {
	  if ( $inbib2html ) {
	    $text .= $self->run_bib2html_post_action( $inbib2html,
						      $_[1],
						      $_[2],
						      $rootdir ) ;
	    $count ++ ;
	  }
	  $inbib2html = undef ;
	}
	elsif ( ! defined( $inbib2html ) ) {
	  $text .= $case ;
	}
      }
    }
  }
  return ( $count, $text ) ;
}

=pod

=item * run_bib2html_post_action()

Replies the text corresponding to the specified bib2html tag.
Takes 4 args.

=cut
sub run_bib2html_post_action($$$$) : method {
  my $self = shift ;
  my $rootdir = $_[3] || confess( 'you must supply the root directory' );
  my $currententry = $_[1] || confess( 'you must supply the current entry key' ) ;
  my $currentfield = $_[2] || confess( 'you must supply the current field key' ) ;
  if ( ( $_[0] ) && ( ! isemptyhash( $_[0] ) ) ) {
    my $action = uc( $_[0]->{'action'} || '' ) ;

    if ( $action eq 'CITE' ) {
      my $label = $_[0]->{'label'} ;
      my $key = $_[0]->{'key'} || '' ;
      if ( $key ) {
	my $bibtex = new Bib2HTML::Translator::BibTeXEntry() ;
	if ( ! $label ) {
	  $label = $bibtex->citation_label( $key, $self->{'CONTENT'}{'entries'}{$key} ) ;
	}
	else {
	  $bibtex->save_citation_label( $key, $label ) ;
	}
	if ( exists $self->{'CONTENT'}{'entries'}{$key} ) {
	  my $filename = $self->filename('entry', $key ) ;

	  return $self->{'THEME'}->href( htmlcatfile($rootdir,$filename),
					 $label,
					 $self->browserframe('entry') ) ;
	}
	else {
	  Bib2HTML::General::Error::warm( "Can't found the entry key for a citation command inside the field '".$currentfield."'",
					  extract_file_from_location( $self->{'CONTENT'}{'entries'}{$currententry}{'location'} ),
					  extract_line_from_location( $self->{'CONTENT'}{'entries'}{$currententry}{'location'} ) ) ;
	  return "?" ;
	}
      }
      else {
	Bib2HTML::General::Error::warm( "Can't found the entry with the key '".$key."' for a citation command inside the field '".$currentfield."'",
					extract_file_from_location( $self->{'CONTENT'}{'entries'}{$currententry}{'location'} ),
					extract_line_from_location( $self->{'CONTENT'}{'entries'}{$currententry}{'location'} ) ) ;
	return "?" ;
      }
    }

  }
  return '' ;
}

#------------------------------------------------------
#
# HTML buildings
#
#------------------------------------------------------

=pod

=item * get_all_authors()

Replies the all authors from the specified list.

=cut
sub get_all_authors($) : method {
  my $self = shift ;
  my $parser = Bib2HTML::Translator::BibTeXName->new() ;
  return $parser->splitnames( $_[0] ) ;
}

=pod

=item * get_first_author()

Replies the first author from the specified list.

=cut
sub get_first_author($) : method {
  my $self = shift ;
  my @authors = $self->get_all_authors( $_[0] ) ;
  return $authors[0] ;
}

=pod

=item * count_authors()

Replies the number of authors inside the specified string

=cut
sub count_authors($) : method {
  my $self = shift ;
  my $parser = Bib2HTML::Translator::BibTeXName->new() ;
  return $parser->countnames( $_[0] ) ;
}

=pod

=item * get_entry_types()

Replies an array of entry types

=cut
sub get_entry_types() : method {
  my $self = shift ;
  my @types = () ;
  foreach my $entry (keys %{$self->{'CONTENT'}{'entries'}}) {
    my $type = lc( $self->{'CONTENT'}{'entries'}{$entry}{'type'} ) ;
    if ( ! strinarray($type,\@types) ) {
      push( @types, $type ) ;
    }
  }
  my @t = sortbyletters(@types);
  return @t ;
}

=pod

=item * get_entry_authors()

Replies an array of entry authors

=cut
sub get_entry_authors() : method {
  my $self = shift ;
  if (%{$self->{'CACHE'}{'BUILT_ENTRY_AUTHOR_LIST'}}) {
    return %{$self->{'CACHE'}{'BUILT_ENTRY_AUTHOR_LIST'}} ;
  }
  else {
    my %authors = () ;
    my $parser = Bib2HTML::Translator::BibTeXName->new() ;
    my @entries = keys %{$self->{'CONTENT'}{'entries'}};
    @entries = sortbyletters(@entries);
    foreach my $entry (@entries) {
      if ( $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'author'} ) {
	my @auts = $self->get_all_authors($self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'author'}) ;
	foreach my $aut (@auts) {
	  if ( ! $aut->{'et al'} ) {
	    my $key = lc(remove_html_accents($parser->formatname( $aut, 'l f.' ))) ;
	    $key =~ s/[^a-zA-Z0-1]+//g ;
	    my $count = 0 ;
	    my $thekey = $key ;
	    while ( ( $count >= 0 ) && ( exists $authors{$thekey} ) ) {
	      if ( $parser->samenames($aut,$authors{$thekey}) ) {
		$count = -1 ;
	      }
	      else {
		$count ++ ;
		$thekey  = "${key}_${count}" ;
	      }
	    }
	    if ( $count >= 0 ) {
	      $authors{$thekey} = $aut ;
	    }
	  }
	}
      }
    }
    $self->{'CACHE'}{'BUILT_ENTRY_AUTHOR_LIST'} = \%authors ;
    return %authors ;
  }
}

=pod

=item * get_all_entries_ayt()

Replies an array of entries sorted by authors, year and title

=cut
sub get_all_entries_ayt() : method {
  my $self = shift ;
  my @keys = keys %{$self->{'CONTENT'}{'entries'}} ;
  return ( sort {
    my $result = &__compare_two_entries_ayt__($a,$b,$self) ;
    return $result ;
  } @keys ) ;
}

=pod

=item * get_all_entries_yat()

Replies an array of entries sorted by authors, year and title

=cut
sub get_all_entries_yat() : method {
  my $self = shift ;
  my @keys = keys %{$self->{'CONTENT'}{'entries'}} ;
  return ( sort {
    my $result = &__compare_two_entries_yat__($a,$b,$self) ;
    return $result ;
  } @keys ) ;
}

# Private function to compare two entries in the purpose
# to sort the entries by author,year,title
# WARNING: years have a decroissant order
sub __compare_two_entries_ayt__($$$) {
  confess( 'you must supply the left comparaison operand' ) unless $_[0] ;
  confess( 'you must supply the right comparaison operand' ) unless $_[1] ;
  my $self = $_[2] || confess( 'you must supply the generator object' ) ;
  my $a1 = $self->get_first_author($self->__get_author_editor__($_[0],'') ) ;
  my $a2 = $self->get_first_author($self->__get_author_editor__($_[1],'') ) ;

  if ( (!$a1) && (!$a2) ) {
    return 0 ;
  }
  elsif (!$a1) {
    return 1 ;
  }
  elsif (!$a2) {
    return -1 ;
  }

  my $y1 = $self->__get_year__( $_[0], 0 ) || 0 ;
  my $y2 = $self->__get_year__( $_[1], 0 ) || 0 ;
  my $t1 = $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'title'} || '' ;
  my $t2 = $self->{'CONTENT'}{'entries'}{$_[1]}{'fields'}{'title'} || '' ;

  if ( ( $a1->{'et al'} ) && ( $a2->{'et al'} ) ) {
    return 0 ;
  }
  elsif ( $a1->{'et al'} ) {
    return 1 ;
  }
  elsif ( $a1->{'et al'} ) {
    return -1 ;
  }
  elsif ( $a1->{'last'} lt $a2->{'last'} ) {
    return -1 ;
  }
  elsif ( $a1->{'last'} gt $a2->{'last'} ) {
    return 1 ;
  }
  elsif ( $y1 < $y2 ) {
    return 1 ;
  }
  elsif ( $y1 > $y2 ) {
    return -1 ;
  }
  elsif ( $t1 lt $t2 ) {
    return -1 ;
  }
  elsif ( $t1 gt $t2 ) {
    return 1 ;
  }
  else {
    return 0 ;
  }
}

# Private function to compare two entries in the purpose
# to sort the entries by year,author,title
# WARNING: years have a decroissant order
sub __compare_two_entries_yat__($$$) {
  confess( 'you must supply the left comparaison operand' ) unless $_[0] ;
  confess( 'you must supply the right comparaison operand' ) unless $_[1] ;
  my $self = $_[2] || confess( 'you must supply the generator object' ) ;
  my $a1 = $self->get_first_author($self->__get_author_editor__($_[0],'') ) ;
  my $a2 = $self->get_first_author($self->__get_author_editor__($_[1],'') ) ;

  if ( (!$a1) && (!$a2) ) {
    return 0 ;
  }
  elsif (!$a1) {
    return 1 ;
  }
  elsif (!$a2) {
    return -1 ;
  }

  my $y1 = $self->__get_year__( $_[0], 0 ) || 0 ;
  my $y2 = $self->__get_year__( $_[1], 0 ) || 0 ;
  my $t1 = $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'title'} || '' ;
  my $t2 = $self->{'CONTENT'}{'entries'}{$_[1]}{'fields'}{'title'} || '' ;
  if ( $y1 < $y2 ) {
    return 1 ;
  }
  elsif ( $y1 > $y2 ) {
    return -1 ;
  }
  elsif ( ( $a1->{'et al'} ) && ( $a2->{'et al'} ) ) {
    return 0 ;
  }
  elsif ( $a1->{'et al'} ) {
    return 1 ;
  }
  elsif ( $a1->{'et al'} ) {
    return -1 ;
  }
  elsif ( $a1->{'last'} lt $a2->{'last'} ) {
    return -1 ;
  }
  elsif ( $a1->{'last'} gt $a2->{'last'} ) {
    return 1 ;
  }
  elsif ( $t1 lt $t2 ) {
    return -1 ;
  }
  elsif ( $t1 gt $t2 ) {
    return 1 ;
  }
  else {
    return 0 ;
  }
}

# Private function to get the year of the specified entry
sub __get_year__($$) {
  my $self = shift ;
  my $y = ( ( exists( $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'year'} ) ) &&
	    ( $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'year'} ) ) ?
	      tonumber($self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'year'}) : $_[1] ;
  if ( ! defined( $y ) ) {
    Bib2HTML::General::Error::warm( "the year field of '$_[0]' is not well-formatted: \"".
				    $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'year'}.
				    "\". It must be a number. Assume none.",
				    extract_file_from_location( $self->{'CONTENT'}{'entries'}{$_[0]}{'location'} ),
				    extract_line_from_location( $self->{'CONTENT'}{'entries'}{$_[0]}{'location'} ) ) ;
    $y = $_[1] ;
  }
  return $y ;
}

# Private function to get the author of the specified entry
sub __get_author_editor__($$) {
  my $self = shift ;
  my $a = ( ( exists( $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'author'} ) ) &&
	    ( $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'author'} ) ) ?
	      $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'author'} : $_[1] ;
  if ( ! $a ) {
    $a = ( ( exists( $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'editor'} ) ) &&
	   ( $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'editor'} ) ) ?
	     $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'editor'} : $_[1] ;
  }
  if ( ! defined( $a ) ) {
    Bib2HTML::General::Error::warm( "the author field of '$_[0]' is not well-formatted: \"".
				    $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'author'}.
				    "\". Assume none.",
				    extract_file_from_location( $self->{'CONTENT'}{'entries'}{$_[0]}{'location'} ),
				    extract_line_from_location( $self->{'CONTENT'}{'entries'}{$_[0]}{'location'} ) ) ;
    $a = $_[1] ;
  }
  return $a ;
}

#------------------------------------------------------
#
# Information
#
#------------------------------------------------------

=pod

=item * display_supported_generators()

Display the list of supported generators.
Takes 2 args:

=over

=item * perldir (string)

is the path to the directory where the Perl packages
are stored.

=item * default (string)

is the name of the default generator

=back

=cut
sub display_supported_generators($$) {
  my $path = $_[0] || confess( 'you must specify the pm path' ) ;
  my $default = $_[1] || '' ;
  my @pack = split /\:\:/, __PACKAGE__ ;
  pop @pack ;
  @pack = ( File::Spec->splitdir($path), @pack ) ;
  my $glob = File::Spec->catfile(@pack, '*');
  $glob =~ s/ /\\ /g;
  foreach my $file ( glob($glob) ) {
    my $name = basename($file) ;
    if ( $name =~ /^(.+)Gen\.pm$/ ) {
      $name = $1 ;
      print join( '',
		  "$name",
		  ( $default && ( $default eq $name ) ) ?
		  " (default)" : "",
		  "\n" ) ;
    }
  }
}

=pod

=item * display_supported_languages()

Display the list of supported languages.
Takes 2 args:

=over

=item * perldir (string)

is the path to the directory where the Perl packages
are stored.

=item * default (string)

is the name of the default language

=back

=cut
sub display_supported_languages($$) {
  Bib2HTML::Generator::LangManager::display_supported_languages($_[0],$_[1]);
}

=pod

=item * display_supported_themes()

Display the list of supported themes.
Takes 2 args:

=over

=item * perldir (string)

is the path to the directory where the Perl packages
are stored.

=item * default (string)

is the name of the default theme

=back

=cut
sub display_supported_themes($$) {
  my $path = $_[0] || confess( 'you must specify the pm path' ) ;
  my $default = $_[1] || '' ;
  my @pack = split /\:\:/, __PACKAGE__ ;
  pop @pack ;
  push @pack, 'Theme' ;
  @pack = ( File::Spec->splitdir($path), @pack ) ;
  my $glob = File::Spec->catfile(@pack, '*');
  $glob =~ s/ /\\ /g;
  foreach my $file ( glob($glob) ) {
    my $name = basename($file) ;
    if ( $name =~ /^(.+)\.pm$/ ) {
      $name = $1 ;
      print join( '',
		  "$name",
		  ( $default && ( $default eq $name ) ) ?
		  " (default)" : "",
		  "\n" ) ;
    }
  }
}

=pod

=item * save_generator_parameter()

Replies if the specified generator parameter was supported.
This function was called each time a generator parameter was
given to this generator. By default, simply updatethe
given parameter value (second parameter).
You could do some stuff before
saving (splitting...). Replies false is the parameter was
not recognized. Don't forget to call inherited functions.
Takes 2 args:

=over

=item * param_name (string)

is the name of the parameter.

=item * param_value (byref string)

is the value of the parameter.

=back

=cut
sub save_generator_parameter($$) {
  my $self = shift ;
  if ( $_[0] eq 'stdout' ) {
    $_[1] = 1 ;
    return 1 ;
  }
  return undef ;
}

=pod

=item * display_supported_generator_params()

Display the list of supported generator parameters.
Child classes must override this method.

=cut
sub display_supported_generator_params() {
  my $self = shift ;
  print "supported generator parameters:\n" ;

  $self->show_supported_param('stdout',
                              'If specified, the generated contents will be print on to the standard output.' );

}

=pod

=item * show_supported_param()

Display the help about one generator parameter.
Takes 3 args:

=over

=item * name (string)

is the name of the parameter

=item * comment (string)

is the comment for the parameter

=item * type (optional string)

is the type of the value that will be affected to
the parameter. If not present, no value needed.

=back

=cut
sub show_supported_param($$;$) {
  my $self = shift ;
  print "    ".($_[0]||'?') ;
  if ( $_[2] ) {
    print " = ".$_[2] ;
  }
  print "\n" ;
  my $t = splittocolumn_base($_[1]||'',
			     55,
			     "\t\t") ;
  print $t ;
  if ( $t !~ /\n\r$/ ) {
    print "\n" ;
  }
}

=pod

=item * merge_params()

Merges the specified parameter value with the given join.
Takes 2 args:

=over

=item * join (string)

=item * value (mixed)

=back

=cut
sub merge_params($) {
  my $self = shift ;
  return join($_[0],@{$_[1]})
    if ( isarray($_[1]) ) ;
  return $_[1] ;
}

=item * last_param()

Replies the last occurrence of a generator parameter value.
Takes 1 args:

=over

=item * value (mixed)

=back

=cut
sub last_param {
  my $self = shift ;
  return $_[0]->[$#{$_[0]}]
    if ( isarray($_[0]) ) ;
  return $_[0] ;
}

=item * first_param()

Replies the first occurrence of a generator parameter value.
Takes 1 args:

=over

=item * value (mixed)

=back

=cut
sub first_param {
  my $self = shift ;
  return $_[0]->[0]
    if ( isarray($_[0]) ) ;
  return $_[0] ;
}

#------------------------------------------------------
#
# Formatting backend
#
#------------------------------------------------------

=pod

=item * formatnames_url_backend()

This method is called each time the BibTeXNames module
must format an author's name with a URL.
Takes 2 args:

=over

=item * author's data (hash)

=item * label (string)

=item * rootdir (string)

=back

=cut
sub formatnames_url_backend($$$) {
  my $self = shift ;
  return $_[1] || '' ;
}

#------------------------------------------------------
#
# Utility
#
#------------------------------------------------------


=pod

=item * copythisfile()

Copy a file.
Takes 2 args:

=over

=item * source (string)

=item * target (string)

=back

=cut
sub copythisfile($$) {
  my $self = shift ;
  my $source = $_[0] || '' ;
  my $target = $_[1] || '' ;

  Bib2HTML::General::Error::syserr( "you must give a source file to copy\n" )
      unless ( $source ) ;
  Bib2HTML::General::Error::syserr( "you must give a target file to copy\n" )
      unless ( $target ) ;

  my $sbase = basename($source) ;
  my $sdir = dirname($source) ;
  my $tbase = basename($target) ;
  my $tdir = dirname($target) ;

  Bib2HTML::General::Verbose::two( "Copying $sbase..." ) ;
  Bib2HTML::General::Verbose::three( "\tfrom $sdir" ) ;
  if ( $tbase ne $sbase ) {
    Bib2HTML::General::Verbose::three( "\tto   $target" ) ;
  }
  else {
    Bib2HTML::General::Verbose::three( "\tto   $tdir" ) ;
  }

  filecopy( "$source",
	    "$target" )
    or Bib2HTML::General::Error::syswarm( "$source: $!\n" );

  return 1 ;
}

=pod

=item * isgenparam()

Replies if the specified string corresponds to a
generator parameter.
Takes 1 arg:

=over

=item * name (string)

=back

=cut
sub isgenparam($) {
  my $self = shift ;
  return ( ( $_[0] ) &&
	   ( exists $self->{'GENERATOR_PARAMS'}{lc($_[0])} ) ) ;
}

=pod

=item * genparam()

Replies the specified generator parameter value.
Takes 1 arg:

=over

=item * name (string)

=back

=cut
sub genparam($) {
  my $self = shift ;
  if ( ( $_[0] ) &&
       ( exists $self->{'GENERATOR_PARAMS'}{lc($_[0])} ) &&
       ( $self->{'GENERATOR_PARAMS'}{lc($_[0])} ) ) {
    return $self->{'GENERATOR_PARAMS'}{lc($_[0])} ;
  }
  else {
    return undef ;
  }
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
