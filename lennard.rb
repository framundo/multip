require 'slop'
require 'benchmark'
require 'debugger'

require_relative 'ps/lennard_system'
require_relative 'ps/lennard_particle'

TIME_STEP = 0.5

opts = nil
begin
  opts = Slop.parse(arguments: true) do
    banner 'Usage: lennard.rb [options]'
    on 'n', 'number', as: Integer, required: true
    on 't', 'time', as: Integer, required: true
  end
  puts opts.to_hash
rescue => e
  puts "Wrong parameters. Usage: lennard.rb --number --time"
  abort
end

if opts
  ps = LennardSystem.new(opts[:n])
  file = File.open("lennard/export_lennard_#{opts[:n]}.xyz", 'w')
  time_file = File.open("lennard/export_lennard_times_#{opts[:n]}.txt", 'w')
  time = 0
  while time < opts[:t] do
    ps.save_snapshot(file)
    ps.move(TIME_STEP)
    f = ps.fraction
    time += TIME_STEP
    puts "#{time}\t#{f}"
    time_file.puts "#{time}\t#{f}"
  end
end
