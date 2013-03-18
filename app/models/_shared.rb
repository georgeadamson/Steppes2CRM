

# IMPORTANT! The filename & location of this common file are chosen as a hack/workaround
# to ensure that this code loads at the correct time, ie before the models!
# If we put it in the lib folder it does not get loaded in time.
# More info at: https://merb.lighthouseapp.com/projects/7433/tickets/1010

# TODO: See if some of these can be moved to lib folder.

# Also see lib/monkey_patches for more workarounds!


module Merb
  module GlobalHelpers

    #alias orig_resource resource
  
    # Handy nesting-aware alternative to standard resource() method
    # Eg: It derives current context (client or group) from the current url so nested_resource(@trip) generates "/clients/1/trips/2"
    #     Where the old resource(@trip) would have simply generated "/trips/2"
    def nested_resource(*args)

      # Prepare to exclude slashes from resulting url when last param in args is a boolean true:
      # (This makes the resulting string safe for use in ui element IDs)
      noSlashes = args.delete_at(-1) if args.last === true

      unless args.empty?

        # Prepare to exclude slashes from resulting url when last param in args is true:
        #noSlashes = args.delete_at(-1) if args.last == true

        if args.first.is_a? Symbol
          
          args.unshift( trip = Trip.get(params[:trip_id]) ) if params[:trip_id]

          if trip && trip.respond_to?(:tour) && trip.tour
            args.unshift trip.tour 
          elsif trip && params[:tour_id]
            args.unshift Tour.get(params[:tour_id])
          elsif params[:client_id]
            args.unshift Client.get(params[:client_id]) 
          end  

        else
  
          # When first argument is a TripElement, insert it's trip object before it:
          if args.first.is_a? TripElement
            if args.first.trip && args.first.trip.id
              args.unshift args.first.trip
            elsif params[:trip_id]
              args.unshift Trip.get(params[:trip_id])
            end
          end

          # Now if first argument is a Trip, insert it's parent context object (tour or client) before it:
          if args.first.is_a?(Trip) && args.first.respond_to?(:tour) && args.first.tour
            args.unshift args.first.tour

          elsif args.first.is_a?(Trip) && params[:tour_id]
            args.unshift Tour.get(params[:tour_id])

          elsif args.first.respond_to?(:context)

            #if args.first.context && !args.first.context.id.nil?
            #  args.unshift args.first.context
            #elsif params[:client_id]
            #  args.unshift Client.get(params[:client_id])
            #end

          end

        end
  
        # When last argument is a NEW object, swap it for symbols:
        # Eg: [ trip, new_trip_element ] => [ trip, :trip_elements, :new ]
        if args.last.respond_to?(:new?) && args.last.new?

          obj   = args.pop
          args << obj.model.name.snake_case.pluralize.to_sym
          args << :new

        # Special allowance for nil TripElement object at end of args array:
        elsif args.last.nil?

          args.pop
          args << :trip_elements
          args << :new

        end
  
      end

      # Remove nils and dupes, just in case:
      args.compact!
      args.uniq!

      #puts "!!! nested_resource(" + args.inspect + ") " + args[0].inspect + ", " + args[1].inspect + " \n"
      return noSlashes ? resource(*args).gsub("/","") : resource(*args)

    end
  end
end




module Merb::AssetsMixin

	alias orig_link_to link_to

	# Enhance link_to method to wrap in <div class="formField'> when :label is specified:
	def link_to(*args)

		attrs = args.last.is_a?(Hash) ? args.last : {}

		if attrs.has_key?(:label)
			contents		= attrs.delete(:label)
			attrs[:class]	= attrs[:class].to_s.split(' ').push('link').uniq.join(' ') if attrs.has_key?(:class)
			tag :div, :class => "formField #{attrs[:class]}" do label(contents) + orig_link_to(*args) end
		else
			orig_link_to(*args)
		end

	end

end
  
  
  
  

module Merb::Helpers::Form

   #%w(text_field text_area select).each do |fieldName|
  #  #self.class_eval <<-RUBY, _ _FILE_ _, _ _LINE_ _ + 1
  #  alias orig_#{fieldName} #{fieldName}
  #
  #   def #{fieldName}(*args)
  #     tag :div do
  #       orig_#{fieldName}(*args)
  #     end
  #   end
  #  #RUBY
  #end

	alias orig_label label
	alias orig_select select
	alias orig_text_area text_area
	alias orig_text_field text_field
	alias orig_check_box check_box
	alias orig_radio_button radio_button


	#def label(*args)
	#	orig_label :class => "#{args.last[:labelClass]}", *args
	#end


	# Custom helper for generating <div class="sectionHead"><h3>Heading</h3></div>
	def section_head( text, attrs = {} )

		attrs[:class] = "sectionHead #{ attrs[:class] }"

		heading_tag = attrs.delete(:heading_tag) || 'h3'

		tag :div, attrs do
			tag heading_tag, text || 'Heading'
		end

	end



  def select(*args)
	  attrs = cleanse_field_args!(*args)
    message     = attrs.delete(:message)
    message_tag = attrs.delete(:message_tag) || :span
    tag :div, :class => "formField select #{attrs[:class]}" do 
      "#{ orig_select(*args) }#{ tag( message_tag, message, :class => 'fieldMessage' ) if message }"
    end
    #tag :div, :class => "formField select #{attrs[:class]}" do orig_select(*args) end
  end
  
  def text_area(*args)
	  attrs = cleanse_field_args!(*args)
    message     = attrs.delete(:message)
    message_tag = attrs.delete(:message_tag) || :span
    tag :div, :class => "formField textarea #{attrs[:class]}" do 
      "#{ orig_text_area(*args) }#{ tag( message_tag, message, :class => 'fieldMessage' ) if message }"
    end
    #tag :div, :class => "formField textarea #{attrs[:class]}" do orig_text_area(*args) end
  end
  
  def text_field(*args)
	  attrs       = cleanse_field_args!(*args)
    message     = attrs.delete(:message)
    message_tag = attrs.delete(:message_tag) || :span
    tag :div, :class => "formField #{attrs[:class]}" do 
      "#{ orig_text_field(*args) }#{ tag( message_tag, message, :class => 'fieldMessage' ) if message }"
    end
  end

  def check_box(*args)
	  attrs  = cleanse_field_args!(*args)
    parent = attrs.delete(:parent) || :div
    tag( parent, :class => "formField checkbox #{attrs[:class]}" ) do orig_check_box(*args) end
	end

  def radio_button(*args)
	  attrs  = cleanse_field_args!(*args)
    parent = attrs.delete(:parent) || :div
    tag parent, :class => "formField radio #{attrs[:class]}" do orig_radio_button(*args) end
  end


	# And out own special <span class="ui-icon ui-icon-xxx"></span>
	def icon( type = :info, attrs = {} )
    text = attrs.delete(:text) || ''
		attrs[:class] = "ui-icon ui-icon-#{ type } #{ attrs[:class] }"
		return tag :span, text, attrs
	end
  


  # Helper for generating select-list items for a belongs_to relationship.
  # Usage: collection_for(Model,:association,opts) or collection_for(:association,opts) or collection_for(:association)
  # Eg: Address belongs_to Country so the address form needs a countries list: collection_for(address,:country)
  # You can omit the first argument but this prevents the :minimal option from deriving the selected item.
  def collection_for( obj, *args )
  	
	  opts				= args.last.is_a?(Hash) ? args.last : {}
	  association = args.first if args.first.is_a? Symbol
	  association = obj				 if obj.is_a? Symbol
	  obj					= nil				 if obj.is_a? Symbol
  	
	  # Allow for missing obj argument: (effectively shift arguments along one place)
	  #opts, association, obj = (association||{}), obj, nil if obj.is_a?(Symbol)
  	
	  # Derive model from relationships. Eg: supplier obj has relationships such as: "linked_supplier"=>#1, :max=>1, :child_key=>[:linked_supplier_id], :child_repository_name=>:default, :parent_repository_name=>nil}, @parent_key=[#], @min=1, @parent_repository_name=nil, @required=true, @child_model=Supplier, @parent_properties=nil, @name=:linked_supplier, @child_properties=[:linked_supplier_id], @writer_visibility=:public, @parent_model_name="Supplier", @child_key=[#], @instance_variable_name="@linked_supplier", @child_model_name="Supplier">
	  model					= opts.delete(:model)
	  model				||= Kernel.const_get(association.to_s.to_const_string) if obj.nil? && !association.to_s.blank?
	  model				||= obj.model.relationships[association].parent_model #|| ( obj.method(association).call && obj.method(association).call.model )
    
	  id_method		  = opts.delete(:id_method)			|| "#{ association.to_s.snake_case }_id"
	  id_method     = "#{ model.to_s.snake_case }_id" unless obj.respond_to?(id_method)
    
	  selected_id		= opts.delete(:selected_id)		|| ( obj && obj.method(id_method).call.to_i )
	  allow_zero_id = opts.delete(:allow_zero_id)
    allow_zero_id = true if allow_zero_id.nil?
	  prevent_empty = opts.delete(:prevent_empty)
    prevent_empty = true if prevent_empty.nil?
  	
    # Assume minimal 'SHOW MORE' list for ajax requests: (unless args[:minimal] is false)
	  ajax					= opts.delete(:ajax)					|| request.ajax?
	  minimal				= opts.delete(:minimal)
    minimal       = !obj.nil? && !obj.new? && ajax if minimal.nil?
  	
	  controller		= opts.delete(:controller)		|| model.to_s.snake_case.pluralize.to_sym
	  conditions		= opts.delete(:conditions)		|| { :order => :name }
	  collection		= opts.delete(:collection)		|| model.all(conditions)
  	
	  more_href			= opts.delete(:more_href)			|| resource( controller.to_sym, conditions.merge(:list => 'option') )
	  more_label		= opts.delete(:more_label)		|| '+ Show more...'
	  item_method		= opts.delete(:item_method)		|| :id_and_name   # Where supported, id_and_name returns [id,name]
	  list					= opts.delete(:list)					|| []             # Default items for the list
    
	  # Drastically cull length of list for the minimal display: (unless empty lists are to be avoided)
	  if minimal && ( allow_zero_id ? selected_id : selected_id.to_i > 0 )
		  minimal_collection = collection.all( :id => selected_id )
		  collection  = minimal_collection unless prevent_empty && minimal_collection.empty?
	  end
  	
	  # When selected item is not already in the list then try to add it:
	  collection   << model.get(selected_id) unless selected_id.to_i.zero? || collection.get(selected_id) || model.get(selected_id).nil?
    
	  # Copy items into an array for populating the list: (Allowing for models that provide custom method returning [id,name])
	  collection.each do |item|
		  if item_method && item.respond_to?(item_method)
			  list << item.method(item_method).call.map{ |val| h(val) }
		  else
			  list << [ h(item.id), h(item.name) ]
		  end
	  end
    
    #    if minimal && ids
    #
    #      uk = Country.get(6)
    #      list << [ uk.id, uk.name ] unless uk.nil?
    #
    #    end

	  # Add "Show all" option to the lists:
	  list << [ more_href, h(more_label) ] if minimal
    
	  return list
    
  end




  # Helper to generate hidden fields instructing client-side script to open a client tab when current page opens:
  def open_client_tab( client_id, client_label = nil )
    
    if client_id
      
      client_label ||= ( c = Client.get(client_id) ) && c.shortname
      
      # TODO: Depricate the 'showClient' css class in favour of 'show-client':
      hidden_field( :name => :client_id,		:value => client_id,		:class => 'show-client showClient' ) +
      hidden_field( :name => :client_label,	:value => client_label, :class => 'show-client showClient' )
      
    end
    
  end





private

	def cleanse_field_args!(*args)
		attrs = args.last.is_a?(Hash) ? args.last : {}
		attrs[:readonly] = :readonly if attrs.delete(:readonly)
		attrs[:disabled] = :disabled if attrs.delete(:disabled)
		attrs[:multiple] = :multiple if attrs.delete(:multiple)
		attrs[:class]    = attrs[:class].to_s.split(' ').push('multiple').uniq.join(' ') if attrs.has_key?(:multiple)
		return attrs
	end

end





# Handy way to serialise errors:
# http://coryodaniel.com/index.php/2009/12/30/datamapper-and-merb-sharing-your-errors-via-the-merb-display-api/
# Usage:  display @person, nil, {:methods => [:errors]}
module DataMapper

  module Validate
 
    class ValidationErrors
      def to_json
        @errors.to_hash.to_json
      end
    end

  end
  
  
  module NestedAttributes
  
		module Model
 
			# These methods add getter/setter methods for arrays of ids.
			# They compliment the accepts_nested_attributes_for plugin.
			#
			# Also handles explicit deletes by removing ids that are repeated with a suffix of '_delete':
			# This is useful where checkboxes are used to choose items to delete. (Each checkbox has value="nn_delete" plus hidden field with value="nn")
			# Eg: ['11','22','33','44','11_delete','44_delete'] => ['22','33']
			#
			# Usage when:
			#				client has n, :countries, :through => :client_interests
			#			we can call: 
			#				accepts_ids_for :countries
			#			to add the following instance methods to the class:
			#				client.countries_ids
			#				client.countries_ids=

			def accepts_ids_for( association_name, options = {} )


				# object.association_ids=()
				# Setter method to accept an array of ids and modify the collection of child objects:
				# Useful for submitting multi-select lists or groups of checkboxes.
				# Eg: A form containing select(:name => 'client[interests_ids][]') will set client.countries_ids = [123,456,789]
				define_method "#{association_name}_ids=" do |ids|

          #ids = ( ids || [] ).flatten
					orig_length = ids.length

					# Handle explicit deletes by removing ids that are repeated with a suffix of '_delete':
					ids = ids.select{ |id| !ids.include?("#{id}_delete") && !id.to_s.include?('_delete') }

					# Typically we want to remove duplicated ids to prevent unexpected dupe associations in the database:
					ids.uniq! unless options[:allow_duplicates]

					#print "\n#{association_name}_ids = #{ids.inspect} (after applying _delete)\n" if ids.length < orig_length

					# Derive the association's Model class name and
					# Replace the associated collection with a new set of items matching the ids:
					model = self.method(association_name).call.model
					
					self.send( "#{association_name}=", model.all( :id => ids ) )

					#print "\n accepts_ids_for #{association_name}_ids count = #{ self.method(association_name).call.length } \n"

				end


				# object.association_ids()
				# Getter method to return array of ids:
				# Useful with our custom all_to_s array method when setting the :selected option on an html select list, eg: select :countries, :selected => client.countries_ids.all_to_s, :collection => Country.all
				# Note: We use .each{} instead of a one-liner such as .map{} because we want to encourage DataMapper to user Strategic Eager Loading.
				define_method "#{association_name}_ids" do |*to_s|

					to_s  = to_s.first || false
					ids   = []

					if to_s
						self.send("#{association_name}").each{ |obj| ids << obj.id.to_s }
					else
						self.send("#{association_name}").each{ |obj| ids << obj.id }
					end

					return ids

				end


			
				# object.association_names()	# Bonus feature!
				# Getter method to return array of names from the collection:
				# Useful when we need a list of child items such as trip.countries_names
				# Note: We use .each{} instead of a one-liner such as .map{} because we want to encourage DataMapper to user Strategic Eager Loading.
				define_method "#{association_name}_names" do |*attr|

					attr = attr.first || :name
					names  = []
					
					self.send("#{association_name}").each{ |obj| names << obj.method(attr).call }
					return names

				end

			end
  
  
		end
	
	end




  
  module Model
    
    # Helper for enabling a simple form of caching on specific attributes:
    # TODO: Write unit tests for this and ensure cached values are not getting muddled between models!
    def cache_attributes_for( *attrs )

      attrs.each do |attr|
        
        if self.respond_to? attr
        
          # Retain a reference to the original attribute: 
          orig_attr = "uncached_#{ attr }"
          alias_method orig_attr, attr
          
          # Overwrite the attribute with our own caching version:
          define_method attr do |*reload|
            
            # Skip the whole caching malarkey when dealing with a new instance:
            if self.new? || self.id.nil?
              
              return self.method(orig_attr).call
              
            else
              
              #self.model.class_variable_set( :@@cached_attributes, {} ) unless self.model.class_variable_defined? :@@cached_attributes
              for_model = self.model.name
              $cached_attributes ||= {}
              $cached_attributes[for_model] ||= {}
              reload = *reload.first || false;

              # Initialise a cache for values associated with the current id:
              # TODO: This could be where the problem lies. Maybe getting muddled between models.
              #self.model.class_variable_get(:@@cached_attributes)[self.id] ||= {}
              $cached_attributes[for_model][self.id] ||= {}
              
              # The first time the attribute is called, the value will be fetched and cached:
              if reload
                #return self.model.class_variable_get(:@@cached_attributes)[self.id][attr]   = self.method(orig_attr).call 
                return $cached_attributes[for_model][self.id][attr] = self.method(orig_attr).call 
              else
                cached_value = $cached_attributes[for_model][self.id][attr]
                puts " !!!!! Using cached_attribute #{attr} #{ cached_value }" if cached_value
                #return self.model.class_variable_get(:@@cached_attributes)[self.id][attr] ||= self.method(orig_attr).call
                return $cached_attributes[for_model][self.id][attr] ||= self.method(orig_attr).call 
              end
              
            end
            
          end
        
        end
        
      end


      # Helper for emptying the cache for current item (will be re-cached the next time it is called)
      define_method :clear_cached_attributes do
        
        puts "clear_cached_attributes #{ self.id }"
        ( @@cached_attributes ||= {} ).delete(self.id) if self.id # class_variable_defined?(:@@cached_attributes)

      end


      # after :save do
      # Automatically clear the cached attributes whenever the item is modified:
      self.method(:after).call :save do

        self.clear_cached_attributes()

      end
      
    end
    
  end



end




#module DataMapper
  #module Validate
    #module ValidationErrors
  
		  # Adapted from DataMapper::NestedAttributes::ValidationErrorCollecting::before_save_child_association
      # Usage: collect_child_error_messages_for( @supplier, company )
		  # Eg: suppliers.companies errors => @errors={:short_name=>["Short name must not be blank"], :images_folder=>["Images folder must not be blank"]}> | #, @errors={}> | #, @errors={}>
      def collect_child_error_messages_for(obj, association, context = :default)
  			
			  errors    = {}
			  context ||= :default
  			
			  if association.respond_to?(:valid?)
  				
				  unless association.valid?(context)
  					
					  association.errors.each_pair { |field_name,message|
  						
						  field_name = "#{ association.model.name.snake_case }_#{field_name}"
						  field_msg  = "#{ association.model.name }:#{ " (#{ association.name })" if association.respond_to?(:name) && association.name != association.model.name }"
						  message.unshift field_msg
  						
						  errors.merge!( field_name.to_sym => message ) unless errors[field_name] && errors[field_name].include?(message)
  						
					  }
  					
				  end
  				
			  else
				  errors.merge! :general => "#{ association.model.name } association is missing"
			  end
  			
			  return obj.errors.merge! errors
  			
		  end
      
      
		  # Helper to call collect_child_error_messages_for() on each child association:
      # Usage: collect_error_messages_for( @supplier, :companies )
		  def collect_error_messages_for( obj, association_name = :all, context = :default )

        if association_name == :all

          #obj.model.relationships.each do | name, association |    # Older versions of DM
          obj.model.relationships.each do | association |

            #puts 'association', association.inspect, association.class, association.methods.sort.inspect
            
            # Allow for when accociation is an array of associations: (Eg: When it's a ManyToMany)
            for assoc in ( defined?(association.name) ? [association] : association ) do
            
              #puts 'defined?(association.name)', defined?(association.name), association.inspect
              #puts 'defined?(assoc.name)', defined?(assoc.name), assoc.inspect
                            
              begin

                name = assoc.name
                
                if obj.respond_to?(name)
                  
                  if ( rel = obj.method(name).call ) && rel.respond_to?(:dirty?) && rel.dirty?
                    
                    Merb.logger.debug "Collecting errors from #{name}"
                    
                    if rel.respond_to?(:each)
                      collect_error_messages_for obj, name.to_sym
                    else
                      collect_child_error_messages_for obj, rel
                    end
                    
                  end #if
                  
                end #if
                
              rescue Exception => reason

                whoopsie = "ERROR during collect_error_messages_for #{ obj.inspect } #{ reason }"
                puts whoopsie
                Merb.logger.error whoopsie

              end

            end #for
            
          end #each

          Merb.logger.debug "#{ obj.class } now has #{ obj.errors.length } errors"

        else

			    obj.send(association_name).each{ |a|
            collect_child_error_messages_for( obj, a, context )
          } if obj.respond_to? association_name
        
        end #if

			  return obj.errors
        
		  end
  
    #end
  #end
#end





class Array

	# Custom method for converting all the array items to strings:
	# (Useful when setting the :selected option on an html select list, eg: select :countries, :selected => client.countries_ids.all_to_s, :collection => Country.all )
	def all_to_s
		map{ |item| item.to_s }
	end
	
end


class NilClass
	
	# Dummy stub to prevent error when we call .formatted(:uidate) on a nil date field:
	def formatted(format = nil)
		return ''
	end
	
	# Dummy stubs to prevent error when we call .name or .display_name on a nil field:
	def id; return nil; end
	alias name id
	alias display_name id
	
end

class String
	
	# Dummy stub to prevent error when we call .formatted(:uidate) on a string date field:
	def formatted(format = nil)
		return ''
	end
	
end

class Hash

	# Helper for serialising hash to url params: (TODO: Find built in method!)
	def to_query
		
    return self.map{|key,val| "#{ CGI::escape(key.to_s) }=#{ CGI::escape(val.to_s) }" }.join('&')
    
		#pairs = []
		#each_pair{ |key,val| pairs << "#{ key }=#{ val }" }
		#return pairs.join('&')
		
	end

  # Helper for excluding keys in blacklist:
  def except(*blacklist)
    self.reject{|key, value| blacklist.include?(key) }
  end
  
  # Helper for excluding keys not in whitelist:
  def only(*whitelist)
    self.reject{|key, value| !whitelist.include?(key) }
  end

end

# Fix <=> comparison of True/False values: (Fixes Datamapper sort on Boolean columns)
# More info: http://grosser.it/2010/07/30/ruby-true-false-comparison-with/
module TrueFalseComparison
  def <=>(other)
    raise ArgumentError unless [TrueClass, FalseClass].include?(other.class)
    other ? (self ? 0 : -1) : (self ? 1 : 0)
  end
end
TrueClass.send(:include, TrueFalseComparison)
FalseClass.send(:include, TrueFalseComparison)



  # Helper to build and/or tidy up comma separated list of tag words:
  def tagList(*tags)
      return tags.join(",").split(",").compact.delete_if{|tag| tag.strip.empty? }.uniq.join(",")
  end

  class String

    def propercase
      return self.downcase.gsub(/\b\w/){$&.upcase}
    end

	  def is_numeric?
		  Float self rescue false
	  end

	  def to_gt_zero
		  self.to_i > 0 ? self.to_i : nil
	  end

  end


  	# return a simple Array of id/name pairs for populating <select> list collections:
  	# Important: By using an 'each' loop we encourage DM's Strategic Eager Loading of associated fields where applicable:
  	# Could not get this to work without crashing CPU!
  def collection_of(list)
		result = []
		if !list.empty? && list.first.respond_to?(:display_name)
			list.each{ |obj| result << [ obj.id, obj.display_name ] }
		else
			list.each{ |obj| result << [ obj.id, obj.name ] }
		end
		return result
	end

  
  
  
  
	# Modify the hash of submitted fields to convert UK dates to US dates ready for datamapper:
	#:return: => n/a
	#:arg: fields => Hash of submitted fields OR a model object.
	#:arg: date_field_names => Array of fields that need to be corrected.
	def accept_valid_date_fields_for( fields, *date_field_names )
		
    date_field_names.flatten!
    attrs = fields.respond_to?(:attributes) ? fields.attributes.only(*date_field_names) : fields

		date_field_names.each do |date_field|
			
			if attrs[date_field].blank?
				
				attrs[date_field] = nil

      elsif attrs[date_field].is_a? String

				# Convert 2-digit year to 4 digits: 01-02-30 => "01-02-2030"
				attrs[date_field].strip!
				attrs[date_field].sub!(/^([0-3]?[0-9][\-\/][0-1]?[0-9][\-\/])([4-9][0-9])$/){|m| $1+'19'+$2} # Don't know why alternative syntax did not work: .sub!(/[\-\/]([4-9][0-9])$/, "\119\2") # See http://ruby-doc.org/core/classes/String.html#M000816
				attrs[date_field].sub!(/^([0-3]?[0-9][\-\/][0-1]?[0-9][\-\/])([0-3][0-9])$/){|m| $1+'20'+$2}
				
				begin
					# Try to parse date string into format ready for database: (dd/mm/yyyy => yyyy/mm/dd)
					attrs[date_field] = Date.strptime( attrs[date_field], '%d/%m/%Y' ).to_s
				rescue
					# Ignore invalid date. It'll be picked up by the dm-validations. 
				end
				
			end
			
		end
		
    # Apply the validated values to the model's attributes if necessary:
    fields.attributes = attrs if fields.respond_to?(:attributes)
    return fields

	end
	

class Date

  # Provide Date.to_datetime helper to maintain my sanity! (Accepts optional time params too)
  def to_datetime( hour = 0, minute = 0, second = 0 )
    return DateTime.civil(self.year, self.month, self.day, hour, minute, second)
  end

end



  

#  # DEPRICATED
#  # Helper for ensuring datamapper does not mess up datetime fields by returning them with +1 hour offset!
#  # This may only be a problem during BST!
#  # Eg: trip.get_datetime_property_of( self, :start_date )
#  def get_datetime_property_of( model, prop, raw_prop = nil )
#
#    raw_prop ||= "raw_#{ prop }"
#    raw_date   = model.method(raw_prop).call
#
#    # Assume datetime is fine if it has not been saved yet:
#    if !raw_date || model.attribute_dirty?(prop)
#
#      return raw_date
#
#    # Allow for offset when reading datetime property from database: (DM adds offset)
#    else
#
#      seconds_offset = raw_date.to_time.utc_offset
#      return (raw_date.to_time.utc + seconds_offset ).utc.to_datetime
#      
#    end
#
#  end





  
  
  # DEPRICATED: Use this plugin instead: http://github.com/snusnu/dm-accepts_nested_attributes
  # Generic-ish handler for saving has-n-through child IDs such as an array of checkboxes:
  # Eg: Trip has n countries through trip_countries.
  # Typically new_ids would be an array of IDs from fields named like 'trip_countries[]'
  # See: http://wonderfullyflawed.com/2009/02/17/rails-forms-microformat/
	#def update_has_through(model, has_model, through_model, new_ids = [])
	#
	#    # model         = @trip                    # Must be an instance of the model class.
	#    # has_model     = Country                  # Must be a class, not an instance of a model class!
	#    # through_model = model.trip_countries     # Must be an instance of the model class.
	#    # new_ids       = params[:trip_countries]  # Array of new has_model_id values.
	#    new_ids       ||= []
	#    model_id        = (model.class.name.snake_case + '_id').to_sym
	#    has_model_id    = (has_model.name.snake_case + '_id').to_sym
	#
	#    # Add rows for any IDs not already in through_model:
	#    new_ids.reject{|id| through_model.first( has_model_id => id ) }.each do |new_id|
	#      through_model.new( model_id => model.id, has_model_id => new_id ) 
	#    end
	#
	#    # Delete any existing through_model rows not in new_ids list:
	#    through_model.all( has_model_id.not => new_ids ).destroy
	#    
	#    # Equivalent to: (example)
	#    #new_ids.reject{|id| @trip.trip_countries.first( :country_id => id ) }.each do |new_id|
	#    #  @trip.trip_countries.new( :trip_id => @trip.id, :country_id => new_id ) 
	#    #end
	#    #@trip.trip_countries.all( :country_id.not => new_ids ).destroy
	#
	#    model.save
	#
	#end