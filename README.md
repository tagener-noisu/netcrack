# netcrack
A tool for password cracking on multiple machines with one server that handles
dictionaries.

### How to
* Pipe dictionaries to the netcrack in the server mode `cat d1 d2 | netcrack -s
5000`
* Start netcrack in a client mode on the other machines and pipe it's output to
the desired program `netcrack 192.168.13.37 5000 | aircrack-ng -w - ...`
* Netcrack will handle the rest
