# NES Quotes Applet for TidByt

Displays randomized quotes from Nintendo Entertainment System games alongside game sprites, with the option to turn off quotes from specific games. The quotes are drawn from a pinned revision of the author's [nes-quotes.csv Gist](https://gist.github.com/markmcintyre/b39cf560d7e66bc0b987f809ca4a568f) and cached weekly.

Schema version 2 gives every game a unique setting ID. The renderer still reads the accidental one-character version 1 IDs when an existing configuration is supplied, so a Cloud migration can preserve the two formerly coupled game pairs without guessing user intent.

![NES Quotes Applet for Tidbyt](nes_quotes.gif)
