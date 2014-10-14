require_relative 'particle'
module Ps
  class ParticleSystem
    attr_reader :particles

    def initialize(static_file, dynamic_file, m, radious, periodic_cont = false)
      @m, @radious, @periodic_cont = m, radious, periodic_cont
      particle_params = []
      File.open(static_file).each_with_index do |line, i|
        case
        when i == 0
          @n = line.to_f
        when i == 1
          @length = line.to_f
          @m = infer_m if @m.nil?
        when i-2 < @n
          r, c = line.split.map(&:to_f)
          particle_params[i-2] = { color: c, radious: r }
        end
      end
      File.open(dynamic_file).each_with_index do |line, i|
        if i > 0 && i <= @n
          particle_params[i-1][:x], particle_params[i-1][:y] = line.split.map(&:to_f)
        end
      end
      @particles = []
      particle_params.each_with_index do |p, i|
        @particles << Ps::Particle.new(i+1 ,p[:x], p[:y], p[:radious], p[:color])
      end
    end

    def to_s
      @particles.to_s
    end

    def brute_force_neighbours(particle)
      @particles.each_with_object(Set.new) do |p, n|
        n << p if (particle != p) && particle.distance(p, @periodic_cont ? @length : nil) < @radious
      end
    end

    def neighbours(particle)
      ci = cell_index
      row, col = particle_index(particle)
      n = Set.new
      n_rows, n_cols = [], []
      n_rows << row
      n_cols << col
      if @periodic_cont
        n_rows << @m-1 if row == 0
        n_rows << 0 if row == @m-1
        n_cols << @m-1 if col == 0
        n_cols << 0 if col == @m-1
      end
      n_rows << row-1 if row > 0
      n_rows << row+1 if row < @m - 1
      n_cols << col-1 if col > 0
      n_cols << col+1 if col < @m -1
      n_rows.each do |r|
        n_cols.each do |c|
          particles = ci[r][c]
          particles.each do |p|
            n << p if (particle != p) && particle.distance(p, @periodic_cont ? @length : nil) < @radious
          end
        end
      end
      n
    end

    def export(particle, brute = false)
      n = {}
      Benchmark.bm do |x|
        x.report do
          particles.each do |p|
            n[p.id] = if brute then brute_force_neighbours(particle) else neighbours(particle) end
          end
        end
      end

      File.open('export.xyz', 'w') do |file|
        file.puts particles.size
        file.puts 'x y rad r g b'
        puts "Neighbours found: #{n[particle.id].size}"
        n[particle.id].each do |p|
          dis = p.distance(particle, @periodic_cont ? @length : nil)
          puts "#{p.id} (#{dis})"
        end

        particles.each do |p|
          color = case
          when n.include?(p)
            [0, 0, 255]
          when p == particle
            [255, 0, 0]
          else
            [255, 255, 255]
          end
          file.puts "#{p.x} #{p.y} #{p.r} #{color.join(' ')}"
        end
      end
    end

    def save_snapshot(file)
      file.puts @particles.size
      file.puts "x y r g b vx vy"
      @particles.each do |p|
        red = Math.sin(p.angle) * 0.5 + 0.5
        green = Math.cos(p.angle) * 0.5 + 0.5
        file.puts [p.x, p.y, red, green, 1.0, p.vx, p.vy].join(' ')
      end
    end

    def move
      @particles.each do |p|
        p.x += p.vx
        p.y += p.vy
        if @periodic_cont
          p.x = p.x % @length
          p.y = p.y % @length
        end
      end
    end

    protected
    def cell_index
      ci = []
      @m.times do |i|
        ci[i] = []
        @m.times do |j|
          ci[i][j] = []
        end
      end
      @particles.each do |particle|
        row, col = particle_index(particle)
        ci[row][col] << particle
      end
      ci
    end

    def cell_size
      @length / @m
    end

    def particle_index(particle)
      [ (particle.y / cell_size).to_i, (particle.x / cell_size).to_i ]
    end

    def infer_m
      (@length.to_f / @radious).floor
    end
  end
end
