require 'spec_helper'

require 'rbeapi/client'
require 'rbeapi/api/system'

describe Rbeapi::Api::System do
  subject { described_class.new(node) }

  let(:node) do
    Rbeapi::Client.config.read(fixture_file('dut.conf'))
    Rbeapi::Client.connect_to('dut')
  end

  describe '#get' do
    let(:entity) do
      { hostname: 'localhost' }
    end

    before { node.config('hostname localhost') }

    it 'returns the snmp resource' do
      expect(subject.get).to eq(entity)
    end
  end

  describe '#set_system' do
    before { node.config('hostname localhost') }

    it 'configures the system hostname value' do
      expect(subject.get[:hostname]).to eq('localhost')
      expect(subject.set_hostname(value: 'foo')).to be_truthy
      expect(subject.get[:hostname]).to eq('foo')
    end

    it 'configures the system hostname with a dot value' do
      expect(subject.get[:hostname]).to eq('localhost')
      expect(subject.set_hostname(value: 'foo.bar')).to be_truthy
      expect(subject.get[:hostname]).to eq('foo.bar')
    end

    it 'negates the hostname' do
      expect(subject.set_hostname(enable: false)).to be_truthy
      expect(subject.get[:hostname]).to be_empty
    end

    it 'defaults the hostname' do
      expect(subject.set_hostname(default: true)).to be_truthy
      expect(subject.get[:hostname]).to be_empty
    end
  end
end
