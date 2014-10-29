require 'slop'
require 'benchmark'
require 'debugger'

require_relative 'ps/silo_system'
require_relative 'ps/silo_particle'
require_relative 'ps/wall'

TIME_STEP = 0.1

opts = nil
begin
  opts = Slop.parse(arguments: true) do
    banner 'Usage: silo.rb [options]'
    on 'n', 'number', as: Integer, required: true
    on 't', 'time', as: Float, required: true
    on 'o', 'offset', as: Float, required: false
  end
  puts opts.to_hash
rescue => e
  puts "Wrong parameters. Usage: silo.rb --number --time"
  abort
end

if opts
  ps = SiloSystem.new(opts[:n], opts[:o] || 0.0)
  file = File.open("silo/export_silo_#{opts[:n]}.xyz", 'w')
  e_file = File.open("silo/export_silo_energy_#{opts[:n]}.txt", 'w')
  # v_file = File.open("lennard/export_lennard_velocity_#{opts[:n]}.txt", 'w')
  time = 0
  while time < opts[:t] do
    ps.save_snapshot(file)
    kinematik = ps.kinematik
    potential = ps.potential
    total = kinematik + potential
    e_file.puts "#{time}\t#{kinematik.round(3)}\t#{potential.round(3)}\t#{total.round(3)}"
    # velocities = ps.particles.map(&:velocity).join("\t")
    # v_file.puts "#{time}\t#{velocities}"
    puts "#{time}\t#{total.round(3)}"
    ps.move(TIME_STEP)
    time += TIME_STEP
  end
end
