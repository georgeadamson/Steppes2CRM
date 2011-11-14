module DataMapper
  module NestedAttributes

    ##
    # Extensions and customizations for @see DataMapper::Resource
    # that are needed if the @see DataMapper::Resource wants to
    # accept nested attributes for any given relationship.
    # Basically, this module provides functionality that allows
    # either assignment or marking for destruction of related parent
    # and child associations, based on the given attributes and what
    # kind of relationship should be altered.
    module Resource

      ##
      # Can be used to remove ambiguities from the passed attributes.
      # Consider a situation with a belongs_to association where both a valid value
      # for the foreign_key attribute *and* nested_attributes for a new record are
      # present (i.e. item_type_id and item_type_attributes are present).
      # Also see http://is.gd/sz2d on the rails-core ml for a discussion on this.
      # The basic idea is, that there should be a well defined behavior for what
      # exactly happens when such a situation occurs. I'm currently in favor for
      # using the foreign_key if it is present, but this probably needs more thinking.
      # For now, this method basically is a no-op, but at least it provides a hook where
      # everyone can perform it's own sanitization by overwriting this method.
      #
      # @param attributes [Hash]
      #   The attributes to sanitize
      #
      # @return [Hash]
      #   The sanitized attributes
      #
      def sanitize_nested_attributes(attributes)
        attributes # noop
      end

      private

      ##
      # Attribute hash keys that should not be assigned as normal attributes.
      #
      # @return [#each]
      #   The model key and :_delete, the latter being a special value
      #   used to mark a resource for destruction
      def unassignable_keys
        model.key.to_a << :_delete
      end


      ##
      # Assigns the given attributes to the resource association.
      #
      # If the given attributes include an <tt>:id</tt> that matches the existing
      # record’s id, then the existing record will be modified. Otherwise a new
      # record will be built.
      #
      # If the given attributes include a matching <tt>:id</tt> attribute _and_ a
      # <tt>:_delete</tt> key set to a truthy value, then the existing record
      # will be marked for destruction.
      #
      # @param relationship [DataMapper::Associations::Relationship]
      #   The relationship backing the association.
      #   Assignment will happen on the target end of the relationship
      #
      # @param attributes [Hash]
      #   The attributes to assign to the relationship's target end
      #   All attributes except @see UNASSIGNABLE_KEYS will be assigned
      #
      # @return nil
      def assign_nested_attributes_for_related_resource(relationship, attributes)
        if attributes[:id].blank?
          return if reject_new_record?(relationship, attributes)
          new_record = relationship.target_model.new(attributes.except(*unassignable_keys))
          relationship.set(self, new_record)
        else
          existing_record = relationship.get(self)
          if existing_record && existing_record.id.to_s == attributes[:id].to_s
            update_or_mark_as_destroyable(relationship, existing_record, attributes)
          end
        end
      end

      ##
      # Assigns the given attributes to the collection association.
      #
      # Hashes with an <tt>:id</tt> value matching an existing associated record
      # will update that record. Hashes without an <tt>:id</tt> value will build
      # a new record for the association. Hashes with a matching <tt>:id</tt>
      # value and a <tt>:_delete</tt> key set to a truthy value will mark the
      # matched record for destruction.
      #
      # For example:
      #
      # assign_nested_attributes_for_collection_association(:people, {
      # '1' => { :id => '1', :name => 'Peter' },
      # '2' => { :name => 'John' },
      # '3' => { :id => '2', :_delete => true }
      # })
      #
      # Will update the name of the Person with ID 1, build a new associated
      # person with the name `John', and mark the associatied Person with ID 2
      # for destruction.
      #
      # Also accepts an Array of attribute hashes:
      #
      # assign_nested_attributes_for_collection_association(:people, [
      # { :id => '1', :name => 'Peter' },
      # { :name => 'John' },
      # { :id => '2', :_delete => true }
      # ])
      #
      # @param relationship [DataMapper::Associations::Relationship]
      #   The relationship backing the association.
      #   Assignment will happen on the target end of the relationship
      #
      # @param attributes [Hash]
      #   The attributes to assign to the relationship's target end
      #   All attributes except @see UNASSIGNABLE_KEYS will be assigned
      #
      # @return nil
      def assign_nested_attributes_for_related_collection(relationship, attributes_collection)

        normalize_attributes_collection(attributes_collection).each do |attributes|

          if attributes[:id].blank?
            next if reject_new_record?(relationship, attributes)
            relationship.get(self).new(attributes.except(*unassignable_keys))
          else

            collection = relationship.get(self)
            if existing_record = collection.get(attributes[:id])
              update_or_mark_as_destroyable(relationship, existing_record, attributes)
            else

            end
          end

        end

      end

      ##
      # Updates a record with the +attributes+ or marks it for destruction if
      # +allow_destroy+ is +true+ and has_delete_flag? returns +true+.
      #
      # @param relationship [DataMapper::Associations::Relationship]
      #   The relationship backing the association.
      #   Assignment will happen on the target end of the relationship
      #
      # @param attributes [Hash]
      #   The attributes to assign to the relationship's target end
      #   All attributes except @see UNASSIGNABLE_KEYS will be assigned
      #
      # @return nil
      def update_or_mark_as_destroyable(relationship, resource, attributes)
        allow_destroy = self.class.options_for_nested_attributes[relationship][:allow_destroy]
        if has_delete_flag?(attributes) && allow_destroy
          if relationship.is_a?(DataMapper::Associations::ManyToMany::Relationship)
            intermediaries = relationship.through.get(self).all(relationship.via => resource)
            intermediaries.each { |intermediate| destroyables << intermediate }
          end
          destroyables << resource
        else
          resource.update(attributes.except(*unassignable_keys))
        end
      end

      ##
      # Determines if the given attributes hash contains a truthy :_delete key.
      #
      # @param attributes [Hash] The attributes to test
      #
      # @return [TrueClass, FalseClass]
      #   true, if attributes contains a truthy :_delete key
      def has_delete_flag?(attributes)
        !!attributes[:_delete]
      end

      ##
      # Determines if a new record should be built with the given attributes.
      # Rejects a new record if @see has_delete_flag? returns true for the given attributes,
      # or if a :reject_if guard exists for the passed relationship that evaluates to +true+.
      #
      # @param relationship [DataMapper::Associations::Relationship]
      #   The relationship backing the association.
      #
      # @param attributes [Hash]
      #   The attributes to test with @see has_delete_flag?
      #
      # @return [TrueClass, FalseClass]
      #   true, if the given attributes will be rejected
      def reject_new_record?(relationship, attributes)
        guard = self.class.options_for_nested_attributes[relationship][:reject_if]
        return false if guard.nil? # if relationship guard is nil, nothing will be rejected
        has_delete_flag?(attributes) || evaluate_reject_new_record_guard(guard, attributes)
      end

      ##
      # Evaluates the given guard by calling it with the given attributes
      #
      # @param [Symbol, String, #call] guard
      #   An instance method name or an object that respond_to?(:call), which
      #   would stop a new record from being created, if it evaluates to true.
      #
      # @param [Hash] attributes
      #   The attributes to pass to the guard for evaluating if it should reject
      #   the creation of a new resource
      #
      # @raise [ArgumentError]
      #   If the given guard doesn't match [Symbol, String, #call]
      #
      # @return [true, false]
      #   The value returned by evaluating the guard
      def evaluate_reject_new_record_guard(guard, attributes)
        if guard.is_a?(Symbol) || guard.is_a?(String)
          send(guard, attributes)
        elsif guard.respond_to?(:call)
          guard.call(attributes)
        else
          # never reached when called from inside the plugin
          raise ArgumentError, "guard must be a Symbol, a String, or respond_to?(:call)"
        end
      end

      ##
      # Make sure to return a collection of attribute hashes.
      # If passed an attributes hash, map it to its attributes
      #
      # @param attributes [Hash, #each]
      #   An attributes hash or a collection of attribute hashes
      #
      # @return [#each]
      #   A collection of attribute hashes
      def normalize_attributes_collection(attributes)
        if attributes.is_a?(Hash)
          attributes.map { |_, attributes| attributes }
        else
          attributes
        end
      end


      def destroyables
        @destroyables ||= []
      end

      def remove_destroyables
        destroyables.each { |r| r.destroy if r.saved? }
        @destroyables.clear
      end

      def save(*)
        saved = super
        remove_destroyables
        saved
      end

    end

  end
end
