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

Bib2HTML::Generator::SqlEngine::PgSql - SQL Generator utilities for PostgreSQL

=over

=cut

package Bib2HTML::Generator::SqlEngine::PgSql;

@ISA = ('');
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Carp ;

use Bib2HTML::General::Error;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of this file
my $VERSION = "1.0" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new() : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless( $self, $class );
  return $self;
}

sub quotesql($) : method {
  my $self = shift;
  my $s = $_[0];
  $s =~ s/\'/\\\'/g;
  return $s;
}


sub createSchema() : method {
  my $self = shift;
  my $schema = '';
  $schema .= join("\n",
	"DROP TABLE IF EXISTS bibtex_entrytype;",
	"CREATE TABLE bibtex_entrytype (",
	"  type varchar(50) NOT NULL,",
	"  PRIMARY KEY(type)",
	");\n");

  $schema .= join("\n",
	"DROP TABLE IF EXISTS bibtex_domain;",
	"CREATE TABLE bibtex_domain (",
	"  identifier integer NOT NULL,",
	"  name varchar(100) NOT NULL,",
	"  PRIMARY KEY(identifier)",
	");\n");

  $schema .= join("\n",
	"DROP TABLE IF EXISTS bibtex_entry;",
	"CREATE TABLE bibtex_entry (",
	"  entry_key varchar(50) NOT NULL,",
	"  year integer NOT NULL default 1900,",
	"  title text NOT NULL,",
	"  type varchar(50) NOT NULL,",
	"  crossref varchar(50),",
	"  PRIMARY KEY(entry_key),",
	"  FOREIGN KEY(type) REFERENCES bibtex_entrytype(type) ON DELETE CASCADE,",
	"  FOREIGN KEY(crossref) REFERENCES bibtex_entry(entry_key) ON DELETE SET NULL",
	");\n");

  $schema .= join("\n",
	"DROP TABLE IF EXISTS bibtex_field;",
	"CREATE TABLE bibtex_field (",
	"  identifier integer NOT NULL,",
	"  name varchar(100) NOT NULL,",
	"  value text,",
	"  entry_key varchar(50) NOT NULL,",
	"  PRIMARY KEY(identifier),",
	"  FOREIGN KEY(entry_key) REFERENCES bibtex_entry(entry_key) ON DELETE CASCADE",
	");\n");

  $schema .= join("\n",
	"DROP TABLE IF EXISTS bibtex_identity;",
	"CREATE TABLE bibtex_identity (",
	"  identifier integer NOT NULL,",
	"  name varchar(100) NOT NULL,",
	"  firstname varchar(100) NOT NULL,",
	"  von varchar(20),",
	"  junior varchar(20),",
	"  PRIMARY KEY(identifier)",
	");\n");

  $schema .= join("\n",
	"DROP TABLE IF EXISTS bibtex_authors;",
	"CREATE TABLE bibtex_authors (",
	"  entry_key varchar(50) NOT NULL,",
	"  author_id integer NOT NULL,",
	"  order_id integer NOT NULL DEFAULT 1,",
	"  etal boolean NOT NULL DEFAULT false,",
	"  PRIMARY KEY(entry_key,author_id),",
	"  FOREIGN KEY(entry_key) REFERENCES bibtex_entry(entry_key) ON DELETE CASCADE,",
	"  FOREIGN KEY(author_id) REFERENCES bibtex_identity(identifier) ON DELETE CASCADE",
	");\n");

  $schema .= join("\n",
	"DROP TABLE IF EXISTS bibtex_editors;",
	"CREATE TABLE bibtex_editors (",
	"  entry_key varchar(50) NOT NULL,",
	"  editor_id integer NOT NULL,",
	"  order_id integer NOT NULL DEFAULT 1,",
	"  etal boolean NOT NULL DEFAULT false,",
	"  PRIMARY KEY(entry_key,editor_id),",
	"  FOREIGN KEY(entry_key) REFERENCES bibtex_entry(entry_key) ON DELETE CASCADE,",
	"  FOREIGN KEY(editor_id) REFERENCES bibtex_identity(identifier) ON DELETE CASCADE",
	");\n");

  $schema .= join("\n",
	"DROP TABLE IF EXISTS bibtex_entrydomain;",
	"CREATE TABLE bibtex_entrydomain (",
	"  entry_key varchar(50) NOT NULL,",
	"  domain_id integer NOT NULL,",
	"  PRIMARY KEY(entry_key,domain_id),",
	"  FOREIGN KEY(entry_key) REFERENCES bibtex_entry(entry_key) ON DELETE CASCADE,",
	"  FOREIGN KEY(domain_id) REFERENCES bibtex_domain(identifier) ON DELETE CASCADE",
	");\n");

  return $schema;
}

sub insertInto($) : method {
	my $self = shift;
	my $table = shift || Bib2HTML::General::Error::syserr('table name parameter is mandatory');
	my $values = shift;
	my $query = '';

	my $sqlFields = '';
	my $sqlValues = '';
	foreach my $field (keys %{$values}) {
		if ($sqlFields) {
			$sqlFields .= ',';
		}
		$sqlFields .= $field;
		if ($sqlValues) {
			$sqlValues .= ',';
		}
		$sqlValues .= "'";
		$sqlValues .= $self->quotesql($values->{$field});
		$sqlValues .= "'";
	}

	$query .= "INSERT INTO ";
	$query .= $table;
	$query .= ' (';
	$query .= $sqlFields;
	$query .= ') VALUES (';
	$query .= $sqlValues;
	$query .= ");\n";

	return $query;
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
