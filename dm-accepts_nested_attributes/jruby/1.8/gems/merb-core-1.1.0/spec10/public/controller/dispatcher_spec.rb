require File.join(File.dirname(__FILE__), "spec_helper")

require File.join(File.dirname(__FILE__), "controllers", "dispatcher")

include Merb::Test::Fixtures::Controllers

describe Merb::Dispatcher do
  include Merb::Test::Rspec::ControllerMatchers
  include ::Webrat::Matchers
  include ::Webrat::HaveTagMatcher
  
  def status(response)
    response.status
  end
  
  def body(response)
    response.body.to_s
  end
  
  def headers(response)
    response.headers
  end
  
  def dispatch(url)
    rack = Merb::Dispatcher.handle(request_for(url))
    Struct.new(:status, :headers, :body, :url).new(rack[0], rack[1], rack[2], url)
  end

  def request_for(url)
    Merb::Request.new(Rack::MockRequest.env_for(url))
  end

  before(:each) do
    Merb::Config[:exception_details] = true
  end

  describe "with a regular route, " do
    before(:each) do
      Merb::Router.prepare do
        default_routes
      end
      @url = "/dispatch_to/index"
    end
  
    it "dispatches to the right controller and action" do
      body(dispatch(@url)).should == "Dispatched"
    end
    
    it "has the correct status code" do
      status(dispatch(@url)).should == 200
    end
    
    it "sets the Request#params to include the route params" do
      # FIXME
      request = request_for(@url)
      Merb::Dispatcher.handle(request)
      request.params.should == 
        {"controller" => "dispatch_to", "action" => "index", 
         "id" => nil, "format" => nil}
    end
    
    it "provides the time for start of request handling via Logger#info" do
      with_level(:info) do
        dispatch(@url)
      end.should include_log("Started request handling")
      
      with_level(:warn) do
        dispatch(@url)
      end.should_not include_log("Started request handling")
    end
    
    it "provides the routed params via Logger#debug" do
      with_level(:debug) do
        dispatch(@url)
      end.should include_log("Routed to:")
      
      with_level(:info) do
        dispatch(@url)
      end.should_not include_log("Routed to:")
    end
    
    it "provides the benchmarks via Logger#info" do
      with_level(:info) do
        dispatch(@url)
      end.should include_log(":after_filters_time")
      
      with_level(:warn) do
        dispatch(@url)
      end.should_not include_log(":after_filters_time")
    end
  end
  
  describe "with a route that redirects" do
    before(:each) do
      Merb::Router.prepare do
        match("/redirect/to/foo").redirect("/foo", :permanent => true)
        default_routes
      end
      @url = "/redirect/to/foo"
      @controller = dispatch(@url)
    end
    
    it "redirects" do
      body(@controller).should =~ %r{You are being <a href="/foo">redirected}
    end
    
    it "reports that it is redirecting via Logger#info" do
      with_level(:info) do
        dispatch(@url)
      end.should include_log("Dispatcher redirecting to: /foo (301)")
      
      with_level(:warn) do
        dispatch(@url)
      end.should_not include_log("Dispatcher redirecting to: /foo (301)")
    end
    
    it "sets the status correctly" do
      status(@controller).should == 301
    end
    
    it "sets the location correctly" do
      headers(@controller)["Location"].should == "/foo"
    end
  end
  
  describe "with a deferred route that redirects" do
    before(:each) do
      Merb::Router.prepare do
        match("/redirect/to/foo").defer_to do |request, params|
          redirect "/foo", :permanent => true
        end
        default_routes
      end
      @url = "/redirect/to/foo"
      @controller = dispatch(@url)
    end
    
    it "redirects" do
      body(@controller).should =~ %r{You are being <a href="/foo">redirected}
    end
    
    it "reports that it is redirecting via Logger#info" do
      with_level(:info) do
        dispatch(@url)
      end.should include_log("Dispatcher redirecting to: /foo (301)")
      
      with_level(:warn) do
        dispatch(@url)
      end.should_not include_log("Dispatcher redirecting to: /foo (301)")
    end
    
    it "sets the status correctly" do
      status(@controller).should == 301
    end
    
    it "sets the location correctly" do
      headers(@controller)["Location"].should == "/foo"
    end
  end
  
  describe "with a route that points to a class that is not a Controller, " do
    before(:each) do
      Merb::Router.prepare do
        default_routes
      end
      @url = "/not_a_controller/index"
      @controller = dispatch(@url)
    end
    
    describe "with exception details showing" do
      it "returns a 404 status" do
        status(@controller).should == 404
      end
      
      it "returns useful info in the body" do
        body(@controller).should =~
          %r{<h2>Controller 'Merb::Test::Fixtures::Controllers::NotAController' not found.</h2>}
      end
    end
    
    describe "when the action raises an Exception" do
      before(:each) do
        Object.class_eval <<-RUBY
          class Exceptions < Merb::Controller
            def gone
              "Gone"
            end
          end
        RUBY
      end
      
      after(:each) do
        Object.send(:remove_const, :Exceptions)
      end
      
      before(:each) do
        Merb::Router.prepare do
          default_routes
        end
        @url = "/raise_gone/index"
        @controller = dispatch(@url)
      end
      
      it "renders the action Exception#gone" do
        body(@controller).should == "Gone"
      end
      
      it "returns the status 410" do
        status(@controller).should == 410
      end
    end
    
    describe "when the action raises an Exception that has a superclass Exception available" do
      before(:each) do
        Object.class_eval <<-RUBY
          class Exceptions < Merb::Controller
            def client_error
              "ClientError"
            end
          end
        RUBY
      end
      
      after(:each) do
        Object.send(:remove_const, :Exceptions)
      end
      
      before(:each) do
        Merb::Router.prepare do
          default_routes
        end
        @url = "/raise_gone/index"
        @controller = dispatch(@url)
      end
      
      it "renders the action Exceptions#client_error since #gone is not defined" do
        body(@controller).should == "ClientError"
      end
      
      it "returns the status 410 (Gone) even though we rendered #client_error" do
        status(@controller).should == 410
      end
    end
  end
  
  describe "with a route that doesn't point to a Controller," do
    
    before(:each) do
      Merb::Router.prepare do
        match('/').register
      end
      
      @controller = dispatch("/")
    end
    
    describe "with exception details showing" do
    
      it "returns a 404 status" do
        status(@controller).should == 404
      end
      
      it "returns useful info in the body" do
        body(@controller).should =~
          %r{<h2>Route matched, but route did not specify a controller.</h2>}
      end
    end
    
    describe "when the action raises an Exception" do
      before(:each) do
        Object.class_eval <<-RUBY
          class Exceptions < Merb::Controller
            def gone
              "Gone"
            end
          end
        RUBY
      end
      
      after(:each) do
        Object.send(:remove_const, :Exceptions)
      end
      
      before(:each) do
        Merb::Router.prepare do
          default_routes
        end
        @url = "/raise_gone/index"
        @controller = dispatch(@url)
      end
      
      it "renders the action Exception#gone" do
        body(@controller).should == "Gone"
      end
      
      it "returns the status 410" do
        status(@controller).should == 410
      end
    end
    
    
  end
  
  describe "when the action raises an Error that is not a ControllerError" do
    before(:each) do
      Object.class_eval <<-RUBY
        class Exceptions < Merb::Controller
          def load_error
            "LoadError"
          end
        end
      RUBY
    end
    
    after(:each) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do
        default_routes
      end
      @url = "/raise_load_error/index"
      @controller = dispatch(@url)
    end
    
    it "renders Exceptions#load_error" do
      body(@controller).should == "LoadError"
    end
    
    it "returns a 500 status code" do
      status(@controller).should == 500
    end
  end

  describe "when the Exception action raises" do
    before(:each) do
      Object.class_eval <<-RUBY
        class Exceptions < Merb::Controller
          def load_error
            raise StandardError, "Big error"
          end
        end
      RUBY
    end
    
    after(:each) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do
        default_routes
      end
      @url = "/raise_load_error/index"
      @controller = dispatch(@url)
    end
    
    it "renders the default exception template" do
      body(@controller).should have_xpath("//h1[contains(.,'Standard Error')]")
      body(@controller).should have_xpath("//h2[contains(.,'Big error')]")

      body(@controller).should have_xpath("//h1[contains(.,'Load Error')]")
      body(@controller).should have_xpath("//h2[contains(.,'Big error')]")
    end
    
    it "returns a 500 status code" do
      status(@controller).should == 500
    end
  end


  describe "when the Exception action raises a NotFound" do
    before(:each) do
      Object.class_eval <<-RUBY
        class Exceptions < Merb::Controller
          def not_found
            raise NotFound, "Somehow, the thing you were looking for was not found."
          end
        end
      RUBY
    end
    
    after(:each) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do
        default_routes
      end
      @url = "/page/not/found"
      @controller = dispatch(@url)
    end
    
    it "renders the default exception template" do
      body(@controller).should have_xpath("//h1[contains(.,'Not Found')]")
      body(@controller).should have_xpath("//h2[contains(.,'Somehow, the thing')]")
    end
    
    it "returns a 404 status code" do
      status(@controller).should == 404
    end
  end

  describe "when the Exception action raises the same thing as the original failure" do
    before(:each) do
      Object.class_eval <<-RUBY
        class Exceptions < Merb::Controller
          def load_error
            raise LoadError, "Something failed here"
          end          
        end
      RUBY
    end
    
    after(:each) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do
        default_routes
      end
      @url = "/raise_load_error/index"
      @controller = dispatch(@url)
    end
    
    it "renders the default exception template" do
      body(@controller).should have_xpath("//h2[contains(.,'Something failed here')]")
    end
    
    it "returns a 500 status code" do
      status(@controller).should == 500
    end
  end

  describe "when more than one Exceptions methods raises an Error" do
    before(:each) do
      Object.class_eval <<-RUBY
        class Exceptions < Merb::Controller
          def load_error
            raise StandardError, "StandardError"
          end
          
          def standard_error
            raise Exception, "Exception"
          end
        end
      RUBY
    end
    
    after(:each) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do
        default_routes
      end
      @url = "/raise_load_error/index"
      @controller = dispatch(@url)
      @body = body(@controller)
    end
    
    it "renders a list of links to the traces" do
      @body.should have_xpath("//li//a[@href='#exception_0']")
      @body.should have_xpath("//li//a[@href='#exception_1']")
      @body.should have_xpath("//li//a[@href='#exception_2']")
    end
    
    it "renders the default exception template" do
      @body.should have_xpath("//h1[contains(.,'Load Error')]")
      @body.should have_xpath("//h2[contains(.,'In the controller')]")
      @body.should have_xpath("//h1[contains(.,'Standard Error')]")
      @body.should have_xpath("//h2[contains(.,'StandardError')]")
      @body.should have_xpath("//h1[contains(.,'Exception')]")
      @body.should have_xpath("//h2[contains(.,'Exception')]")
    end
    
    it "returns a 500 status code" do
      status(@controller).should == 500
    end
  end
  
  describe "dispatching to abstract controllers" do
    before(:each) do
      Object.class_eval <<-RUBY
        class AbstractOne < Merb::Controller
          abstract!
          def index; "AbstractOne#index"; end
        end
      
        class NotAbstract < AbstractOne
          def index; "NotAbstract#index"; end
        end
        
        class NormalController < Application
          def index; "NormalController#index"; end
        end
      RUBY
      class Application < Merb::Controller
        def method_for_abstract_test; "method_for_abstract_test"; end
      end
      Merb::Router.prepare do
        default_routes
      end
    end
    
    after(:each) do
      Object.class_eval do 
        remove_const(:AbstractOne)
        remove_const(:NotAbstract)
      end
      
      class Application < Merb::Controller
        undef method_for_abstract_test
      end
      
      # Merb::Router.prepare do
      #   default_routes
      # end      
    end
    
    it "should return a NotFound for an Application#method" do
      status(dispatch("/application/method_for_abstract_test")).should == 404
    end
    
    it "should have Application marked as abstract" do
      Application.should be_abstract
    end
    
    it "should have AbstractOne marked as abstract" do
      AbstractOne.should be_abstract
    end
    
    it "should return a NotFound for an abstract controllers method" do
      status(dispatch("/abstract_one/index")).should == 404
    end
    
    it "should return correctly for a normal controller" do
      result = dispatch("/normal_controller/index")
      status(result).should == 200
      body(result).should == "NormalController#index"
    end
    
    it "should return correctly for a controller that is inherited from an abstract controller" do
      result = dispatch("/not_abstract/index")
      status(result).should == 200
      body(result).should == "NotAbstract#index"
    end
    
    
    
  end
  
end