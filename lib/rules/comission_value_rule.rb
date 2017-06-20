class ComissionValueRule
  def initialize(multiplied_factor)
    @multiplied_factor = multiplied_factor
  end

  def apply(val)
    (@multiplied_factor * val[0].from_german_to_f).to_german_s 
  end
end
