class LennardSystem
  require 'matrix'
  attr_reader :particles

  WIDTH = 400 # m
  HEIGHT = 200 # m
  GATE = 10 # m
  EPS = 1.0 # m

  RADIOUS = 5 # m
  VELOCITY = 10 # m/s
  MASS = 10.0 # kg
  DELTA_T = 0.001
  DELTA_T_2 = DELTA_T ** 2
  RM = 1.0

  def initialize(n)
    @particles = []
    n.times do |i|
      x = y = nil
      loop do
        x = Random.rand((RADIOUS) .. (WIDTH/2 - RADIOUS))
        y = Random.rand((RADIOUS) .. (HEIGHT - RADIOUS))
        break if @particles.all? { |p| (x-p.x)**2 + (y-p.y)**2 > (RADIOUS*2)**2 }
      end
      angle = Random.rand(-Math::PI/2 .. Math::PI/2)
      vx = VELOCITY * Math.cos(angle)
      vy = VELOCITY * Math.sin(angle)
      p = LennardParticle.new(i + 1, x, y, vx, vy, MASS, RADIOUS, [1.0 - i.to_f/n, i.to_f/n, i.to_f ** 2/n])
      @particles << p
    end
    @particles.each { |p| force(p) }
    new_particles = @particles.map do |p|
      x = p.x + DELTA_T * p.vx + DELTA_T_2 * p.ax / 2
      vx = p.vx + DELTA_T / p.mass * p.fx
      y = p.y + DELTA_T * p.vy + DELTA_T_2 * p.ay / 2
      vy = p.vy + DELTA_T / p.mass * p.fy
      LennardParticle.new(p.id, x, y, vx, vy, p.mass, p.r, p.c)
    end
    @particles_old = @particles
    @particles = new_particles
  end

  def save_snapshot(file)
    file.puts @particles.size + 2
    file.puts "x y rad r g b vx vy"
    @particles.each do |p|
      red, green, blue = p.c
      file.puts [p.x, p.y, p.r, red, green, blue, p.vx, p.vy].join(' ')
    end
    file.puts [0, 0, 0, 0, 0, 0, 0, 0].join(' ')
    file.puts [WIDTH, HEIGHT, 0, 0, 0, 0, 0, 0].join(' ')
  end

  def move(time)
    (time / DELTA_T).to_i.times do
      particles_new = []
      @particles.each { |p| force(p) }
      @particles.each_with_index do |p, i|
        old_p = @particles_old[i]
        x = 2 * p.x - old_p.x + DELTA_T_2 / p.mass * p.fx
        vx = x - old_p.x / (2 * DELTA_T)
        y = 2 * p.y - old_p.y + DELTA_T_2 / p.mass * p.fy
        vy = y - old_p.y / (2 * DELTA_T)
        particles_new << LennardParticle.new(p.id, x, y, vx, vy, p.mass, p.r, p.c)
      end
      @particles_old = @particles
      @particles = particles_new
    end
  end

  def force(p)
    p.fx = 0
    p.fy = 0
    @particles.each do |p2|
      next if p == p2
      delta_x = (p.x - p2.x)
      delta_y = (p.y - p2.y)
      p.fx += 12 * EPS / RM * ((RM / delta_x) ** 13 - (RM / delta_x) ** 7) #if delta_x.abs < R && delta_x.abs > RMIN
      p.fy += 12 * EPS / RM * ((RM / delta_y) ** 13 - (RM / delta_y) ** 7) #if delta_y.abs < R && delta_y.abs > RMIN
    end
    [p.fx, p.fy]
  end

  def fraction
    @particles.select { |p| p.x > WIDTH/2 }.size.to_f / @particles.size
  end

end
