
use 5.10.0;
use strict;
use warnings;
use locale;
use utf8;
use vars qw($VERSION %IRSSI);
use Fcntl;
use open qw( :encoding(UTF-8) :std );
use Irssi;
use Encode qw( decode );
use HTML::Entities;
$VERSION = "1.0";
%IRSSI = (
    authors     => 'induktio',
    contact     => 'info@induktio.net',
    name        => 'urlgrabber',
    description => 'grab all the urls from channels to a database/html log file',
    license     => 'MIT license',
    url         => '',
);

Irssi::settings_add_bool("url_grab", "url_grab", 1);
Irssi::settings_add_str("url_grab", "url_grab_db", 'irclogs/irssi_urls.log');
Irssi::settings_add_str("url_grab", "url_grab_html", 'irclogs/irssi_urls.html');
Irssi::settings_add_int("url_grab", "url_grab_html_size", 400);
Irssi::settings_add_str("url_grab", "url_grab_ignores", ''); # space-separated ignored nicks/chans

our $db_file = Irssi::settings_get_str("url_grab_db");
our $html_file = Irssi::settings_get_str("url_grab_html");
our @urls;
our $new_urls = 0;
our $startup = time;

if (Irssi::settings_get_bool("url_grab")) {
	if (open DB, '<', "$db_file") {
		my $html_max_size = Irssi::settings_get_int("url_grab_html_size");
		while (<DB>) {
			chomp;
			my ($time, $chan, $nick, $url) = split(/\t/);
			push @urls, [$time, $chan, $nick, $url];
			while (scalar @urls > $html_max_size) {
				shift @urls;
			}
		}
		close DB;
		Irssi::print "URL db loaded from $db_file";
	} else {
		Irssi::print "URL db not found.";
	}
	open DB, '>>', "$db_file" or die $!;
	select((select(DB), $| = 1)[0]);
	Irssi::signal_add_last('message public', \&public_msg);
	Irssi::signal_add_last('message own_public', \&own_public_msg);
	Irssi::command_bind ('urlstatus' => \&urlstatus);
	Irssi::command_bind ('writehtml' => \&write_html);
}

sub public_msg {
	my @arg = map { decode("utf-8",$_) } @_;
	my %ignores;
	my ($server, $msg, $nick, $address, $chan) = @arg;
	$ignores{lc($_)}=1 for split(/ +/, Irssi::settings_get_str("url_grab_ignores"));
	return if exists $ignores{lc($nick)} || exists $ignores{lc($chan)};
	while ($msg =~ /(https?:\/\/[^ \/]{4,}[^ ]*)/ig) {
		my $url = $1;
		$url =~ s/[\n\t]//g;
		push @urls, [time, $chan, $nick, $url];
		my $line = join("\t", @{$urls[$#urls]})."\n";
		print DB $line;
		$new_urls++;
		my $html_max_size = Irssi::settings_get_int("url_grab_html_size");
		while (scalar @urls > $html_max_size) {
			shift @urls;
		}
		write_html() if $html_file =~ /\w/ && $new_urls%4 == 0;
	}
}

sub own_public_msg {
	my ($server, $msg, $chan) = @_;
	public_msg($server, $msg, $server->{nick}, $server->{userhost}, $chan);
}

sub write_html {
	open HTML, '>', "$html_file" or die $!;
	print HTML qq{<!doctype html>
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>irssi urls</title></head><body>
};
	my $stamp = "";
	my $i = $#urls;
	for (reverse @urls) {
		my @u = map { encode_entities($_) } @{ $_ };
		my $tt = scalar(localtime($u[0]));
		my $day = substr($tt, 0, 10);
		my $time = substr($tt, 11, 5);
		if ($stamp ne $day) {
			print HTML "<h2>$day</h2>\n";
		}
		print HTML qq
{$time $u[1] &lt;$u[2]&gt; <a href="$u[3]" target="_blank">$u[3]</a><br>
};
		$stamp = $day;
	}
	print HTML "</body></html>";
	close HTML;
}

sub urlstatus {
	my $hours = (time-$startup)/3600;
	Irssi::print "Urlgrabber startup ".localtime($startup);
	Irssi::print "$new_urls new urls, ".sprintf("%.2f",$new_urls/$hours)." per hour";
}






