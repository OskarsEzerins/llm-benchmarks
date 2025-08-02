class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small = small
    @medium = medium
    @large = large
  end

  def park(car)
    if car.type == 'small'
      @small -= 1
    elif