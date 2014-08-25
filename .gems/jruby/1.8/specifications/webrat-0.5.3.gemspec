# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{webrat}
  s.version = "0.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bryan Helmkamp"]
  s.date = %q{2009-08-27}
  s.description = %q{Webrat lets you quickly write expressive and robust acceptance tests
for a Ruby web application. It supports simulating a browser inside
a Ruby process to avoid the performance hit and browser dependency of
Selenium or Watir, but the same API can also be used to drive real
Selenium tests when necessary (eg. for testing AJAX interactions).
Most Ruby web frameworks and testing frameworks are supported.}
  s.email = %q{bryan@brynary.com}
  s.files = ["spec/fakes/test_adapter.rb", "spec/integration/mechanize/sample_app.rb", "spec/integration/mechanize/spec/mechanize_spec.rb", "spec/integration/mechanize/spec/spec_helper.rb", "spec/integration/merb/app/controllers/application.rb", "spec/integration/merb/app/controllers/exceptions.rb", "spec/integration/merb/app/controllers/testing.rb", "spec/integration/merb/config/environments/development.rb", "spec/integration/merb/config/environments/rake.rb", "spec/integration/merb/config/environments/test.rb", "spec/integration/merb/config/init.rb", "spec/integration/merb/config/rack.rb", "spec/integration/merb/config/router.rb", "spec/integration/merb/spec/spec_helper.rb", "spec/integration/merb/spec/webrat_spec.rb", "spec/integration/merb/tasks/merb.thor/app_script.rb", "spec/integration/merb/tasks/merb.thor/common.rb", "spec/integration/merb/tasks/merb.thor/gem_ext.rb", "spec/integration/merb/tasks/merb.thor/ops.rb", "spec/integration/merb/tasks/merb.thor/utils.rb", "spec/integration/rack/app.rb", "spec/integration/rack/test/helper.rb", "spec/integration/rack/test/webrat_rack_test.rb", "spec/integration/rails/app/controllers/application.rb", "spec/integration/rails/app/controllers/buttons_controller.rb", "spec/integration/rails/app/controllers/fields_controller.rb", "spec/integration/rails/app/controllers/links_controller.rb", "spec/integration/rails/app/controllers/webrat_controller.rb", "spec/integration/rails/app/helpers/buttons_helper.rb", "spec/integration/rails/app/helpers/fields_helper.rb", "spec/integration/rails/app/helpers/links_helper.rb", "spec/integration/rails/config/boot.rb", "spec/integration/rails/config/environment.rb", "spec/integration/rails/config/environments/development.rb", "spec/integration/rails/config/environments/selenium.rb", "spec/integration/rails/config/environments/test.rb", "spec/integration/rails/config/initializers/inflections.rb", "spec/integration/rails/config/initializers/mime_types.rb", "spec/integration/rails/config/initializers/new_rails_defaults.rb", "spec/integration/rails/config/routes.rb", "spec/integration/rails/test/integration/button_click_test.rb", "spec/integration/rails/test/integration/fill_in_test.rb", "spec/integration/rails/test/integration/link_click_test.rb", "spec/integration/rails/test/integration/webrat_test.rb", "spec/integration/rails/test/test_helper.rb", "spec/integration/sinatra/classic_app.rb", "spec/integration/sinatra/modular_app.rb", "spec/integration/sinatra/test/classic_app_test.rb", "spec/integration/sinatra/test/modular_app_test.rb", "spec/integration/sinatra/test/test_helper.rb", "spec/private/core/configuration_spec.rb", "spec/private/core/field_spec.rb", "spec/private/core/link_spec.rb", "spec/private/core/logging_spec.rb", "spec/private/core/session_spec.rb", "spec/private/mechanize/mechanize_adapter_spec.rb", "spec/private/merb/attaches_file_spec.rb", "spec/private/merb/merb_adapter_spec.rb", "spec/private/nokogiri_spec.rb", "spec/private/rails/attaches_file_spec.rb", "spec/private/rails/rails_adapter_spec.rb", "spec/private/selenium/application_servers/rails_spec.rb", "spec/public/basic_auth_spec.rb", "spec/public/check_spec.rb", "spec/public/choose_spec.rb", "spec/public/click_area_spec.rb", "spec/public/click_button_spec.rb", "spec/public/click_link_spec.rb", "spec/public/fill_in_spec.rb", "spec/public/locators/field_by_xpath_spec.rb", "spec/public/locators/field_labeled_spec.rb", "spec/public/locators/field_with_id_spec.rb", "spec/public/matchers/contain_spec.rb", "spec/public/matchers/have_selector_spec.rb", "spec/public/matchers/have_tag_spec.rb", "spec/public/matchers/have_xpath_spec.rb", "spec/public/reload_spec.rb", "spec/public/save_and_open_spec.rb", "spec/public/select_date_spec.rb", "spec/public/select_datetime_spec.rb", "spec/public/select_spec.rb", "spec/public/select_time_spec.rb", "spec/public/selenium/application_server_factory_spec.rb", "spec/public/selenium/application_servers/external_spec.rb", "spec/public/selenium/selenium_session_spec.rb", "spec/public/set_hidden_field_spec.rb", "spec/public/submit_form_spec.rb", "spec/public/visit_spec.rb", "spec/public/within_spec.rb", "spec/spec_helper.rb"]
  s.homepage = %q{http://github.com/brynary/webrat}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{webrat}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Ruby Acceptance Testing for Web applications}
  s.test_files = ["spec/fakes/test_adapter.rb", "spec/integration/mechanize/sample_app.rb", "spec/integration/mechanize/spec/mechanize_spec.rb", "spec/integration/mechanize/spec/spec_helper.rb", "spec/integration/merb/app/controllers/application.rb", "spec/integration/merb/app/controllers/exceptions.rb", "spec/integration/merb/app/controllers/testing.rb", "spec/integration/merb/config/environments/development.rb", "spec/integration/merb/config/environments/rake.rb", "spec/integration/merb/config/environments/test.rb", "spec/integration/merb/config/init.rb", "spec/integration/merb/config/rack.rb", "spec/integration/merb/config/router.rb", "spec/integration/merb/spec/spec_helper.rb", "spec/integration/merb/spec/webrat_spec.rb", "spec/integration/merb/tasks/merb.thor/app_script.rb", "spec/integration/merb/tasks/merb.thor/common.rb", "spec/integration/merb/tasks/merb.thor/gem_ext.rb", "spec/integration/merb/tasks/merb.thor/ops.rb", "spec/integration/merb/tasks/merb.thor/utils.rb", "spec/integration/rack/app.rb", "spec/integration/rack/test/helper.rb", "spec/integration/rack/test/webrat_rack_test.rb", "spec/integration/rails/app/controllers/application.rb", "spec/integration/rails/app/controllers/buttons_controller.rb", "spec/integration/rails/app/controllers/fields_controller.rb", "spec/integration/rails/app/controllers/links_controller.rb", "spec/integration/rails/app/controllers/webrat_controller.rb", "spec/integration/rails/app/helpers/buttons_helper.rb", "spec/integration/rails/app/helpers/fields_helper.rb", "spec/integration/rails/app/helpers/links_helper.rb", "spec/integration/rails/config/boot.rb", "spec/integration/rails/config/environment.rb", "spec/integration/rails/config/environments/development.rb", "spec/integration/rails/config/environments/selenium.rb", "spec/integration/rails/config/environments/test.rb", "spec/integration/rails/config/initializers/inflections.rb", "spec/integration/rails/config/initializers/mime_types.rb", "spec/integration/rails/config/initializers/new_rails_defaults.rb", "spec/integration/rails/config/routes.rb", "spec/integration/rails/test/integration/button_click_test.rb", "spec/integration/rails/test/integration/fill_in_test.rb", "spec/integration/rails/test/integration/link_click_test.rb", "spec/integration/rails/test/integration/webrat_test.rb", "spec/integration/rails/test/test_helper.rb", "spec/integration/sinatra/classic_app.rb", "spec/integration/sinatra/modular_app.rb", "spec/integration/sinatra/test/classic_app_test.rb", "spec/integration/sinatra/test/modular_app_test.rb", "spec/integration/sinatra/test/test_helper.rb", "spec/private/core/configuration_spec.rb", "spec/private/core/field_spec.rb", "spec/private/core/link_spec.rb", "spec/private/core/logging_spec.rb", "spec/private/core/session_spec.rb", "spec/private/mechanize/mechanize_adapter_spec.rb", "spec/private/merb/attaches_file_spec.rb", "spec/private/merb/merb_adapter_spec.rb", "spec/private/nokogiri_spec.rb", "spec/private/rails/attaches_file_spec.rb", "spec/private/rails/rails_adapter_spec.rb", "spec/private/selenium/application_servers/rails_spec.rb", "spec/public/basic_auth_spec.rb", "spec/public/check_spec.rb", "spec/public/choose_spec.rb", "spec/public/click_area_spec.rb", "spec/public/click_button_spec.rb", "spec/public/click_link_spec.rb", "spec/public/fill_in_spec.rb", "spec/public/locators/field_by_xpath_spec.rb", "spec/public/locators/field_labeled_spec.rb", "spec/public/locators/field_with_id_spec.rb", "spec/public/matchers/contain_spec.rb", "spec/public/matchers/have_selector_spec.rb", "spec/public/matchers/have_tag_spec.rb", "spec/public/matchers/have_xpath_spec.rb", "spec/public/reload_spec.rb", "spec/public/save_and_open_spec.rb", "spec/public/select_date_spec.rb", "spec/public/select_datetime_spec.rb", "spec/public/select_spec.rb", "spec/public/select_time_spec.rb", "spec/public/selenium/application_server_factory_spec.rb", "spec/public/selenium/application_servers/external_spec.rb", "spec/public/selenium/selenium_session_spec.rb", "spec/public/set_hidden_field_spec.rb", "spec/public/submit_form_spec.rb", "spec/public/visit_spec.rb", "spec/public/within_spec.rb", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.2.0"])
      s.add_runtime_dependency(%q<rack>, [">= 1.0"])
    else
      s.add_dependency(%q<nokogiri>, [">= 1.2.0"])
      s.add_dependency(%q<rack>, [">= 1.0"])
    end
  else
    s.add_dependency(%q<nokogiri>, [">= 1.2.0"])
    s.add_dependency(%q<rack>, [">= 1.0"])
  end
end