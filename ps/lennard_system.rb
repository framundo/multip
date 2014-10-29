class LennardSystem
  require 'matrix'
  attr_reader :particles

  WIDTH = 400 # m
  HEIGHT = 200 # m
  GATE = 10 # m
  EPS = 2.0 # m

  RADIOUS = 2 # m
  VELOCITY = 10.0 # m/s
  MASS = 0.1 # kg
  DELTA_T = 0.0001
  DELTA_T_2 = DELTA_T ** 2
  RM = 1.0
  CUT_R = 5.0

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
    @cell_index = cell_index
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
      @cell_index = cell_index
      @particles.each { |p| force(p) }
      @particles.each_with_index do |p, i|
        old_p = @particles_old[i]
        vx = p.vx + DELTA_T * p.fx / p.mass
        vy = p.vy + DELTA_T * p.fy / p.mass
        x = p.x + DELTA_T * vx
        y = p.y + DELTA_T * vy
        particles_new << LennardParticle.new(p.id, x, y, vx, vy, p.mass, p.r, p.c)
      end
      @particles_old = @particles
      @particles = particles_new
    end
  end

  def cell_index
    ci = []
    height_cells.times do |i|
      ci[i] = []
      width_cells.times do |j|
        ci[i][j] = []
      end
    end
    @particles.each do |particle|
      row, col = particle_index(particle)
      ci[row][col] << particle
    end
    ci
  end

  def neighbours(particle)
    row, col = particle_index(particle)
    n = Set.new
    n_rows, n_cols = [], []
    n_rows << row
    n_cols << col
    n_rows << row-1 if row > 0
    n_rows << row+1 if row < height_cells - 1
    n_cols << col-1 if col > 0
    n_cols << col+1 if col < width_cells - 1
    n_rows.each do |r|
      n_cols.each do |c|
        particles = @cell_index[r][c]
        particles.each do |p|
          n << p if (particle != p) && particle.distance(p) <= CUT_R
        end
      end
    end
    n
  end

  def particle_index(particle)
    [ (particle.y / cell_height).to_i, (particle.x / width_cells).to_i ]
  end

  def force(p)
    p.fx = 0
    p.fy = 0
    neighbours(p).each do |p2|
      next if p == p2
      r = p.distance(p2)
      next if r > CUT_R
      if r != 0
        force = 12.0 * EPS / RM * ((RM / r) ** 13 - (RM / r) ** 7)
        tita = Math.atan2(p.y - p2.y, p.x - p2.x)
        p.fx += force * Math.cos(tita)
        p.fy += force * Math.sin(tita)
      end
    end
    # puts "Force:" + Vector[p.fx, p.fy].magnitude.to_s if (p.fx || p.fy) > 0
    [p.fx, p.fy]
  end

  def height_cells
    (HEIGHT.to_f / CUT_R).floor
  end

  def width_cells
    (WIDTH.to_f / CUT_R).floor
  end

  def cell_width
    WIDTH / width_cells
  end

  def cell_height
    HEIGHT / height_cells
  end

  def fraction
    @particles.select { |p| p.x > WIDTH/2 }.size.to_f / @particles.size
  end

  def potential
    potential = 0
    @particles.each do |p|
      @particles.each do |p2|
        next if p.id == p2.id
        r = p.distance(p2)
        next if r > CUT_R || r == 0.0
        potential += EPS * ((RM / r) ** 12 - 2 * (RM / r) ** 6)
      end
    end
    potential
  end

  def kinematik
    @particles.reduce(0) { |a, e| a + e.kinematik }
  end

end
