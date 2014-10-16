class LennardParticle
  attr_accessor :id, :x, :y, :r, :velocity, :angle, :c, :mass, :vx, :vy, :fx, :fy

  def initialize(id, x, y, vx, vy, mass, r, c)
    @id, @x, @y, @r, @c, @vx, @vy, @mass = id, x, y, r, c, vx, vy ,mass
    # Horizontal colission
    if @x + @r > LennardSystem::WIDTH
      puts "Horizontal colission #{id}"
      @x = LennardSystem::WIDTH - @r
      @vx = - @vx.abs
    end
    if @x < @r
      puts "Horizontal colission #{id}"
      @x = @r
      @vx = @vx.abs
    end
    if (@x - LennardSystem::WIDTH/2).abs < @r && (@y - LennardSystem::HEIGHT/2).abs > LennardSystem::GATE/2
      puts "Wall colission #{id}"
      if @x > LennardSystem::WIDTH/2
        @x = LennardSystem::WIDTH/2 + @r
        @vx = @vx.abs
      else
        @x = LennardSystem::WIDTH/2 - @r
        @vx = - @vx.abs
      end
    end
    # Vertical colission
    if @y < @r
      puts "Vertical colission #{id}"
      @y = @r
      @vy = @vy.abs
    end
    if @y + @r > LennardSystem::HEIGHT
      puts "Vertical colission #{id}"
      @y = LennardSystem::HEIGHT - @r
      @vy = - @vy.abs
    end
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

  def ax
    fx / mass
  end

  def ay
    fy / mass
  end
end
