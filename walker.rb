require 'slop'
require 'benchmark'
require 'debugger'

require_relative 'ps/walker_system'
require_relative 'ps/walker_particle'
require_relative 'ps/walker_wall'

TIME_STEP = 0.1

opts = nil
begin
  opts = Slop.parse(arguments: true) do
    banner 'Usage: walker.rb [options]'
    on 'n', 'number', as: Integer, required: true
    # on 't', 'time', as: Float, required: true
    on 'd', 'distance', as: Float, default: 0.0
  end
  puts opts.to_hash
rescue => e
  puts "Wrong parameters. Usage: walker.rb --number --time"
  abort
end

if opts
  ps = WalkerSystem.new(opts[:n], opts[:d])
  file = File.open("walker/export_walker_#{opts[:n]}_#{opts[:d]}.xyz", 'w')
  # e_file = File.open("silo/export_silo_energy_#{opts[:n]}.txt", 'w')
  time = 0
  while !ps.all_in_goal? do
    ps.save_snapshot(file)
    # kinematik = ps.kinematik
    # potential = ps.potential
    # total = kinematik + potential
    # e_file.puts "#{time}\t#{kinematik.round(3)}\t#{potential.round(3)}\t#{total.round(3)}"
    puts "#{time}"
    ps.move(TIME_STEP)
    time += TIME_STEP
  end
end
