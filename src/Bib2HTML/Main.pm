# Copyright (C) 2002-09  Stephane Galland <galland@arakhne.org>
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

package Bib2HTML::Main;

@ISA = ('Exporter');
@EXPORT = qw( &launchBib2HTML ) ;
@EXPORT_OK = qw();
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Getopt::Long ;
use Pod::Usage ;
use File::Basename ;
use File::Spec ;
use File::Path ;

use Bib2HTML::Release ;
use Bib2HTML::General::Verbose ;
use Bib2HTML::General::Error ;
use Bib2HTML::General::Misc ;
use Bib2HTML::Parser::Parser ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of bib2html
my $VERSION = Bib2HTML::Release::getVersionNumber() ;
# Date of this release of bib2html
my $VERSION_DATE = Bib2HTML::Release::getVersionDate() ;
# URL from which the users can submit a bug
my $SUBMIT_BUG_URL = Bib2HTML::Release::getBugReportURL() ;
# Email of the author of bib2html
my $AUTHOR = Bib2HTML::Release::getAuthorName() ;
# Email of the author of bib2html
my $AUTHOR_EMAIL = Bib2HTML::Release::getAuthorEmail() ;
# Page of bib2html
my $URL = Bib2HTML::Release::getMainURL() ;
# Contributors to Bib2HTML
my %CONTRIBUTORS = Bib2HTML::Release::getContributors() ;

# Default Generator
my $DEFAULT_GENERATOR = 'HTML' ;
# Default Language
my $DEFAULT_LANGUAGE = 'English' ;
# Default Theme
my $DEFAULT_THEME = 'Simple' ;

#------------------------------------------------------
#
# Functions
#
#------------------------------------------------------

sub check_output($$) {
  my $output = shift ;
  my $force = shift ;
  if ( ! $output ) {
    $output = File::Spec->catdir( ".", "bib2html" ) ;
  }
  if ( ( -e "$output" ) && ( ! $force ) ) {
    Bib2HTML::General::Error::syserr( "The output '$output".
				      "' already exists. Use the -f option to force the overwrite\n" ) ;
  }
  return "$output" ;
}

sub show_usage($$$) {
  my $exitval = shift;
  my $PERLSCRIPTDIR = shift;
  my $PERLSCRIPTNAME = shift;

  my $basename = "$PERLSCRIPTNAME";
  $basename =~ s/\.[^.]*$//;

  my $sharedir = "/usr/share";

  my @searchdirs = (
	File::Spec->catdir("$PERLSCRIPTDIR",'pod'),
	File::Spec->catdir("$PERLSCRIPTDIR",'man'),
	File::Spec->catdir("$PERLSCRIPTDIR",File::Spec->updir(),'pod'),
	File::Spec->catdir("$PERLSCRIPTDIR",File::Spec->updir(),'man'),
	File::Spec->catdir("$sharedir",'doc',"$basename"),
	File::Spec->catdir("$sharedir",'doc',"$basename"),
	File::Spec->catdir("$sharedir",'doc',"$basename",'pod'),
	File::Spec->catdir("$sharedir",'doc',"$basename",'man'),
	);

  my @langs = ();

  if (($ENV{'LANG'})&&($ENV{'LANG'} =~ /^([^_.\-]+)/)) {
    push @langs, "$1";
  }

  push @langs, 'en';

  foreach my $lang (@langs) {
    foreach my $dir (@searchdirs) {
      my $pod = File::Spec->catdir("$dir","${basename}_${lang}.pod");
      if ( -r "$pod" ) {
        print "$pod\n";
        pod2usage(-exitval => $exitval, -input => "$pod");
        exit $exitval;
      }
    }
  }

  die("unable to find the documentation file for $basename\n");
}

sub show_manual($$$) {
  my $exitval = shift;
  my $PERLSCRIPTDIR = shift;
  my $PERLSCRIPTNAME = shift;

  my $basename = "$PERLSCRIPTNAME";
  $basename =~ s/\.[^.]*$//;

  my $sharedir = "/usr/share";

  my @searchdirs = (
	File::Spec->catdir("$PERLSCRIPTDIR",'pod'),
	File::Spec->catdir("$PERLSCRIPTDIR",'man'),
	File::Spec->catdir("$PERLSCRIPTDIR",File::Spec->updir(),'pod'),
	File::Spec->catdir("$PERLSCRIPTDIR",File::Spec->updir(),'man'),
	File::Spec->catdir("$sharedir",'doc',"$basename"),
	File::Spec->catdir("$sharedir",'doc',"$basename"),
	File::Spec->catdir("$sharedir",'doc',"$basename",'pod'),
	File::Spec->catdir("$sharedir",'doc',"$basename",'man'),
	);

  my @langs = ();

  if (($ENV{'LANG'})&&($ENV{'LANG'} =~ /^([^_.\-]+)/)) {
    push @langs, "$1";
  }

  push @langs, 'en';

  foreach my $lang (@langs) {
    foreach my $dir (@searchdirs) {
      my $pod = File::Spec->catdir("$dir","${basename}_${lang}.pod");
      if ( -r "$pod" ) {
        print "$pod\n";
        use Pod::Perldoc;
        @ARGV = ( "$pod" );
        Pod::Perldoc->run();
        exit $exitval;
      }
    }
  }

  die("unable to find the documentation file for $basename\n");
}

#------------------------------------------------------
#
# Main Program
#
#------------------------------------------------------

sub launchBib2HTML($$) {

  my $PERLSCRIPTDIR = shift;
  my $PERLSCRIPTNAME = shift;

  # Command line options
  my %options = () ;

  # Read the command line
  $options{warnings} = 1 ;
  $options{genphpdoc} = 1 ;
  $options{generator} = "$DEFAULT_GENERATOR" ;
  $options{lang} = "$DEFAULT_LANGUAGE" ;
  $options{theme} = "$DEFAULT_THEME" ;
  $options{genparams} = {} ;
  $options{'show-bibtex'} = 1 ;
  Getopt::Long::Configure("bundling") ;
  if ( ! GetOptions( "b|bibtex!" => \$options{'show-bibtex'},
		     "checknames" => \$options{'check-names'},
		     "cvs" => sub {
		       @{$options{'protected_files'}} = ()
		         unless ( exists $options{'protected_files'} ) ;
		       push @{$options{'protected_files'}}, ".cvs", "CVSROOT", "CVS" ;
		     },
		     "doctitle=s" => \$options{'title'},
		     "f|force" => \$options{'force'},
		     "generator|g=s" => \$options{'generator'},
		     'generatorparam|d:s%' => sub {
		       my $name = lc($_[1]) ;
		       @{$options{'genparams'}{"$name"}} = ()
		         unless ( exists $options{'genparams'}{"$name"} ) ;
		       push @{$options{'genparams'}{"$name"}}, $_[2] ;
		     },
		     "generatorparams!" => \$options{'genparamlist'},
		     "genlist" => \$options{'genlist'},
		     "h|?" => \$options{'help'},
		     "help|man|manual" => \$options{'manual'},
		     "jabref!" => \$options{'jabref'},
		     "lang=s" => \$options{'lang'},
		     "langlist" => \$options{'langlist'},
		     "o|output=s" => sub {
		       $options{'output'} = $_[1];
		       delete $options{'stdout'};
		     },
		     "p|preamble=s" => \$options{'tex-preamble'},
		     "protect=s" => sub {
		       my $regex = lc($_[1]) ;
		       @{$options{'protected_files'}} = ()
		         unless ( exists $options{'protected_files'} ) ;
		       push @{$options{'protected_files'}}, $regex ;
		     },
		     "q" => \$options{'quiet'},
		     "sortw!" => \$options{'sort-warnings'},
		     "stdout" => sub {
		       delete $options{'output'};
		       $options{'stdout'} = 1;
		     },
		     "svn" => sub {
		       @{$options{'protected_files'}} = ()
		         unless ( exists $options{'protected_files'} ) ;
		       push @{$options{'protected_files'}}, ".svn", "svn" ;
		     },
		     "texcmd" => \$options{'tex-commands'},
		     "theme=s" => \$options{'theme'},
		     "themelist" => \$options{'themelist'},
		     "v+" => \$options{'verbose'},
		     "version" => \$options{'version'},
		     "warning!" => \$options{'warnings'},
		     "windowtitle=s" => \$options{'wintitle'},
		   ) ) {
    show_usage(2,"$PERLSCRIPTDIR","$PERLSCRIPTNAME") ;
  }

  # Generator class
  if ( $options{'generator'} !~ /::/ ) {
    $options{'generator'} = "Bib2HTML::Generator::".$options{'generator'}."Gen" ;
  }
  eval "require ".$options{'generator'}.";" ;
  if ( $@ ) {
    Bib2HTML::General::Error::syserr( "Unable to find the generator class: ".$options{'generator'}."\n$@\n" ) ;
  }

  # Show the version number
  if ( $options{version} ) {

    my $final_copyright = 1998;
    if ($VERSION_DATE =~ /^([0-9]+)\/[0-9]+\/[0-9]+$/) {
      if ($1<=98) {
        $final_copyright = 2000 + $1;
      }
      elsif ($1==99) {
        $final_copyright = 1999;
      }
      else {
        $final_copyright = $1;
      }
    }

    if ($final_copyright!=1998) {
      $final_copyright = "1998-$final_copyright";
    }

    print "bib2html $VERSION, $VERSION_DATE\n" ;
    print "Copyright (c) $final_copyright, $AUTHOR <$AUTHOR_EMAIL>, under GPL\n" ;
    print "Contributors:\n" ;
    while ( my ($email,$name) = each(%CONTRIBUTORS) ) {
      print "  $name <$email>\n" ;
    }
    exit 1 ;
  }

  # Show the list of generators
  if ( $options{genlist} ) {
    use Bib2HTML::Generator::AbstractGenerator ;
    Bib2HTML::Generator::AbstractGenerator::display_supported_generators($PERLSCRIPTDIR,
								         "$DEFAULT_GENERATOR") ;
    exit 1 ;
  }

  # Show the list of languages
  if ( $options{langlist} ) {
    use Bib2HTML::Generator::AbstractGenerator ;
    Bib2HTML::Generator::AbstractGenerator::display_supported_languages($PERLSCRIPTDIR,
								      "$DEFAULT_LANGUAGE") ;
    exit 1 ;
  }

  # Show the list of themes
  if ( $options{themelist} ) {
    use Bib2HTML::Generator::AbstractGenerator ;
    Bib2HTML::Generator::AbstractGenerator::display_supported_themes($PERLSCRIPTDIR,
								   "$DEFAULT_THEME") ;
    exit 1 ;
  }

  # Show the list of themes
  if ( $options{'tex-commands'} ) {
    use Bib2HTML::Translator::TeX ;
    Bib2HTML::Translator::TeX::display_supported_commands($PERLSCRIPTDIR) ;
    exit 1 ;
  }

  # Show the list of generator params
  if ( $options{'genparamlist'} ) {
    ($options{'generator'})->display_supported_generator_params() ;
    exit 1 ;
  }

  # Show the help screens
  if ( $options{manual} ) {
    show_manual(1,"$PERLSCRIPTDIR","$PERLSCRIPTNAME") ;
  }
  if ( $options{help} || ( $#ARGV < 0 ) ) {
    show_usage(1,"$PERLSCRIPTDIR","$PERLSCRIPTNAME") ;
  }

  # Force the output to stdout
  if ( $options{'stdout'} ) {
     my $name = "stdout" ;
     $options{'genparams'}{"stdout"} = [1];
  }

  #
  # Sets the default values of options
  #
  # Titles:

  # Verbosing:
  if ( $options{quiet} ) {
    $options{verbose} = -1 ;
  }
  Bib2HTML::General::Verbose::setlevel( $options{verbose} ) ;

  # Error messages:
  if ( $options{'warnings'} ) {
    Bib2HTML::General::Error::unsetwarningaserror() ;
  }
  else {
    Bib2HTML::General::Error::setwarningaserror() ;
  }
  if ( $options{'sort-warnings'} ) {
    Bib2HTML::General::Error::setsortwarnings() ;
  }
  else {
    Bib2HTML::General::Error::unsetsortwarnings() ;
  }

  #
  # Create the output directory
  #
  unless ($options{'stdout'}) {
    $options{'output'} = check_output($options{'output'},$options{'force'});
  }

  # Read the BibTeX files
  my $parser = new Bib2HTML::Parser::Parser($options{'show-bibtex'}) ;
  if ( $options{'tex-preamble'} ) {
    $parser->read_preambles( $options{'tex-preamble'} ) ;
  }
  $parser->parse( \@ARGV ) ;

  # Check if the names of the authors are similars
  if ( $options{'check-names'} ) {
    eval "require Bib2HTML::Checker::Names;" ;
    if ( $@ ) {
      Bib2HTML::General::Error::syserr( "Unable to find the generator class: Bib2HTML::Checker::Names\n$@\n" ) ;
    }
    my $check = new Bib2HTML::Checker::Names() ;
    $check->check($parser->content()) ;
  }

  # Translate the entries according to the JabRef tool
  if ($options{'jabref'}) {
    use Bib2HTML::JabRef::JabRef;

    my $jabref = new Bib2HTML::JabRef::JabRef();

    $jabref->parse($parser->content());
  }

  # Create the generator
  #
  Bib2HTML::Generator::LangManager::set_default_lang("$DEFAULT_LANGUAGE");
  my $generator = ($options{'generator'})->new( $parser->content(),
					        $options{'output'},
					        { 'VERSION' => $VERSION,
					  	  'BUG_URL' => $SUBMIT_BUG_URL,
						  'URL' => $URL,
						  'AUTHOR_EMAIL' => $AUTHOR_EMAIL,
						  'AUTHOR' => $AUTHOR,
						  'PERLSCRIPTDIR' => $PERLSCRIPTDIR,
					        },
					        { 'SHORT' => $options{'wintitle'},
						  'LONG' => $options{'title'},
					        },
					        $options{'lang'},
					        $options{'theme'},
					        $options{'show-bibtex'},
					        $options{'genparams'} ) ;
  if ($options{'protected_files'}) {
    $generator->set_unremovable_files(@{$options{'protected_files'}});
  }

  # Generates the HMTL pages
  #
  $generator->generate() ;

  # Display the quantity of warnings
  Bib2HTML::General::Error::printwarningcount() ;

  exit 0 ;
}

1;
__END__
