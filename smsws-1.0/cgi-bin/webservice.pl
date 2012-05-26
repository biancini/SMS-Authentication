#!/usr/bin/perl -w

# webservice.pl
# Written by Andrea Biancini <andrea.biancini@reti.it> 2004/06/28

use CGI qw(:standard);
use XML::LibXSLT;
use XML::LibXML;

# print the HTTP header
my $query = new CGI;
print $query->header;
my %in = ();

# reads the QueryString and puts it in the array %in
if (length($ENV{'QUERY_STRING'}) > 0) {
	$buffer = $ENV{'QUERY_STRING'};
	@pairs = split(/&/, $buffer);

	foreach $pair (@pairs){
		($name, $value) = split(/=/, $pair);
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$in{$name} = $value; 
	}
}

# initialize the parser and XSLT processor
my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

# read the XSL file and substitute the parameters
my $xsl_string = "";
my $cur_riga;
open(XSLFILE, "<../html/webservice.xsl");
while (<XSLFILE>) {
	$cur_riga = $_;
	$cur_riga =~ s/\<xsl:if test=\"\@name = &quot;NAMEWS&quot;\"\>/\<xsl:if test=\"\@name = &quot;$in{"ws"}&quot;\"\>/g;
	$xsl_string .= "$cur_riga\n";
}
close XSLFILE;

# print the html page transformed from XML/XSLT
my $stylestring = $parser->parse_string($xsl_string);
my $source_doc = $parser->parse_file("../html/webservices.xml");

my $stylesheet = $xslt->parse_stylesheet($stylestring);
my $result = $stylesheet->transform($source_doc);
my $body = $stylesheet->output_string($result);

$body =~ s/&lt;/\</g;
$body =~ s/&gt;/\>/g;
$body =~ s/&amp;/\&/g;

print $body;
