class ComissionNumberRule
  def initialize(cancellation_factor)
    @cancellation_factor = cancellation_factor
  end

  def apply(val)
    (@cancellation_factor * val[0].from_german_to_f).to_german_s
  end
end 
