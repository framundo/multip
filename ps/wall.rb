class Wall
  attr_reader :xi, :yi, :xf, :yf

  def initialize(xi, yi, xf, yf)
    @xi, @yi, @xf, @yf = xi, yi, xf, yf
  end

  def length
    (Vector[@xf, @yf] - Vector[@xi, @yi]).magnitude
  end

  def width
    xf - xi
  end

  def height
    yf - yi
  end

  def horizontal?
    height == 0
  end

  def vertical?
    width == 0
  end
end