# Copyright (C) 2004-07  Stephane Galland <galland@arakhne.org>
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

Bib2HTML::Generator::XMLGen - A basic XML generator

=head1 SYNOPSYS

use Bib2HTML::Generator::XMLGen ;

my $gen = Bib2HTML::Generator::XMLGen->new( content, output, info, titles,
                                            lang, theme, params ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::XMLGen is a Perl module, which permits to
generate XML pages for the BibTeX database.
The generated XML file is compliant with the DTD from
http://bibtexml.sf.net/

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use Bib2HTML::Generator::XMLGen;

    my $gen = Bib2HTML::Generator::XMLGen->new( { }, "./bib",
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

package Bib2HTML::Generator::XMLGen;

@ISA = ('Bib2HTML::Generator::AbstractGenerator');
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Carp ;
use File::Spec ;
use File::Basename ;

use Bib2HTML::Generator::AbstractGenerator;
use Bib2HTML::General::Misc;
use Bib2HTML::General::Error;
use Bib2HTML::General::HTML;
use Bib2HTML::General::Encode;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of this generator
my $VERSION = "1.0" ;

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
       push @langs, $l."_XMLGen";
     }
     push @langs, $l;
    }
  }
  else {
     @langs = ( $_[4] );
     if ($_[4] !~ /_[a-zA-Z0-9]+Gen$/) {
       unshift @langs, $_[4]."_XMLGen";
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

  return $self;
}

#------------------------------------------------------
#
# Generation parameters
#
#------------------------------------------------------

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
  my $self = shift ;
  if ( ( $_[0] eq 'xml-encoding' ) ) {
    # will be saved by PARENT::new
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
  my $self = shift ;
  $self->SUPER::display_supported_generator_params() ;

  $self->show_supported_param('xml-encoding',
			      'String, the character encoding used in the HTML pages '.
			      '("UTF8", "ISO-8859-1"...).' );
}

#------------------------------------------------------
#
# Generation API
#
#------------------------------------------------------

=pod

=item * pre_processing()

Pre_processing.

=cut
sub pre_processing() : method {
  my $self = shift ;

  # Set the HTML encoding
  if (!$self->{'GENERATOR_PARAMS'}{'xml-encoding'}) {
    $self->{'GENERATOR_PARAMS'}{'xml-encoding'} = get_default_encoding();
  }
  set_default_encoding($self->{'GENERATOR_PARAMS'}{'xml-encoding'});

  # Call inherited generation method
  $self->SUPER::pre_processing() ;
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
  my $t = '' ;

  # Generates the content for each entries
  $self->create_XMLENTRIES($t) ;

  # Generates the complete data file
  $self->create_XML_file($t) ;

  # Generates the header and the footer
  $self->create_XMLHEADER($t) ;
  $self->create_XMLFOOTER($t) ;

  # Create7 file file
  $self->create_FILE($t) ;
}

=pod

=item * create_the_xml_entry()

Generates and replies the XML string for the specified entry
Takes 1 arg:

=over

=item * key (string)

is the key of the bibtex entry.

=back

=cut
sub create_the_xml_entry($) : method {
  my $self = shift ;
  my $key = shift ;

  # Compute entry constants
  my $type = $self->{'CONTENT'}{'entries'}{"$key"}{'type'} ;
  my $entry = '' ;

  # Calls the content building function
  my $fct = "create_XMLENTRY_$type" ;
  if ( my $funcref = $self->can( $fct ) ) {
    $self->$funcref( $key,
		     $self->{'CONTENT'}{'entries'}{"$key"},
		     $entry ) ;
  }
  else {
    Bib2HTML::General::Error::warm("I don't know how to generate a '\@".$type.
				   "' for the entry '$key'. Assume '\@misc'",
				   extract_file_from_location( $self->{'CONTENT'}{'entries'}{"$key"}{'location'} ),
				   extract_line_from_location( $self->{'CONTENT'}{'entries'}{"$key"}{'location'} ) ) ;
    $self->create_XMLENTRY_misc( $key,
				 $self->{'CONTENT'}{'entries'}{"$key"},
				 $entry ) ;
  }

  # Create the entry's XML string
  $entry = $self->build_xmltag("bibtex:$type",$entry) ;
  $entry = $self->build_xmltag("bibtex:entry",$entry,
			       "id=\"$key\"") ;
  $_[0] .= $entry ;
}

=pod

=item * create_the_standalone_xml_entry()

Generates and replies the standalone XML string for the specified entry
Takes 1 arg:

=over

=item * key (string)

is the key of the bibtex entry.

=back

=cut
sub create_the_standalone_xml_entry($) : method {
  my $self = shift ;

  my $content = $self->create_the_xml_entry($_[0]) ;
  $self->create_XML_file($content) ;
  $self->create_XMLHEADER($content) ;
  return $content ;
}

=pod

=item * create_XMLENTRIES()

Generates the XML pages for each entry
Takes 1 arg:

=over

=item * content (string)

is the content to fill

=back

=cut
sub create_XMLENTRIES($) : method {
  my $self = shift ;
  my @entries = $self->get_all_entries_ayt() ;
  my $i = $#entries ;
  while ( $i >= 0 ) {
    # Compute entry constants
    my $type = $self->{'CONTENT'}{'entries'}{$entries[$i]}{'type'} ;
    my $entry = '' ;

    # Calls the content building function
    my $fct = "create_XMLENTRY_$type" ;
    if ( my $funcref = $self->can( $fct ) ) {
      $self->$funcref( $entries[$i],
		       $self->{'CONTENT'}{'entries'}{$entries[$i]},
		       $entry ) ;
    }
    else {
      Bib2HTML::General::Error::warm("I don't know how to generate a '\@".$type.
  				     "' for the entry '".$entries[$i]."'. Assume '\@misc'",
  				     extract_file_from_location( $self->{'CONTENT'}{'entries'}{$entries[$i]}{'location'} ),
  				     extract_line_from_location( $self->{'CONTENT'}{'entries'}{$entries[$i]}{'location'} ) ) ;
      $self->create_XMLENTRY_misc( $entries[$i],
				   $self->{'CONTENT'}{'entries'}{$entries[$i]},
				   $entry ) ;
    }

    # Create the entry's XML string
    $entry = $self->build_xmltag("bibtex:$type",$entry) ;
    $entry = $self->build_xmltag("bibtex:entry",$entry, 
				 "id=\"".$entries[$i]."\"") ;
    $_[0] .= $entry ;

    $i -- ;
  }
}

=pod

=item * create_XMLHEADER

Replies the header of the XML file.
Takes 1 arg:

=over

=item * content (string)

is the content to fill

=back

=cut
sub create_XMLHEADER($) : method {
  my $self = shift ;
  my $encoding = $self->genparam('xml-encoding') || "ISO-8859-1";
  $_[0] = join( '',
		"<?xml version=\"1.0\" encoding=\"",
		$encoding,
                "\"?>\n",
		"<!DOCTYPE bibtex:file PUBLIC \"-//BibTeXML//DTD XML for BibTeX v1.0//EN\" \"bibteXML-ext.dtd\" >\n",
		$_[0]);
}

=pod

=item * create_XMLFOOTER

Replies the header of the XML file.
Takes 1 arg:

=over

=item * content (string)

is the content to fill

=back

=cut
sub create_XMLFOOTER($) : method {
  my $self = shift ;
  $_[0] = join( '',
		$_[0],
		"<!-- File generated with bib2html ",
		$self->{'BIB2HTML'}{'VERSION'},
		" the ",
		"".localtime(),
		"\n     Copyright (c) ",
		$self->{'BIB2HTML'}{'AUTHOR'},
		" (",
		$self->{'BIB2HTML'}{'AUTHOR_EMAIL'},
		") -->\n");
}

=pod

=item * create_XML_file

Create <bibtex:file>
Takes 1 arg:

=over

=item * content (string)

is the content to fill

=back

=cut
sub create_XML_file($) : method {
  my $self = shift ;
  $_[0] = $self->build_xmltag('bibtex:file',$_[0],
			      "xmlns:bibtex=\"http://bibtexml.sf.net/\"") ;
}

=pod

=item * create_FILE

Creates the XML file.
Takes 1 arg:

=over

=item * content (string)

is the content of the XML file.

=back

=cut
sub create_FILE($) : method {
  my $self = shift ;
  Bib2HTML::General::Verbose::two( "Writing ".$self->{'TARGET'}."..." ) ;

  my $writer = $self->get_stream_writer();
  
  $writer->openstream($self->{'TARGET'});
  $writer->out($_[0]||'') ;
  $writer->closestream() ;
}

=pod

=item * create_XMLENTRY_REQUIREDFIELD()

Generates a required XML field.
Takes 4 args:

=over

=item * name (string)

is the name of the field.

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_REQUIREDFIELD($$$$) : method {
  my $self = shift ;
  my $name = shift ;
  my $entrykey = shift ;
  my $data = shift ;

  my $content = '' ;
  if ( exists $data->{'fields'}{"$name"} ) {
    $content = $data->{'fields'}{"$name"} || '' ;
  }
  $content = strip_html_tags($content); #get_html_entities() ;
  $content =~ s/\s+/ /g;
  $_[0] .= $self->build_xmltag("bibtex:$name",$content) ;
}

=pod

=item * create_XMLENTRY_OPTIONALFIELD()

Generates a optional XML field.
Takes 4 args:

=over

=item * name (string)

is the name of the field.

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_OPTIONALFIELD($$$$) : method {
  my $self = shift ;
  my $name = shift ;
  my $entrykey = shift ;
  my $data = shift ;

  if ( exists $data->{'fields'}{"$name"} ) {
    my $content = $data->{'fields'}{"$name"} || '' ;
    $content = strip_html_tags($content); #get_html_entities(strip_html_tags($content)) ;
    $content =~ s/\s+/ /g;
    $_[0] .= $self->build_xmltag("bibtex:$name",$content) ;
  }
}

=pod

=item * create_XMLENTRY_NAMEFIELD()

Generates a optional names' XML field.
Takes 4 args:

=over

=item * name (string)

is the name of the field.

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_NAMEFIELD($$$$) : method {
  my $self = shift ;
  my $name = shift ;
  my $entrykey = shift ;
  my $data = shift ;

  if ( exists $data->{'fields'}{"$name"} ) {
    my @authors = $self->get_all_authors($data->{'fields'}{"$name"} || '') ;
    my $content = '' ;
    foreach my $author (@authors) {
      my $aut = '' ;
      if (!$author->{'et al'}) {
	if ($author->{'first'}) {
	  if ($author->{'first'} =~ /^[a-zA-Z]+\.(?:[a-zA-Z]+\.)*$/) {
	    $aut .= $self->build_xmltag('bibtex:initials',
					strip_html_tags($author->{'first'}));
					    #get_html_entities(strip_html_tags($author->{'first'}))) ;
	  }
	  else {
	    $aut .= $self->build_xmltag('bibtex:first',
					strip_html_tags($author->{'first'}));
					#    get_html_entities(strip_html_tags($author->{'first'}))) ;
	  }
	}
	if ($author->{'last'}) {
	  $aut .= $self->build_xmltag('bibtex:last',
					strip_html_tags($author->{'last'}));
					#  get_html_entities(strip_html_tags($author->{'last'}))) ;
	}
	if ($author->{'von'}) {
	  $aut .= $self->build_xmltag('bibtex:prelast',
					strip_html_tags($author->{'first'}));
					#  get_html_entities(strip_html_tags($author->{'von'}))) ;
	}
	if ($author->{'jr'}) {
	  $aut .= $self->build_xmltag('bibtex:lineage',
					strip_html_tags($author->{'first'}));
					#  get_html_entities(strip_html_tags($author->{'jr'}))) ;
	}
      }
      $content .= $self->build_xmltag("bibtex:people",$aut) ;
    }
    if ($content) {
      $_[0] .= $self->build_xmltag("bibtex:$name",$content) ;
    }
  }
}

=pod

=item * create_XMLENTRY_KEYWORDSFIELD()

Generates a optional keywords' XML field.
Takes 4 args:

=over

=item * name (string)

is the name of the field.

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_KEYWORDSFIELD($$$$) : method {
  my $self = shift ;
  my $name = shift ;
  my $entrykey = shift ;
  my $data = shift ;

  if ( exists $data->{'fields'}{"$name"} ) {
    my $content = '' ;
    my @words ;
    if ($data->{'fields'}{"$name"} =~ /;,:/) {
      @words = split(/\s*[;,:]\s*/,$data->{'fields'}{"$name"}) ;
    }
    else {
      @words = split(/\s+/,$data->{'fields'}{"$name"}) ;
    }
    foreach my $word (@words) {
      $content .= $self->build_xmltag('bibtex:keyword',
				      strip_html_tags($word));
					#get_html_entities(strip_html_tags($word))) ;
    }
    if ($content) {
      $_[0] .= $self->build_xmltag("bibtex:$name",$content) ;
    }
  }
}

=pod

=item * create_XMLENTRY_DEFAULTFIELDS()

Generates the default XML fields.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_DEFAULTFIELDS($$$) : method {
  my $self = shift ;

  $self->create_XMLENTRY_REQUIREDFIELD('title',@_) ;

  $self->create_XMLENTRY_NAMEFIELD('author',@_) ;
  $self->create_XMLENTRY_NAMEFIELD('editor',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('month',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('note',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('abstract',@_) ;
  $self->create_XMLENTRY_KEYWORDSFIELD('keywords',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('isbn',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('issn',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('lccn',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('url',@_) ;

  if ( exists $_[1]{'fields'}{'annote'} ) {
    $self->create_XMLENTRY_OPTIONALFIELD('annote',@_) ;
  }
  elsif ( exists $_[1]{'fields'}{'comments'} ) {
    $self->create_XMLENTRY_OPTIONALFIELD('comments',@_) ;
  }
}

#------------------------------------------------------
#
# Generation of entries API
#
#------------------------------------------------------

=pod

=item * create_XMLENTRY_article()

Generates the XML entry for an article.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_article($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;

  $self->create_XMLENTRY_REQUIREDFIELD('journal',@_) ;

  $self->create_XMLENTRY_OPTIONALFIELD('volume',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('number',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('pages',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('address',@_) ;
}

=pod

=item * create_XMLENTRY_book()

Generates the XML entry for a book.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_book($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;

  $self->create_XMLENTRY_REQUIREDFIELD('publisher',@_) ;

  $self->create_XMLENTRY_OPTIONALFIELD('series',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('volume',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('number',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('edition',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('address',@_) ;
}

=pod

=item * create_XMLENTRY_booklet()

Generates the XML entry for a book's part.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_booklet($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;

  $self->create_XMLENTRY_OPTIONALFIELD('howpublished',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('address',@_) ;
}

=pod

=item * create_XMLENTRY_inbook()

Generates the XML entry for a book's part.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_inbook($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;

  $self->create_XMLENTRY_OPTIONALFIELD('howpublished',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('address',@_) ;
}

=pod

=item * create_XMLENTRY_incollection()

Generates the XML entry for a collection's article.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_incollection($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_inproceedings(@_) ;
}

=pod

=item * create_XMLENTRY_inproceedings()

Generates the XML entry for an article in a conference's proceedings.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_inproceedings($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;

  $self->create_XMLENTRY_REQUIREDFIELD('booktitle',@_) ;

  $self->create_XMLENTRY_OPTIONALFIELD('series',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('editor',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('volume',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('number',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('pages',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('organization',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('publisher',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('address',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('type',@_) ;
}

=pod

=item * create_XMLENTRY_manual()

Generates the XML entry for a manual.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_manual($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;

  $self->create_XMLENTRY_OPTIONALFIELD('edition',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('organization',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('address',@_) ;
}

=pod

=item * create_XMLENTRY_masterthesis()

Generates the XML entry for a master's thesis.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_masterthesis($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_phdthesis(@_) ;
}

=pod

=item * create_XMLENTRY_mastersthesis()

Generates the XML entry for a master's thesis.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_mastersthesis($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_phdthesis(@_) ;
}

=pod

=item * create_XMLENTRY_phdthesis()

Generates the XML entry for a PHD thesis.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_phdthesis($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;

  $self->create_XMLENTRY_REQUIREDFIELD('school',@_) ;

  $self->create_XMLENTRY_OPTIONALFIELD('type',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('address',@_) ;
}

=pod

=item * create_XMLENTRY_proceedings()

Generates the XML entry for a conference's proceedings.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_proceedings($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;

  $self->create_XMLENTRY_OPTIONALFIELD('series',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('volume',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('number',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('address',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('organization',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('publisher',@_) ;
}

=pod

=item * create_XMLENTRY_techreport()

Generates the XML entry for a technical report.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_techreport($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;

  $self->create_XMLENTRY_REQUIREDFIELD('institution',@_) ;

  $self->create_XMLENTRY_OPTIONALFIELD('number',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('address',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('type',@_) ;
}

=pod

=item * create_XMLENTRY_unpublished()

Generates the XML entry for an unpublished document.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_unpublished($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;
}

=pod

=item * create_XMLENTRY_misc()

Generates the XML entry for a miscellaneous document.
Takes 3 args:

=over

=item * key (string)

is the key of the entry.

=item * data (hash)

is the data for the entry.

=item * content (ref string)

is the content to update.

=back

=cut
sub create_XMLENTRY_misc($$$) : method {
  my $self = shift ;
  $self->create_XMLENTRY_DEFAULTFIELDS(@_) ;

  $self->create_XMLENTRY_OPTIONALFIELD('howpublished',@_) ;
  $self->create_XMLENTRY_OPTIONALFIELD('year',@_) ;
}

#------------------------------------------------------
#
# Uitility API
#
#------------------------------------------------------

=pod

=item * indent

indent the specified string.
Takes 1 arg:

=over

=item * content (string)

is the content of the XML file.

=back

=cut
sub indent($) : method {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my @lines = split(/\n/,($_[0]||'')) ;
  @lines = map { "  $_" } @lines ;
  $text = join("\n",@lines) ;
  if ( $text !~ /\n$/ ) {
    $text .= "\n" ;
  }
  return $text ;
}

=pod

=item * build_xmllevel

replies an XML tag built from the parameters.
Takes 3 args:

=over

=item * name (string)

is the name of the tag.

=item * content (string)

is the content of the tag.

=item * params (optional string)

is the list of parameters for the tags.

=back

=cut
sub build_xmltag($$;$) : method {
  my $self = shift ;
  my $name = $_[0] || confess('you must supply a tag name') ;
  my $content = $_[1] || '' ;
  my $params = $_[2] || '' ;
  if ($content) {
    my $begin = "<$name".($params?" $params":"").">" ;
    my $end = "</$name>\n" ;
    if (($content =~ /\n/)||(length("$begin$content$end")>=40)) {
      return join( '',
		   "$begin\n",
		   $self->indent($content),
		   "$end" );
    }
    else {
      $content =~ s/^\s+// ;
      $content =~ s/\s+$// ;
      return join( '',
		   "$begin",
		   $content,
		   "$end" );
    }
  }
  else {
    return "<$name".($params?" $params":"")." />" ;
  }
}

1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 2004-07 Stéphane Galland E<lt>galland@arakhne.orgE<gt>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by Stéphane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

bib2html.pl
