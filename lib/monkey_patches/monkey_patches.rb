
# Hacks and patches to workaround bugs in the framework!


# Workaround for JRuby 'getBackRef' error: "DummyDynamicScope.java:49:in 'getBackRef':java.lang.RuntimeException: DummyDynamicScope should never be used for backref storage ..."
# Bug discussion: http://jira.codehaus.org/browse/JRUBY-3765
# More info:      http://groups.google.com/group/datamapper/browse_thread/thread/d62be1ff46e9b258/29174e564db2989e
# Code from:      http://github.com/mkristian/ixtlan/blob/master/ixtlan-core/lib/ixtlan/monkey_patches.rb

if RUBY_PLATFORM =~ /java/
  module DataMapper
    module Validate
      class NumericValidator
        
        def validate_with_comparison(value, cmp, expected, error_message_name, errors, negated = false)
          return if expected.nil?
          if cmp == :=~
            return value =~ expected
          end
          comparison = value.send(cmp, expected)
          return if negated ? !comparison : comparison
          
          errors << ValidationErrors.default_error_message(error_message_name, field_name, expected)
        end
      end
    end
  end
end






# Fix the code that appends '[]' to the end of MULTIPLE-SELECT elements:
# Now it will only add '[]' if the name does not already *contain* '[]'

module Merb::Helpers::Form::Builder
  
  class Base
    
    def unbound_select(attrs = {})
      update_unbound_controls(attrs, "select")
      # attrs[:name] << "[]" if attrs[:multiple] && !(attrs[:name] =~ /\[\]$/)
      # attrs[:name] << "[]" if attrs[:multiple] && !(attrs[:name] =~ /\[\]/)   # <-- Removed '$' from regex.
      if attrs[:multiple] && !(attrs[:name] =~ /\[\]/)   # <-- Removed '$' from regex.
        attrs[:name] = attrs[:name].class == Symbol ? "#{ attrs[:name] }[]".to_sym : "#{ attrs[:name] }[]"
      end
      tag(:select, options_for(attrs), attrs)
    end

  end

end






# Workaround for "TripClient#update cannot be called on a dirty resource - (DataMapper::UpdateConflictError)"
# See /jruby-1.4.0/lib/ruby/gems/1.8/gems/dm-core-0.10.2/lib/dm-core/resource.rb:323:in `update'
# This is the same code but with one line removed to prevent UpdateConflictError.

module DataMapper
  module Resource
    def update(attributes = {})
      #assert_update_clean_only(:update)    # Line removed to prevent UpdateConflictError
      self.attributes = attributes
      save
    end
  end
end






# This bug was not upsetting users but simply causing noise in the output/log:
# "Read error: #<NoMethodError: undefined method `each' for 186:Fixnum>"
# C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-core-1.0.15/lib/merb-core/rack/stream_wrapper.rb:18:in `each'
module Merb
  module Rack
    
    class StreamWrapper
      
      # :api: private
      def each(&callback)
        if Proc === @body
          @writer = lambda { |x| callback.call(x) }
          @body.call(self)
        elsif @body.is_a?(String)
          @body.each_line(&callback)
        else
          # @body.each(&callback) # Line 18: Changed this as follows. Not sure what it's doing exactly:
          @body.each(&callback) if @body.respond_to? :each
        end
      end

    end   
  
  end
end  