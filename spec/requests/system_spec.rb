require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/system" do
  before(:each) do
    @response = request("/system")
  end
end