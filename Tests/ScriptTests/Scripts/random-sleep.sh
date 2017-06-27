#!/usr/bin/env ruby --disable=gems,did_you_mean,rubyopt

def nap
  sleep (50 + rand(300)) / 1000
end

puts "A"
puts "~~~"
nap
puts "B"
nap
puts "~~~"
puts "C"
