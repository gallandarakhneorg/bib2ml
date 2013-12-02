# Copyright (C) 2007  Stephane Galland <galland@arakhne.org>
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

Bib2HTML::JabRef::JabRef - A translator to support JabRef format.

=head1 DESCRIPTION

Bib2HTML::JabRef::JabRef is a Perl module, which permits to
translate bibTeX data according to the JabRef format.

=head1 SYNOPSYS

my $j = Bib2HTML::JabRef::JabRef->new() ;
$j->parser(content);

=cut

package Bib2HTML::JabRef::JabRef;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of JabRef Translator
my $VERSION = "1.0" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new() : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {} ;
  bless($self,$class);
  return $self;
}

#------------------------------------------------------
#
# Translation API
#
#------------------------------------------------------

=pod

=item * parse($)

Translate the specified content which must be a reference
to an hashtable given by a parser.

=cut
sub parse($) : method {
  my $self = shift ;

  $self->parseComments(@{$_[0]->{'comments'}});

  if (($self->{'variables'}{'groupsversion'} !~ /^\s*([0-9]+)\s*;\s*$/)||
      (int($1) < 3))  {
    Bib2HTML::General::Error::syserr( "the JabRef translator does not support groups' version below 3.0" ) ;
  }

  # Treat the groups
  if ($self->{'variables'}{'groupstree'}) {
    my %categoryAssignation = $self->assignCategories($self->{'variables'}{'groupstree'});
    $self->createCategories(\%categoryAssignation,$_[0]->{'entries'});
  }
}

#------------------------------------------------------
#
# Tool API
#
#------------------------------------------------------

=pod

=item * createCategories(\%$)

Add the categories to each bibtex entries.

=cut
sub createCategories(\%$) {
  my $self = shift;
  foreach my $key (keys(%{$_[0]})) {
    if (exists $_[1]->{"$key"}) {
      my $newcategories = join(':',@{$_[0]->{"$key"}});
      if ($_[1]->{"$key"}{'fields'}{'domains'}) {
	$newcategories .= ":".$_[1]->{"$key"}{'fields'}{'domains'};
      }
      $_[1]->{"$key"}{'fields'}{'domains'} = "$newcategories";
    }
  }
}

=pod

=item * assignCategories($)

Parse the JabRef group list and replies the assignations
for each bibtex entry.

=cut
sub assignCategories($) {
  my $self = shift;
  my $jabrefgroups = "$_[0]";
  my %assignments = ();
  my @categories = ();

  while (($jabrefgroups)&&
         ($jabrefgroups =~ /^\s*([0-9]+)\s+([^:]*):(.*?)(?<!\\);\s*(.*)$/s)) {
    my $order = "$1";
    my $content = "$3";
    $jabrefgroups = "$4";

    if (lc("$2") eq "explicitgroup") {
      $content =~ s/[\n\r]+//g; # remove carriage returns because they are not significant

      my @elements = split(/\\;/, "$content");
      my $name = shift @elements;
      shift @elements; # eat the number

      splice(@categories,($order-1));
      $categories[$order-1] = "$name";

      foreach my $key (@elements) {
        if (!$assignments{"$key"}) {
	  $assignments{"$key"} = [];
	}
        push @{$assignments{"$key"}}, join('/',@categories);
      }
    }
  }

  return %assignments;
}

=pod

=item * parseComments(@)

Parse the given comments to detect JabRef tokens.

=cut
sub parseComments(@) : method {
  my $self = shift ;

  foreach my $comment (@_) {
	if ($comment =~ /^\s*jabref\-meta:\s*(.+?)\s*\:\s*(.*?)\s*$/is) {
		$self->{'variables'}{lc("$1")} = "$2";
	}
  }

}


1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 2007 Stéphane Galland E<lt>galland@arakhne.orgE<gt>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by Stéphane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

bib2html.pl
