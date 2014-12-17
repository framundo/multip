class WalkerParticle
  attr_accessor :id, :x, :y, :r, :angle, :color, :mass, :vx, :vy, :fx, :fy, :vd, :dead, :dx, :dy

  VD = 2
  VD_DELTA = 1
  GOAL_MARGIN = 20

  def initialize(id, x, y, vx, vy, mass, r, color, vd = nil)
    @id, @x, @y, @r, @vx, @vy, @mass = id, x, y, r, vx, vy ,mass
    @color = color
    @vd = vd || Random.rand((VD - VD_DELTA).to_f..(VD + VD_DELTA).to_f)
    @dx = blue? ? -GOAL_MARGIN : WalkerSystem::WIDTH + GOAL_MARGIN
    @dy = y
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

  def red?
    self.color == WalkerSystem::RED
  end

  def blue?
    self.color == WalkerSystem::BLUE
  end

  def dead?
    self.dead
  end
end
