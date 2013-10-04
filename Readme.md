# Irssi URL Grabber
Feeling like missing too many Internet memes? Frustration no more, URL Grabber collects all the links from channels to a HTML file for easy viewing later.

### Requirements
* Perl 5.10

### Usage
* Put <code>urlgrabber.pl</code> to <code>.irssi/scripts/autorun/</code>
* Change your pwd to ~ before loading the script
* <code>/script load /path/to/urlgrabber.pl</code> or restart irssi
* Whenever you make changes to the file settings, unload & load the script.
* By default, the output files will be written to ~/irclogs/

### Settings
* <code>/set url_grab 1</code> - set to 0 to disable script
* <code>/set url_grab_db irclogs/irssi_urls.log </code>
* <code>/set url_grab_html irclogs/irssi_urls.html</code>
* <code>/set url_grab_html_size 400</code> - show this many latest urls in html
* <code>/set url_grab_ignores nick1 #chan1</code> - space-separated ignored nicks/chans

