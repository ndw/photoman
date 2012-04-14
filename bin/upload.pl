#!/usr/bin/perl -- # -*- Perl -*-

use strict;
use English;
use LWP;
use Cwd 'abs_path';
use Getopt::Std;
use vars qw($opt_c $opt_u $opt_s);
use Digest::SHA qw(sha1_hex);

my $usage = "$0 [-u user] [-c collection] [-s] imageDir\n";

die "Bad options\n$usage" if ! getopts('c:u:s');

die "No image files or directory\n$usage" unless @ARGV;

my ($file, $UPLOADTS);

my $collection = $opt_c;
my $user = $opt_u || "ndw";
my $skip = $opt_s;

my $ua = new LWP::UserAgent;
$ua->timeout(30);

my $tmp = "/tmp/photoman-upload.$$.xml";

my $BASE = abs_path($0);
$BASE =~ s/\/bin\/.*$//;
$BASE .= "/photos";

foreach $file (@ARGV) {
    my $abs = abs_path($file);
    die "Bad filename: $file\n$usage" unless $abs =~ /^\//;

    $UPLOADTS = time();
    upload($abs);
}

unlink $tmp;

sub upload {
    my $file = shift;
    chop $file if $file =~ /\/$/;
    if (-d $file) {
        my @files = ();
        opendir (DIR, $file);
        while (my $name = readdir(DIR)) {
            next if $name =~ /^\.\.?$/;
            my $path = $file . "/" . $name;
            next if -d $path && ($name eq '64' || $name eq '150' || $name eq '500');
            push (@files, $path);
        }
        closedir (DIR);
        foreach my $file (@files) {
            upload($file);
        }
    } else {
        my $baseuri = substr($file, length($BASE)+1);
        $baseuri =~ s/\.[^\.]+$//;

        my $thumb = $file;
        $thumb =~ s/^(.*)\/([^\/]+)$/$1\/150\/$2/;
        my $small = $file;
        $small =~ s/^(.*)\/([^\/]+)$/$1\/500\/$2/;
        my $square = $file;
        $square =~ s/^(.*)\/([^\/]+)$/$1\/64\/$2/;

        if (! -f $thumb || ! -f $small || ! -f $square) {
            warn "Missing image: $file\n";
            return;
        }

        system("exiftool -X --a $file > $tmp");
        my $xml = $file;
        $xml =~ s/\.jpe?g$/\.xml/;

        my $rc = post($tmp, "/images/$user/$baseuri.xml");
        if ($rc == 200) {
            post($file, "/images/$user/large/$baseuri.jpg");
            post($thumb, "/images/$user/thumb/$baseuri.jpg");
            post($small, "/images/$user/small/$baseuri.jpg");
            post($square, "/images/$user/square/$baseuri.jpg");
        }
    }
}

# ================================================================================

sub post {
    my $file = shift;
    my $uri = shift;
    my $type = $file =~ /\.xml$/ ? "application/xml" : "image/jpeg";
    my $method = "POST";
    my $username = undef;
    my $password = undef;

    my $posturi  = "http://localhost:7071/upload.xqy?media=$type&uri=$uri";
    $posturi .= "&file=$file" if $type eq 'image/jpeg';
    $posturi .= "&uploadts=$UPLOADTS";
    $posturi .= "&collection=$collection" if defined($collection);
    $posturi .= "&skip=true" if defined($skip);

    my $req = new HTTP::Request($method => $posturi);

    open (F, $file);
    read (F, $_, -s $file);
    close (F);

    $req->content($_);
    $req->header("Content-Type" => $type);

    my $resp = $ua->request($req);

    if ($resp->code() == 401 && defined($username) && defined($password)) {
        #print "Authentication required. Trying again with specified credentials.\n";
        my $host = $posturi;
        $host =~ s/^.*?\/([^\/]+).*?$/$1/;
        my $realm = scalar($resp->header('WWW-Authenticate'));
        if ($realm =~ /realm=[\'\"]/) {
            $realm =~ s/^.*?realm=([\'\"])(.*?)\1.*$/$2/;
        } else {
            $realm =~ s/^.*?realm=(.*?)$/$1/;
        }
        # print "Auth: $host, $realm, $username, $password\n";
        $ua->credentials($host, $realm, $username => $password);
        $resp = $ua->request($req);
    }

    print $resp->code(), " ", $resp->content(), "\n";
    return $resp->code();
}
