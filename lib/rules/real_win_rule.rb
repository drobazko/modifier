class RealWinRule
  def apply(val)
    val.select {|v| not (v.nil? or v == 0 or v == '0' or v == '')}.last
  end
end
