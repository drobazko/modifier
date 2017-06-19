# input:
# - two enumerators returning elements sorted by their key
# - block calculating the key for each element
# - block combining two elements having the same key or a single element, if there is no partner
# output:
# - enumerator for the combined elements
class Combiner
	def initialize(&key_extractor)
		@key_extractor = key_extractor
	end

	def key(value)
		value && @key_extractor.call(value)
	end

	def combine(*enumerators)
		Enumerator.new do |yielder|
			last_values = Array.new(enumerators.size)
			while not enumerators.all?(&:nil?)
				last_values.each_with_index do |value, index|
					if value.nil? and enumerators[index]
						begin
							last_values[index] = enumerators[index].next
						rescue StopIteration
							enumerators[index] = nil
						end
					end
				end

				done = enumerators.all?(&:nil?) and last_values.compact.empty?
				unless done
					min_key = last_values.map { |e| key(e) }.compact.min
					values = Array.new(last_values.size)
					last_values.each_with_index do |value, index|
						if key(value) == min_key
							values[index] = value
							last_values[index] = nil
						end
					end
					yielder.yield(values)
				end
			end
		end
	end
end