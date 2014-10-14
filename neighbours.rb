require 'slop'
require 'benchmark'
require 'debugger'

require_relative 'ps/particle_system'
require_relative 'ps/particle'

opts = nil
begin
  opts = Slop.parse(arguments: true) do
    banner 'Usage: neighbours.rb [options] filename'
    on 'n', 'number', as: Integer, required: true
    on 'm', 'cells', as: Integer, required: true
    on 'r', 'radious', as: Float, required: true
    on 'p', 'periodic', as: :boolean, required: false
    on 'b', 'brute-force', as: :boolean, required: false
  end
  puts opts.to_hash
rescue => e
  puts "Wrong parameters. Usage: neighbours.rb --number --cells --radious --periodic --brute-force static_file dynamic_file"
  abort
end

if opts
  ps = Ps::ParticleSystem.new(ARGV[0], ARGV[1], opts[:m], opts[:r], opts[:p] == "true")
  ps.export(ps.particles[opts[:n]-1], opts[:b] == "true")
end
