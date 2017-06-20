Dir['./lib/float.rb', './lib/string.rb', './lib/rules/*.rb'].each {|f| require f }

rules = [
  { rule: ValueWinRule.new, in: [1, 2], expected: 2 },
  { rule: RealWinRule.new, in: [nil, 0, '0', '', 1, 2], expected: 2 },
  { rule: IntRule.new, in: [1, 2], expected: '1' },
  { rule: FloatRule.new, in: ['1.2', '1.3'], expected: '1,2' },
  { rule: ComissionNumberRule.new(0.5), in: ['100', '200'], expected: '50,0' },
  { rule: ComissionValueRule.new(0.5), in: ['100', '200'], expected: '50,0' }
]

rules.each do |r|
  describe r[:rule].class do
    context '#apply' do
      subject { r[:rule].apply(r[:in]) }
      it "Getting correct value after apply" do
        expect(subject).to eq(r[:expected])
      end
    end
  end
end