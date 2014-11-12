class SiloSystem
  require 'matrix'
  attr_reader :particles

  WIDTH = 20 # m
  HEIGHT = 30 # m
  # D = 0.0
  D = 5.0 # m

  # RADIOUS = 0.5
  RADIOUS = D/10.0 # m
  MASS = 0.01 # kg
  KN = 10.0 ** 5
  KT = 0.0001 * KN
  DELTA_T = 0.5 * Math.sqrt(MASS/KN)
  DELTA_T_2 = DELTA_T ** 2
  CUT_R = 2 * RADIOUS

  G = -10.0

  def initialize(n, offset)
    @particles = []
    @walls = []
    @walls << Wall.new(0, 0, 0, HEIGHT)
    @walls << Wall.new(WIDTH, 0, WIDTH, HEIGHT)
    @walls << Wall.new(0, 0, WIDTH/2 - D/2 - offset, 0)
    @walls << Wall.new(WIDTH/2 + D/2 - offset, 0, WIDTH, 0)
    n.times do |i|
      x = y = nil
      loop do
        x = Random.rand(RADIOUS .. WIDTH - RADIOUS)
        y = Random.rand(RADIOUS .. HEIGHT - RADIOUS)
        break if @particles.all? { |p| (x-p.x)**2 + (y-p.y)**2 > (RADIOUS*2)**2 }
      end
      p = SiloParticle.new(i + 1, x, y, 0, 0, MASS, RADIOUS)
      @particles << p
    end
    @cell_index = cell_index
    @particles.each { |p| force(p) }
    new_particles = @particles.map do |p|
      x = p.x + DELTA_T * p.vx + DELTA_T_2 * p.ax / 2
      vx = p.vx + DELTA_T / p.mass * p.fx
      y = p.y + DELTA_T * p.vy + DELTA_T_2 * p.ay / 2
      vy = p.vy + DELTA_T / p.mass * p.fy
      SiloParticle.new(p.id, x, y, vx, vy, p.mass, p.r)
    end
    @particles_old = @particles
    @particles = new_particles
  end

  def save_snapshot(file)
    wall_particles = []
    @walls.each do |wall|
      (wall.length/(RADIOUS*2)).ceil.times do |i|
        r, g, b = [1.0, 1.0, 1.0]
        x = wall.xi + wall.width * (i.to_f / wall.length.ceil)
        y = wall.yi + wall.height * (i.to_f / wall.length.ceil)
        wall_particles << [x, y, RADIOUS, r, g, b, 0, 0]
      end
    end
    file.puts @particles.size + wall_particles.size
    file.puts "x y rad r g b vx vy"
    max_vx = @particles.map(&:vx).max
    max_vy = @particles.map(&:vy).max
    @particles.each do |p|
      red, green, blue = [0.5, Vector[p.vx, p.vy].magnitude / Vector[max_vx, max_vy].magnitude, 0.5]
      file.puts [p.x, p.y, p.r, red, green, blue, p.vx, p.vy].join(' ')
    end
    wall_particles.each do |p|
      file.puts p.join(' ')
    end
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
        particles_new << SiloParticle.new(p.id, x, y, vx, vy, p.mass, p.r)
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
      next unless inside_box(particle)
      row, col = particle_index(particle)
      debugger if ci.nil? || ci[row].nil?
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
    p.fy = p.mass * G
    return unless inside_box(p)
    neighbours(p).each do |p2|
      d = p.distance(p2)
      # next if r > CUT_R
      if d != 0.0
        # next if d < 0.1
        xi = p.r + p2.r - d
        # xi = 0 if xi < 0 || xi > 1
        enx = (p2.x - p.x) / d
        eny = (p2.y - p.y) / d
        en = [enx, eny]
        et = [-eny, enx]
        rrel = [p.vx - p2.vx, p.vy - p2.vy]
        rrelt = rrel[0] * et[0] + rrel[1] * et[1]
        fn = - KN * xi
        ft = - KT * xi * rrelt
        p.fx += fn * enx + ft * (-eny)
        p.fy += fn * eny + ft * enx
      end
    end

    # Wall force
    @walls.each do |wall|
      if wall.vertical?
        if (p.x - wall.xi).abs < p.r && p.y.between?(wall.yi, wall.yf)
          xi = p.r - (p.x - wall.xi).abs
          sign = sign(wall.xi - p.x)
          p.fx += - KN * xi * sign
          p.fy += KT * xi * p.vy * sign
        end
      elsif wall.horizontal?
        if (p.y - wall.yi).abs < p.r && p.x.between?(wall.xi, wall.xf)
          yi = p.r - (p.y - wall.yi).abs
          sign = sign(wall.yi - p.y)
          p.fy += - KN * yi * sign
          p.fx += KT * yi * p.vx * sign
        end
      end
    end
  end

  def sign(f)
    f <=> 0
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
    @particles.reduce(0) { |a, e| a + e.potential }
  end

  def kinematik
    @particles.reduce(0) { |a, e| a + e.kinematik }
  end

  def inside_box(p)
    p.x < WIDTH && p.x > 0 && p.y < HEIGHT && p.y > 0
  end

end
