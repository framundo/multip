require 'slop'
require 'benchmark'
require 'debugger'

require_relative 'ps/particle_system'
require_relative 'ps/particle'

VELOCITY = 0.5

def calculate_angle(particle, neighbors, interval)
  sum = neighbors.reduce(particle.angle) { |a, e| a + e.angle }
  avg = sum.to_f / (neighbors.size + 1)
  noise = Random.rand(interval)
  (avg + noise) % (2 * Math::PI)
end

def average_normalized_velocity(system)
  velocity_sum = system.particles.each_with_object({ x: 0, y: 0 }) do |p, v|
    v[:x] += p.vx
    v[:y] += p.vy
  end
  average_velocity = Math.sqrt(velocity_sum[:x]**2 + velocity_sum[:y]**2)
  average_velocity / (system.particles.size * VELOCITY)
end

opts = nil
begin
  opts = Slop.parse(arguments: true) do
    banner 'Usage: neighbours.rb [options] filename'
    on 'r', 'radious', as: Float, required: true
    on 'i', 'iterations', as: Integer, required: true
    on 'e', 'eta', as: Float, required: true
  end
  puts opts.to_hash
rescue => e
  puts "Wrong parameters. Usage: off_latice.rb --iterations --eta --radious static_file dynamic_file"
  abort
end

if opts
  ps = Ps::ParticleSystem.new(ARGV[0], ARGV[1], nil, opts[:r], true)
  ps.particles.each do |p|
    p.velocity = VELOCITY
    p.angle = Random.rand(0.0..(2 * Math::PI))
  end
  file = File.open('export_latice.xyz', 'w')
  interval = ((-opts[:eta] / 2)..(opts[:eta] / 2))
  opts[:i].times do |i|
    ps.save_snapshot(file)
    puts "#{i}\t#{average_normalized_velocity(ps)}" if i%10 == 0
    ps.move
    ps.particles.each do |p|
      p.angle = calculate_angle(p, ps.neighbours(p), interval)
    end
  end
end
