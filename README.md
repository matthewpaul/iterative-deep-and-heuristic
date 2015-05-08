# iterative-deep-and-heuristic

This program solves the River Crossing board games using a combination of Iterative deepening, in addition to an A* heuristic search. 
You can choose which of these types of searches are performed by modifying calls at the end of the program. 

In order to execute this script, run the PlankGame.rb file in the command line with one of the provided text files as an argument.
The game boards are set up as a list of planks. "Plank occupiable spaces" have a Start stump, an end stump, a length, and a boolean 
T or F to determine whether they're filled by a plank. 

Feel free to create your own board, but if the board is not solveable, the program will not terminate unless memory is exhausted.
