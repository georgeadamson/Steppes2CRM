require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/timeline_styles" do
  before(:each) do
    @response = request("/timeline_styles")
  end
end