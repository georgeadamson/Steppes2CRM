require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Controller, " redirects" do
  it "redirects with simple URLs" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::SimpleRedirect, :index)
    @controller.status.should == 302
    @controller.headers["Location"].should == "/"
  end

  it "redirects if passed in via throw :halt" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::RedirectViaHalt, :index)
    @controller.status.should == 302
    @controller.headers["Location"].should == "/"
  end

  it "permanently redirects" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::PermanentRedirect, :index)
    @controller.status.should == 301
    @controller.headers["Location"].should == "/"
  end

  it "recirect with :permanent and :stauts use :status" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::PermanentAndStatusRedirect, :index)
    @controller.status.should == 302
    @controller.headers["Location"].should == "/"
  end

  it "redirect with status" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::WithStatusRedirect, :index)
    @controller.status.should == 307
    @controller.headers["Location"].should == "/"
  end

  it "redirects with messages" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::RedirectWithMessage, :index)
    @controller.status.should == 302
    expected_url = Merb::Parse.escape([Marshal.dump(:notice => "what?")].pack("m"))
    @controller.headers["Location"].should == "/?_message=#{expected_url}"
  end
  
  it "redirects with message and fragment" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::RedirectWithMessageAndFragment, :index)
    @controller.status.should == 302
    expected_url = Merb::Parse.escape([Marshal.dump(:notice => "what?")].pack("m"))
    @controller.headers["Location"].should == "/?_message=#{expected_url}#someanchor"
  end
  
  it "redirects with short style using :notice" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::RedirectWithNotice, :index)
    @controller.status.should == 302
    expected_url = Merb::Parse.escape([Marshal.dump(:notice => "what?")].pack("m"))
    @controller.headers["Location"].should == "/?_message=#{expected_url}"
  end

  it "redirects with short style using :error" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::RedirectWithError, :index)
    @controller.status.should == 302
    expected_url = Merb::Parse.escape([Marshal.dump(:error => "errored!")].pack("m"))
    @controller.headers["Location"].should == "/?_message=#{expected_url}"
  end

  it "consumes redirects with messages" do
    message = Merb::Parse.escape([Marshal.dump(:notice => "what?")].pack("m"))
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConsumesMessage, :index, {:_message => message})
    @controller.body.should == "\"what?\""
  end
  
  it "supports setting the message for use immediately" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::SetsMessage, :index)
    @controller.body.should == "Hello"
  end

  it "handles malformed message" do
    message = Merb::Parse.escape([Marshal.dump(:notice => "what?")].pack("m"))
    message = message.reverse
    lambda do
      @controller = dispatch_to(Merb::Test::Fixtures::Controllers::SetsMessage, :index, {:_message => message})
    end.should_not raise_error(TypeError)
  end
end
