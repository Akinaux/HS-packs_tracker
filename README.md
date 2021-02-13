# Hearthstone - packs_tracker

## Purpose

This repository contains a script to extract and display the packs opened in Hearthstone.
It can also convert the hspacktracker.com into a new format to include the old pack tracker result.

## Usage
~~~
Usage: packs_tracker.sh -a convert -s <sourcefile>     [-j <jsondata>] [-F <folder>]
Usage: packs_tracker.sh -a extract [-l <logfile>]      [-j <jsondata>] [-F <folder>] [-W]
Usage: packs_tracker.sh -a display [-f <html>|<ascii>] [-j <jsondata>] [-F <folder>] [-e <extension> [-p|-P]] [-t <number>] [-L <LANG>]
	-a: Action you want to do: [ extract | convert | display ]
	-e: Extension you want to display stats about [Default: Last_extension]
	-f: Format to display the result [Default: ascii]
	-F: Folder to store the data [Default: current folder]
	-j: Json Data used by the script [Default: packs_tracker.json]
	-l: Log file where to extract the data from [Default: /Applications/Hearthstone/Logs/Achievements.log]
	-L: Lang you want the cards to be displayed in
	-p: Display the Pity Timers in addition of the cards for an extension (it requires [-e extension])
	-P: Display ONLY the Pity Timers for an extension (it requires [-e extension])
	-s: Source file from hspacktracker to convert
	-t: Tail the database to display only <number> packs
	-W: Wait for packs from the logfile to extract (use Ctrl+C to break the script)
	-d: Run the script in debug mode (debug, info) [Suggested: info]
~~~

## How to convert your hspacktracker.com archive file

To convert your last hspacktracker.com archive file in the new json format, you will have to run a command like this:
~~~
packs_tracker.sh -a convert -s hspacktracker-packs-20201016.txt
~~~
Where hspacktracker-packs-20201016.txt is refering to the last archive.
You can use the **-j** option to create a temporary jsondata if you want to test the command.
The command will not delete anything from the HSpacktracker archive.
The date protection should avoid to convert a pack which as the same timestamp and the same set name.
 
## How to extract the packs

To extract the packs after opening them all, you only have to run the command:
~~~
packs_tracker.sh -a extract
~~~
If you want to extract to a new jsondata file use the **-j** option.
If you want to specify a different Achievements file, use the **-l** option
The date protection should avoid to convert a pack which as the same timestamp and the same set name.

## How to display your packs

The display action can display multiple things in 2 different format.
The supported formats are:
- ASCII (using colors to identify the card rarity). A 'G' tag will follow the Golden cards.
- HTML (generating a local file to display the pack content)

**ASCII** is the default, it use less resouce and provide enough visibility of the packs.
**HTML** will display each cards in a format w:128px h:184px, golden cards will match the animated version.
To set the format, use the **-f** option

It's currently not possible to display specific packs (like class or golden packs), but you can filter on the last X packs or on a specific extension.
- Using the -t option will allow you to display the last X packs (X is a number)

In addition or in replacement of the card packs, you can display the pity timers of each extension.
Please note that the pity timers are based on the packs available in the json file.
If your last legendary pack is missing in the database, the legendary pity timer will be based on your previous legendary pack.
- Using the -p option will add the pity timer list at the end of the packs presentation.
- Using the -P option will only display the pity timers (pack list will be omitted).

### Examples:

#### Display the last 5 packs:
~~~
$ ./packs_tracker.sh -a display -t 5
| DARKMOON_FAIRE     | Stage Dive                   | Insight                      | Carousel Gryphon             | Shadow Clone                 | Foxy Fraud                   |
| DARKMOON_FAIRE     | Game Master                  | Renowned Performer           | Dreadlord's Bite             | Feat of Strength             | Costumed Entertainer         |
| DARKMOON_FAIRE     | Imprisoned Phoenix           | Carousel Gryphon             | Rock Rager                   | Armor Vendor                 | Libram of Judgment           |
| DARKMOON_FAIRE     | Backfire                     | Mask of C'Thun               | Stormstrike                  | Imprisoned Phoenix           | Banana Vendor                |
| DARKMOON_FAIRE     | Strongman                    | Mask of C'Thun               | Banana Vendor              G | Idol of Y'Shaarj             | Backfire                     |

-----------------------------------------
Number of packs opened: 5
-----------------------------------------
~~~

#### Display only the pity timer of an extension
~~~
$ ./packs_tracker.sh -a display -e DARKMOON_FAIRE -P
Number of packs to scan: 98
Progress : [########################################] 100% (98/98)
-----------------------------------------
Number of packs opened: 98
-----------------------------------------
|        Card Type | Total | Pity-timer |
-----------------------------------------
| GOLDEN LEGENDARY |     0 |  339 / 437 |
|      GOLDEN EPIC |     0 |   60 / 158 |
|      GOLDEN RARE |     7 |   20 /  30 |
|    GOLDEN COMMON |     7 |   26 /  26 |
|        LEGENDARY |     3 |    7 /  40 |
|             EPIC |    26 |   10 /  10 |
-----------------------------------------
~~~

#### Display the packs and pity timer of the extension DARKMOON_FAIRE in a html format.
~~~
$ ./packs_tracker.sh -a display -e DARKMOON_FAIRE -f html -p
Progress : [########################################] 100% (98/98)
URL to Access the HTML file: file:///Users/[...]/packs_tracker_DARKMOON_FAIRE.html
~~~
[HTML sample file](https://htmlpreview.github.io/?https://github.com/Akinaux/HS-packs_tracker/blob/main/samples/packs_tracker_DARKMOON_FAIRE.html)

### How to run the script from a container image:

The script is actually hosted in a Ubuntu Container which can be run using a Container runtime such as podman, docker, ...

To do so, you can run the command like `docker run --rm --name packs_tracker -v /Applications/Hearthstone/Logs/:/Applications/Hearthstone/Logs/ -v /Users/myuser/Hearthstone:/Hearthstone/data  quay.io/akinaux/hearthstone_packs_tracker /Hearthstone/packs_tracker.sh -a display -e DARKMOON_FAIRE -f html -p -F /Hearthstone/data`

In this command:
- "-v /Applications/Hearthstone/Logs/:/Applications/Hearthstone/Logs/" => this will export your local folder /Applications/Hearthstone/Logs/ into the container (you may have to share this folder in your Container application)
- "-v /Users/myuser/Hearthstone:/Hearthstone/data" => This will export your local folder /Users/myuser/Hearthstone into the container as /Hearthstone/data
-  "quay.io/akinaux/hearthstone_packs_tracker" => This will download the Container image from quay.io
- The last part of the command "/Hearthstone/packs_tracker.sh -a display -e DARKMOON_FAIRE -f html -p -F /Hearthstone/data" is the part to actually run the script into the container as describe previsouly

To retrieve the latest version of the Container image, please run the command:
- docker pull quay.io/akinaux/hearthstone_packs_tracker

#### Know Issues:
- The data protection is only working if you extract the data from the log on the same day. Running the script from the same log on the different day will duplicate the imported packs
