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

Bib2HTML::Generator::DomainGen - An HTML generator

=head1 SYNOPSYS

use Bib2HTML::Generator::DomainGen ;

my $gen = Bib2HTML::Generator::DomainGen->new( data, output, info, titles,
                                               lang, theme ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::DomainGen is a Perl module, which permits to
generate HTML pages for the BibTeX database.
In addition to the features of Bib2HTML::Generator::ExtendedGen, this
generator supports the following bibtex fields:

=over

=item * domain

is a string that identify the first domain in which
the document was located.

=item * nddomain

is a string that identify the second domain in which
the document was located.

=item * rddomain

is a string that identify the third domain in which
the document was located.

=item * domains

is column-separated list of domains in which
the document was located.

=back

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use Bib2HTML::Generator::DomainGen;

    my $gen = Bib2HTML::Generator::DomainGen->new( { }, "./bib",
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

see ExtendedGen help.

=item * output (string)

see ExtendedGen help.

=item * bib2html_data (hash)

see ExtendedGen help.

=item * titles (hash)

see ExtendedGen help.

=item * lang (string)

see ExtendedGen help.

=item * theme (string)

see ExtendedGen help.

=item * show_bibtex (boolean)

See ExtendedGen.pm

=item * params (optional array)

see ExtendedGen help.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in DomainGen.pm itself.

=over

=cut

package Bib2HTML::Generator::DomainGen;

@ISA = ('Bib2HTML::Generator::ExtendedGen');
@EXPORT = qw( );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

use Bib2HTML::Generator::ExtendedGen ;
use Bib2HTML::General::HTML ;
use Bib2HTML::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of this generator
my $VERSION = "4.0" ;

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
       push @langs, $l."_DomainGen";
     }
     push @langs, $l;
    }
  }
  else {
     @langs = ( $_[4] );
     if ($_[4] !~ /_[a-zA-Z0-9]+Gen$/) {
       unshift @langs, $_[4]."_DomainGen";
     }
  }

  $_[4] = \@langs;

  my $self = $class->SUPER::new(@_) ;

  $self->{'FILENAMES'}{'domain-tree'} = 'domain-tree.html';

  bless( $self, $class );

  $self->addNavigationButton($self->filename('domain-tree'),
			     'I18N_LANG_DOMAINS');
  return $self;
}

#------------------------------------------------------
#
# Generation API
#
#------------------------------------------------------

=pod

=item * do_processing()

Main processing.

=cut
sub do_processing() : method {
  my $self = shift ;

  # Call inherited generation method
  $self->SUPER::do_processing() ;

  # Generates the domain pages
  $self->generate_domain_tree() ;
}

=pod

=item * generate_domain_tree()

Generates domain-tree.html

=cut
sub generate_domain_tree() : method {
  my $self = shift ;
  my $filename = $self->filename('domain-tree');
  return unless ($self->is_restricted_file("$filename"));
  my $rootdir = "." ;
  $filename = htmlcatfile($rootdir,$filename) ;
  my $bar = $self->{'THEME'}->get_navigation_bar( $filename,
						  { 'tree' => 0,
						    'index' => $self->{'__INDEX_GENERATED__'},
						    'userdef' => $self->getNavigationButtons('I18N_LANG_DOMAINS'),
						  },
						  $rootdir ) ;
  my $content = join('',
		     $bar,
		     $self->{'THEME'}->partseparator(),
		     $self->generate_domain_tree_content($rootdir),
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

#------------------------------------------------------
#
# Overwriteable Generation API
#
#------------------------------------------------------

=pod

=item * generate_domain_tree_content()

Generates and replies the content of domain-tree.html.
Takes 1 arg:

=over

=item * rootdir (string)

=back

=cut
sub generate_domain_tree_content($) : method {
  my $self = shift ;
  my $rootdir = shift ;
  my @entries = $self->get_all_entries_ayt() ;
  my $content = $self->{'THEME'}->title($self->{'LANG'}->get('I18N_LANG_DOMAIN_TREE')) ;

  # Build the tree
  my %tree = () ;
  foreach my $entry (@entries) {

    # Search the domains of the entry
    my @domains = $self->get_all_domains_for($entry) ;

    if ( @domains ) {

      # Generate the entry data
      my $entrylabel = $self->get_short_entry_description("$entry",$rootdir) ;

      # Register the entry inside the tree
      foreach my $domain (@domains) {
	my @parts = htmlsplit($domain) ;
	my $t = \%tree ;

	# Creates categories inside the tree
	# $t is a reference to the current leaf
	foreach my $part (@parts) {
	  $part =~ s/[ \t\n\r]+/&nbsp;/g ;
	  $part = $self->{'THEME'}->strong("$part");
	  $t->{"$part"} = {}
	    unless ( exists $t->{"$part"} ) ;
	  $t = $t->{"$part"} ;
	}

	# Adds the entry into the new category
	$t->{"$entrylabel"} = {} ;
      }
    }
  }

   # Generate the HTML representation of the tree
  $content .= $self->{'THEME'}->get_tree( \%tree, $rootdir, $self->{'LANG'}->get('I18N_LANG_KEYWORDS') ) ;

  return $content ;
}

#------------------------------------------------------
#
# Domain API
#
#------------------------------------------------------

=pod

=item * get_all_domain_for()

Replies the array of the domains for the specified entry
Takes 1 arg:

=over

=item * entry (string)

is the identifier of the entry.

=back

=cut
sub get_all_domains_for($) : method {
  my $self = shift ;
  my @domains = () ;

  if ( $self->{'CONTENT'}{'entries'}{$_[0]} ) {
    my $domain1 = $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'domain'} || '' ;
    my $domain2 = $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'nddomain'} || '' ;
    my $domain3 = $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'rddomain'} || '' ;
    my $alldomains = $self->{'CONTENT'}{'entries'}{$_[0]}{'fields'}{'domains'} || '' ;

    if ( $alldomains ) {
      @domains = split(':', $alldomains) ;
    }
    if ( ($domain1) && (!strinarray("$domain1",\@domains)) ) {
      unshift @domains, "$domain1" ;
    }
    if ( ($domain2) && (!strinarray("$domain2",\@domains)) ) {
      unshift @domains, "$domain2" ;
    }
    if ( ($domain3) && (!strinarray("$domain3",\@domains)) ) {
      unshift @domains, "$domain3" ;
    }

  }
  return @domains ;
}

=pod

=item * get_all_documents_for_domain()

Replies the array of the documents keys which
are in the specified domain.
Takes 1 arg:

=over

=item * domain (string)

is the identifier of the domain.

=back

=cut
sub get_all_documents_for_domain($) : method {
  my $self = shift ;
  my @documents = () ;

  foreach my $entry (keys %{$self->{'CONTENT'}{'entries'}}) {

    my $domain1 = $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'domain'} || '' ;
    my $domain2 = $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'nddomain'} || '' ;
    my $domain3 = $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'rddomain'} || '' ;
    my $alldomains = $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{'domains'} || '' ;

    my @domains = () ;
    if ( $alldomains ) {
      @domains = split(':', $alldomains) ;
    }
    if ( ( @domains ) && ( strinarray($_[0], \@domains) ) ) {
      push @documents, $entry ;
    }
    elsif ( ($domain1) && ($domain1 eq $_[0]) ) {
      push @documents, $entry ;
    }
    elsif ( ($domain2) && ($domain2 eq $_[0]) ) {
      push @documents, $entry ;
    }
    elsif ( ($domain3) && ($domain3 eq $_[0]) ) {
      push @documents, $entry ;
    }

  }
  return @documents ;
}

=pod

=item * get_short_entry_description()

Replies a short entry description.
Takes 2 args:

=over

=item * entry (string)

is the entry key.

=item * rootdir (string)

is the root directory.

=back

=cut
sub get_short_entry_description($$) : method {
  my $self = shift ;
  my $entry = $_[0] || confess('you must supply the entry key') ;
  my $rootdir = $_[1] || confess('you must supply the root directory') ;
  my $biblabeller = Bib2HTML::Translator::BibTeXEntry->new() ;
  my $translator = Bib2HTML::Translator::BibTeXName->new() ;

  # Generate the entry data
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

  return $entrylabel ;
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
Takes 3 args:

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

  # Call the inherited method
  my $result = $self->SUPER::generate_entry_content($key,$entry,$url,$rootdir,$title,\@content,$aut_ed_flg,$note_req) ;

  # Generates the domains of the entry
  my @domains = $self->get_all_domains_for("$key");

  if ( @domains ) {

    my $content = '' ;
    my %tree = () ;

    foreach my $domain (@domains) {
      my @entries = $self->get_all_documents_for_domain("$domain") ;

      $domain =~ s/[ \t\n\r]+/&nbsp;/g ;
      $domain = $self->{'THEME'}->strong("$domain");

      # Adds the entry into the new category
      foreach my $entry (@entries) {
	my $label = $self->get_short_entry_description($entry,$rootdir);
	$tree{"$domain"}{"$label"} = {} ;
      }
    }

    $content = $self->{'THEME'}->get_tree( \%tree, $rootdir ) ;
    push @{$result}, $self->{'THEME'}->build_onecolumn_array( $self->{'LANG'}->get('I18N_LANG_ARTICLESINSAMEDOMAINS'),
							      [ $content ] ) ;

  }

  return $result ;
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
