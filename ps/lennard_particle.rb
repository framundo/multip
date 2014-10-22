class LennardParticle
  attr_accessor :id, :x, :y, :r, :angle, :c, :mass, :vx, :vy, :fx, :fy

  def initialize(id, x, y, vx, vy, mass, r, c)
    @id, @x, @y, @r, @c, @vx, @vy, @mass = id, x, y, r, c, vx, vy ,mass
    #Horizontal colission
    if @x + @r > LennardSystem::WIDTH
      @x = LennardSystem::WIDTH - @r
      @vx = - @vx.abs
    end
    if @x < @r
      @x = @r
      @vx = @vx.abs
    end
    if (@x - LennardSystem::WIDTH/2).abs < @r && (@y - LennardSystem::HEIGHT/2).abs > LennardSystem::GATE/2
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
      @y = @r
      @vy = @vy.abs
    end
    if @y + @r > LennardSystem::HEIGHT
      @y = LennardSystem::HEIGHT - @r
      @vy = - @vy.abs
    end
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
