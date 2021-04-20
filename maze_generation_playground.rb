require "opl"

# todo
# add a constraint or optimize for complexity of the solution as well

# size of the maze
n = ARGV[0].to_i
n = 6 if n.nil? || n == 0

def psol
  pmat = []
  $lp.matrix_solution["x"].each_index do |i|
    row = $lp.matrix_solution["x"][i]
    r = []
    row.each_index do |j|
      elem = row[j]
      is_correct = $lp.matrix_solution["y"][i][j] == 1.0 rescue false

      is_incorrect = nil
      row.each_index do |v|
        row.each_index do |w|
          if $lp.matrix_solution["p"][i][j][v][w] == 1.0
            # puts "incorrect: #{i},#{j} #{v},#{w}"
            is_incorrect = "#{v},#{w}"
          end
        end
      end

      if is_correct
        r << " * "
      elsif !is_incorrect.nil?
        r << is_incorrect
      elsif elem == 0.0
        r << "   "
      else
        r << "+++"
      end
    end
    pmat << r
  end

  pmat.each do |row|
    puts row.join("")
  end

  ""
end

# as many walls as possible
# objective = "sum(i in (0..#{n-1}), j in (0..#{n-1}), x[i][j])"
# as many incorrect squares as possible
objective = "sum(i in (1..#{n-2}), j in (1..#{n-2}), v in (1..#{n-2}), w in (1..#{n-2}), p[i][j][v][w])"
# any old solution will do
# objective = "1"

constraints = []

# base case constraint
constraints << "forall(i in (0..#{n-1}), j in (0..#{n-1}), x[i][j] >= 0)"

# if a square is empty, then there is at least one adjacent empty square
# constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), x[i-1][j] + x[i + 1][j] + x[i][j - 1] + x[i][j + 1] - x[i][j] <= 3)"
# for left side
# constraints << "forall(i in (1..#{n-2}), x[i][0] - x[i][1] >= 0)"
# for right side
# constraints << "forall(i in (1..#{n-2}), x[i][#{n-1}] - x[i][#{n-2}] >= 0)"

# don't allow for a space to be surrounded by four spaces
# constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), x[i-1][j] + x[i + 1][j] + x[i][j - 1] + x[i][j + 1] + x[i][j] >= 1)"
# don't allow for a wall to be surrounded by four walls
# constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), x[i-1][j] + x[i + 1][j] + x[i][j - 1] + x[i][j + 1] + x[i][j] <= 4)"

# don't allow for a set of four spaces to form a "space square"
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), x[i][j-1] + x[i-1][j-1] + x[i-1][j] + x[i][j] >= 1)"

# don't allow any row to be fully blocked off
# constraints << "forall(i in (1..#{n-2}), sum(j in (0..#{n-1}), x[i][j]) <= #{n-1})"
# don't allow any column to be fully blocked off
# constraints << "forall(j in (1..#{n-2}), sum(i in (0..#{n-1}), x[i][j]) <= #{n-1})"

# top and bottom rows of the maze are blocked off
constraints << "forall(j in (0..#{n-1}), x[0][j] = 1)"
constraints << "forall(j in (0..#{n-1}), x[#{n-1}][j] = 1)"

# every row must have at least a certain number of spaces
# constraints << "forall(i in (1..#{n-2}), sum(j in (0..#{n-1}), x[i][j]) <= #{(n / 2.0).ceil})"

# enter
constraints << "x[1][0] = 0"
constraints << "sum(i in (0..#{n-1}), x[i][0]) = #{n-1}"
# constraints << "forall(i in (2..#{n-1}), x[i][0] = 1)"
# exit
constraints << "x[#{n-2}][#{n-1}] = 0"
constraints << "sum(i in (0..#{n-1}), x[i][#{n-1}]) = #{n-1}"
# constraints << "forall(i in (0..#{n-3}), x[i][#{n-1}] = 1)"

# entrance and exit are on the correct path
constraints << "y[1][0] = 1"
constraints << "y[#{n-2}][#{n-1}] = 1"

# entrance and exit have a correct path square to the right/left of them
constraints << "y[1][1] = 1"
constraints << "y[#{n-2}][#{n-2}] = 1"

# a square on the correct path is surrounded by exactly 2 other squares on the correct path
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), y[i-1][j] + y[i + 1][j] + y[i][j - 1] + y[i][j + 1] - 2*y[i][j] >= 0)"
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), y[i-1][j] + y[i + 1][j] + y[i][j - 1] + y[i][j + 1] + 2*y[i][j] <= 4)"

# a square on the correct path is empty
constraints << "forall(i in (0..#{n-1}), j in (0..#{n-1}), y[i][j] + x[i][j] - 1 <= 0)"

# ensure a p-value for all squares
constraints << "forall(i in (0..#{n-1}), j in (0..#{n-1}), v in (0..#{n-1}), w in (0..#{n-1}), p[i][j][v][w] >= 0)"
# edges cannot be on an incorrect path
constraints << "forall(j in (0..#{n-1}), v in (1..#{n-2}), w in (1..#{n-2}), p[0][j][v][w] = 0)"
constraints << "forall(j in (0..#{n-1}), v in (1..#{n-2}), w in (1..#{n-2}), p[#{n-1}][j][v][w] = 0)"
constraints << "forall(i in (0..#{n-1}), v in (1..#{n-2}), w in (1..#{n-2}), p[i][0][v][w] = 0)"
constraints << "forall(i in (0..#{n-1}), v in (1..#{n-2}), w in (1..#{n-2}), p[i][#{n-1}][v][w] = 0)"
# all squares on the correct path are on their own incorrect path
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), p[i][j][i][j] - y[i][j] = 0)"
# a square can either be on an incorrect path or it is a wall
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), sum(v in (1..#{n-2}), w in (1..#{n-2}), p[i][j][v][w]) + x[i][j] = 1)"
# a square can be on at most one incorrect path
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), sum(v in (1..#{n-2}), w in (1..#{n-2}), p[i][j][v][w]) <= 1)"
# an incorrect square is surrounded by squares that are either
  # also on that incorrect path, or
  # are walls, or
  # the square is on the correct path
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), v in (1..#{n-2}), w in (1..#{n-2}), 4*p[i][j][v][w] - 4*y[i][j] - p[i+1][j][v][w] - p[i-1][j][v][w] - p[i][j+1][v][w] - p[i][j-1][v][w] - x[i+1][j] - x[i-1][j] - x[i][j+1] - x[i][j-1] <= 0)"
# square i,j cannot be on incorrect path originating at v,w if v,w is not on the correct path (can remove?)
# constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), v in (1..#{n-2}), w in (1..#{n-2}), p[i][j][v][w] - y[v][w] <= 0)"

# at least a few incorrect squares
# constraints << "sum(i in (1..#{n-2}), j in (1..#{n-2}), v in (1..#{n-2}), w in (1..#{n-2}), p[i][j][v][w]) >= #{(n*n/3).ceil}"

time = Time.now
$lp = maximize(objective, subject_to(constraints, ["BOOLEAN: x,y,p"]))
puts "Completed in #{Time.now - time} seconds."

psol
