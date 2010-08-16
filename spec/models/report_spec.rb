require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/report_spec.rb


describe Report do

  before :all do

    seed_lookup_tables()
    
    # Prepare some data to actually show in reports:
    invoice_number = valid_money_in_attributes[:name]
    MoneyIn.create!( valid_money_in_attributes.merge( :is_deposit => true,  :amount => 100  ) )
    MoneyIn.create!( valid_money_in_attributes.merge( :is_deposit => false, :amount => 1000 ) )
    MoneyIn.create!( valid_money_in_attributes.merge( :is_deposit => false, :amount => 200, :name => "#{ invoice_number }/1"  ) )
    MoneyIn.create!( valid_money_in_attributes.merge( :is_deposit => false, :amount => 200, :name => "#{ invoice_number }/2C" ) )

  end


  before :each do

    @report = Report.new(valid_report_attributes)

  end

  after :each do

    @report.report_fields.destroy if @report.saved?

  end





  it "should be valid" do
    #@report.valid?
    #puts @report.errors.inspect
    @report.should be_valid
  end

  it "should set and get source_model" do
    @report.source = Trip
    @report.save.should be_true
    @report.reload
    @report.source.should       == 'Trip'
    @report.source_model.should ==  Trip
  end


  it "should set and get report_fields" do
    
    @report.attributes = {
      :report_fields_attributes => valid_money_in_report_fields_attributes
    }

    @report.save.should be_true
    @report.should have( valid_money_in_report_fields_attributes.length ).report_fields
    
  end


  it "should set and get filter fields" do
    
    @report.attributes = {
      :report_fields_attributes => valid_money_in_report_fields_attributes
    }
    @report.should have( valid_money_in_report_fields_attributes.length ).report_fields
    filter = @report.report_fields.first( :name => 'money_in[amount]' )
    filter.update( :filter_operator => 'lt', :filter_value => 200 )

    @report.save.should be_true
    @report.filters.should have(1).item
    
  end


  it "should parse filter field names" do
    
    # Eg: For queries such as MoneyIn.all( MoneyIn.trip.trip_clients.client.name.like => 'ada%' ).length
    @report.attributes = {
      :report_fields_attributes => {
        :'0' => { :name => 'amount' },
        :'1' => { :name => 'money_in[amount]' },
        :'2' => { :name => 'money_in[trip][start_date]' },
        :'3' => { :name => 'money_in[trip][trip_clients][client][name]' },
        :'4' => { :name => 'money_in[trip][trip_clients][client][client_addresses][address][postcode]' }, # Nested attributes style syntax.
        :'5' => { :name => 'money_in.trip.trip_clients.client.client_addresses.address.postcode' }        # Alternative syntax.
      }
    }
    @report.save.should be_true
    @report.reload
    
    @report.should have(6).report_fields
    @report.report_fields[0].name.should == 'amount'
    @report.report_fields[1].name.should == 'money_in[amount]'
    @report.report_fields[2].name.should == 'money_in[trip][start_date]'
    @report.report_fields[4].name.should == 'money_in[trip][trip_clients][client][client_addresses][address][postcode]'
    @report.report_fields[5].name.should == 'money_in.trip.trip_clients.client.client_addresses.address.postcode'
    
    @report.report_fields[0].filter_path.should == :amount
    @report.report_fields[1].filter_path.should == :amount
    @report.report_fields[2].filter_path.should == MoneyIn.trip.start_date
    @report.report_fields[3].filter_path.should == MoneyIn.trip.trip_clients.client.name
    @report.report_fields[4].filter_path.should == MoneyIn.trip.trip_clients.client.client_addresses.address.postcode
    @report.report_fields[5].filter_path.should == MoneyIn.trip.trip_clients.client.client_addresses.address.postcode
    
  end


  it "should derive filter condition syntax" do
    
    # Eg: For queries such as MoneyIn.all( MoneyIn.trip.trip_clients.client.name.like => 'ada%' ).length
    @report.attributes = {
      :report_fields_attributes => {
        :'0' => { :filter_operator => 'eql',  :filter_value => 100,           :name => 'amount' },
        :'1' => { :filter_operator => 'lte',  :filter_value => 200,           :name => 'money_in[amount]' },
        :'2' => { :filter_operator => 'gte',  :filter_value => '2010-11-12',  :name => 'money_in[trip][start_date]' },
        :'3' => { :filter_operator => 'like', :filter_value => 'armitag%',    :name => 'money_in[trip][trip_clients][client][name]' },
        :'4' => { :filter_operator => 'like', :filter_value => 'GL7%',        :name => 'money_in[trip][trip_clients][client][client_addresses][address][postcode]' },
        :'5' => { :filter_operator => 'like', :filter_value => 'GL7%',        :name => 'money_in.trip.trip_clients.client.client_addresses.address.postcode' }       
      }
    }
    @report.save.should be_true
    @report.reload
    
    @report.report_fields[0].filter_condition.should == { :amount => '100' }
    @report.report_fields[1].filter_condition.should == { :amount.lte => '200' }
    @report.report_fields[2].filter_condition.should == { MoneyIn.trip.start_date.gte => '2010-11-12' }
    @report.report_fields[3].filter_condition.should == { MoneyIn.trip.trip_clients.client.name.like => 'armitag%' }
    @report.report_fields[4].filter_condition.should == { MoneyIn.trip.trip_clients.client.client_addresses.address.postcode.like => 'GL7%' }
    @report.report_fields[5].filter_condition.should == { MoneyIn.trip.trip_clients.client.client_addresses.address.postcode.like => 'GL7%' }
    
  end


  it "should accept filters as hash of attributes" do

    @report.attributes = {
      :report_filters_attributes => {
        :'0' => { :filter_operator => 'eql',  :filter_value => 100,           :name => 'amount' },
        :'1' => { :filter_operator => 'lte',  :filter_value => 200,           :name => 'money_in[amount]' },
        :'2' => { :filter_operator => 'gte',  :filter_value => '2010-11-12',  :name => 'money_in[trip][start_date]' },
        :'3' => { :filter_operator => 'like', :filter_value => 'armitag%',    :name => 'money_in[trip][trip_clients][client][name]' },
        :'4' => { :filter_operator => 'like', :filter_value => 'GL7%',        :name => 'money_in[trip][trip_clients][client][client_addresses][address][postcode]' },
        :'5' => { :filter_operator => 'like', :filter_value => 'GL7%',        :name => 'money_in.trip.trip_clients.client.client_addresses.address.postcode' }       
      }
    }
    @report.save.should be_true
    @report.reload

    @report.report_fields.should have(6).report_fields
    @report.filters.should have(6).report_fields

  end


#  it "should accept a combination of new field and filter attributes" do
#
#    @report.attributes = {
#      :report_fields_attributes => {
#        :'0' => { :name => 'amount' },
#        :'1' => { :name => 'money_in.trip.start_date' },
#        :'2' => { :name => 'money_in.trip.trip_clients.client.name' }
#      },
#      :report_filters_attributes => {
#        :'0' => { :name => 'amount',                                  :filter_operator => 'eql',  :filter_value => 100 },
#        :'2' => { :name => 'money_in.trip.trip_clients.client.name',  :filter_operator => 'like', :filter_value => 'armit%' }
#      }
#    }
#    @report.save.should be_true
#    @report.reload
#
#    @report.report_fields.should have(3).report_fields
#    @report.filters.should have(2).report_fields
#
#  end


  it "should accept a combination of new/existing field and filter attributes" do

    # Create:
    @report.attributes = {
      :report_fields_attributes => {
        :'0' => { :name => 'amount' },
        :'1' => { :name => 'money_in.trip.trip_clients.client.name' }
      },
      :report_filters_attributes => {
        :'0' => { :name => 'amount',                                  :filter_operator => 'eql',  :filter_value => 100 }
      }
    }
    @report.save.should be_true
    @report.reload

    @report.report_fields.should have(2).report_fields
    @report.filters.should have(1).report_fields

    existing_filter = @report.filters.first

    # Update with new and existing fields:
    @report.attributes = {
      :report_fields_attributes => {
        :'0' => { :name => 'money_in.trip.start_date' }
      },
      :report_filters_attributes => {
        :'0' => { :id => existing_filter.id,                          :filter_operator => 'lte',  :filter_value => 200 },
        :'1' => { :name => 'money_in.trip.trip_clients.client.name',  :filter_operator => 'like', :filter_value => 'armit%' }
      }
    }
    @report.save.should be_true
    @report.reload

    @report.report_fields.should have(3).report_fields
    @report.filters.should have(2).report_fields

    @report.filters.first.filter_value.should == "200"

  end


  it "should provide list of potential_fields of source model" do

    # When report.source is MoneyIn:
    @report.potential_fields.should have_at_least(5).report_fields    # See MoneyIn.potential_report_fields for the actual number of defined fields.

    @report.potential_fields.select{ |field| field.name == 'MoneyIn.name'           }.should have(1).report_field
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.narrative'      }.should have(1).report_field
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.is_deposit'     }.should have(1).report_field
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.clients.count'  }.should have(1).report_field

    @report.potential_fields.select{ |field| field.name == 'MoneyIn.name'           }.first.property_type.should == ReportField::ATTRIBUTE
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.narrative'      }.first.property_type.should == ReportField::ATTRIBUTE
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.is_deposit'     }.first.property_type.should == ReportField::ATTRIBUTE
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.clients.count'  }.first.property_type.should == ReportField::COUNT
    
    # When report.source is Trip:
    @report.source = 'Trip'
    @report.report_fields.should have(0).report_fields
    @report.potential_fields.select{ |field| field.name == 'Trip.name'              }.should have(1).report_field
    @report.potential_fields.select{ |field| field.name == 'Trip.status.name'   }.should have(1).report_field
    
  end


  it "should provide list of potential_report_filters of source model" do

    @report.potential_filters.should have_at_least(5).report_fields    # See MoneyIn.potential_report_fields for the actual number of defined fields.

    @report.potential_filters.select{ |field| field.name == 'MoneyIn.name'          }.should have(1).report_field
    @report.potential_filters.select{ |field| field.name == 'MoneyIn.narrative'     }.should have(1).report_field
    @report.potential_filters.select{ |field| field.name == 'MoneyIn.is_deposit'    }.should have(1).report_field
    @report.potential_filters.select{ |field| field.name == 'MoneyIn.clients.count' }.should have(0).report_field # Should NOT be a filter.

    @report.potential_filters.select{ |field| field.name == 'MoneyIn.name'       }.first.property_type.should == ReportField::ATTRIBUTE
    @report.potential_filters.select{ |field| field.name == 'MoneyIn.narrative'  }.first.property_type.should == ReportField::ATTRIBUTE
    @report.potential_filters.select{ |field| field.name == 'MoneyIn.is_deposit' }.first.property_type.should == ReportField::ATTRIBUTE
    
  end


  it "should provide list of potential_report_fields of source model associations" do

    pending

    # Report derives more potential_fields from source_model.potential_report_fields and it's associated models.
    @report.potential_fields.should have_at_least(5).report_fields

    # Test for some nested paths and their property type:
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.trip.name'                      }.should have(1).report_field
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.trip.trip_clients.is_primary'   }.should have(1).report_field
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.trip.clients.name'              }.should have(1).report_field
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.client.trip_clients.trip.title' }.should have(1).report_field
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.trip.name'                      }.first.property_type.should == ReportField::ATTRIBUTE
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.trip.trip_clients.is_primary'   }.first.property_type.should == ReportField::ATTRIBUTE
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.trip.clients.name'              }.first.property_type.should == ReportField::ATTRIBUTE
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.client.trip_clients.trip.title' }.first.property_type.should == ReportField::CUSTOM
    
    # Should avoid recursive nesting of field paths: (Where model appears more than one in path)
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.trip.trip_clients.trip.name'                      }.should have(0).report_field
    @report.potential_fields.select{ |field| field.name == 'MoneyIn.trip.trip_clients.client.trip_clients.is_primary' }.should have(0).report_field
    
  end


  it "should derive property_type of each field" do

    @report.attributes = {
      :report_fields_attributes => valid_money_in_report_fields_attributes
    }
    field = @report.report_fields.first

    field.name = 'amount'
    field.property_type.should == ReportField::ATTRIBUTE

    field.name = 'money_in[amount]'
    field.property_type.should == ReportField::ATTRIBUTE

    field.name = 'money_in.trip'
    field.property_type.should == ReportField::OBJECT

    field.name = 'money_in.trip.clients'
    field.property_type.should == ReportField::COLLECTION

    field.name = 'money_in.trip.trip_clients'
    field.property_type.should == ReportField::COLLECTION

    field.name = 'money_in.trip.trip_elements'
    field.property_type.should == ReportField::COLLECTION

    field.name = 'money_in.trip.title'
    field.property_type.should == ReportField::CUSTOM
    
  end




  it "should walk through long filter paths to get value" do

    trip      = Trip.new( valid_trip_attributes )
    trip.save.should be_true
    money_in  = MoneyIn.first

    field_name_parts = @report.report_fields.new( :name => 'MoneyIn.trip.name' ).tokenise_filter_field_name
    @report.walk_path_to_value( money_in, field_name_parts ).should == money_in.trip.name

    field_name_parts = @report.report_fields.new( :name => 'MoneyIn.trip.user.name' ).tokenise_filter_field_name
    @report.walk_path_to_value( money_in, field_name_parts ).should == money_in.trip.user.name

  end



  it "should discard fields when report name is changed" do

    @report.attributes = {
      :report_fields_attributes => valid_money_in_report_fields_attributes
    }
    @report.save.should be_true
    @report.report_fields.should have(4).report_fields

    # Set source to same value:
    @report.source = 'MoneyIn'
    @report.report_fields.should have(4).report_fields

    # Set source to new value:
    @report.source = 'Client'
    @report.report_fields.should have(0).report_fields

  end



  describe " run" do


    it "should run report" do
      
      @report.attributes = {
        :report_fields_attributes => valid_money_in_report_fields_attributes
      }
      @report.save.should be_true
      @report.run.should have_at_least(2).items # Actual number of items will depend on available test data
      
    end

    it "should run report with row limit" do
      
      @report.attributes = {
        :limit                    => 3,
        :report_fields_attributes => valid_money_in_report_fields_attributes
      }
      @report.save.should be_true
      @report.run.should have(3).items
      
    end

    it "should run report with filters" do
      
      @report.attributes = {
        :report_fields_attributes => valid_money_in_report_fields_attributes
      }
      test_field = @report.report_fields.first( :name => 'money_in[amount]' )
      
      # Test filter with just a simple field name:
      test_field.update( :filter_operator => 'lt', :filter_value => 200, :name => 'amount' )
      @report.filters.should have(1).items
      @report.save.should be_true
      
      expected = MoneyIn.all( :amount.lt => 200 )
      @report.run.should have( expected.count ).items
      
      # Test same filter with a more fully qualified field:
      test_field.update( :filter_operator => 'lt', :filter_value => 200, :name => 'money_in[amount]' )
      @report.filters.should have(1).items
      @report.save.should be_true
      
      expected = MoneyIn.all( :amount.lt => 200 )
      @report.run.should have( expected.count ).items
      
      # Test eql filter: (Because it has been depricated and now the code has to to explicitly exclude the operator from the condition)
      test_field.update( :filter_operator => 'eql', :filter_value => 1000 )
      @report.filters.should have(1).items
      @report.save.should be_true
      
      expected = MoneyIn.all( :amount => 1000 )
      @report.run.should have( expected.count ).items
      
    end


    it "should run report with filters containing multiple values" do
      
      Client.create( valid_client_attributes.merge( :name => 'Duck' ) )
      Client.create( valid_client_attributes.merge( :name => 'Goose' ) )
      Client.create( valid_client_attributes.merge( :name => 'Swan' ) )
      Client.create( valid_client_attributes.merge( :name => 'Crow' ) )
      Client.create( valid_client_attributes.merge( :name => 'Cow' ) )

      @report.attributes = {
        :source => 'Client',
        :report_fields_attributes => {
          :'0' => { :name => 'client.name', :filter_operator => 'eql', :filter_value => 'Cow' }
        }        
      }
      
      # Test filter with just a simple field name:
      @report.filters.should have(1).items
      @report.save.should be_true
      @report.run.should have(1).items

      test_field = @report.report_fields.first.filter_value = ['Cow','Crow']
      @report.valid?
      @report.report_fields.first.valid?
      @report.save.should be_true
      @report.run.should have(2).items
      
    end


    it "should run report with filters on association objects" do

      # Set up some test data:
      @report.save.should be_true
      trip   = Trip.new( valid_trip_attributes )
      client = Client.new( valid_client_attributes.merge( :name => 'Armitage' ) )
      trip.save.should be_true
      client.save.should be_true
      trip.clients << client
      trip.save
      trip.clients.should have(1).client

      # Test eql filter: (Because it has been depricated and now the code has to explicitly exclude the operator from the condition)
      @report.report_fields.create( :name => 'money_in[amount]', :filter_operator => 'eql', :filter_value => 1000 )
      @report.filters.should have(1).items
      @report.save.should be_true
      
      expected = MoneyIn.all( :amount => 1000 )
      @report.run.should have( expected.count ).items

      # Test other simple filter:
      @report.report_fields.create( :name => 'money_in[amount]', :filter_operator => 'gt', :filter_value => 200 )
      @report.filters.should have(2).items
      @report.save.should be_true
      
      expected = MoneyIn.all( :amount.gt => 200 )
      @report.run.should have( expected.count ).items

      # Test nested filter consiting of chained objects:
      @report.report_fields.create( :name => 'money_in[trip][user][name]' ).update( :filter_operator => 'like', :filter_value => 'test%' )
      @report.filters.should have(3).items
      @report.save.should be_true
      
      expected = MoneyIn.all( MoneyIn.trip.user.name.like => 'test%', :amount.gt => 200 )
      @report.run.should have( expected.count ).items

      # Test nested filter consiting of chained objects and collections:
      #  @report.report_fields.create( :name => 'money_in[trip][trip_clients][client][name]' ).update( :filter_operator => 'like', :filter_value => 'armitag%' )
      #  @report.filters.should have(3).items
      #  @report.save.should be_true
      #  
      #  expected = MoneyIn.all( MoneyIn.trip.trip_clients.client.name.like => 'armitag%', :amount.gt => 200 )
      #  @report.run.should have( expected.count ).items
      
    end




  end # of Report run




end





def valid_report_attributes
  {
    :name         => 'Sample report',
    :description  => 'Sample report for tesing',
    :source       => 'MoneyIn'
  }
end

# Hash of fields to display in a money_in report: 
def valid_money_in_report_fields_attributes
  {
    :'0' => { :name => 'money_in[name]' },
    :'1' => { :name => 'money_in[trip_id]' },
    :'2' => { :name => 'money_in[amount]' },
    :'3' => { :name => 'money_in[amount]' }
  }
end