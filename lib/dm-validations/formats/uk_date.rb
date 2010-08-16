# encoding: utf-8

module DataMapper
  module Validate
    module Format
      module UkDate

        def self.included(base)
          DataMapper::Validate::FormatValidator::FORMATS.merge!(
            :uk_date => [ UkDate, lambda { |field, value| '%s is not a valid UK date'.t(value) }]
          )
        end

        UkDate = begin
          /^[0-3]?[0-9][\-\/][0-1]?[0-9][\-\/][0-9][0-9][0-9][0-9]$/i
        end

      end # module UkDate
    end # module Format
  end # module Validate
end # module DataMapper


module DataMapper
  module Validate
    
    class FormatValidator < GenericValidator
      
      include DataMapper::Validate::Format::UkDate

    end

  end # module Validate
end # module DataMapper