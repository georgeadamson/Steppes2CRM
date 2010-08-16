class BigDecimal
  
  DEFAULT_STRING_FORMAT = 'F'
  
  def to_formatted_s(format = DEFAULT_STRING_FORMAT)
	_original_to_s(format)
  end
  
  alias_method :_original_to_s, :to_s
  alias_method :to_s, :to_formatted_s

end