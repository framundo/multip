module Ps
  class MoleculeSystem
    require 'matrix'
    attr_reader :particles

    WIDTH = 0.24 # m
    HEIGHT = 0.09 # m
    GATE = 0.006 # m
    EPS = Float::EPSILON # m
    RAD = 0.005

    def initialize(n, radious, velocity, mass)
      @particles = []
      n.times do |i|
        x = y = nil
        loop do
          x = Random.rand((radious) .. (WIDTH/2 - radious))
          y = Random.rand((radious) .. (HEIGHT - radious))
          break if @particles.all? { |p| (x-p.x)**2 + (y-p.y)**2 > (radious*2)**2 }
        end
        p = Particle.new(i + 1, x, y, radious, [1.0 - i.to_f/n, i.to_f/n, i.to_f ** 2/n])
        p.mass = mass
        angle = Random.rand(-Math::PI/2 .. Math::PI/2)
        p.vx = velocity * Math.cos(angle)
        p.vy = velocity * Math.sin(angle)
        @particles << p
      end
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

    def next_colission_time
      colission_time = [Float::INFINITY, nil]
      @particles.each do |p|
        particle_colissions = []
        # Horizontal colission
        if p.vx > 0
          if p.x > WIDTH / 2
            particle_colissions << (WIDTH - p.r - p.x) / p.vx
          else
            time = (WIDTH/2 - p.r - p.x) / p.vx
            particle_colissions << time if (p.y + p.vy * time - HEIGHT/2).abs > GATE/2
          end
        elsif p.vx < 0
          if p.x < WIDTH / 2
            particle_colissions << (0 + p.r - p.x) / p.vx
          else
            time = (WIDTH/2 + p.r - p.x) / p.vx
            particle_colissions << time if (p.y + p.vy * time - HEIGHT/2).abs > GATE/2
          end
        end

        # Vertical colission
        particle_colissions << (HEIGHT - p.r - p.y) / p.vy if p.vy > 0
        particle_colissions << (0 + p.r - p.y) / p.vy if p.vy < 0

        # Particles colission
        partile_collider = []
        neighbours(p).each do |p2|
          dr = Vector[p2.x - p.x, p2.y - p.y]
          dv = Vector[p2.vx - p.vx, p2.vy - p.vy]
          vr = dv.inner_product(dr)
          next if vr >= 0
          vv = dv.inner_product(dv)
          s = (p.r + p2.r)
          d = vr ** 2 - vv * (dr.inner_product(dr) - s**2)
          next if d < 0
          particle_colissions << - (vr + Math.sqrt(d)) / vv
          partile_collider << p2
        end
        time = particle_colissions.min
        if time > 0 && time < colission_time.first
          colission_time = [time, p, partile_collider]
        end
      end
      colission_time
    end

    def move(step)
      loop do
        time, p , colliders = next_colission_time
        time = [time, step].min
        @particles.each do |p|
          p.x += p.vx * time
          p.y += p.vy * time
        end

        # Horizontal colission
        p.vx *= -1 if p.x + p.r >= WIDTH - EPS || p.x - p.r <= EPS
        p.vx *= -1 if (p.x - WIDTH/2).abs <= p.r + EPS && (p.y - HEIGHT/2).abs > GATE/2
        # Vertical colission
        p.vy *= -1 if p.y + p.r >= HEIGHT - EPS || p.y - p.r <= EPS
        # Particles colission
        colliders.each do |p2|
          next unless p != p2 && (p2.x-p.x)**2 + (p2.y-p.y)**2 - (p.r + p2.r)**2 < EPS
          # en_before = p.energy + p2.energy
          dr = Vector[p2.x - p.x, p2.y - p.y]
          dv = Vector[p2.vx - p.vx, p2.vy - p.vy]
          vr = dv.inner_product(dr)
          s = (p.r + p2.r)
          j = 2 * p.mass * p2.mass * vr / (s * (p.mass + p2.mass))
          jx = j * (p2.x - p.x) / s
          jy = j * (p2.y - p.y) / s

          p.vx += jx/p.mass
          p.vy += jy/p.mass

          p2.vx -= jx/p2.mass
          p2.vy -= jy/p2.mass
          # en_after = p.energy + p2.energy
          # puts "Colission before: #{en_before} after: #{en_after}"
        end
        step -= time
        break if step <= 0
      end
    end

    def fraction
      @particles.select { |p| p.x > WIDTH/2 }.size.to_f / @particles.size
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

    def particle_index(particle)
      [ (particle.y / cell_height).to_i, (particle.x / width_cells).to_i ]
    end

    def height_cells
      (HEIGHT.to_f / RAD).floor
    end

    def width_cells
      (WIDTH.to_f / RAD).floor
    end

    def cell_width
      WIDTH / width_cells
    end

    def cell_height
      HEIGHT / height_cells
    end

    def neighbours(particle)
      ci = cell_index
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
          particles = ci[r][c]
          particles.each do |p|
            n << p if (particle != p) && particle.distance(p, nil) < RAD
          end
        end
      end
      n
    end

  end
end
