
require 'set'
require 'benchmark'

# This is the main ruby file for the Plank Game

# Action: An action can be 1 {a move from one stump to another}, 
# 2 {picking up a plank}, 3 {putting down a plank}. 
# If we are performing a move action, src and dst are the source stump and destination stump respectively. 
# when picking up a plank, src and dst define the start and finish of the plank being picked up. 
class Action
	def initialize(type, src, dst)
		@type = type
		@src = src
		@dst = dst
	end

	def type
		@type
	end

	def src
		@src
	end

	def dst
		@dst
	end

	def to_s
		if self.type == 1
			return "Move from " + self.src + " to " + self.dst
		elsif self.type == 2
			return "Pick up plank that spans stumps " + self.src + " and " + self.dst
		else
			return "Put down the plank you're carrying between " + self.src + " and " + self.dst
		end
	end
end


# Edge: An edge is VERY DIFFERENT from a plank. 
# An edge is an available space to place a plank. 
# It has a unique ID, a start stump, a finish stump, and a length. It is also filled or not filled. 
class Edge
	def initialize(id, start, finish, length, filled)
		@id = id
		@start = start
		@finish = finish
		@length = length.to_i
		@filled = filled
	end

	def id
		@id
	end

	def start
		@start
	end

	def start=(value)
		@start = value
	end

	def finish
		@finish
	end

	def finish=(value)
		@finish = value
	end

	def length
		@length
	end

	def filled
		@filled
	end

	def filled=(value)
		@filled = value
	end

	def to_s
		puts "Edge: " + self.id.to_s + " spans: " + self.start + " - " + self.finish + " Length: " + self.length.to_s + " Filled = " + (self.filled ? "True" : "False")
	end
end

# Plank: A plank has a start stump and a finish stump that define the plank's location. 
# A plank also has a length and an ID that is unique to that plank. 
class Plank
	def initialize(id, start, finish, length)
		@id = id
		@length = length.to_i
		@start = start
		@finish = finish
	end

	def id
		@id
	end

	def start
		@start
	end

	def start=(value)
		@start = value
	end

	def finish
		@finish
	end

	def finish=(value)
		@finish = value
	end

	def length
		@length
	end

	def to_s

		if ((self.start == nil) || (self.finish == nil))
			return "Plank: " + self.id.to_s + " {Currently Held} Length: " + self.length.to_s
		else
		return "Plank: " + self.id.to_s + " spans: " + self.start + " - " + self.finish + " Length: " + self.length.to_s
		end
	end
end

# Stump: A stump has a unique ID that specifies which stump it is, 
# and also has an array of accessible planks that can be used to determine which 
# planks can be picked up from this stump. 
# Distance is used in hsearch for computing manhattan distances of nodes.
# It is initialized at infinity (10000 in this case) for use in Dijkstra's algorithm. 
class Stump
	def initialize(id, planks)
		@planks = planks
		@id = id
		@distance = 10000
	end

	def id
		@id
	end

	def planks
		@planks
	end

	def planks=(value)
		@planks = value
	end

	def distance
		@distance
	end

	def distance=(value)
		@distance = value
	end

	def visited
		@visited
	end

	def visited=(value)
		@visited = value
	end

	def to_s
		print "Stump " + self.id + " has planks: "
		if self.planks.empty?
			puts "None"
		else
			self.planks.each do |p|
				puts p.to_s
			end
		end
	end
end

# Player: A player has a stump location(stump ID), a boolean value 
# that determines whether or not they are currently carrying a plank
class Player
	def initialize(position, plank)
		@position = position
		@plank = plank
	end

	def position
		@position
	end

	def position=(value)
		@position = value
	end

	def plank
		@plank
	end

	def plank=(value)
		@plank = value
	end

	def to_s
		puts "Player position = " + self.position + ", plank = " + self.plank.to_s
	end
end

# State: A state has an array of stumps(the tree stump number, or a node in the graph) 
# and planks(these are the edges in the graph, which should have a boolean value as to whether 
#        it's filled by a plank)
class State
	def initialize(stumps, edges, planks, player)
		@stumps = stumps
		@edges = edges
		@planks = planks
		@player = player
	end

	def stumps
		@stumps
	end

	def edges
		@edges
	end

	def planks
		@planks
	end

	def player
		@player
	end

	def player=(value)
		@player = value
	end

	def goal?
		(self.player.position == "Goal") ? (return true) : (return false)
	end

	def actions
		possibleActions = Array.new
		currentState = self
		currentPosition = currentState.player.position

		# Generate potential "plank pick up" actions
		if(self.player.plank == nil)
			currentPositionContents = Array.new
			currentState.planks.each do |p|
				if(p.start == currentPosition) || (p.finish == currentPosition)
					currentPositionContents.push(p)
				end
			end
			if !currentPositionContents.empty?
				count = currentPositionContents.size - 1
				for i in 0..count
					plank = currentPositionContents[i]
					action = Action.new(2, plank.start, plank.finish)
					possibleActions.push(action)
				end
			end
		end
		# Now get all the adjacent edges
		adjacentEdges = currentState.edges.select {|e| ((e.start == currentPosition || e.finish == currentPosition))}
		# See if the adjacent edges are filled
		adjacentEdges.each do |e|
			filled = e.filled
			destination = nil
			# If an adjacent edge is filled, we can cross it
			if filled
					if e.start == currentPosition
						destination = e.finish
					else
						destination = e.start
					end
				action = Action.new(1, currentPosition, destination)
				possibleActions.push(action)
		# If it's not filled and we have a plank with the same length, we can put our plank in that spot
			else
				if currentState.player.plank != nil
					if currentState.player.plank.length == e.length
						if e.start == currentPosition
							dst = e.finish
						else
							dst = e.start
						end
						action = Action.new(3, currentPosition, dst)
						possibleActions.push(action)
					end
				end
			end
		end
		return possibleActions
	end

	def result(action, game)
		# Apply the {1 - move} action
		if (action.type == 1)
			self.player.position = action.dst

			if (self.player.position == "Goal")
				game.goal_found = true
			end
		# Apply the {2 - picking up plank} action
		# Need to add the plank to the player's inventory, and change the edge's filled value to false
		elsif (action.type == 2)
			plank = nil
			self.planks.each do |p|
				if(((p.start == action.src) && (p.finish == action.dst)) || ((p.start == action.dst) && (p.finish == action.src)))
					p.start = nil
					p.finish = nil
					plank = p
				end
			end
			self.edges.each do |e|
				if (((e.start == action.src) && (e.finish == action.dst)) || ((e.start == action.dst) && (e.finish == action.src)))
					e.filled = false
				end
			end
			self.player.plank = plank
		# Apply the {3 - putting down the held plank}
		else
			self.planks.each do |p|
				if((p.start == nil) && (p.finish == nil))
					p.start = action.src
					p.finish = action.dst
				end
			end
			self.edges.each do |e|
				if (((e.start == action.src) && (e.finish == action.dst)) || ((e.start == action.dst) && (e.finish == action.src)))
					e.filled = true
				end
			end
			self.player.plank = nil
		end
	end

	def to_s
		puts "******************* State *******************"
		puts "--------------------Player-------------------"
		puts self.player.to_s
		puts "--------------------Planks-------------------"
		self.planks.each do |p|
			puts p.to_s
		end
		puts "--------------------Edges--------------------"
		self.edges.each do |e|
			puts e.to_s
		end
	end
end

# An ActionStateNode is used as a bookmarking object in order to 
# keep track of the action used to generate a state, parent and children.
# This makes it easier to present a solution at the end of a search.
class ActionStateNode
	def initialize(action, state, parent, children)
		@state = state
		@action = action
		@parent = parent
		@children = children
		@discovered = false
		@processed = false
		@g = 0
	end

	def action
		@action
	end

	def state
		@state
	end

	def parent
		@parent
	end

	def discovered
		@discovered
	end

	def processed
		@processed
	end

	def processed=(value)
		@processed = value
	end

	def discovered=(value)
		@discovered = value
	end

	def parent=(value)
		@parent = value
	end

	def children
		@children
	end

	def children=(value)
		@children = value
	end

	def g
		@g
	end

	def g=(value)
		@g = value
	end

	def nodes_equal(node2)
		equal = true
		for i in 0..(self.state.edges.size - 1)
			if(self.state.edges[i].filled != node2.state.edges[i].filled)
				equal = false
				break
			end
		end
		if(self.state.player.position != node2.state.player.position)
			equal = false
		end
		if((self.state.player.plank == nil) && (node2.state.player.plank != nil))
			equal = false
		elsif((self.state.player.plank == nil) && (node2.state.player.plank != nil))
			equal = false
		end
		return equal

	end


	# Expands the current state into all of the possible children states
	def expand(game)
		game.nodesExpanded += 1
		childNodes = Array.new
		possibleActions = self.state.actions
		possibleActions.each do |a|
			stumps = Array.new
			edges = Array.new
			planks = Array.new
			self.state.stumps.each do |s|
				stumps.push(s.clone)
			end
			self.state.edges.each do |e|
				edges.push(e.clone)
			end
			self.state.planks.each do |p|
				planks.push(p.clone)
			end
			state = State.new(stumps, edges, planks, self.state.player.clone)
			state.result(a, game)
			node = ActionStateNode.new(a, state, self, nil)
			node.g = self.g + 1
			childNodes.push(node)
		end
		self.children = childNodes
	end

	def dls(game, i, bound)
		depth = i + 1
		currentNode = self
		if(currentNode.state.goal? && !game.solution_printed)
				puts "This node is the solution! g(n) = " + currentNode.g.to_s
				game.goal_found = true
				stack = Array.new
				while(currentNode.parent != nil)
					stack.push(currentNode.action)
					currentNode = currentNode.parent
				end
				puts "Solution: "
				puts currentNode.action
				while(!stack.empty?)
					puts stack.pop.to_s
				end
				game.solution_printed = true
		end
		if(depth < bound && !game.goal_found)
			currentNode.discovered = true
			alreadyExplored = false
			game.explored.each do |n|
				if(n.nodes_equal(currentNode)) 
					alreadyExplored = true
					#puts "already explored this node"
					break
				end
			end
			if(!alreadyExplored)
			currentNode.expand(game)
			game.explored.push(currentNode)
			children = currentNode.children
			children.each do |c|
				if (c.discovered == false)
					c.parent = currentNode
					c.dls(game, depth, bound)
				elsif(!c.processed)
					if(c.state.goal?)
						puts "C is the solution!"
					end
				end
				c.processed = true
			end
		end
		end
	end

	def to_s
		puts self.action.to_s
		puts "Results in: "
		self.state.to_s
	end

	def h
		return 0
	end

	def h2
		# Calculate player distance to goal first
		# May have to reinitialize stump values if object cloning was not deep enough. Not sure yet.
		root = self.state.player.position
		currentStump = nil
		stumps = self.state.stumps
		stumps.each do |s|
			s.visited = false
		end
		# Initialize root node to 0, all other nodes to infinity. Add root to visited nodes.
		stumps.each do |s|
			if s.id == root
				currentStump = s
				currentStump.distance = 0
				currentStump.visited = true
			else
				s.distance = 10000
				s.visited = false
			end
		end
		# Select the edges connected to the stump we're currently at
		connectedEdges = self.state.edges.select {|e| (e.start == currentStump.id) || (e.finish == currentStump.id) }
		# Now use these edges to find the neighbors
		neighbors = Array.new
		while(!((stumps.select {|s| s.id == "Goal"})[0].visited))
			puts (stumps.select {|s| s.id == "Goal"})[0].to_s
			connectedEdges.each do |e|
				# Calculate the distance of each neighbor that the edge connects to
				if (e.start == currentStump.id)
					nStump = (stumps.select { |s| (s.id == e.finish) && !(s.visited) })[0]
				elsif (e.finish == currentStump.id)
					nStump = (stumps.select { |s| (s.id == e.start) && !(s.visited) })[0]
				end
				cost = 0
				if e.filled
					cost = 1 + currentStump.distance
				else
					cost = 2 + currentStump.distance
				end
				if(nStump != nil)
				(cost < nStump.distance) ? nStump.distance = cost : nStump.distance = nStump.distance

					puts "nStump ID = " + nStump.id + " and distance = " + nStump.distance.to_s
					neighbors.push(nStump)
					nStump.visited = true
				end
				end
				neighbors.sort {|a, b| a.distance < b.distance }
				neighbors.each do |n|
				puts n.to_s
				end
				currentStump = neighbors.pop
				currentStump.visited = true
			end
		return currentStump.distance
	end

	def astar(game)
		currentNode = self
		if(currentNode.state.goal? && !game.solution_printed)
				puts "This node is the solution! f(n) = g(n) + h(n) = " + currentNode.g.to_s
				game.goal_found = true
				stack = Array.new
				while(currentNode.parent != nil)
					stack.push(currentNode.action)
					currentNode = currentNode.parent
				end
				puts "Solution: "
				puts currentNode.action
				while(!stack.empty?)
					puts stack.pop.to_s
				end
				game.solution_printed = true
		end
		if(!game.goal_found)
			currentNode.discovered = true
			alreadyExplored = false
			game.explored.each do |n|
				if(n.nodes_equal(currentNode)) 
					alreadyExplored = true
					#puts "already explored this node"
					break
				end
			end
			if(!alreadyExplored)
			currentNode.expand(game)
			game.explored.push(currentNode)
			children = currentNode.children
			queue = Array.new
			children.each do |c|
				queue.push(c)
				queue.sort {|a, b| (a.g + a.h) <=> (b.g + b.h)}
				if (c.discovered == false)
					c.parent = currentNode
				elsif(!c.processed)
					if(c.state.goal?)
						puts "C is the solution!"
					end
				end
				c.processed = true
			end
			while(!queue.empty?)
				queue.pop.astar(game)
			end
		end
		end
	end
end

# PlankGame: A PlankGame has a current state(potential plank placements 
# and whether or not they are filled)
class PlankGame
	def initialize(startState, start, goal)
		@state = startState
		@start = start
		@goal = goal
		@goal_found = false
		@solution_printed = false
		@explored = Array.new
		@nodesExpanded = 0
	end

	def state
		@state
	end

	def state=(value)
		@state = value
	end

	def start
		@start
	end

	def goal
		@goal
	end

	def goal_found
		@goal_found
	end

	def solution_printed
		@solution_printed
	end

	def solution_printed=(value)
		@solution_printed = value
	end

	def goal_found=(value)
		@goal_found=(value)
	end

	def explored
		@explored
	end

	def explored=(value)
		@explored = value
	end

	def nodesExpanded
		@nodesExpanded
	end

	def nodesExpanded=(value)
		@nodesExpanded = value
	end

	# Performs a blind search using Iterative Deepening
	def bsearch(start_depth)
		bound = start_depth
		root_node = ActionStateNode.new(nil, self.state, nil, nil)

		while(!self.goal_found)
		self.explored.clear
		self.nodesExpanded = 0
		bound += 1
		puts "Attempting to find solution at depth " + bound.to_s
		root_node.dls(self, 0, bound)
		#self.explored.each do |n|
		#	n.to_s
		#end
		end

		
	end

	def hsearch
		puts "Performing hsearch"
		root_node = ActionStateNode.new(nil, self.state, nil, nil)

		root_node.astar(self)
	end

end

def analyze(game)
	t1 = Time.now
	yield
	t2 = Time.now
	puts "*********************** " + (t2 - t1).to_s + " seconds ***********************"
	puts game.nodesExpanded.to_s + " nodes expanded during last iteration"
end 


################################################################################################## BEGIN A.I CODE ###############################################################################################

# In order to initialize the program, the user must type "ruby PlankGame.rb {gamefile.txt}

lineNumber = 1
plankNumber = 1
lines = 0

puts "Attempting to read " + ARGV.first

#test test test test test
File.open(ARGV.first, 'r') do |f1|
	while line = f1.gets
		puts line
	end
end


# Count the number of lines in the file
File.open(ARGV.first, 'r') do |f|
	while line = f.gets
		lines += 1
	end
end

puts "There are " + lines.to_s + " edges in this game"


# Convert each line to game pieces
puts "Building Game..."
player = Player.new("Start", nil)
puts "Initializing player..."
puts "Structuring the board..."
edges = Array.new
planks = Array.new
stumpIDs = Array.new
stumps = Array.new
File.open(ARGV.first, 'r') do |f|
	while line = f.gets
		if (lineNumber == 1) 
			line[10] == "T" ? filled = true : filled = false
			# Generate Stumps
			stumpIDs.push("Start")
			stumpIDs.push(line[6])
			# Generate the edge for the game
			edge = Edge.new(1, "Start", line[6], line[8], filled)
			edges.push(edge)
			puts "    Made an edge from Start to " + line[6] + " of length " + line[8]
			# Check to see if we build a plank
			if filled
				plank = Plank.new(plankNumber, "Start", line[6], line[8])
				planks.push(plank)
				puts "    Made a plank!"
				plankNumber += 1
			end
			lineNumber += 1
		elsif (lineNumber == (lines)) 
			line[9] == "T" ? filled = true : filled = false
			# Check to see if stumps are in the game. If they aren't, add them. 
			if !(stumpIDs.include?(line[0])) 
				stumpIDs.push(line[0])
			end
			stumpIDs.push("Goal")
			# Generate the edge for the game
			edge = Edge.new(lineNumber, line[0], "Goal", line[7], filled)
			edges.push(edge)
			puts "    Made an edge from " + line[0] + " to " + line[2..5] + " of length " + line[7]
			# Check to see if we build a plank
			if filled
				plank = Plank.new(plankNumber, line[0], "Goal", line[7])
				planks.push(plank)
				puts "    Made a plank!"
				plankNumber += 1
			end
			lineNumber += 1
		else 
			line[6] == "T" ? filled = true : filled = false
			# Check to see if stumps are in the game. If they aren't, add them. 
			if !(stumpIDs.include?(line[0])) 
				stumpIDs.push(line[0])
			end
			if !(stumpIDs.include?(line[2])) 
				stumpIDs.push(line[2])
			end
			# Generate the edge for the game
			edge = Edge.new(lineNumber, line[0], line[2], line[4], filled)
			edges.push(edge)
			puts "    Made an edge from " + line[0] + " to " + line[2] + " of length " + line[4]
			# Check to see if we build a plank
			if filled
				plank = Plank.new(plankNumber, line[0], line[2], line[4])
				planks.push(plank)
				puts "    Made a plank!"
				plankNumber += 1
			end
			lineNumber += 1
		end
	end
end

puts "******************* Stumps **********************"
stumpIDs.each do |s|
	# Initialize stumps with the planks that are resting on them
	planksOnStump = planks.select {|p| (p.start == s) || (p.finish == s)}
	stumpy = Stump.new(s, planksOnStump)
	stumpy.to_s
	stumps.push(stumpy)
end
puts stumps.size.to_s + " stumps in the game"
puts "******************* Planks **********************"
planks.each do |plank|
	puts plank.to_s
end
puts "******************* Edges **********************"
edges.each do |edge|
	edge.to_s
end

startState = State.new(stumps, edges, planks, player)
game = PlankGame.new(startState, "Start", "Goal")
puts "Game build complete!"
puts "Generating potential actions..."
puts "Player position = " + game.state.player.position
potentialActions = game.state.actions
puts "******************** Potential Actions *********************"
potentialActions.each do |a|
	puts a.to_s
end
puts "************************************************************"
puts "Completed action generation!"

puts "Performing Iterative Deepening!"
analyze(game) { game.bsearch(0) }		

#analyze(game) { game.hsearch }