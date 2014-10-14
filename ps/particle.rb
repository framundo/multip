module Ps
  class Particle
    attr_accessor :id, :x, :y, :r, :velocity, :angle, :c, :mass, :vx, :vy

    def initialize(id, x, y, r, c)
      @id, @x, @y, @r, @c = id, x, y, r, c
    end

    def to_s
      [@x, @y]
    end

    def distance(particle, length)
      x_distance = particle.x - x
      y_distance = particle.y - y
      if length
        x_distance = length - x_distance.abs if x_distance.abs > length / 2
        y_distance = length - y_distance.abs if y_distance.abs > length / 2
      end
      Math.sqrt( x_distance ** 2 + y_distance ** 2) - (@r + particle.r)
    end

    def energy
      Vector[vx, vy].inner_product(Vector[vx, vy]) * mass / 2
    end

    # def vx
    #   velocity * Math.cos(angle)
    # end

    # def vy
    #   velocity * Math.sin(angle)
    # end
  end
end
