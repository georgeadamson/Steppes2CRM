module Merb
  class Authentication
  
    def errors
      @errors ||= Errors.new
    end

    # Lifted from DataMapper's dm-validations plugin :)
    # @author Guy van den Berg
    # @since  DM 0.9
    class Errors

      include Enumerable

      # Clear existing authentication errors.
      def clear!
        errors.clear
      end

      # Add a authentication error. Use the field_name :general if the errors does
      # not apply to a specific field of the Resource.
      #
      # @param <Symbol> field_name the name of the field that caused the error
      # @param <String> message    the message to add
      def add(field_name, message)
        (errors[field_name] ||= []) << message
      end

      # Collect all errors into a single list.
      def full_messages
        errors.inject([]) do |list,pair|
          list += pair.last
        end
      end

      # Return validation errors for a particular field name or an empty array
      #
      # This method is a necessary requirement for active_model compatibility.
      #
      # @param [Symbol] field_name the name of the field you want an error for
      # @return [Array<Array<String>>]
      #   array of validation errors or empty array, if there are no errors on given field
      def [](field_name)
        errors[field_name] ||= []
      end

      # Return authentication errors for a particular field_name.
      #
      # @param <Symbol> field_name the name of the field you want an error for
      def on(field_name)
        errors_for_field = errors[field_name]
        errors_for_field.blank? ? nil : errors_for_field
      end

      def each
        errors.map.each do |k,v|
          next if v.blank?
          yield(v)
        end
      end

      def empty?
        entries.empty?
      end

      def method_missing(meth, *args, &block)
        errors.send(meth, *args, &block)
      end

      private
      def errors
        @errors ||= {}
      end

    end # class Errors
  end # Authentication
end #  Merb