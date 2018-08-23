# Patrick's Pocket Challenge

Remove all 28 squares from the board in a neverending series of randomized puzzles.

_Patrick’s Pocket Challenge_ for the Nintendo® GAME BOY™ is fun for all ages. Are you ready for the challenge?

## How to play

The object of the game is to move Patrick around the board and remove all 28 squares. Squares with symbols will remove extra squares and can make the puzzles trickier.

If you win, you gain 60 points minus the number of steps Patrick has made. If you lose, you lose 60 points plus the number of steps.

### Controls

* D-pad: Select square
* A: Move Patrick
* B: Load a new level (if you haven't moved yet)

## Download

To download a ROM, please go to the [Releases](https://github.com/tobiasvl/pocket-patrick/releases) page and download the latest version.

If you don't have the means to play the ROM on actual hardware, you will need to run it in an accurate Game Boy emulator that simulates uninitialized RAM. I recommend [BGB](http://bgb.bircd.org/).

## Building

* Install [RGBDS](https://github.com/rednex/rgbds)
* Run `make`
* The assembled ROM will end up in `build/patrick.gb`, together with some extra files that aren't necessary for playing (but nice for debugging).
