# Copyright (C) 2004-07  Stephane Galland <galland@arakhne.org>
# Copyright (C) 2011  Stephane Galland <galland@arakhne.org>
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

Bib2HTML::Generator::SQLGen - A basic SQL generator

=head1 SYNOPSYS

use Bib2HTML::Generator::SQLGen ;

my $gen = Bib2HTML::Generator::SQLGen->new( content, output, info, titles,
                                            lang, theme, params ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::SQLGen is a Perl module, which permits to
generate SQL scripts for the BibTeX database.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use Bib2HTML::Generator::SQLGen;

    my $gen = Bib2HTML::Generator::SQLGen->new( { }, "./bib.sql",
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

This section contains only the methods in SQLGen.pm itself.

=over

=cut

package Bib2HTML::Generator::SQLGen;

@ISA = ('Bib2HTML::Generator::AbstractGenerator');
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use constant TRUE => (1==1);
use constant FALSE => (1==0);
use Carp ;
use File::Spec ;
use File::Basename ;

use Bib2HTML::Generator::AbstractGenerator;
use Bib2HTML::General::Misc;
use Bib2HTML::General::Error;
use Bib2HTML::General::HTML;
use Bib2HTML::General::Encode;
use Bib2HTML::Translator::BibTeXName;

use Bib2HTML::Generator::SqlEngine::MySql;
use Bib2HTML::Generator::SqlEngine::PgSql;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of this generator
my $VERSION = "3.0" ;

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
       push @langs, $l."_SQLGen";
     }
     push @langs, $l;
    }
  }
  else {
     @langs = ( $_[4] );
     if ($_[4] !~ /_[a-zA-Z0-9]+Gen$/) {
       unshift @langs, $_[4]."_SQLGen";
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

  $self->{'sql_identifiers'}{'identity'} = 0;
  $self->{'current_sql_engine_instance'} = undef;

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
  if ( ( $_[0] eq 'sql-encoding' ) ) {
    # will be saved by PARENT::new
    return 1 ;
  }
  elsif ( ( $_[0] eq 'sql-engine' ) ) {
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

  $self->show_supported_param('sql-encoding',
			      'String, the character encoding used in the SQL script '.
			      '("UTF8", "ISO-8859-1"...).' );
  $self->show_supported_param('sql-engine',
			      'String, the name of the SQL engine for which the '.
                              'SQL script should be generated '.
			      '("mysql", "pgsql"...).' );
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
  if (!$self->{'GENERATOR_PARAMS'}{'sql-encoding'}) {
    $self->{'GENERATOR_PARAMS'}{'sql-encoding'} = get_default_encoding();
  }
  set_default_encoding($self->{'GENERATOR_PARAMS'}{'sql-encoding'});

  # Set the default SQL engine
  if (!$self->{'GENERATOR_PARAMS'}{'sql-engine'}) {
    $self->{'GENERATOR_PARAMS'}{'sql-engine'} = "mysql";
  }
  else {
    $self->{'GENERATOR_PARAMS'}{'sql-engine'} = lc($self->{'GENERATOR_PARAMS'}{'sql-engine'});
  }

  if ($self->{'GENERATOR_PARAMS'}{'sql-engine'} eq 'mysql') {
    $self->{'current_sql_engine_instance'} = new Bib2HTML::Generator::SqlEngine::MySql();
  }
  elsif ($self->{'GENERATOR_PARAMS'}{'sql-engine'} eq 'pgsql') {
    $self->{'current_sql_engine_instance'} = new Bib2HTML::Generator::SqlEngine::PgSql();
  }
  else {
	Bib2HTML::General::Error::syserr("unsupported SQL engine: ".$self->{'GENERATOR_PARAMS'}{'sql-engine'});
  }

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

  # Generates the schema of the database
  $self->create_SQLSCHEMA($t) ;

  # Generates the content for each entries
  $self->create_SQLENTRIES($t) ;

  # Create file
  $self->create_FILE($t) ;
}


sub quotesql($) {
	my $self = shift;
	my $v = shift;
	my $sqlEngine = $self->{'current_sql_engine_instance'};
	return $sqlEngine->quotesql($v);
}


=pod

=item * create_SQLSCHEMA()

Generates the SQL schema.
Takes 1 arg:

=over

=item * content (string)

is the content to fill

=back

=cut
sub create_SQLSCHEMA($) : method {
  my $self = shift ;
  my $sqlEngine = $self->{'current_sql_engine_instance'};
  $_[0] .= $sqlEngine->createSchema();
}

=pod

=item * create_SQLENTRIES()

Generates the SQL pages for each entry
Takes 1 arg:

=over

=item * content (string)

is the content to fill

=back

=cut
sub create_SQLENTRIES($) : method {
  my $self = shift ;
  my @entries = $self->get_all_entries_ayt() ;
  my $i = $#entries ;
  my $sqlEngine = $self->{'current_sql_engine_instance'};

  while ( $i >= 0 ) {
    # Compute entry constants
    my $type = $self->{'CONTENT'}{'entries'}{$entries[$i]}{'type'} ;
    my $fields = $self->{'CONTENT'}{'entries'}{$entries[$i]}{'fields'};
    my $entry = '';

    # Insert the entry's type
    if ((!$self->{'GENERATION'}{'types'})||
        (!strinarray($type,$self->{'GENERATION'}{'types'}))) {
      $entry .= $sqlEngine->insertInto(
		'bibtex_entrytype',
		{ 'type' => $type });
      push @{$self->{'GENERATION'}{'types'}}, "$type";
    }

    # Insert the entry
    $entry .= $sqlEngine->insertInto(
		'bibtex_entry',
		{ 'entry_key' => $entries[$i],
		  'year'      => $fields->{'year'}||0,
		  'title'     => $fields->{'title'}||'',
		  'type'      => $type});
    delete $fields->{'year'};
    delete $fields->{'title'};

    if (exists $fields->{'author'}) {
      $self->create_SQLAUTHORS($entries[$i],$fields->{'author'},$entry);
      delete $fields->{'author'};
    }

    if (exists $fields->{'editor'}) {
      $self->create_SQLEDITORS($entries[$i],$fields->{'editor'},$entry);
      delete $fields->{'editor'};
    }

    if ((exists $fields->{'domain'})||
        (exists $fields->{'nddomain'})||
        (exists $fields->{'rddomain'})||
        (exists $fields->{'domains'})) {
      $self->create_SQLDOMAINS($entries[$i],
	join(':',
		($fields->{'domain'}||''),
		($fields->{'nddomain'}||''),
		($fields->{'rddomain'}||''),
		($fields->{'domains'}||'')),
	$entry);
      delete $fields->{'domain'};
      delete $fields->{'nddomain'};
      delete $fields->{'rddomain'};
      delete $fields->{'domains'};
    }

    # Fields
    foreach my $field (keys %{$fields}) {
      $self->create_SQLFIELD($entries[$i],
      		"$field", $fields->{"$field"},
		$entry);
    }

    $_[0] .= $entry ;
    $i -- ;
  }
}

=pod

=item * create_SQLAUTHORS()

Generates the SQL pages for the authors
Takes 3 args:

=over

=item * entry_key (string)

is the BibTeX key of the entry.

=item * authors (string)

is the list of authors.

=item * content (string)

is the content to fill.

=back

=cut
sub create_SQLAUTHORS($$$) : method {
  my $self = shift;
  my $entry_key = shift;
  my $sauthors = shift;

  my $sqlEngine = $self->{'current_sql_engine_instance'};
  my $translator = Bib2HTML::Translator::BibTeXName->new();  
  my @names = $translator->splitnames($sauthors);
  my $idxauthor = 0;

  my %insertedAuthors = ();

  for(my $idxname=0; $idxname<@names; $idxname++) {
    my $name = $names[$idxname];
    if (!$name->{'et al'}) {
      my $author_key = html_lc($translator->formatname($name,'l,i.'));

      my $id;
      if ((!$self->{'GENERATION'}{'authors'})||
          (!$self->{'GENERATION'}{'authors'}{"sqlid_$author_key"})) {
	$self->{'sql_identifiers'}{'identity'}++;
        $_[0] .= $sqlEngine->insertInto(
			'bibtex_identity',
			{ 'identifier' => $self->{'sql_identifiers'}{'identity'},
			  'name'       => translate_html_entities($name->{'last'}),
			  'firstname'  => translate_html_entities($name->{'first'}),
			  'von'	       => translate_html_entities($name->{'von'}),
			  'junior'     => translate_html_entities($name->{'jr'})});
        $self->{'GENERATION'}{'authors'}{"sqlid_$author_key"} = $self->{'sql_identifiers'}{'identity'};
	$id = $self->{'sql_identifiers'}{'identity'};
      }
      else {
        $id = $self->{'GENERATION'}{'authors'}{"sqlid_$author_key"};
      }

      my $etal = ((($idxname+1)<@names)&&($names[$idxname+1]->{'et al'}));
    
      if ($insertedAuthors{"||$entry_key||$id||"}) {
	Bib2HTML::General::Error::syswarm("Duplicate author '$id' for entry '$entry_key'");
      }
      else {
	      $_[0] .= $sqlEngine->insertInto(
			'bibtex_authors',
			{ 'entry_key' => $entry_key,
			  'author_id' => $id,
			  'order_id'  => $idxauthor,
			  'etal'      => ($etal ? "true" : "false")});
	$insertedAuthors{"||$entry_key||$id||"} = TRUE;
        $idxauthor++;
      }
    }
  }
}

=pod

=item * create_SQLEDITORS()

Generates the SQL pages for the editors
Takes 3 args:

=over

=item * entry_key (string)

is the BibTeX key of the entry.

=item * editors (string)

is the list of editors.

=item * content (string)

is the content to fill.

=back

=cut
sub create_SQLEDITORS($$$) : method {
  my $self = shift;
  my $entry_key = shift;
  my $seditors = shift;

  my $sqlEngine = $self->{'current_sql_engine_instance'};
  my $translator = Bib2HTML::Translator::BibTeXName->new();  
  my @names = $translator->splitnames($seditors);
  my $idxeditor = 0;

  for(my $idxname=0; $idxname<@names; $idxname++) {
    my $name = $names[$idxname];
    if (!$name->{'et al'}) {
      my $editor_key = html_lc($translator->formatname($name,'l,i.'));

      my $id;
      if ((!$self->{'GENERATION'}{'authors'})||
          (!$self->{'GENERATION'}{'authors'}{"sqlid_$editor_key"})) {
        $self->{'sql_identifiers'}{'identity'}++;
        $_[0] .= $sqlEngine->insertInto(
			'bibtex_identity',
			{ 'identifier' => $self->{'sql_identifiers'}{'identity'},
			  'name'       => translate_html_entities($name->{'last'}),
			  'firstname'  => translate_html_entities($name->{'first'}),
			  'von'        => translate_html_entities($name->{'von'}),
			  'junior'     => translate_html_entities($name->{'jr'})});
        $self->{'GENERATION'}{'authors'}{"sqlid_$editor_key"} = $self->{'sql_identifiers'}{'identity'};
	$id = $self->{'sql_identifiers'}{'identity'};
      }
      else {
        $id = $self->{'GENERATION'}{'authors'}{"sqlid_$editor_key"};
      }

      my $etal = ((($idxname+1)<@names)&&($names[$idxname+1]->{'et al'}));
    
      $_[0] .= $sqlEngine->insertInto(
			'bibtex_editors',
			{ 'entry_key' => $entry_key,
			  'editor_id' => $id,
			  'order_id'  => $idxeditor,
			  'etal'      => ($etal ? "true" : "false")});

      $idxeditor++;
    }
  }
}

=pod

=item * create_SQLDOMAINS()

Generates the SQL pages for the entry's domains
Takes 3 args:

=over

=item * entry_key (string)

is the BibTeX key of the entry.

=item * domains (string)

is the list of domains separated by ':'.

=item * content (string)

is the content to fill.

=back

=cut
sub create_SQLDOMAINS($$$) : method {
  my $self = shift;
  my $entry_key = shift;
  my $sdomains = shift;

  my $sqlEngine = $self->{'current_sql_engine_instance'};
  my @domains = split(/\s*:\s*/,$sdomains);

  foreach my $domain (@domains) {
    $domain =~ s/^\s+//;
    $domain =~ s/\s+$//;
    if ($domain) {
      my $domain_key = $domain;
      $domain_key =~ s/\s//g;
      $domain_key = html_lc($domain_key);

      my $id;
      if ((!$self->{'GENERATION'}{'domains'})||
          (!$self->{'GENERATION'}{'domains'}{"$domain_key"})) {
        if (!$self->{'GENERATION'}{'domains'}) {
          $id = 1;
        }
        else {
          $id = %{$self->{'GENERATION'}{'domains'}} + 1;
        }
        $_[0] .= $sqlEngine->insertInto(
			'bibtex_domain',
			{ 'identifier' => $id,
			  'name'       => translate_html_entities($domain)});
        $self->{'GENERATION'}{'domains'}{"$domain_key"} = $id;
      }
      else {
        $id = $self->{'GENERATION'}{'domains'}{"$domain_key"};
      }

      $_[0] .= $sqlEngine->insertInto(
			'bibtex_entrydomain',
			{ 'entry_key' => $entry_key,
			  'domain_id' => $id});
    }
  }
}

=pod

=item * create_SQLFIELD()

Generates the SQL pages for the entry's field
Takes 4 args:

=over

=item * entry_key (string)

is the BibTeX key of the entry.

=item * field_name (string)

is the name of the field to add.

=item * field_value (string)

is the value of the field to add.

=item * content (string)

is the content to fill.

=back

=cut
sub create_SQLFIELD($$$$) : method {
  my $self = shift;
  my $entry_key = shift;
  my $field_name = shift;
  my $field_value = shift;

  my $sqlEngine = $self->{'current_sql_engine_instance'};

  if ($self->{'GENERATION'}{'field_id'}) {
    $self->{'GENERATION'}{'field_id'}++;
  }
  else {
    $self->{'GENERATION'}{'field_id'} = 1;
  }

  $_[0] .= $sqlEngine->insertInto(
		'bibtex_field',
		{ 'identifier' => $self->{'GENERATION'}{'field_id'},
		  'entry_key'  => $entry_key,
		  'name'       => translate_html_entities("$field_name"),
		  'value'      => translate_html_entities("$field_value")});
}

=pod

=item * create_FILE

Creates the SQL file.
Takes 1 arg:

=over

=item * content (string)

is the content of the SQL file.

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

1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 2004-07 Stéphane Galland E<lt>galland@arakhne.orgE<gt>, under GPL.
(c) Copyright 2011 Stéphane Galland E<lt>galland@arakhne.orgE<gt>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by Stéphane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

bib2html.pl
