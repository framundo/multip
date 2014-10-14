require 'slop'
require 'benchmark'
require 'debugger'

require_relative 'ps/molecule_system'
require_relative 'ps/particle'

opts = nil
begin
  opts = Slop.parse(arguments: true) do
    banner 'Usage: gas.rb [options] static_file dynamic_file'
    on 'n', 'number', as: Integer, required: true
  end
  puts opts.to_hash
rescue => e
  puts "Wrong parameters. Usage: gas.rb --number static_file dynamic_file"
  abort
end

if opts
  RADIOUS = 0.0015 # m
  VELOCITY = 0.01 # m/s
  MASS = 1.0 # kg
  TIME_STEP = 2.0

  ps = Ps::MoleculeSystem.new(opts[:n], RADIOUS, VELOCITY, MASS)
  file = File.open("export_gas_#{opts[:n]}.xyz", 'w')
  time_file = File.open("export_times_#{opts[:n]}.txt", 'w')
  time = 0
  loop do
    ps.save_snapshot(file)
    ps.move(TIME_STEP)
    f = ps.fraction
    time += TIME_STEP
    puts "#{time}\t#{f}"
    time_file.puts "#{time}\t#{f}"
    break if (f - 0.5).abs < 0.05
  end
end
