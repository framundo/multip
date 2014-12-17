class WalkerSystem
  require 'matrix'
  attr_reader :particles

  WIDTH = 50.0 # m
  HEIGHT = 30.0 # m

  # RADIOUS = 0.5
  RADIOUS = 0.25 # m
  MASS = 70.0 # kg
  KN = 10.0 ** 5
  KT = 0.0001 * KN
  DELTA_T = 0.5 * Math.sqrt(MASS/KN)
  DELTA_T_2 = DELTA_T ** 2
  CUT_R = 3.0 * RADIOUS

  TAU = 0.5

  A = 1800
  B = 0.09

  BLUE = [0.0, 0.0, 1.0]
  RED = [1.0, 0.0, 0.0]
  GRAY = [0.5, 0.5, 0.5]

  def initialize(n, distance)
    @particles = []
    @walls = []
    @walls << WalkerWall.new(0, 0, 0, HEIGHT, BLUE)
    @walls << WalkerWall.new(WIDTH, 0, WIDTH, HEIGHT, RED)
    # @walls << WalkerWall.new(0, 0, WIDTH, 0, GRAY)
    # @walls << WalkerWall.new(0, HEIGHT, WIDTH, HEIGHT, GRAY)
    (n*2).times do |i|
      x = y = nil
      loop do
        offset = i.even? ? 0 : WIDTH/2
        x = if i.even?
          Random.rand(RADIOUS .. WIDTH/2 - RADIOUS - distance/2)
        else
          Random.rand(WIDTH/2 + RADIOUS + distance/2 .. WIDTH - RADIOUS)
        end
        y = Random.rand(RADIOUS .. HEIGHT - RADIOUS)
        break if @particles.all? { |p| (x-p.x)**2 + (y-p.y)**2 > (RADIOUS*2)**2 }
      end
      @particles << WalkerParticle.new(i + 1, x, y, 0, 0, MASS, RADIOUS, i.even? ? RED : BLUE)
    end
    @cell_index = cell_index
    @particles.each { |p| force(p) }
    new_particles = @particles.map do |p|
      x = p.x + DELTA_T * p.vx + DELTA_T_2 * p.ax / 2
      vx = p.vx + DELTA_T / p.mass * p.fx
      y = p.y + DELTA_T * p.vy + DELTA_T_2 * p.ay / 2
      vy = p.vy + DELTA_T / p.mass * p.fy
      WalkerParticle.new(p.id, x, y, vx, vy, p.mass, p.r, p.color)
    end
    @particles_old = @particles
    @particles = new_particles
  end

  def save_snapshot(file)
    wall_particles = []
    @walls.each do |wall|
      (wall.length/(RADIOUS*2.0)).ceil.times do |i|
        r, g, b = wall.color
        x = wall.xi + wall.width * (i * RADIOUS * 2.0 / wall.length.ceil)
        y = wall.yi + wall.height * (i * RADIOUS * 2.0 / wall.length.ceil)
        wall_particles << [x, y, RADIOUS, r, g, b, 0, 0]
      end
    end
    file.puts @particles.size + wall_particles.size
    file.puts "x y rad r g b vx vy"
    max_vx = @particles.map(&:vx).max
    max_vy = @particles.map(&:vy).max
    @particles.each do |p|
      red, green, blue = p.color
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
        if in_goal?(p)
          particles_new << p
        else
          old_p = @particles_old[i]
          vx = p.vx + DELTA_T * p.fx / p.mass
          vy = p.vy + DELTA_T * p.fy / p.mass
          x = p.x + DELTA_T * vx
          y = p.y + DELTA_T * vy
          particles_new << WalkerParticle.new(p.id, x, y, vx, vy, p.mass, p.r, p.color)
        end
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
      # next unless inside_box(particle)
      row, col = particle_index(particle)
      next if ci.nil? || ci[row].nil?
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
    p.fx = 0.0
    p.fy = 0.0
    # return if dead
    return if in_goal?(p)
    driving_force(p)
    social_force(p)

    # Wall force
    # @walls.each do |wall|
    #   if wall.vertical?
    #     if (p.x - wall.xi).abs < p.r && p.y.between?(wall.yi, wall.yf)
    #       xi = p.r - (p.x - wall.xi).abs
    #       sign = sign(wall.xi - p.x)
    #       p.fx += - KN * xi * sign
    #       p.fy += KT * xi * p.vy * sign
    #     end
    #   elsif wall.horizontal?
    #     if (p.y - wall.yi).abs < p.r && p.x.between?(wall.xi, wall.xf)
    #       yi = p.r - (p.y - wall.yi).abs
    #       sign = sign(wall.yi - p.y)
    #       p.fy += - KN * yi * sign
    #       p.fx += KT * yi * p.vx * sign
    #     end
    #   end
    # end
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

  # Force = A * exp ** (ξ / B) * eij
  def social_force(p)
    return if p.dead?
    fx = 0.0
    fy = 0.0
    @particles.select { |p2| p2.id != p.id && !p2.dead? }.each do |p2|
      d = p.distance(p2)
      xi = p.r + p2.r - d
      delta_x = -(p2.x - p.x)
      delta_y = -(p2.y - p.y)
      mod = Math.sqrt(delta_x ** 2 + delta_y ** 2)
      e_x = delta_x / mod
      e_y = delta_y / mod
      fx += A * Math::E ** (xi / B) * e_x
      fy += A * Math::E ** (xi / B) * e_y
    end
    p.fx += fx
    p.fy += fy
  end

  # Force = Mass * (vdi * e - vi) / TAU
  def driving_force(p)
    driving_v = p.vd
    driving_v = 0 if p.dead?
    delta_x = (p.dx - p.x)
    delta_y = (p.dy - p.y)
    mod = Math.sqrt(delta_x ** 2 + delta_y ** 2)
    e_x = delta_x / mod
    e_y = delta_y / mod
    fx = p.mass * (driving_v * e_x - p.vx) / TAU
    fy = p.mass * (driving_v * e_y - p.vy) / TAU
    p.fx += fx
    p.fy += fy
  end

  def in_goal?(p)
    return true if p.blue? && p.x <= p.r
    return true if p.red? && p.x >= WIDTH - p.r
    false
  end

  def all_in_goal?
    @particles.all? { |p| in_goal?(p) }
  end

end
