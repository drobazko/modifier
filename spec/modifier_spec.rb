Dir['../lib/*.rb', '../lib/rules/*.rb'].each {|f| require f }
require_relative 'spec_helper'
require './modifier'
require 'csv'

# one field from every modification group
FIELDS = ['Keyword Unique ID', 'Account ID', 'Last Avg CPC', 'Clicks', 'CTR', 'number of commissions', 'Commission Value']

def enumerator_for(arr)
  Enumerator.new do |yielder|
    arr.each{ |r| yielder.yield(CSV::Row.new(FIELDS, r)) }
  end
end

def read_from_enumerator_and_map(enum)
  read_from_enumerator(enum).map(&:values)
end

describe Modifier do
  context '#proceed' do
    let(:input1) {
      [
        [ '3',  'acc3',  'an3',  'cpc3', '30',  '300', '30.30'  ],
        [ '2', 'acc22', 'an22', 'cpc22', '22', '2200', '220.20' ],
      ]      
    }
    let(:input2) {
      [
        [ '3', 'acc33', 'an33', 'cpc33', '330', '3300', '330.30' ],
        [ '2',  'acc2',  'an2',  'cpc2',   '2',  '220',  '22.20' ],
      ]      
    }
    let(:input3) {
      [
        [ '2',  'acc2',  'an2',  'cpc2',   '2',  '220',  '22.20' ],
      ]      
    }
    let(:result1) {
      [
        [ '3',  'acc3',  'an3',  'cpc3', '30,0',  '150,0', '15,15' ], 
        [ '2', 'acc22', 'an22', 'cpc22', '22,0', '1100,0', '110,1' ]
      ]
    }
    let(:result2) {
      [
        [ '3', 'acc33', 'an33',  'cpc3', '30,0',  '150,0', '15,15' ], 
        [ '2',  'acc2',  'an2', 'cpc22', '22,0', '1100,0', '110,1' ]
      ]
    }
    let(:result3) {
      [
        [ '2',  'acc2',  'an2',  'cpc2',  '2,0',  '110,0',  '11,1'  ],
        [ '3',  'acc3',  'an3',  'cpc3', '30,0',  '150,0', '15,15'  ],
        [ '2', 'acc22', 'an22', 'cpc22', '22,0', '1100,0',  '110,1' ]
      ]
    }
    context "#proceed with single input" do
      subject { Modifier.new(saleamount_factor: 1, cancellation_factor: 0.5).proceed(enumerator_for(input1)) }
      it "should proceed with converting values according rules without any merging" do
        expect(read_from_enumerator_and_map(subject)).to eq(result1)
      end
    end

    context "#proceed with couple of 'equal' inputs" do
      subject { Modifier.new(saleamount_factor: 1, cancellation_factor: 0.5).proceed(enumerator_for(input1), enumerator_for(input2)) }
      it "should proceed with merging and converting the same key values" do
        expect(read_from_enumerator_and_map(subject)).to eq(result2)
      end
    end

    context "#proceed with couple of not 'equal' inputs" do
      subject { Modifier.new(saleamount_factor: 1, cancellation_factor: 0.5).proceed(enumerator_for(input1), enumerator_for(input3)) }
      it "should proceed with merging and converting values" do
        expect(read_from_enumerator_and_map(subject)).to eq(result3)
      end
    end

  end
end 