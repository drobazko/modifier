Dir['./lib/*.rb', './lib/rules/*.rb'].each {|f| require f }

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
      [ COMISSION_VALUES, ComissionValueRule.new(@cancellation_factor * @saleamount_factor) ]
    ]
  end

  def proceed(*input_enumerator)
    combiner = Combiner.new { |value| value[KEYWORD_UNIQUE_ID] }.combine(*input_enumerator)

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

  def find_rule(key)
    @rules.find{ |rule| rule[0].include?(key) }[1]
  end

  def combine_values(hash)
    hash.map{ |k, v| [ k, find_rule(k).apply(v.compact) ] }.to_h
  end

  def combine_hashes(list_of_rows)
    result = {}
    list_of_rows
      .compact
      .reduce([]){|acc, v| acc + v.headers }.uniq.each do |key|
        result[key] = []
        list_of_rows.each do |row|
          result[key] << (row && row[key])
        end
      end
    result
  end
end