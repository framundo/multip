require 'slop'
require 'benchmark'
require 'debugger'

require_relative 'ps/lennard_system'
require_relative 'ps/lennard_particle'

TIME_STEP = 0.2

opts = nil
begin
  opts = Slop.parse(arguments: true) do
    banner 'Usage: lennard.rb [options]'
    on 'n', 'number', as: Integer, required: true
    on 't', 'time', as: Float, required: false
  end
  puts opts.to_hash
rescue => e
  puts "Wrong parameters. Usage: lennard.rb --number --time"
  abort
end

if opts
  ps = LennardSystem.new(opts[:n])
  file = File.open("lennard/export_lennard_#{opts[:n]}.xyz", 'w')
  f_file = File.open("lennard/export_lennard_times_#{opts[:n]}.txt", 'w')
  e_file = File.open("lennard/export_lennard_energy_#{opts[:n]}.txt", 'w')
  v_file = File.open("lennard/export_lennard_velocity_#{opts[:n]}.txt", 'w')
  time = 0
  while (opts[:t].nil? && ps.fraction < 0.45) || (!opts[:t].nil? && time < opts[:t]) do
    ps.save_snapshot(file)
    f = ps.fraction
    f_file.puts "#{time}\t#{f}"
    kinematik = ps.kinematik
    potential = ps.potential
    e_file.puts "#{time}\t#{kinematik.round(3)}\t#{potential.round(3)}\t#{(kinematik+potential).round(3)}"
    velocities = ps.particles.map(&:velocity).join("\t")
    v_file.puts "#{time}\t#{velocities}"
    puts "#{time}\t#{f}"
    ps.move(TIME_STEP)
    time += TIME_STEP
  end
end
