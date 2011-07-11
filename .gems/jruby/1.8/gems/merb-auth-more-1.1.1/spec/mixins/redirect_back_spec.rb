require 'spec_helper'
require 'merb-auth-more/mixins/redirect_back'


describe "every call to redirect_back", :shared => true do

  it "should set the return_to in the session when sent to the exceptions controller from a failed login" do
    r = request("/go_back")
    r.status.should == Merb::Controller::Unauthenticated.status
    r2 = login
    r2.should redirect_to(@return_to_after_failed_login)
  end

  it  "should not set the return_to in the session when deliberately going to unauthenticated" do
    r = login
    r.should redirect_to("/")
  end

  it "should still redirect to the original even if it's failed many times" do
    request("/go_back")
    request("/login", :method => "put", :params => {:pass_auth => false})
    request("/login", :method => "put", :params => {:pass_auth => false})
    request("/login", :method => "put", :params => {:pass_auth => false})
    r = login
    r.should redirect_to(@return_to_after_failed_login)
  end

  it "should not redirect back to a previous redirect back after being logged out" do
    request("/go_back")
    request("/login", :method => "put", :params => {:pass_auth => false})
    request("/login", :method => "put", :params => {:pass_auth => false})
    request("/login", :method => "put", :params => {:pass_auth => false})
    r = login
    r.should redirect_to(@return_to_after_failed_login)
    request("/logout", :method => "delete")
    r = login
    r.should redirect_to("/")
  end

end

describe "redirect_back" do

  before(:all) do
    Merb::Config[:exception_details] = true
    clear_strategies!
    Merb::Router.reset!
    Merb::Router.prepare do
      match("/login", :method => :get).to(:controller => "exceptions", :action => "unauthenticated").name(:login)
      match("/login", :method => :put).to(:controller => "sessions", :action => "update")
      match("/go_back").to(:controller => "my_controller")
      match("/").to(:controller => "my_controller")
      match("/logout", :method => :delete).to(:controller => "sessions", :action => "destroy")
    end

    class Merb::Authentication
      def store_user(user); user; end
      def fetch_user(session_info); session_info; end
    end

    # class MyStrategy < Merb::Authentication::Strategy; def run!; request.env["USER"]; end; end
    class MyStrategy < Merb::Authentication::Strategy
      def run!
        params[:pass_auth] = false if params[:pass_auth] == "false"
        params[:pass_auth]
      end
    end

    class Application < Merb::Controller; end

    class Exceptions < Merb::Controller
      include Merb::Authentication::Mixins::RedirectBack

      def unauthenticated; end

    end

    class Sessions < Merb::Controller
      before :ensure_authenticated
      def update
        redirect_back_or "/", :ignore => [url(:login)]
      end

      def destroy
        session.abandon!
      end
    end

    class MyController < Application
      before :ensure_authenticated
      def index
        "IN MY CONTROLLER"
      end
    end

  end

  def login
    request("/login", :method => "put", :params => {:pass_auth => true})
  end

  describe "without Merb::Config[:path_prefix]" do
    before(:all) do
      Merb::Config[:path_prefix] = nil
      @return_to_after_failed_login = '/go_back'
    end
    it_should_behave_like 'every call to redirect_back'
  end

  describe "without Merb::Config[:path_prefix]" do
    before(:all) do
      Merb::Config[:path_prefix] = '/myapp'
      @return_to_after_failed_login = '/myapp/go_back'
    end
    it_should_behave_like 'every call to redirect_back'
  end

end