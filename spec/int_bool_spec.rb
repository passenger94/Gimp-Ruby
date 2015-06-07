
require_relative 'helper_spec'

describe Integer do
  describe "#to_bool" do
    subject {gimp_boolean}  
    let(:gimp_boolean) { 1 } 
#    it { expect(gimp_boolean.to_bool).to eq(true) }
    it "should give a ruby boolean" do
        expect(gimp_boolean.to_bool).to eq(true)
    end
  end
end

