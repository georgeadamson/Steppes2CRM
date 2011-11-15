require 'spec_helper'

describe "merb-param-protection" do
  describe "Controller" do
    it "should store the accessible parameters for that controller" do
      dispatch_to(ParamsAccessibleController, :create).send(:accessible_params_args).should == {
        :address=> [:street, :zip], :post=> [:title, :body], :customer=> [:name, :phone, :email]
      }
    end
      
    it "should store the protected parameters for that controller" do
      dispatch_to(ParamsProtectedController, :create).send(:protected_params_args).should == {
        :address=> [:long, :lat], :customer=> [:activated?, :password]
      }
    end

    it "should remove the parameters from the request that are not accessible" do
      c = dispatch_to(ParamsAccessibleController, :create,
        :customer => {:name => "teamon", :phone => "123456789", :email => "my@mail", :activated? => "yes", :password => "secret"}, 
        :address => {:street => "Merb Street 4", :zip => "98765", :long => "Meeeeerrrrrrbbbb sooo looong", :lat => "123"},
        :post => {:title => "First port", :body => "Some long lorem ipsum stuff", :date => "today"}
      )
      c.params[:customer][:name].should == "teamon"
      c.params[:customer][:phone].should == "123456789"
      c.params[:customer][:email].should == "my@mail"
      c.params[:customer].should_not have_key(:activated?)
      c.params[:customer].should_not have_key(:password)
      c.params[:address][:street].should == "Merb Street 4"
      c.params[:address][:zip].should == "98765"
      c.params[:address].should_not have_key(:long)
      c.params[:address].should_not have_key(:lat)
      c.params[:post][:title].should == "First port"
      c.params[:post][:body].should == "Some long lorem ipsum stuff"
      c.params[:post].should_not have_key(:date)
    end
    
    it "should remove the parameters from the request that are protected" do
      c = dispatch_to(ParamsProtectedController, :create,
        :customer => {:name => "teamon", :phone => "123456789", :email => "my@mail", :activated? => "yes", :password => "secret"}, 
        :address => {:street => "Merb Street 4", :zip => "98765", :long => "Meeeeerrrrrrbbbb sooo looong", :lat => "123"},
        :post => {:title => "First port", :body => "Some long lorem ipsum stuff", :date => "today"}
      )
      c.params[:customer][:name].should == "teamon"
      c.params[:customer][:phone].should == "123456789"
      c.params[:customer][:email].should == "my@mail"
      c.params[:customer].should_not have_key(:activated?)
      c.params[:customer].should_not have_key(:password)
      c.params[:address][:street].should == "Merb Street 4"
      c.params[:address][:zip].should == "98765"
      c.params[:address].should_not have_key(:long)
      c.params[:address].should_not have_key(:lat)
      c.params[:post][:title].should == "First port"
      c.params[:post][:body].should == "Some long lorem ipsum stuff"
      c.params[:post][:date].should == "today"
    end
  end

  describe "param clash prevention" do
    it "should raise an error 'cannot make accessible'" do
      lambda {
        class TestAccessibleController < Merb::Controller
          params_protected :customer => [:password]
          params_accessible :customer => [:name, :phone, :email]
          def index; end
        end
      }.should raise_error(/Cannot make accessible a controller \(.*?TestAccessibleController\) that is already protected/)
    end

    it "should raise an error 'cannot protect'" do
      lambda {
        class TestProtectedController < Merb::Controller
          params_accessible :customer => [:name, :phone, :email]
          params_protected :customer => [:password]
          def index; end
        end
      }.should raise_error(/Cannot protect controller \(.*?TestProtectedController\) that is already accessible/)
    end
  end
    
  describe "param filtering" do
    it "should remove specified params" do
      post_body = "post[title]=hello%20there&post[body]=some%20text&post[status]=published&post[author_id]=1&commit=Submit"
      request = fake_request( {:request_method => 'POST'}, {:post_body => post_body})
      request.remove_params_from_object(:post, [:status, :author_id])
      request.params[:post][:title].should == "hello there"
      request.params[:post][:body].should == "some text"
      request.params[:post][:status].should_not == "published"
      request.params[:post][:author_id].should_not == 1
      request.params[:commit].should == "Submit"
    end

    it "should restrict parameters" do
      post_body = "post[title]=hello%20there&post[body]=some%20text&post[status]=published&post[author_id]=1&commit=Submit"
      request = fake_request( {:request_method => 'POST'}, {:post_body => post_body})
      request.restrict_params(:post, [:title, :body])
      request.params[:post][:title].should == "hello there"
      request.params[:post][:body].should == "some text"
      request.params[:post][:status].should_not == "published"
      request.params[:post][:author_id].should_not == 1
      request.params[:commit].should == "Submit"
      request.trashed_params.should == {"status"=>"published", "author_id"=>"1"}
    end
  end
  
  it "should not have any plugin methods accidently exposed as actions" do
    Merb::Controller.callable_actions.should be_empty
  end

  describe "log params filtering" do
    it "should filter params" do
      c = dispatch_to(LogParamsFiltered, :index, :password => "topsecret", :password_confirmation => "topsecret",
                                                 :card_number => "1234567890", :other => "not so secret")
      c.params[:password].should == "topsecret"
      c.params[:password_confirmation].should == "topsecret"
      c.params[:card_number].should == "1234567890"
      c.params[:other].should == "not so secret"
      
      filtered = c.class._filter_params(c.params)
      filtered["password"].should == "[FILTERED]"
      filtered["password_confirmation"].should == "[FILTERED]"
      filtered["card_number"].should == "[FILTERED]"
      filtered["other"].should == "not so secret"
    end
  end

end




