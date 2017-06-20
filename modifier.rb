require File.expand_path('lib/combiner', File.dirname(__FILE__))
require File.expand_path('lib/workspace_handler', File.dirname(__FILE__))

class String
  def from_german_to_f
    self.gsub(',', '.').to_f
  end
end

class Float
  def to_german_s
    self.to_s.gsub('.', ',')
  end
end

class ValueWinRule
  def apply(val)
    val.last
  end
end

class RealWinRule
  def apply(val)
    val.select {|v| not (v.nil? or v == 0 or v == '0' or v == '')}.last
  end
end

class IntRule
  def apply(val)
    val[0].to_s
  end
end

class FloatRule
  def apply(val)
    val[0].from_german_to_f.to_german_s
  end
end

class ComissionNumberRule
  def initialize(cancellation_factor)
    @cancellation_factor = cancellation_factor
  end

  def apply(val)
    (@cancellation_factor * val[0].from_german_to_f).to_german_s
  end
end 

class ComissionValueRules
  def initialize(multiplied_factor)
    @multiplied_factor = multiplied_factor
  end

  def apply(val)
    (@multiplied_factor * val[0].from_german_to_f).to_german_s 
  end
end

class Modifier
  KEYWORD_UNIQUE_ID = 'Keyword Unique ID'
  LAST_VALUE_WINS = ['Account ID', 'Account Name', 'Campaign', 'Ad Group', 'Keyword', 'Keyword Type', 'Subid', 'Paused', 'Max CPC', 
    'Keyword Unique ID', 'ACCOUNT', 'CAMPAIGN', 'BRAND', 'BRAND+CATEGORY', 'ADGROUP', 'KEYWORD']
  LAST_REAL_VALUE_WINS = ['Last Avg CPC', 'Last Avg Pos']
  INT_VALUES = ['Clicks', 'Impressions', 'ACCOUNT - Clicks', 'CAMPAIGN - Clicks', 'BRAND - Clicks', 'BRAND+CATEGORY - Clicks', 
    'ADGROUP - Clicks', 'KEYWORD - Clicks']
  FLOAT_VALUES = ['Avg CPC', 'CTR', 'Est EPC', 'newBid', 'Costs', 'Avg Pos']
  COMISSION_NUMBERS = ['number of commissions']
  COMISSION_VALUES = ['Commission Value', 'ACCOUNT - Commission Value', 'CAMPAIGN - Commission Value', 'BRAND - Commission Value', '
      BRAND+CATEGORY - Commission Value', 'ADGROUP - Commission Value', 'KEYWORD - Commission Value']

  def initialize(saleamount_factor:, cancellation_factor:)
    @saleamount_factor = saleamount_factor
    @cancellation_factor = cancellation_factor

    @rules = [
      [ LAST_VALUE_WINS, ValueWinRule.new ],
      [ LAST_REAL_VALUE_WINS, RealWinRule.new ],
      [ INT_VALUES, IntRule.new ],
      [ FLOAT_VALUES, FloatRule.new ],
      [ COMISSION_NUMBERS, ComissionNumberRule.new(@cancellation_factor) ],
      [ COMISSION_VALUES, ComissionValueRules.new(@cancellation_factor * @saleamount_factor) ]
    ]
  end

  def proceed(input_enumerator)
    combiner = Combiner.new { |value| value[KEYWORD_UNIQUE_ID] }.combine(input_enumerator)

    Enumerator.new do |yielder|
      while true
        begin
          list_of_rows = combiner.next
          merged = combine_hashes(list_of_rows)
          yielder.yield(combine_values(merged))
        rescue StopIteration
          break
        end
      end
    end
  end

  private

  def combine(merged)
    merged.map{|_, hash| combine_values(hash) }
  end

  def find_rule(key)
    @rules.find{ |rule| rule[0].include?(key) }[1]
  end

  def combine_values(hash)
    hash.map{ |k, v| [ k, find_rule(k).apply(v) ] }.to_h
  end

  def combine_hashes(list_of_rows)
    keys = []
    list_of_rows.each do |row|
      next if row.nil?
      row.headers.each do |key|
        keys << key
      end
    end
    result = {}
    keys.each do |key|
      result[key] = []
      list_of_rows.each do |row|
        result[key] << (row.nil? ? nil : row[key])
      end
    end
    result
  end
end

workspace = WorkspaceHandler.new
modifier = Modifier.new(saleamount_factor: 1, cancellation_factor: 0.4)
modified_data = modifier.proceed( workspace.latest_file.sort.lazy_read )
workspace.output_with_pagination modified_data
puts "DONE modifying"
