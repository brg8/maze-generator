require "opl"

# size of the maze
n = ARGV[0].to_i

def psol
  pmat = []
  $lp.matrix_solution["x"].each_index do |i|
    row = $lp.matrix_solution["x"][i]
    r = []
    row.each_index do |j|
      elem = row[j]
      is_correct = $lp.matrix_solution["y"][i][j] == 1.0 rescue false

      is_incorrect = nil

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

# maximize the number of walls in the maze
objective = "sum(i in (0..#{n-1}), j in (0..#{n-1}), x[i][j])"

constraints = []
# ensure that we have a value for each square
# constraints << "forall(i in (0..#{n-1}), j in (0..#{n-1}), x[i][j] >= 0)"

# enter
constraints << "x[1][0] = 0"
# exit
constraints << "x[#{n-2}][#{n-1}] = 0"

# if a square is empty, then there is at least one adjacent empty square
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), x[i-1][j] + x[i + 1][j] + x[i][j - 1] + x[i][j + 1] - x[i][j] <= 3)"
# for left side
constraints << "forall(i in (1..#{n-2}), x[i][0] - x[i][1] >= 0)"
# for right side
constraints << "forall(i in (1..#{n-2}), x[i][#{n-1}] - x[i][#{n-2}] >= 0)"

# don't allow for a wall to be surrounded by four walls
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), x[i-1][j] + x[i + 1][j] + x[i][j - 1] + x[i][j + 1] + x[i][j] <= 4)"

# entrance is on the correct path
constraints << "y[1][0] = 1"
# entrance has a correct path square to the right of it
constraints << "y[1][1] = 1"
# a square on the correct path is surrounded by exactly 2 other squares on the correct path
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), y[i-1][j] + y[i + 1][j] + y[i][j - 1] + y[i][j + 1] - 2*y[i][j] >= 0)"
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), y[i-1][j] + y[i + 1][j] + y[i][j - 1] + y[i][j + 1] + 2*y[i][j] <= 4)"
# a square on the correct path is empty
constraints << "forall(i in (0..#{n-1}), j in (0..#{n-1}), y[i][j] + x[i][j] - 1 <= 0)"

# top and bottom rows of the maze are blocked off
constraints << "sum(j in (0..#{n-1}), x[0][j]) = #{n}"
constraints << "sum(j in (0..#{n-1}), x[#{n-1}][j]) = #{n}"
# left and right (except for entry and exit)
constraints << "sum(i in (0..#{n-1}), x[i][0]) = #{n-1}"
constraints << "sum(i in (0..#{n-1}), x[i][#{n-1}]) = #{n-1}"

# every row must have at least n/2 spaces
constraints << "forall(i in (1..#{n-2}), sum(j in (0..#{n-1}), x[i][j]) <= #{(n / 2.0).ceil})"

# don't allow for a set of four spaces to form a "space square"
constraints << "forall(i in (1..#{n-2}), j in (1..#{n-2}), x[i][j-1] + x[i-1][j-1] + x[i-1][j] + x[i][j] >= 1)"

time = Time.now
$lp = maximize(objective, subject_to(constraints, ["BOOLEAN: x,y"]))

psol
puts "Completed in #{Time.now - time} seconds."
