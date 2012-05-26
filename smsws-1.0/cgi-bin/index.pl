#!/usr/bin/perl -w

# index.pl
# Written by Andrea Biancini <andrea.biancini@reti.it> 2004/06/28

use CGI qw(:standard);
use XML::LibXSLT;
use XML::LibXML;

# print the HTTP header
my $query = new CGI;
print $query->header;

# initialize the parser and XSLT processor
my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

# print the html page transformed from XML/XSLT
my $stylesheet = $xslt->parse_stylesheet_file("../html/index.xsl");
my $source_doc = $parser->parse_file("../html/webservices.xml");

my $result = $stylesheet->transform($source_doc);
my $body = $stylesheet->output_string($result);

$body =~ s/&lt;/\</g;
$body =~ s/&gt;/\>/g;
$body =~ s/&amp;/\&/g;

print $body;
