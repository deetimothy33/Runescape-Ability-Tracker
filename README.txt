I wrote an ability tracker in ruby.
It was requested that I share it so I have placed it in a GitHub repository linked above.

USAGE
Pass the combat styles to display as command line arguments as in the below examples.
./tracker.rb magic
./tracker.rb magic melee

The program reads keyboard inputs and outputs the images corresponding to the abilities as an html file.

I use an OBS browser source with a plugin called Browser Auto Refresh to update the tracker display.
Refresh interval is set to 1 second.

UPDATE: 
The Browser Auto Refresh tool no longer seems to be necessary.
The html file output by the tracker now has metadata set up cause a page refresh every 1 second.