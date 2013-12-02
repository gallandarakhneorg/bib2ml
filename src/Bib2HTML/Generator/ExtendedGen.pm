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

Bib2HTML::Generator::ExtendedGen - An HTML generator

=head1 SYNOPSYS

use Bib2HTML::Generator::ExtendedGen ;

my $gen = Bib2HTML::Generator::ExtendedGen->new( data, output, info, titles,
                                                 lang, theme ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::ExtendedGen is a Perl module, which permits to
generate HTML pages for the BibTeX database.
In addition to the features of Bib2HTML::Generator::HTMLGen, this
generator supports the following bibtex fields:

=over

=item * isbn

is the ISBN number.

=item * issn

is the ISSN number.

=item * readers

is the list of people who read this entry. The format
is similar as for the author field.

=item * abstract

is the abstract of the document.

=item * keywords

are the keywords associated to the document.

=item * localfile

is the local path to a electronic version of
the document. This document could be dowload
from the generated webpage.

=back

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use Bib2HTML::Generator::ExtendedGen;

    my $gen = Bib2HTML::Generator::ExtendedGen->new( { }, "./bib",
						 { 'BIB2HTML_VERSION' => "0.1",
						 },
						 { 'SHORT' => "This is the title",
						   'LONG' => "This is the title",
						 },
						 "English",
						 "Simple"
					       ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * content (hash)

See HTMLGen.pm.

=item * output (string)

See HTMLGen.pm.

=item * bib2html_data (hash)

See HTMLGen.pm.

=item * titles (hash)

See HTMLGen.pm.

=item * lang (string)

See HTMLGen.pm.

=item * theme (string)

See HTMLGen.pm.

=item * show_bibtex (boolean)

See HTMLGen.pm

=item * params (optional array)

is the set of parameters passed to the generator.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in ExtendedGen.pm itself.

=over

=cut

package Bib2HTML::Generator::ExtendedGen;

@ISA = ('Bib2HTML::Generator::HTMLGen');
@EXPORT = qw( );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

use File::Basename ;

use Bib2HTML::Generator::HTMLGen ;
use Bib2HTML::General::Misc ;
use Bib2HTML::General::HTML ;
use Bib2HTML::General::Verbose ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of this generator
my $VERSION = "5.0" ;

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
       push @langs, $l."_ExtendedGen";
     }
     push @langs, $l;
    }
  }
  else {
     @langs = ( $_[4] );
     if ($_[4] !~ /_[a-zA-Z0-9]+Gen$/) {
       unshift @langs, $_[4]."_ExtendedGen";
     }
  }

  $_[4] = \@langs;

  my $self = $class->SUPER::new(@_) ;
  $self->{'EXTEND_FILES_TO_COPY'} = [] ;
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Background tasks
#
#------------------------------------------------------


=pod

=item * pre_processing()

Pre_processing.

=cut
sub pre_processing() : method {
  my $self = shift ;

  # Call inherited copying method
  $self->SUPER::pre_processing() ;

  foreach my $key (keys %{$self->{'CONTENT'}{'entries'}}) {
    my $entry = $self->{'CONTENT'}{'entries'}{"$key"};
    if ((exists $entry->{'fields'}{'pdf'})&&
        (!exists $entry->{'fields'}{'localfile'})) {
	$self->addLocalFileFromPDF($key,$entry->{'fields'}{'pdf'}, $entry->{'fields'});
    }
  }
}

sub addLocalFileFromPDF($$$) {
  my $self = shift;
  my $key = shift;
  my $url = shift;

  my $filename = undef;

  if ( $url =~ /^file:\s*(.*?)\s*$/i) {
    $filename = "$1";
  }
  elsif ( ( $url !~ /^http:/i ) &&
          ( $url !~ /^ftp:/i ) &&
          ( $url !~ /^https:/i ) &&
          ( $url !~ /^gopher:/i ) &&
          ( $url !~ /^mailto:/i ) ) {
    $filename = "$url" ;
  }

  if ($filename) {
    Bib2HTML::General::Verbose::one ("The 'pdf' field of $key was replaced by the 'localfile' field.");
    $_[0]->{'localfile'} = "$filename";
    delete $_[0]->{'pdf'};
  }      
}

=pod

=item * copy_files()

Overwrite this method.

=cut
sub copy_files() : method {
  my $self = shift ;

  # Call inherited copying method
  $self->SUPER::copy_files() ;

  # Copy the Extended's files
  my @source = File::Spec->splitdir($self->{'BIB2HTML'}{'PERLSCRIPTDIR'}) ;
  @source = ( @source, split(/\:\:/, __PACKAGE__) ) ;
  pop @source ;

  # Copy icons
  $self->copythisfile( File::Spec->catfile(@source,"drive.png"),
		       File::Spec->catfile($self->{'TARGET'},"drive.png") ) ;

  # Copy registered electronic documents
  foreach my $file (@{$self->{'EXTEND_FILES_TO_COPY'}}) {
    if ($self->is_restricted_file($file->{'target'})) {
      if ( ! mkdir_rec( dirname( $file->{'target'} ) ) ) {
        Bib2HTML::General::Error::syswarm( $file->{'target'}.": $!\n" );
      }
      elsif ( ! $self->copythisfile( $file->{'source'}, $file->{'target'} ) ) {
        Bib2HTML::General::Error::syswarm( $file->{'source'}.": $!\n" );
      }
    }
  }
}

=pod

=item * register_file_to_copy()

Register a file which must be copied.
Takes 2 args:

=over

=item * source (string)

=item * target (string)

=back

=cut
sub register_file_to_copy($$) : method {
  my $self = shift;
  push @{$self->{'EXTEND_FILES_TO_COPY'}},
    { 'source' => $_[0],
      'target' => $_[1],
    } ;
}

#------------------------------------------------------
#
# Entry Generation
#
#------------------------------------------------------

=pod

=item * generate_entry_content()

Generates the HTML entry-???.html
Overwrite this method.
Takes 5 args:

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

=cut
sub generate_entry_content($$$$$) {
  my $self = shift ;
  my @content = @{$_[5]} ;
  my ($key,$entry,$url,$rootdir) = ($_[0],$_[1],$_[2],$_[3]) ;
  my ($title,$aut_ed_flg,$note_req) = ($_[4],$_[6],$_[7]) ;

  #
  # Prepare the additional fields which are supported by
  # this generator.
  # There new fields must be displayed inside the
  # first generated array of attributes.
  #
  # ISBN
  if ( exists $entry->{'fields'}{'isbn'} ) {
    push @content, { 'name' => $self->{'LANG'}->get('I18N_LANG_FIELD_ISBN'),
		     'explanation' => $entry->{'fields'}{'isbn'} || "-",
		   } ;
  }
  # ISSN
  if ( exists $entry->{'fields'}{'issn'} ) {
    push @content, { 'name' => $self->{'LANG'}->get('I18N_LANG_FIELD_ISSN'),
		     'explanation' => $entry->{'fields'}{'issn'} || "-",
		   } ;
  }
  # URL
  if ( exists $entry->{'fields'}{'url'} ) {
    my $url = $entry->{'fields'}{'url'} ;
    if ( $url ) {
	$url =~ s/\\(.)/$1/g unless ($self->isgenparam('backslash'));
	if ( ( $url !~ /^http:/i ) &&
	     ( $url !~ /^ftp:/i ) &&
	     ( $url !~ /^file:/i ) &&
	     ( $url !~ /^https:/i ) &&
	     ( $url !~ /^gopher:/i ) &&
	     ( $url !~ /^mailto:/i ) ) {
	    $url = "http://".$url ;
	}
    }
    push @content, { 'name' => $self->{'LANG'}->get('I18N_LANG_FIELD_URL'),
		     'explanation' => ( $url ) ?
		     $self->{'THEME'}->href( $url,
					     $url,
					     "_top" ) : "-",
		   } ;
  }
  # ADSURL - ASTROPHYSICS REFERENCE CITATION LIBRARY
  if ( exists $entry->{'fields'}{'adsurl'} ) {
    my $url = $entry->{'fields'}{'adsurl'} ;
    if ( $url ) {
	$url =~ s/\\(.)/$1/g unless ($self->isgenparam('backslash'));
	if ( ( $url !~ /^http:/i ) &&
	     ( $url !~ /^ftp:/i ) &&
	     ( $url !~ /^file:/i ) &&
	     ( $url !~ /^https:/i ) &&
	     ( $url !~ /^gopher:/i ) &&
	     ( $url !~ /^mailto:/i ) ) {
	    $url = "http://".$url ;
	}
    }
    push @content, { 'name' => $self->{'LANG'}->get('I18N_LANG_FIELD_ADSURL'),
		     'explanation' => ( $url ) ?
		     $self->{'THEME'}->href( $url,
					     $url,
					     "_top" ) : "-",
		   } ;
  }
  # DOI - ACM URL
  if ( exists $entry->{'fields'}{'doi'} ) {
    my $url = $entry->{'fields'}{'doi'} ;
    if ( $url ) {
	$url =~ s/\\(.)/$1/g unless ($self->isgenparam('backslash'));
	if ( ( $url !~ /^http:/i ) &&
	     ( $url !~ /^ftp:/i ) &&
	     ( $url !~ /^file:/i ) &&
	     ( $url !~ /^https:/i ) &&
	     ( $url !~ /^gopher:/i ) &&
	     ( $url !~ /^mailto:/i ) ) {
	    $url = "http://".$url ;
	}
    }
    push @content, { 'name' => $self->{'LANG'}->get('I18N_LANG_FIELD_DOI'),
		     'explanation' => ( $url ) ?
		     $self->{'THEME'}->href( $url,
					     $url,
					     "_top" ) : "-",
		   } ;
  }
  # PDF file
  if ( exists $entry->{'fields'}{'pdf'} ) {
      my $pdf = $entry->{'fields'}{'pdf'} ;
      if ( $pdf ) {
	  $pdf =~ s/\\(.)/$1/g unless ($self->isgenparam('backslash'));
	  if ( ( $pdf =~ /^http:/i ) ||
	       ( $pdf =~ /^ftp:/i ) ||
	       ( $pdf =~ /^file:/i ) ||
	       ( $pdf =~ /^https:/i ) ||
	       ( $pdf =~ /^gopher:/i ) ||
	       ( $pdf =~ /^mailto:/i ) ) {
	      $pdf = $self->{'THEME'}->href($pdf,
					    get_html_entities($pdf),
					    "_top") ;
	  }
      }
      push @content, { 'name' => $self->{'LANG'}->get('I18N_LANG_FIELD_PDFFILE'),
		       'explanation' => ( $pdf ) ? "$pdf" : "-",
		   } ;
  }
  # Readers' names
  if ( exists $entry->{'fields'}{'readers'} ) {
      my $translator = Bib2HTML::Translator::BibTeXName->new() ;
      push @content, { 'name' => $self->{'LANG'}->get('I18N_LANG_FIELD_READERS'),
		       'explanation' => $translator->formatnames($entry->{'fields'}{'readers'},
								 $self->{'FORMATS'}{'name'},
								 $self->{'FORMATS'}{'names'},
								 -1) || "-",
		   } ;
  }

  #
  # Call the inherited generating method
  # which permits to create the first array
  # of attributes
  #
  my $result = $self->SUPER::generate_entry_content($key,$entry,$url,$rootdir,$title,\@content,$aut_ed_flg,$note_req) ;

  my $sliceindex = 2 ;

  #
  # Generates additional information which are
  # specified to this extended generator
  #
  # Box for abstract and keywords
  if ( ( exists $entry->{'fields'}{'abstract'} ) ||
       ( exists $entry->{'fields'}{'keywords'} ) ) {

    my ($abstract,$title) = ('','') ;
    if ( exists $entry->{'fields'}{'abstract'} ) {
      $title = $self->{'LANG'}->get('I18N_LANG_FIELD_ABSTRACT') ;
      $abstract = $entry->{'fields'}{'abstract'} ;
    }
    if ( exists $entry->{'fields'}{'keywords'} ) {
      if ( $title ) {
	$title = $self->{'LANG'}->get('I18N_LANG_FIELD_ABSTRACT_KEYWORDS') ;
	$abstract .= "<BR><BR>\n" ;
      }
      else {
	$title = $self->{'LANG'}->get('I18N_LANG_FIELD_KEYWORDS_TITLE') ;
      }
      $abstract .= $self->{'THEME'}->small($self->{'LANG'}->get('I18N_LANG_FIELD_KEYWORDS', $entry->{'fields'}{'keywords'} ) ) ;
    }
    my $r = $self->{'THEME'}->build_onecolumn_array( $title,
						     [ $abstract ] ) ;
    array_slice( $result, $sliceindex, $r ) ;
    $sliceindex ++ ;

  }

  # Downloadable file
  if ( ( ( exists $entry->{'fields'}{'localfile'} ) ||
	 ( $self->isgenparam('doc-repository') ) ) &&
       ( ! $self->isgenparam('nodownload') ) ) {

    # Compute the source path of the PDF document
    my ($abs,$rel,$turl,$drepos) = ($self->genparam('absolute-source'),
				    $self->genparam('relative-source'),
				    $self->genparam('target-url'),
				    $self->genparam('doc-repository')) ;

    my ($sourcefilename,$targetfilename,$targeturl) ;

    # Does it is an URL?
    if ($turl) {
      $targeturl = htmlcatdir( $turl, File::Spec->splitdir( $entry->{'fields'}{'localfile'} ) ) ;
    }
    # Does it have an absolute filename?
    elsif ( $rel ) {
      my @path = File::Spec->splitdir($entry->{'dirname'}) ;
      push @path, File::Spec->splitdir("$rel") ;
      $sourcefilename = File::Spec->catfile(@path,
					    htmltolocalpath( $entry->{'fields'}{'localfile'} ) ) ;
    }
    # Does it have a relative filename?
    elsif ( $abs ) {
      my @path = File::Spec->splitdir("$abs") ;
      $sourcefilename = File::Spec->catfile( @path,
					     htmltolocalpath( $entry->{'fields'}{'localfile'} ) ) ;
    }
    # Default location
    else {
      my @path = File::Spec->splitdir($entry->{'dirname'}) ;
      $sourcefilename = File::Spec->catfile(@path,
 					    htmltolocalpath( $entry->{'fields'}{'localfile'} ) ) ;
    }

    # Does the document repository exists?
    if ($drepos) {
      my @exts = ('pdf','PDF','ps','PS');
      my $i = 0;
      do {
        $sourcefilename = File::Spec->catfile( File::Spec->splitdir("$drepos"), $key.".".$exts[$i] ) ;
	$i ++;
      }
      while (( ! -f "$sourcefilename" )&&($i<@exts));
      $sourcefilename = undef unless ( -f "$sourcefilename" );
    }

    if ($sourcefilename) {
      if ( (!$drepos) && ( exists $entry->{'fields'}{'localfile'} ) ) {
        my @path = htmlsplit( $entry->{'fields'}{'localfile'} ) ;
        $targeturl = htmlcatfile( 'e-documents', @path ) ;
      }
      else {
        $targeturl = htmlcatfile( 'e-documents', basename($sourcefilename) ) ;
      }
      $targetfilename = File::Spec->catdir( $self->{'TARGET'}, $targeturl ) ;
    }

    if ( (!$sourcefilename) || ( -f "$sourcefilename" ) ) {

      # Register the PDF document to copy
      # The real copy will be made during the copy_files() call.
      if (($sourcefilename)&&($targetfilename)) {
	$self->register_file_to_copy( "$sourcefilename", "$targetfilename" ) ;
      }

      if ($targeturl) {
        my $alttext = '';
        if ($sourcefilename) {
          $alttext = basename("$sourcefilename");
        }

        # Generate the HTML code which permits to download the document
        my $r = $self->{'THEME'}->par( $self->{'LANG'}->get( 'I18N_LANG_FIELD_DOWNLOAD',
							     $self->{'THEME'}->href( $targeturl,
										     "<IMG align='middle' src='".
										     htmlcatdir($rootdir,'drive.png').
										     "' alt='".
										     $alttext.
										     "' border='0'>",
										     "_top" ) ) ) ;
        array_slice( $result, $sliceindex, $r ) ;
      }
    }
    else {
      Bib2HTML::General::Error::syswarm( "$sourcefilename: $!\n" );
    }
  }

  return $result ;
}

#------------------------------------------------------
#
# Generator helpers
#
#------------------------------------------------------

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
  # all the following parameters will be saved by AbstractGenerator::new
  return 1 if ( strinarray($_[0],
			   ['absolute-source',
			    'nodownload',
			    'doc-repository',
			    'relative-source',
			    'target-url',
			    'backslash']) ) ;
  return $self->SUPER::save_generator_parameter($_[0],$_[1]) ;
}

=pod

=item * display_supported_generator_params()

Display the list of supported generator parameters.

=cut
sub display_supported_generator_params() {
  my $self = shift ;
  $self->SUPER::display_supported_generator_params() ;

  $self->show_supported_param('absolute-source',
			      'is the absolute path where the '.
			      'downloadable articles could be '.
			      'found',
			      'path') ;

  $self->show_supported_param('backslash',
			      'if presents, indicates that '.
			      'backslashes will be removed from '.
			      'the link fields (url,ftp...).') ;

  $self->show_supported_param('doc-repository',
			      'if presents, indicates the path to '.
			      'the direction where the electronical '.
			      'documents was stored. The documents '.
			      'must have the same name as the '.
			      'BibTeX key.') ;

  $self->show_supported_param('nodownload',
			      'if presents, indicates that no '.
			      'link to the electronic documents '.
			      'will be generated. By extension, '.
			      'if presents no copy will be made.') ;

  $self->show_supported_param('relative-source',
			      'is the path where the downloadable '.
			      'articles could be found, relatively '.
			      'to the .bib file location.',
			      'path') ;

  $self->show_supported_param('target-url',
			      'is the base URL where document '.
			      'could be download. If presents, '.
			      'the document will not be copied.',
			      'url') ;
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
