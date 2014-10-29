class SiloParticle
  attr_accessor :id, :x, :y, :r, :angle, :c, :mass, :vx, :vy, :fx, :fy

  def initialize(id, x, y, vx, vy, mass, r)
    @id, @x, @y, @r, @vx, @vy, @mass = id, x, y, r, vx, vy ,mass
  end

  def to_s
    [@x, @y]
  end

  def distance(particle)
    x_distance = particle.x - x
    y_distance = particle.y - y
    Math.sqrt( x_distance ** 2 + y_distance ** 2)
  end

  def kinematik
    Vector[vx, vy].magnitude ** 2 * mass / 2
  end

  def potential
    mass * SiloSystem::G.abs * y
  end

  def ax
    fx / mass
  end

  def ay
    fy / mass
  end

  def velocity
    Vector[vx, vy].magnitude
  end
end
