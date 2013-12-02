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

Bib2HTML::Generator::HTMLGen - A basic HTML generator

=head1 SYNOPSYS

use Bib2HTML::Generator::HTMLGen ;

my $gen = Bib2HTML::Generator::HTMLGen->new( content, output, info, titles,
                                             lang, theme, params ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::HTMLGen is a Perl module, which permits to
generate HTML pages for the BibTeX database.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use Bib2HTML::Generator::HTMLGen;

    my $gen = Bib2HTML::Generator::HTMLGen->new( { }, "./bib",
						 { 'BIB2HTML_VERSION' => "0.1",
						 },
						 { 'SHORT' => "This is the title",
						   'LONG' => "This is the title",
						 },
						 "English",
						 "Simple", ""
					       ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * content (hash)

see AbstractGenerator help.

=item * output (string)

see AbstractGenerator help.

=item * bib2html_data (hash)

see AbstractGenerator help.

=item * titles (hash)

see AbstractGenerator help.

=item * lang (string)

see AbstractGenerator help.

=item * theme (string)

is the name of the theme to use

=item * show_bibtex (boolean)

indicates if this parser must generate a verbatim of the BibTeX code

=item * params (optional array)

is the set of parameters passed to the generator.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in HTMLGen.pm itself.

=over

=cut

package Bib2HTML::Generator::HTMLGen;

@ISA = ('Bib2HTML::Generator::AbstractGenerator');
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Carp ;
use File::Spec ;
use File::Basename;

use Bib2HTML::Generator::AbstractGenerator;
use Bib2HTML::General::Misc;
use Bib2HTML::General::HTML;
use Bib2HTML::General::Title;
use Bib2HTML::General::Error;
use Bib2HTML::General::Encode;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of this generator
my $VERSION = "6.0" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$$$$;$) : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my @langs = ();
  if (isarray($_[4])) {
    foreach my $l (@{$_[4]}) {
     if ($l !~ /_[a-zA-Z0-9]+Gen$/) {
       push @langs, $l."_HTMLGen";
     }
     push @langs, $l;
    }
  }
  else {
     @langs = ( $_[4] );
     if ($_[4] !~ /_[a-zA-Z0-9]+Gen$/) {
       unshift @langs, $_[4]."_HTMLGen";
     }
  }

  my $self = $class->SUPER::new($_[0], #content
				$_[1], #output
				$_[2], #bib2html info
				$_[3], #titles
				\@langs, #lang
				$_[6], #show bibtex
				$_[7], #params
			       ) ;
  bless( $self, $class );

  $self->{'__INDEX_GENERATED__'} = 0 ; # index not generated

  # Filenames patterns
  $self->{'FILENAMES'} = { 'overview-frame' => 'overview-frame.html',
			   'overview-summary' => 'overview-summary.html',
			   'allelements' => 'allelements-frame.html',
			   'type-overview' => 'type-#1.html',
			   'entry' => 'entry-#1.html',
			   'overview-tree' => 'overview-tree.html',
			   'main_index' => "index.html",
			   'index' => "index-#1.html",
			   'author-overview' => 'author-#1.html',
			 } ;
  $self->{'ENTRY_FILENAMES'} = {} ;
  $self->{'AUTHOR_FILENAMES'} = {} ;

  # HTML frames identifiers
  $self->{'FRAMES'} = { 'overview-frame' => 'typeFrame',
			'overview-summary' => 'mainFrame',
			'allelements' => 'entryFrame',
			'type-overview' => 'entryFrame',
			'entry' => 'mainFrame',
			'overview-tree' => 'mainFrame',
			'main_index' => "_top",
			'index' => "mainFrame",
		      } ;

  # Storage area for the buttons added into the navigation bar
  $self->{'USER_NAVIGATION_BUTTONS'} = [] ;

  # Creates the theme support
  my $theme = $_[5] || confess( 'you must supply the theme' ) ;
  if ( $theme !~ /\:\:/ ) {
    $theme = "Bib2HTML::Generator::Theme::".$theme ;
  }
  eval "require $theme ;" ;
  if ( $@ ) {
    Bib2HTML::General::Error::syserr( "Unable to find the theme class: $theme\n$@\n" ) ;
  }
  $self->{'THEME'} = ($theme)->new( $self,
				    $self->{'BIB2HTML'},
				    $self->{'TARGET'},
				    $self->{'SHORT_TITLE'},
				    $self->{'LANG'} ) ;

  # Create an instance of a XML generator
  if ($self->genparam('xml-verbatim')) {
    require Bib2HTML::Generator::XMLGen ;
    $self->{'XML_GENERATOR'} = Bib2HTML::Generator::XMLGen->new($_[0], #content
								$_[1], #output
								$_[2], #bib2html info
								$_[3], #titles
								$_[4], #lang
								$_[6], #show bibtex
								$_[7], #params
							       ) ;
  }

  return $self;
}


=pod

=item * save_generator_parameter()

Replies if the specified generator parameter was supported.
This function was called each time a generator parameter was
given to this generator. By default, simply update the
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
  # Patch by Norbert Preining added the 2003/03/17
  # Patch by Norbert Preining added the 2003/03/27
  # Patch by Aurel Gabris added the 2006/04/10
  my $self = shift ;
  if ( ( $_[0] eq 'author-regexp' ) ||
       ( $_[0] eq 'max-names-overview' ) ||
       ( $_[0] eq 'max-titlelength-overview' ) ||
       ( $_[0] eq 'max-names-list') ||
       ( $_[0] eq 'html-encoding' ) ) {
    # will be saved by PARENT::new
    return 1 ;
  }
  elsif ( $_[0] eq 'newtype' ) {
    # extracts new type definitions
    $_[1] = $self->merge_params(',',$_[1]) ;
    my @ntypedef = split /\s*,\s*/, "$_[1]" ;
    # adds each extracted definition
    foreach my $td (@ntypedef) {
      if ( $td !~ /^\s*(.+?)\s*:\s*(.+?)\s*:\s*(.+?)\s*$/ ) {
	Bib2HTML::General::Error::syserr("syntax error for generator parameter ".
					 "'newtype' for \"$td\"" ) ;
      }
      else {
	my @foo = (lc($1),$2,$3) ;
	Bib2HTML::General::Verbose::one(join('',
					     "\tadd BibTeX type: ".$foo[0].",\n",
					     "\t    singular: ".($foo[1]||'')."\n",
					     "\t    plurial:  ".($foo[2]||''))) ;
	$self->{'SINGULAR_TYPE_LABELS'}{$foo[0]} = $foo[1] ;
	$self->{'PLURIAL_TYPE_LABELS'}{$foo[0]} = $foo[2] ;
      }
    }
    return 1 ;
  }
  elsif ( $_[0] eq 'type-matching' ) {
    # Normalize the syntax of this parameter's value
    my $val = $self->merge_params(',',$_[1]) ;
    $val =~ s/\=>/,/g ;
    $val =~ s/\->/,/g ;
    $val =~ s/>/,/g ;
    # Check the syntax of this parameter's value
    my @foo = split /\s*,\s*/, "$val" ;
    if ((@foo)&&((@foo%2)==0)) {
      $_[1] = {} ;
      while (@foo) {
	my $a = shift @foo ;
	my $b = shift @foo ;
	$_[1]->{"$a"} = "$b" ;
      }
    }
    else {
      # Die on error if the syntax was invalid
      Bib2HTML::General::Error::syserr("invalid value for the generator parameter 'type-matching'") ;
    }
    return 1 ;
  }
  elsif ( $_[0] eq 'restrict' ) {
    # extracts output filename restrictions
    $_[1] = $self->merge_params(',',$_[1]) ;
    my @restricts = split /\s*,\s*/, "$_[1]" ;
    # adds each extracted definition
    $self->{'FILE_RESTRICTIONS'} = [];
    foreach my $res (@restricts) {
      push @{$self->{'FILE_RESTRICTIONS'}}, shell_to_regex($res);
    }
    return 1 ;
  }
  elsif ( ( $_[0] eq 'xml-verbatim' ) ||
	  ( $_[0] eq 'show-journalparams-overview' ) ||
	  ( $_[0] eq 'hideindex' ) ) {
    $_[1] = 1 ;
    return 1 ;
  }
  else {
    return $self->SUPER::save_generator_parameter($_[0],$_[1]) ;
  }
}

=pod

=item * display_supported_generator_params()

Display the list of supported generator parameters.

=cut
sub display_supported_generator_params() {
  # Patch by Norbert Preining added the 2003/03/17
  # Patch by Norbert Preining added the 2003/03/27
  # Patch by Aurel Gabris added the 2006/04/10
  my $self = shift ;
  $self->SUPER::display_supported_generator_params() ;

  $self->show_supported_param('author-regexp',
			      'A regexp (case-insensitive) against which '.
			      'the lastname of '.
			      'an author is matched. If the author '.
			      'matches, (s)he is included in the '.
			      'overview window author list.' );

  $self->show_supported_param('hideindex',
			      'If present, the generator will hide the index pages.' );

  $self->show_supported_param('html-encoding',
			      'String, the character encoding used in the HTML pages '.
			      '("UTF8", "ISO-8859-1"...).' );

  $self->show_supported_param('max-names-overview',
			      'Integer, max number of authors on '.
			      'the overview page.' );

  $self->show_supported_param('max-names-list',
			      'Integer, max number of authors on the '.
			      'listing in the lower left window.' );

  $self->show_supported_param('max-titlelength-overview',
                              'Integer, max length of title on '.
                              'the overview page.' );

  $self->show_supported_param('newtype',
			      'A comma separated list of new type, with singular and '.
			      'plural form, format: '.
			      'type:Singular:Plural[,type:Singular:Plural...]' );

  $self->show_supported_param('restrict',
			      'A comma separated list of strings containing shell-like wildcards. They '.
                              'corresponds to the pattern filenames that are available to be generated.' );

  $self->show_supported_param('show-journalparams-overview',
                              'If specified, show journal parameters instead '.
                              'of type for articles on the overview page.' );

  $self->show_supported_param('type-matching',
			      'A coma separated list of items which inititalizes an '.
			      'associative array of type entry mappings. '.
			      'For example \'incollection,article,inproceedings,article\' '.
			      'means that all the BibTeX\'s \'@incollection\' entries will be '.
			      'considered as \'@article\' entries. Same thing for the '.
			      '\'@inproceedings\'.' );

  $self->show_supported_param('xml-verbatim',
			      'If present, each entry\'s page will contains the '.
			      'XML entry as verbatim.' );
}

#------------------------------------------------------
#
# Generation API
#
#------------------------------------------------------

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
  my $old_writer = $self->SUPER::set_stream_writer($writer);
  if ($self->{'THEME'}) {
    $self->{'THEME'}->set_stream_writer($writer);
  }
  return $old_writer;
}


=pod

=item * pre_processing()

Pre_processing.

=cut
sub pre_processing() : method {
  my $self = shift ;

  # Set the HTML encoding
  if (!$self->{'GENERATOR_PARAMS'}{'html-encoding'}) {
    $self->{'GENERATOR_PARAMS'}{'html-encoding'} = get_default_encoding();
  }
  set_default_encoding($self->{'GENERATOR_PARAMS'}{'html-encoding'});
  $self->{'THEME'}->set_html_encoding($self->{'GENERATOR_PARAMS'}{'html-encoding'});

  # Call inherited generation method
  $self->SUPER::pre_processing() ;

  # Create the output directory
  $self->create_output_directory();
}

=pod

=item * do_processing()

Main processing.

=cut
sub do_processing() : method {
  my $self = shift ;

  # Call inherited generation method
  $self->SUPER::do_processing() ;

  # Generates each part of the document

  if (!$self->genparam('hideindex')) {
  	$self->{'__INDEX_GENERATED__'} = $self->generate_indexes() ;
  }
  else {
	$self->{'__INDEX_GENERATED__'} = undef;
  }
  $self->generate_index() ;
  $self->generate_overviewframe() ;
  $self->generate_allelementframe() ;
  $self->generate_typeoverviews() ;
  $self->generate_authoroverviews() ;
  $self->generate_overviewtree() ;
  $self->generate_overview() ;
  $self->generate_entries() ;
}

=pod

=item * post_processing()

Post_processing.

=cut
sub post_processing() : method {
  my $self = shift ;
  # Call inherited generation method
  $self->SUPER::post_processing() ;
  # Copy resource files
  my $writer = $self->{'THEME'}->get_stream_writer();
  if ($writer->is_file_creation_allowed()) {
    $self->copy_files() ;
  }
}

=pod

=item * is_restricted_file($)

Replies if the specified filename is inside the
restriction list. If the restriction list was empty,
this function replies true.
Takes 1 arg:

=over

=item * filename (string)

is the filename to treat.

=back

=cut
sub is_restricted_file($) : method {
  my $self = shift;
  my $filename = shift;
  $filename = basename($filename);
  return 1 unless ($self->{'FILE_RESTRICTIONS'});
  foreach my $pattern (@{$self->{'FILE_RESTRICTIONS'}}) {
    if ($filename =~ /$pattern/) {
      return 1;
    }
  }
  return undef;
}

=pod

=item * generate_entries()

Generates the HTML pages for each entry

=cut
sub generate_entries() : method {
  my $self = shift ;
  my $rootdir = "." ;
  my @entries = $self->get_all_entries_ayt() ;
  my $i = $#entries ;
  while ( $i >= 0 ) {
    # Compute entry constants
    my $filename = $self->filename('entry',$entries[$i]) ;

    Bib2HTML::General::Verbose::three( "Generates entry '".$entries[$i]."'\n" ) ;

    next unless ($self->is_restricted_file("$filename"));

    my $type = $self->{'CONTENT'}{'entries'}{$entries[$i]}{'type'} ;
    my $url = htmlcatfile($rootdir,$filename) ;
    my $bar = $self->{'THEME'}->get_navigation_bar( $filename,
						  { 'index' => $self->{'__INDEX_GENERATED__'},
						    'previous' => '',
						    'next' => '',
						    'userdef' => $self->getNavigationButtons(),
						  },
						  $rootdir ) ;

    # Generate the header
    my $content = $bar.$self->{'THEME'}->partseparator() ;

    # Calls the content building function
    my $fct = "generate_entry_content_$type" ;
    my $entrytitle = '' ;
    if ( my $funcref = $self->can( $fct ) ) {
      $content .= join( '', @{ $self->$funcref( $entries[$i],
                                   $self->{'CONTENT'}{'entries'}{$entries[$i]},
                                   $url,$rootdir,$entrytitle,[]) } ) ;
    }
    else {
      Bib2HTML::General::Error::warm("I don't know how to generate a '\@".$type.
				     "' for the entry '".$entries[$i]."'. Assume '\@misc'",
				     extract_file_from_location( $_[1]{'location'} ),
				     extract_line_from_location( $_[1]{'location'} ) ) ;
      $content .= join( '', @{ $self->generate_entry_content_misc( $entries[$i],
								   $self->{'CONTENT'}{'entries'}{$entries[$i]},
								   $url,$rootdir,$entrytitle,[]) } ) ;
    }

    # Generate the footer
    $content .= join( '',
                      $self->{'THEME'}->partseparator(),
                      $bar,
		      $self->{'THEME'}->partseparator(),
                      $self->{'THEME'}->get_copyright() ) ;

    # Output to the file
    $self->{'THEME'}->create_html_body_page( $url,
					     $content,
					     $entrytitle||$self->{'SHORT_TITLE'},
					     $rootdir,
					     'html') ;
  }
  continue {
    $i -- ;
  }
}

=pod

=item * generate_index()

Generates the HTML index.html

=cut
sub generate_index() : method {
  my $self = shift ;
  my $rootdir = "." ;
  my $filename = $self->filename('main_index');

  Bib2HTML::General::Verbose::three( "Generates the main index file\n" ) ;

  return unless ($self->is_restricted_file("$filename"));

  my $content = $self->{'THEME'}->get_html_index($rootdir);
  $self->{'THEME'}->create_html_page( htmlcatfile($rootdir,$filename),
				      $content,
				      $self->{'SHORT_TITLE'},
				      $rootdir ) ;
}

=pod

=item * generate_overviewframe()

Generates the HTML overview-frame.html
Dont overwrite this method.

=cut
sub generate_overviewframe : method {
  my $self = shift ;
  my $rootdir = "." ;
  my $filename = $self->filename('overview-frame');

  Bib2HTML::General::Verbose::three( "Generates the overview frame\n" ) ;

  return unless ($self->is_restricted_file("$filename"));

  my $content = join( '',
		      $self->{'THEME'}->frame_subpart( '',
						       [ $self->{'THEME'}->ext_href( 'allelements',
										     $self->{'LANG'}->get('I18N_LANG_ALL_ELEMENTS'),
										     $rootdir ),
						       ],
						       $rootdir ),
		      $self->generate_overviewframe_content($rootdir)
		    ) ;

  $self->{'THEME'}->create_html_body_page( htmlcatfile($rootdir,$filename),
					   $self->{'THEME'}->frame_window( $self->{'SHORT_TITLE'},
									   $content ),
					   $self->{'SHORT_TITLE'},
					   $rootdir,
					   'small', 'html') ;
}

=pod

=item * generate_allelementframe()

Generates the HTML allelements-frame.html

=cut
sub generate_allelementframe() : method {
  my $self = shift ;
  my $rootdir = "." ;
  my $filename = $self->filename('allelements');

  Bib2HTML::General::Verbose::three( "Generates the all-element frame\n" ) ;

  return unless ($self->is_restricted_file("$filename"));

  my @entries = $self->get_all_entries_yat() ;
  my $translator = Bib2HTML::Translator::BibTeXName->new() ;
  my $biblabeller = Bib2HTML::Translator::BibTeXEntry->new() ;
  my $currentyear = '' ;
  my $content = '' ;
  my @current = () ;

  foreach my $entry (@entries) {
    my $year = $self->__get_year__( $entry, '' ) ;
    if ( "$currentyear" ne "$year" ) {
      if ( @current ) {
	$content .= $self->{'THEME'}->frame_subpart( $currentyear || $self->{'LANG'}->get('I18N_LANG_NO_DATE'),
						     \@current,
						     $rootdir ) ;
      }
      $currentyear = $year ;
      @current = () ;
    }

    my $biblabel = '' ;
    if ( exists( $self->{'CONTENT'}{'entries'}{$entry} ) ) {
      my $filename = $self->filename('entry',$entry) ;
      $biblabel = join( '',
			'[',
			$self->{'THEME'}->href( htmlcatfile($rootdir,$filename),
						$biblabeller->citation_label( $entry,
									      $self->{'CONTENT'}{'entries'}{$entry} ),
						$self->browserframe('entry') ),
			']&nbsp;' ) ;
    }
    $biblabel .= $translator->formatnames( $self->__get_author_editor__($entry,''),
					   $self->{'FORMATS'}{'name'},
					   $self->{'FORMATS'}{'names'},
					   exists($self->{'GENERATOR_PARAMS'}{'max-names-list'})?$self->{'GENERATOR_PARAMS'}{'max-names-list'}:1 ) ;

    push @current, $biblabel ;
  }

  if ( @current ) {
    $content .= $self->{'THEME'}->frame_subpart( $currentyear || $self->{'LANG'}->get('I18N_LANG_NO_DATE'),
						 \@current,
						 $rootdir ) ;
  }

  $self->{'THEME'}->create_html_body_page( htmlcatfile($rootdir,$filename),
					   $self->{'THEME'}->frame_window( $self->{'LANG'}->get('I18N_LANG_ALL_ELEMENTS'),
									   $content ),
					   $self->{'SHORT_TITLE'},
					   $rootdir,
					   'small', 'html') ;
}

=pod

=item * generate_typeoverviews()

Generates the HTML type-???.html

=cut
sub generate_typeoverviews() : method {
  # Patch by Norbert Preining added the 2003/03/27
  my $self = shift ;
  my $rootdir = "." ;
  my @entries = $self->get_all_entries_yat() ;
  my @types = $self->get_entry_types() ;
  my $translator = Bib2HTML::Translator::BibTeXName->new() ;
  my $biblabeller = Bib2HTML::Translator::BibTeXEntry->new() ;
  my %typematching = () ;

  if ( exists($self->{'GENERATOR_PARAMS'}{'type-matching'}) ) {
    %typematching = %{$self->{'GENERATOR_PARAMS'}{'type-matching'}};
  }
  if ( @types > 0 ) {
    foreach my $type (@types) {
      if ( ! exists( $typematching{$type} ) ) {
	$typematching{$type} = $type;
      }
    }
    my @sortedtypes = values %typematching;
    @sortedtypes = uniq(sortbyletters(@sortedtypes));
    foreach my $type (@sortedtypes) {
      my $url = $self->filename('type-overview',$type) ;
      Bib2HTML::General::Verbose::three( "Generates type overview for '$type'\n" ) ;
      next unless ($self->is_restricted_file("$url"));
      my ($currentyear,$writeentry) = ('',0) ;
      my @current = () ;
      my $content = '' ;

      foreach my $entry (@entries) {
        my $year = $self->__get_year__( $entry, '' ) ;
        if ( $typematching{$self->{'CONTENT'}{'entries'}{$entry}{'type'}} eq $type ) {
          if ( "$currentyear" ne "$year" ) {
	    if ( @current ) {
	      $content .= $self->{'THEME'}->frame_subpart( $currentyear,
							   \@current,
							   $rootdir ) ;
	    }
            $currentyear = $year ;
	    @current = () ;
          }
	  my $biblabel = '' ;
	  if ( exists( $self->{'CONTENT'}{'entries'}{$entry} ) ) {
	    my $filename = $self->filename('entry',$entry) ;
	    $biblabel = join( '',
			      '[',
			      $self->{'THEME'}->href( htmlcatfile($rootdir,$filename),
						      $biblabeller->citation_label( $entry,
										    $self->{'CONTENT'}{'entries'}{$entry} ),
						      $self->browserframe('entry') ),
			      ']&nbsp;' ) ;
	  }
	  $biblabel .= $translator->formatnames( $self->__get_author_editor__($entry,''),
						 $self->{'FORMATS'}{'name'},
						 $self->{'FORMATS'}{'names'},
						 exists($self->{'GENERATOR_PARAMS'}{'max-names-list'})?$self->{'GENERATOR_PARAMS'}{'max-names-list'}:1) ;
	  push @current, $biblabel ;
        }
      }

      if ( @current ) {
	$content .= $self->{'THEME'}->frame_subpart( $currentyear,
						     \@current,
						     $rootdir ) ;
      }

      $self->{'THEME'}->create_html_body_page( htmlcatfile($rootdir,$url),
					       $self->{'THEME'}->frame_window( $self->{'PLURIAL_TYPE_LABELS'}{$type},
									       $content,
									       $self->{'THEME'}->ext_href( 'allelements',
													   $self->{'LANG'}->get('I18N_LANG_ALL_ELEMENTS'),
													   $rootdir )),
					       $self->{'SHORT_TITLE'},
					       $rootdir,
					       'small', 'html') ;
    }

  }
}

=pod

=item * generate_authoroverviews()

Generates the HTML author-???.html

=cut
sub generate_authoroverviews() : method {
  my $self = shift ;
  my $rootdir = "." ;
  my $translator = Bib2HTML::Translator::BibTeXName->new() ;
  my $biblabeller = Bib2HTML::Translator::BibTeXEntry->new() ;
  my @entries = $self->get_all_entries_yat() ;
  my %authors = $self->get_entry_authors() ;

  if ( !isemptyhash(\%authors) ) {
    foreach my $author (keys %authors) {
      my $url = $self->filename('author-overview',$author) ;
      Bib2HTML::General::Verbose::three( "Generates author overview for '$author'\n" ) ;
      next unless ($self->is_restricted_file("$url"));
      my @current = () ;
      my ($content,$currentyear) = ('','') ;

      foreach my $entry (@entries) {

	if ( $translator->isauthorin($authors{$author},
				     $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'author'}) ) {

	  my $year = $self->__get_year__( $entry, '' ) ;
	  if ( "$currentyear" ne "$year" ) {
	    if ( @current ) {
	      $content .= $self->{'THEME'}->frame_subpart( $currentyear,
							   \@current,
							   $rootdir ) ;
	    }
	    $currentyear = $year ;
	    @current = () ;
	  }
	  my $biblabel = '' ;
	  if ( exists( $self->{'CONTENT'}{'entries'}{$entry} ) ) {
	    my $filename = $self->filename('entry',$entry) ;
	    $biblabel = join( '',
			      '[',
			      $self->{'THEME'}->href( htmlcatfile($rootdir,$filename),
						      $biblabeller->citation_label( $entry,
										    $self->{'CONTENT'}{'entries'}{$entry} ),
						      $self->browserframe('entry') ),
			      ']&nbsp;' ) ;
	  }
	  $biblabel .= $translator->formatnames( $self->__get_author_editor__($entry,''),
						 $self->{'FORMATS'}{'name'},
						 $self->{'FORMATS'}{'names'} ) ;
	  push @current, $biblabel ;
	}

      }



      if ( @current ) {
	$content .= $self->{'THEME'}->frame_subpart( $currentyear,
						     \@current,
						     $rootdir ) ;
      }

      $self->{'THEME'}->create_html_body_page( htmlcatfile($rootdir,$url),
					       $self->{'THEME'}->frame_window( $translator->formatname($authors{$author},'l, f.'),
									       $content,
									       $self->{'THEME'}->ext_href( 'allelements',
													   $self->{'LANG'}->get('I18N_LANG_ALL_ELEMENTS'),
													   $rootdir )),
					       $self->{'SHORT_TITLE'},
					       $rootdir,
					       'small', 'html') ;
    }
  }
}

=pod

=item * generate_overview()

Generates the HTML overview-summary.html
Dont overwrite this method.

=cut
sub generate_overview() : method {
  my $self = shift ;
  my $rootdir = "." ;
  my $filename = $self->filename('overview-summary') ;
  Bib2HTML::General::Verbose::three( "Generates overview summary\n" ) ;
  return unless ($self->is_restricted_file("$filename"));
  $filename = htmlcatfile($rootdir,$filename) ;
  my $bar = $self->{'THEME'}->get_navigation_bar( $filename,
						  { 'overview' => 1,
						    'index' => $self->{'__INDEX_GENERATED__'},
						    'userdef' => $self->getNavigationButtons(),
						  },
						  $rootdir ) ;
  my $content = join('',
		     $bar,
		     $self->{'THEME'}->partseparator(),
		     $self->{'THEME'}->title($self->{'LONG_TITLE'}),
		     $self->generate_overview_content($rootdir),
		     $self->{'THEME'}->partseparator(),
		     $bar,
		     $self->{'THEME'}->partseparator(),
		     $self->{'THEME'}->get_copyright($rootdir) ) ;

  $self->{'THEME'}->create_html_body_page( $filename,
					   $content,
					   $self->{'SHORT_TITLE'},
					   $rootdir,
					   'html' ) ;
}

=pod

=item * generate_overviewtree()

Generates the HTML overview-tree.html
Dont overwrite this method.

=cut
sub generate_overviewtree() : method {
  my $self = shift ;
  my $rootdir = "." ;
  my $filename = $self->filename('overview-tree') ;
  Bib2HTML::General::Verbose::three( "Generates overview tree\n" ) ;
  return unless ($self->is_restricted_file("$filename"));
  $filename = htmlcatfile($rootdir,$filename) ;
  my $bar = $self->{'THEME'}->get_navigation_bar( $filename,
						  { 'tree' => 1,
						    'index' => $self->{'__INDEX_GENERATED__'},
						    'userdef' => $self->getNavigationButtons(),
						  },
						  $rootdir ) ;
  my $content = join('',
		     $bar,
		     $self->{'THEME'}->partseparator(),
		     $self->generate_overviewtree_content($rootdir),
		     $self->{'THEME'}->partseparator(),
		     $bar,
		     $self->{'THEME'}->partseparator(),
		     $self->{'THEME'}->get_copyright($rootdir) ) ;

  $self->{'THEME'}->create_html_body_page( $filename,
					   $content,
					   $self->{'SHORT_TITLE'},
					   $rootdir,
					   'html') ;
}

=pod

=item * generate_indexes()

Generates the HTML index-???.html
Dont overwrite this method.

=cut
sub generate_indexes() : method {
  my $self = shift ;
  my $rootdir = "." ;
  my $translator = Bib2HTML::Translator::BibTeXName->new() ;
  my %indexentries = () ;

  Bib2HTML::General::Verbose::two( "Build the indexes\n" ) ;
  my @entries = $self->get_all_entries_ayt() ;
  foreach my $entry (@entries) {

    # Builds the comment for this entry
    my $filename = $self->filename('entry',$entry) ;
    my $url = htmlcatfile($rootdir,$filename) ;
    my $year = $self->__get_year__( $entry, '' ) ;
    my $entrycomment = join( '',
                             $self->{'LANG'}->get('I18N_LANG_SMALL_IN',
						  $translator->formatnames( $self->__get_author_editor__($entry,''),
									    $self->{'FORMATS'}{'name'},
									    $self->{'FORMATS'}{'names'},
									    -1 )),
			     "<BR>\n",
			     $self->{'THEME'}->entry_title( $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'title'} ),
			     ( $year ? " (".$year.")" : '' ) ) ;

    # Adds the authors
    if ( exists $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'author'} ) {
      Bib2HTML::General::Verbose::three( "\tinclude the authors\n" ) ;
      my @authors = $self->get_all_authors($self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'author'}) ;
      foreach my $author (@authors) {
        my %desc = ( 'url' => $url,
                     'label' => $translator->formatname( $author, $self->{'FORMATS'}{'name'} ),
                     'comment' => $entrycomment,
                     'short-comment' => $self->{'LANG'}->get('I18N_LANG_INDEX_COMMENT_AUTHOR'),
                   ) ;
	my $sorttag = lc(remove_html_accents($author->{'last'}));
        push @{$indexentries{$sorttag}}, \%desc ;
      }
    }

    # Adds the editors
    if ( exists $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'editor'} ) {
      Bib2HTML::General::Verbose::three( "\tinclude the editors\n" ) ;
      my @editors = $self->get_all_authors($self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'editor'}) ;
      foreach my $editor (@editors) {
        my %desc = ( 'url' => $url,
                     'label' => $translator->formatname( $editor, $self->{'FORMATS'}{'name'} ),
                     'comment' => $entrycomment,
                     'short-comment' => $self->{'LANG'}->get('I18N_LANG_INDEX_COMMENT_EDITOR'),
                   ) ;
	my $sorttag = lc(remove_html_accents($editor->{'last'}));
        push @{$indexentries{$sorttag}}, \%desc ;
      }
    }

    # Adds the title keywords
    if ( exists $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'title'} ) {
      Bib2HTML::General::Verbose::three( "\tinclude the titles\n" ) ;
      $self->_add_sentence_keywords( \%indexentries,
                                     $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'title'},
                                     $url, $entrycomment,
				     $self->{'LANG'}->get('I18N_LANG_INDEX_COMMENT_TITLE')) ;
    }

    # Adds the booktitle
    if ( exists $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'booktitle'} ) {
      Bib2HTML::General::Verbose::three( "\tinclude the booktitles\n" ) ;
      $self->_add_sentence_keywords( \%indexentries,
                                     $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'booktitle'},
                                     $url, $entrycomment,
				     $self->{'LANG'}->get('I18N_LANG_INDEX_COMMENT_BOOKTITLE')) ;
    }

    # Adds the journal
    if ( exists $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'journal'} ) {
      Bib2HTML::General::Verbose::three( "\tinclude the journal\n" ) ;
      $self->_add_sentence_keywords( \%indexentries,
                                     $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'journal'},
                                     $url, $entrycomment,
				     $self->{'LANG'}->get('I18N_LANG_INDEX_COMMENT_ARTICLE')) ;
    }

    # Adds the publisher
    if ( exists $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'publisher'} ) {
      Bib2HTML::General::Verbose::three( "\tinclude the publisher\n" ) ;
      $self->_add_sentence_keywords( \%indexentries,
                                     $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'publisher'},
                                     $url, $entrycomment,
				     $self->{'LANG'}->get('I18N_LANG_INDEX_COMMENT_PUBLISHER')) ;
    }

    # Adds the school
    if ( exists $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'school'} ) {
      Bib2HTML::General::Verbose::three( "\tinclude the school\n" ) ;
      $self->_add_sentence_keywords( \%indexentries,
                                     $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'school'},
                                     $url, $entrycomment,
				     $self->{'LANG'}->get('I18N_LANG_INDEX_COMMENT_SCHOOL')) ;
    }

    # Adds the institution
    if ( exists $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'institution'} ) {
      Bib2HTML::General::Verbose::three( "\tinclude the institution\n" ) ;
      $self->_add_sentence_keywords( \%indexentries,
                                     $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'institution'},
                                     $url, $entrycomment,
				     $self->{'LANG'}->get('I18N_LANG_INDEX_COMMENT_INSTITUTION')) ;
    }

    # Adds the howpublished
    if ( exists $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'howpublished'} ) {
      Bib2HTML::General::Verbose::three( "\tinclude the howpublished\n" ) ;
      $self->_add_sentence_keywords( \%indexentries,
                                     $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'howpublished'},
                                     $url, $entrycomment,
				     $self->{'LANG'}->get('I18N_LANG_INDEX_COMMENT_HOWPUBLISHED')) ;
    }

    # Calls the overwritable function to adds entries
    $self->generate_index_content(\%indexentries,$entry,$url,$entrycomment,$rootdir) ;

  }

  # Builds the list of letters
  Bib2HTML::General::Verbose::three( "\tgets the index letters\n" ) ;
  my @words = keys %indexentries;
  @words = sortbyletters(@words) ;
  my $letterlist = "" ;
  my $lastletter = "" ;
  my $maxcount = 0 ;

  foreach my $word (@words) {
    $word =~ /^(.)/ ;
    my $letter = lc($1) ;
    if ( ! ( $letter eq $lastletter ) ) {
      $lastletter = $letter ;
      $letterlist .= $self->{'THEME'}->href( htmlcatfile($rootdir,
							 $self->filename('index',$maxcount)),
			   		     uc( $letter ),
					     $self->browserframe('index') ) ;
      $maxcount ++ ;
    }
  }

  if ( isemptyhash(\%indexentries) ) {
    return 0 ;
  }

  # Ouputs the indexes
  my $nav = "" ;
  my $content = '' ;
  my @letterentries = () ;
  my $count = 0 ;
  my $currentfile = "" ;
  $lastletter = "" ;
  $self->{'__INDEX_GENERATED__'} = 1 ;

  foreach my $word (@words) {
    $word =~ /^(.)/ ;
    my $letter = lc($1) ;
    if ( ! ( $letter eq $lastletter ) ) {
      #
      # The first letter has changed
      #
      if ( $currentfile ) {
	# finish to write the previous file
	$content = join( '',
			 $nav,
			 $self->{'THEME'}->partseparator(),
			 $self->{'THEME'}->format_index_page( $letterlist,
							      $lastletter,
							      \@letterentries ),
			 $self->{'THEME'}->partseparator(),
			 $nav,
			 $self->{'THEME'}->partseparator(),
			 $self->{'THEME'}->get_copyright($rootdir) ) ;
	$self->{'THEME'}->create_html_body_page( $currentfile,
						 $content,
						 $self->{'SHORT_TITLE'},
						 $rootdir,
						 'html') ;
      }
      Bib2HTML::General::Verbose::three( "\tgenerates the index content for '$letter'\n" ) ;
      $lastletter = $letter ;
      # begin to write the file for the current letter
      $currentfile = $self->{'THEME'}->filename('index',$count) ;
      unless ($self->is_restricted_file("$currentfile")) {
        $currentfile = '';
      }
      if ($currentfile) {
        $nav = $self->{'THEME'}->get_navigation_bar( $currentfile,
						   { 'index' => (($count > 0) && ($self->{'__INDEX_GENERATED__'})),
						     'previous' => ( ( $count > 0 ) ? htmlcatfile($rootdir,
												  $self->{'THEME'}->filename('index',($count-1))) : "" ),
						     'next' => ( ($count<($maxcount-1)) ? htmlcatfile($rootdir,
												      $self->{'THEME'}->filename('index',($count+1))) : "" ),
						     'notree' => ( isemptyhash( $self->{'CONTENT'}{'entries'} ) ),
						     'userdef' => $self->getNavigationButtons(),
						   },
						   $rootdir ) ;
      }
      $count ++ ;
      @letterentries = () ;
    }

    @letterentries = ( @letterentries, @{$indexentries{$word}} ) ;
  }

  if ( $currentfile ) {
    # Really finish the last file
    $content = join( '',
		     $nav,
		     $self->{'THEME'}->partseparator(),
		     $self->{'THEME'}->format_index_page( $letterlist,
							  $lastletter,
							  \@letterentries ),
		     $self->{'THEME'}->partseparator(),
		     $nav,
		     $self->{'THEME'}->partseparator(),
		     $self->{'THEME'}->get_copyright($rootdir) ) ;
    $self->{'THEME'}->create_html_body_page( $currentfile,
					     $content,
					     $self->{'SHORT_TITLE'},
					     $rootdir,
					     'html') ;
  }

  Bib2HTML::General::Verbose::three( "\tindexes finished\n" ) ;

  return 1 ;
}

#------------------------------------------------------
#
# Overwritable Generation API
#
#------------------------------------------------------

my %__FIELD_TO_LANG_TRANS_TBL = ( 'editor' => 'EDITORS',
				  'booktitle' => 'IN',
				  'author' => 'AUTHORS',
				) ;

=pod

=item * MAKE_REQUIRED()

Add a required parameter into the specified array.

=cut
sub MAKE_REQUIRED(\@$$;$$) {
  my $self = shift ;
  my $LABEL = 'I18N_LANG_FIELD_';
  if ( exists $__FIELD_TO_LANG_TRANS_TBL{lc("$_[2]")} ) {
    $LABEL .= $__FIELD_TO_LANG_TRANS_TBL{lc("$_[2]")} ;
  }
  else {
    $LABEL .= uc($_[2]) ;
  }
  my $val = $_[1]->{'fields'}{"$_[2]"} || "-" ;
  $val = "$_[3]$val" if ($_[3]) ;
  $val .= "$_[4]" if ($_[4]) ;
  push @{$_[0]}, { 'name' => $self->{'LANG'}->get("$LABEL"),
		   'explanation' => "$val",
		 } ;
}

=pod

=item * MAKE_OPTIONAL()

Add a optional parameter into the specified array.

=cut
sub MAKE_OPTIONAL(\@$$;$$) {
  my $self = shift ;
  if ((exists $_[1]->{'fields'}{"$_[2]"})&&
      ($_[1]->{'fields'}{"$_[2]"})) {
    my $LABEL = 'I18N_LANG_FIELD_';
    if ( exists $__FIELD_TO_LANG_TRANS_TBL{lc("$_[2]")} ) {
      $LABEL .= $__FIELD_TO_LANG_TRANS_TBL{lc("$_[2]")} ;
    }
    else {
      $LABEL .= uc($_[2]) ;
    }
    my $val = $_[1]{'fields'}{"$_[2]"} ;
    $val = "$_[3]$val" if ($_[3]) ;
    $val .= "$_[4]" if ($_[4]) ;
    push @{$_[0]}, { 'name' => $self->{'LANG'}->get("$LABEL"),
                     'explanation' => "$val",
                   } ;
  }
}

=pod

=item * generate_entry_content_article()

See generate_entry_content()

=cut
sub generate_entry_content_article($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;

  my @content = () ;
  $self->MAKE_REQUIRED(\@content,$_[1],'journal') ;

  $self->MAKE_OPTIONAL(\@content,$_[1],'volume') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'number') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'pages') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;

  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content);
}

=pod

=item * generate_entry_content_book()

See generate_entry_content()

=cut
sub generate_entry_content_book($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;

  my @content = () ;
  $self->MAKE_REQUIRED(\@content,$_[1],'publisher') ;

  $self->MAKE_OPTIONAL(\@content,$_[1],'series') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'volume') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'number') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'edition') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;

  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content,1);
}

=pod

=item * generate_entry_content_booklet()

See generate_entry_content()

=cut
sub generate_entry_content_booklet($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;

  my @content = () ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'howpublished') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;

  # The following fields are not required in BibTeX specification
  $self->MAKE_OPTIONAL(\@content,$_[1],'publisher') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'series') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'volume') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'number') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'edition') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;

  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content);
}

=pod

=item * generate_entry_content_inbook()

See generate_entry_content()

=cut
sub generate_entry_content_inbook($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;

  my @content = () ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'howpublished') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;

  # The following fields are not required in BibTeX specification
  $self->MAKE_OPTIONAL(\@content,$_[1],'publisher') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'series') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'volume') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'number') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'edition') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;

  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content);
}

=pod

=item * generate_entry_content_incollection()

See generate_entry_content()

=cut
sub generate_entry_content_incollection($$$$$) : method {
  my $self = shift ;
  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content(@_);
}

=pod

=item * generate_entry_content_inproceedings()

See generate_entry_content()

=cut
sub generate_entry_content_inproceedings($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;

  my @content = () ;
  $self->MAKE_REQUIRED(\@content,$_[1],'booktitle') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'series') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'editor') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'volume') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'number') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'pages') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'organization') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'publisher') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'type') ;

  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content);
}

=pod

=item * generate_entry_content_manual()

See generate_entry_content()

=cut
sub generate_entry_content_manual($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;

  my @content = () ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'edition') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'organization') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;

  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content);
}

=pod

=item * generate_entry_content_mastersthesis()

See generate_entry_content()

=cut
sub generate_entry_content_mastersthesis($$$$$) : method {
  my $self = shift ;
  return $self->generate_entry_content_phdthesis(@_) ;
}

=pod

=item * generate_entry_content_phdthesis()

See generate_entry_content()

=cut
sub generate_entry_content_phdthesis($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;

  my @content = () ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'type') ;
  $self->MAKE_REQUIRED(\@content,$_[1],'school') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;

  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content);
}

=pod

=item * generate_entry_content_proceedings()

See generate_entry_content()

=cut
sub generate_entry_content_proceedings($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;

  my @content = () ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'series') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'volume') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'number') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'organization') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'publisher') ;

  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content, 1);
}

=pod

=item * generate_entry_content_techreport()

See generate_entry_content()

=cut
sub generate_entry_content_techreport($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;

  my @content = () ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'number') ;
  $self->MAKE_REQUIRED(\@content,$_[1],'institution') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'address') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'type') ;

  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content);
}

=pod

=item * generate_entry_content_unpublished()

See generate_entry_content()

=cut
sub generate_entry_content_unpublished($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;
  my @content = () ;
  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content,undef,1);
}

=pod

=item * generate_entry_content_misc()

See generate_entry_content()

=cut
sub generate_entry_content_misc($$$$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;

  my @content = () ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'howpublished') ;
  $self->MAKE_OPTIONAL(\@content,$_[1],'year') ;

  #key,entry,url,rootdir,title,[user_fields,aut_ed,note]
  return $self->generate_entry_content($key,$_[1],$url,$rootdir,$_[4],\@content,1);
}

=pod

=item * generate_entry_content()

Generates the HTML entry-???.html
Overwrite this method.
Takes 6 args:

=over

=item * key (string)

is the BibTeX key of the current bibliographical entry

=item * entry (hash ref)

is the description of the current bibliographical entry

=item * url (string)

is the URL of the current entry

=item * rootdir (string)

is the path to the root.

=item * entry_title (ref string)

must be filled with the title of the entry.

=item * user_fields (array)

is the field predefined by the user. It must be an
array of associative arrays (one for each generable field).

=item * aut_ed_flg (optional boolean)

indicates if the author and the editor fields are mutual
alternatives.

=item * note_req (optional boolean)

indicates if the field 'note' was required.

=cut
sub generate_entry_content($$$$$;$$) : method {
  my $self = shift ;
  my ($key,$url,$rootdir) = ($_[0],$_[2],$_[3]) ;
  my ($aut_ed_flg,$note_req) = ($_[6],$_[7]) ;
  my $translator = Bib2HTML::Translator::BibTeXName->new() ;
  my $biblabeller = Bib2HTML::Translator::BibTeXEntry->new() ;

  # Compute the publication year
  my $date = $self->__get_year__( $_[0], '' ) ;
  if ( $date ) {
    if ( exists $_[1]{'fields'}{'month'} ) {
      $date = $self->{'THEME'}->format_date($_[1]{'fields'}{'month'},$date) ;
    }
  }
  else {
    Bib2HTML::General::Error::warm("You must specify a year for the entry '".$key."'",
				   extract_file_from_location( $_[1]{'location'} ),
				   extract_line_from_location( $_[1]{'location'} ) ) ;
  }

  #
  # Build the main tabular
  #
  my @content = () ;
  # The fields 'author' and 'editor' are mutual alternatives
  if ($aut_ed_flg) {
    push @content, { 'name' => $_[1]{'fields'}{'author'} ?
				$self->{'LANG'}->get('I18N_LANG_FIELD_AUTHORS') :
				$self->{'LANG'}->get('I18N_LANG_FIELD_EDITORS'),
		     'explanation' => $translator->formatnames_withurl(($_[1]{'fields'}{'author'}||
									$_[1]{'fields'}{'editor'})||'',
								       $self->{'FORMATS'}{'name'},
								       $self->{'FORMATS'}{'names'},
								       $self,
								       -1,
								       $rootdir) || "-",
		   } ;
  }
  else {
    # Only the field 'author' is required
    $self->MAKE_REQUIRED(\@content,$_[1],'author') ;
  }

  # Finish to build the tabular
  $self->MAKE_REQUIRED(\@content,$_[1],'title', '&laquo;&nbsp;<i>', '&nbsp;&raquo;</i>') ;
  #$self->MAKE_REQUIRED(\@content,$_[1],'date') ;
  push @content, @{$_[5]} ;

  if (($aut_ed_flg)&&
      (exists $_[1]{'fields'}{'author'})&&
      ($_[1]{'fields'}{'author'})&&
      (exists $_[1]{'fields'}{'editor'})&&
      ($_[1]{'fields'}{'editor'})) {
    $self->MAKE_OPTIONAL(\@content,$_[1],'editor') ;
  }

  if ($note_req) {
    $self->MAKE_REQUIRED(\@content,$_[1],'note') ;
  }
  else {
    $self->MAKE_OPTIONAL(\@content,$_[1],'note') ;
  }

  # Compute the user comments
  my $annote = '' ;
  if ( ( exists $_[1]{'fields'}{'annote'} ) ||
       ( exists $_[1]{'fields'}{'comments'} ) ) {
    $annote = $self->{'THEME'}->section( $self->{'LANG'}->get('I18N_LANG_FIELD_ANNOTATION'),
					 ($_[1]{'fields'}{'annote'}||'').
					 ($_[1]{'fields'}{'comments'}||''),
					 $rootdir ) ;
  }

  # What is the title of this entry?
  my $title = '['.$biblabeller->citation_label($key,$_[1]).'] &nbsp;' ;
  if ( ! $_[1]{'fields'}{'title'} ) {
    Bib2HTML::General::Error::warm( "Can't found the title for the entry with key '".$key."'",
				    extract_file_from_location( $_[1]{'location'} ),
				    extract_line_from_location( $_[1]{'location'} ) ) ;
  }
  $title .= ucfirst($_[1]{'fields'}{'title'}) || '' ;
  # Replies the title to the calling function
  $_[4] = translate_html_entities(strip_html_tags($title)) ;
  $_[4] =~ s/\s+/ /g;

  # Computes the BibTeX verbatim part
  my $bibtex_verb = '' ;
  if ( $self->{'SHOW_BIBTEX'} ) {

    my $e = new Bib2HTML::Translator::BibTeXEntry() ;
    $bibtex_verb = $e->bibtex_build_entry_html($_[1]{'type'},"$key",
					       $_[1]{'original-fields'},
					       $self->{'CONTENT'}{'constants'},
					       80) ;

    if ( $bibtex_verb ) {
      $bibtex_verb = $self->{'THEME'}->section( $self->{'LANG'}->get('I18N_LANG_FIELD_BIBTEX_VERBATIM'),
						"<PRE><CODE>".
						"$bibtex_verb".
						"</CODE></PRE>",
						$rootdir ) ;
    }

  }

  # Computes the XML verbatim part
  my $xml_verb = '' ;
  if (( $self->genparam('xml-verbatim') )&&( $self->{'XML_GENERATOR'} )) {

    $xml_verb = get_html_entities($self->{'XML_GENERATOR'}->create_the_standalone_xml_entry("$key")) ;

    if ( $xml_verb ) {
      $xml_verb = $self->{'THEME'}->section( $self->{'LANG'}->get('I18N_LANG_FIELD_XML_VERBATIM'),
					     "<PRE><CODE>".
					     "$xml_verb".
					     "</CODE></PRE>",
					     $rootdir ) ;
    }

  }

  # Generates each main parts of the entry page
  return [ $self->{'THEME'}->subtitle($title), # title
           $self->{'THEME'}->build_twocolumn_array( $key." ". # main tabular
						    $self->{'THEME'}->small("(".
									    $self->{'SINGULAR_TYPE_LABELS'}{$_[1]{'type'}}.
									    ")"),
						    \@content ),
           $annote, # user comments
	   $bibtex_verb, # BibTeX verbatim part
	   $xml_verb, # XML verbatim part
         ] ;
}

=pod

=item * copy_files()

Generates the HTML pages.
Overwrite this method.

=cut
sub copy_files() : method {
  my $self = shift ;
  my @source = File::Spec->splitdir($self->{'BIB2HTML'}{'PERLSCRIPTDIR'}) ;
  @source = ( @source, split(/\:\:/, __PACKAGE__) ) ;
  pop @source ;

  # Copy icons
  $self->copythisfile( File::Spec->catfile(@source,"valid-html401.gif"),
		       File::Spec->catfile($self->{'TARGET'},"valid-html401.gif") ) ;
  $self->copythisfile( File::Spec->catfile(@source,"valid-css.gif"),
		       File::Spec->catfile($self->{'TARGET'},"valid-css.gif") ) ;
  $self->copythisfile( File::Spec->catfile(@source,"loupe.gif"),
		       File::Spec->catfile($self->{'TARGET'},"loupe.gif") ) ;

  # Copy the theme files
  $self->{'THEME'}->copy_files() ;
}

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

  my $sbase = basename("$target") ;

  if ($self->is_restricted_file("$sbase")) {
    $self->SUPER::copythisfile("$source","$target");
  }

  return 1 ;
}

=pod

=item * generate_index_content()

Generates the HTML index-???.html
Overwrite this method.
Takes 5 args:

=over

=item * entries (hash ref)

is the associative array that this method must
update to add some entry inside the index.

=item * entry (hash ref)

is the description of the current bibliographical entry

=item * url (string)

is the URL of the current entry

=item * comment (string)

is the comment associated to the current entry

=item * rootdir (string)

is the path to the root.

=cut
sub generate_index_content(\%$$$$) : method {
  my $self = shift ;
  my ($entry,$url,$comment,$rootdir) = ($_[1],$_[2],$_[3],$_[4]) ;
}

=pod

=item * generate_overviewtree_content()

Generates the HTML overview-tree.html.
Overwrite this method.
Takes 1 arg:

=over

=item * rootdir (string)

is the path to the root.

=back

=cut
sub generate_overviewtree_content($) : method {
  my $self = shift ;
  my $rootdir = shift ;
  my @entries = $self->get_all_entries_ayt() ;
  my $translator = Bib2HTML::Translator::BibTeXName->new() ;
  my $biblabeller = Bib2HTML::Translator::BibTeXEntry->new() ;
  my $content = $self->{'THEME'}->title($self->{'LANG'}->get('I18N_LANG_ENTRY_TYPE_TREE')) ;

  # Build the tree
  my %tree = () ;
  foreach my $entry (@entries) {
    my $type = $self->{'CONTENT'}{'entries'}{$entry}{'type'} ;
    if ( $self->{'PLURIAL_TYPE_LABELS'}{$type} ) {
      my $typelabel = $self->{'THEME'}->strong($self->{'PLURIAL_TYPE_LABELS'}{$type}) ;
      $typelabel =~ s/[ \t\n\r]+/&nbsp;/g ;
      my $filename = $self->filename('entry',$entry) ;
      my $name = $translator->formatnames( $self->__get_author_editor__($entry,''),
					   $self->{'FORMATS'}{'name'},
					   $self->{'FORMATS'}{'names'} ) ;
      $name =~ s/[ \t\n\r]+/&nbsp;/g ;
      my $title = $self->{'THEME'}->entry_title( extract_first_words( $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'title'},
								      40 ) ) ;
      $title =~ s/[ \t\n\r]+/&nbsp;/g ;
      my $year = $self->__get_year__( $entry, '' ) ;
      my $entrylabel = join( '',
			     "[",
			     $self->{'THEME'}->href( htmlcatfile($rootdir,$filename),
						     $biblabeller->citation_label($entry,$self->{'CONTENT'}{'entries'}{$entry}),
						     $self->browserframe('overview-summary') ),
			     "]&nbsp;",
			     $name,
			     ",&nbsp;",
			     $title,
			     (  $year ? "&nbsp;(". $year .")" :	'' )
			   ) ;
      $tree{$typelabel}{$entrylabel} = {} ;
    }
  }
  # Generate the HTML representation of the tree
  if ( $self->{'THEME'}->can('get_tree') ) {
    $content .= $self->{'THEME'}->get_tree( \%tree, $rootdir, $self->{'LANG'}->get('I18N_LANG_DOCUMENTS') ) ;
  }
  else {
    # Display the tree
    if ( ! isemptyhash( \%tree ) ) {
      my $treecontent = '' ;
      foreach my $type (sortbyletters @{keys %tree}) {
	if ( ! isemptyhash( $tree{$type} ) ) {
	  my $subs = '' ;
	  foreach my $entry (sortbyletters @{keys %{$tree{$type}}}) {
	    $subs .= $self->{'THEME'}->get_tree_leaf( $entry, $rootdir ) ;
	  }
	  $treecontent .= $self->{'THEME'}->get_tree_node( $type, $subs, $rootdir ) ;
	}
      }
      if ( $treecontent ) {
	$content .= $self->{'THEME'}->get_tree_node( '', $treecontent, $rootdir ) ;
      }
    }
  }

  return $content ;
}

=pod

=item * generate_overview_content()

Generates the HTML overview-summary.html.
Overwrite this method.
Takes 1 arg:

=over

=item * rootdir (string)

is the path to the root.

=back

=cut
sub generate_overview_content($) : method {
  # Patch by Aurel Gabris added the 2006/04/10
  my $self = shift ;
  my $rootdir = shift ;
  my $content = '' ;
  my @entries = $self->get_all_entries_yat() ;
  my $translator = Bib2HTML::Translator::BibTeXName->new() ;
  my $currentyear = '' ;
  my @tab = () ;

  foreach my $entry (@entries) {
    my $year = $self->__get_year__( $entry, '' ) ;
    if ( "$currentyear" ne "$year" ) {
      # Display tab
      if ( @tab ) {
	$content .= $self->{'THEME'}->build_twocolumn_array( $currentyear||
							     $self->{'LANG'}->get('I18N_LANG_NO_DATE'),
							     \@tab ) ;
      }
      @tab = () ;
      $currentyear = $year ;
    }
    my $filename = $self->filename('entry',$entry) ;
    push @tab, { 'name' => $self->{'THEME'}->href( htmlcatfile($rootdir,$filename),
						   $translator->formatnames( $self->__get_author_editor__($entry,''),
									     $self->{'FORMATS'}{'name'},
									     $self->{'FORMATS'}{'names'},
									     $self->genparam('max-names-overview')||1),
						   $self->browserframe('overview-summary') ),
                  'explanation' => join( '',
					 $self->{'THEME'}->entry_title( extract_first_words( $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'title'},
											     $self->genparam('max-titlelength-overview')||70 ) ),
					 "<BR>\n",
					 (exists($self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'journal'}) &&
                                         exists($self->{'GENERATOR_PARAMS'}{'show-journalparams-overview'})) ?
                                         $self->{'THEME'}->small($self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'journal'}).(exists($self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'volume'})?" ".$self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'volume'}.(exists($self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'pages'})?", ".$self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'pages'}.(exists($self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'year'})?" (".$self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'year'}.")":""):""):""):					
					 $self->{'THEME'}->small("(".
								 $self->{'SINGULAR_TYPE_LABELS'}{$self->{'CONTENT'}{'entries'}{$entry}{'type'}}.
								 ")") ),
               } ;
  }
  if ( @tab ) {
    # Display tab
    $content .= $self->{'THEME'}->build_twocolumn_array( $currentyear||
							 $self->{'LANG'}->get('I18N_LANG_NO_DATE'),
							 \@tab ) ;
  }
  return $content ;
}

=pod

=item * generate_overviewframe_content()

Generates the HTML overview-frame.html.
Overwrite this method.
Takes 1 arg:

=over

=item * rootdir (string)

is the path to the rootdirectory.

=back

=cut
sub generate_overviewframe_content($) : method {
  my $self = shift ;
  my $rootdir = $_[0] || confess( 'you must supply the root directory' );
  my @lines = () ;

  # Generates the list of types
  my @types = $self->get_entry_types() ;
  my %typematching;
  if ( exists($self->{'GENERATOR_PARAMS'}{'type-matching'}) ) {
    %typematching = %{$self->{'GENERATOR_PARAMS'}{'type-matching'}};
  }

  if ( @types > 0 ) {
    # fill emtpy type matching slots
    foreach my $type (@types) {
      if ( ! exists( $typematching{$type} ) ) {
	$typematching{$type} = $type;
      }
    }
    my @thevals = values %typematching;
    foreach my $type (uniq(sort(@thevals))) {
      if ( $self->{'PLURIAL_TYPE_LABELS'}{$type} ) {
	my $url = $self->filename('type-overview',$type) ;
	push @lines, $self->{'THEME'}->href( htmlcatfile($rootdir,$url),
					     $self->{'PLURIAL_TYPE_LABELS'}{$type},
					     $self->browserframe('allelements') ) ;
      }
      else {
	confess( "You must supply a label for the entry type '$type'" ) ;
      }
    }
  }

  my $subframe = $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_FRAME_TITLE_TYPES'),
						  \@lines,
						  $rootdir ) ;

  # Generates the list of authors
  my $subframe2 ;
  my %authors = $self->get_entry_authors() ;
  my $parser = Bib2HTML::Translator::BibTeXName->new() ;
  @lines = () ;
  my @authors = keys %authors;
  @authors = sortbyletters(@authors);
  foreach my $author (@authors) {
    if ( exists($self->{'GENERATOR_PARAMS'}{'author-regexp'}) ) {
      if (! ( $parser->formatname($authors{$author}, 'l') =~ /$self->{'GENERATOR_PARAMS'}{'author-regexp'}/i)) { next };
    }
    my $url = $self->filename('author-overview',$author) ;
    push @lines, $self->{'THEME'}->href( htmlcatfile($rootdir,$url),
					 $parser->formatname($authors{$author}, 'l, f.'),
					 $self->browserframe('allelements') ) ;
  }
  $subframe2 = $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_FRAME_TITLE_AUTHORS'),
						\@lines,
						$rootdir ) ;

  return join('',$subframe,$subframe2) ;
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
  confess( 'you must supply the author\'s data' ) unless $_[0] ;
  my $rootdir = $_[2] || confess( 'you must supply the root directory' );
  my $data = $_[0] ;
  my $label = $_[1] || '' ;
  my $url = '' ;

  if ($label) {
    my $texname = Bib2HTML::Translator::BibTeXName->new() ;
    # Search for the first author which corresponds to
    # the specified one.
    my %authors = $self->get_entry_authors() ;

    my $k = undef ;
    while ((!$k)&&(my $authorkey = each(%authors))) {
      if ($texname->samenames($authors{$authorkey},$data)) {
	$k = $authorkey ;
      }
    }
    # Compute the filename for this author
    if ($k) {
      my $filename = $self->filename('author-overview',$k) ;
      $url = $self->{'THEME'}->href($filename) ;
      $url = $self->{'THEME'}->href( (($rootdir) ?
				      htmlcatfile($rootdir,$filename) :
				      $filename),
				     $label,
				     $self->browserframe('allelements') ) ;
    }
  }
  if (!$url) {
    $url = "$label";
  }
  return $url ;
}

#------------------------------------------------------
#
# Helpers
#
#------------------------------------------------------

=pod

=item * _add_sentence_keywords()
Takes 5 args.

=cut
sub _add_sentence_keywords($$$$$) : method {
  my $self = shift ;
  my @words = get_title_keywords( $_[1] ) ;
  foreach my $word (@words) {
    if ( $word !~ /^[A-Z]+$/ ) {
      $word = ucfirst($word) ;
    }
    my %desc = ( 'url' => $_[2],
                 'label' => $word,
                 'comment' => $_[3],
                 'short-comment' => $_[4],
               ) ;
    my $sorttag = lc(remove_html_accents($word));
    push @{$_[0]->{$sorttag}}, \%desc ;
  }
}

#------------------------------------------------------
#
# Getters
#
#------------------------------------------------------

=pod

=item * filename()

Replies the filename of the specified section.
Takes 1 arg:

=over

=item * section (string)

is the name of the section.

=back

=cut
sub filename($) : method {
  my $self = shift ;
  my $section = $_[0] || '' ;

  # Does the specified request already encountered?
  if ( ($section) &&
       ($section eq 'entry') &&
       ($_[1]) &&
       ($self->{'ENTRY_FILENAMES'}{$_[1]}) ) {
      return $self->{'ENTRY_FILENAMES'}{$_[1]} ;
  }
  elsif ( ($section) &&
	  ($section eq 'author-overview') &&
	  ($_[1]) &&
	  ($self->{'AUTHOR_FILENAMES'}{$_[1]}) ) {
      return $self->{'AUTHOR_FILENAMES'}{$_[1]} ;
  } 

  # Compute a new filename
  my $fn = $self->{'FILENAMES'}{$section} ;
  confess( "filename not found for '$section'" ) unless $fn ;
  my $i = 1 ;
  while ( $fn =~ /\#\Q$i\E/ ) {
    my $val = (defined($_[$i])) ? $_[$i] : '' ;
    $fn =~ s/\#$i/$val/g ;
    $i ++ ;
  }

  # Make sure that the filename could be supported by most of the
  # operating systems
  $fn =~ s/:/-/g if ($fn);

  # Save the filename
  if ( ($section) &&
       ($section eq 'entry') &&
       ($_[1]) ) {
      $self->{'ENTRY_FILENAMES'}{$_[1]} = $fn ;
  }
  elsif ( ($section) &&
	  ($section eq 'author-overview') &&
	  ($_[1]) ) {
      $self->{'AUTHOR_FILENAMES'}{$_[1]} = $fn ;
  }
  
  return $fn ;
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
sub browserframe($) : method {
  my $self = shift ;
  my $section = $_[0] || '' ;
  my $fr = $self->{'FRAMES'}{$section} ;
  confess( "frame not found for '$section'" ) unless $fr ;
  return $fr ;
}


=pod

=item * getNavigationButtons()

Replies the additional buttons for the navigation bar.
Takes 1 arg:

=over

=item * exception (optional mixed)

is the list of label to not reply.

=back

=cut
sub getNavigationButtons : method {
  my $self = shift ;
  my @buttons = () ;
  if ( int(@_) > 0 ) {
    if ( isarray($_[0]) ) {
      foreach my $button (@{$self->{'USER_NAVIGATION_BUTTONS'}}) {
	if ( ! strinarray($button->{'label'},$_[0]) ) {
	  push @buttons, $button ;
	}
      }
    }
    else {
      foreach my $button (@{$self->{'USER_NAVIGATION_BUTTONS'}}) {
	if ( ! strinarray($button->{'label'},\@_) ) {
	  push @buttons, $button ;
	}
      }
    }
  }
  else {
    @buttons = @{$self->{'USER_NAVIGATION_BUTTONS'}} ;
  }
  return \@buttons ;
}

=pod

=item * addNavigationButton()

Adds an additional button for the navigation bar.
Takes 2 args:

=over

=item * url (string)

is the URL for the new button

=item * key (string)

is the language string identifier that corresponds
to the label of the button.

=back

=cut
sub addNavigationButton($$) : method {
  my $self = shift ;
  my $url = $_[0] || '' ;
  my $label = $_[1] || '' ;
  return unless (($url)&&($label)) ;
  push @{$self->{'USER_NAVIGATION_BUTTONS'}}, { 'url' => "$url",
						'label' => "$label",
					      } ;
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
