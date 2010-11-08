require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/client_spec.rb

describe Client do

  before :each do

    Trip.all.destroy
    Client.all.destroy
    Address.all.destroy
    TripClient.all.destroy
    ClientAddress.all.destroy
    
    @clientA  = @client   = Client.create(valid_client_attributes)
    @clientB  =             Client.create(valid_client_attributes)
    @tripA    = @trip     = Trip.create(valid_trip_attributes)
    @tripB    =             Trip.create(valid_trip_attributes)
    @addressA = @address  = Address.create(valid_address_attributes)
    @addressB = Address.create(valid_address_attributes2)

    @new_postcode = 'New pcode!'
    
  end


  it 'should be valid' do

    @client.should be_valid

    # Just to be sure about our other test data:
    @addressA.should be_valid
    @addressB.should be_valid
    
  end


  it 'should save new client_address relationship' do

    Address.all.count.should        == 2    # @addressA and @addressB only
    ClientAddress.all.count.should  == 0    # @addressA and @addressB only
        
    @client.client_addresses.should be_empty
    @addressA.clients.should        be_empty
            
    address_relationship = ClientAddress.create( :client => @client, :address => @addressA )

    Address.all.length.should       == 2    # @addressA and @addressB only
    ClientAddress.all.length.should == 1    # address_relationship

    @client.reload                          # <-- This should not be necessary but it is!
    @client.addresses.length.should == 1
    
  end
  
  
  it 'should update address fields through addresses_attributes (using array format)' do
    
    @client.addresses << @addressA
    @client.addresses << @addressB
    @client.save

    @client.addresses_attributes = [
      @addressA.attributes.merge( :postcode => @new_postcode ),
      @addressB.attributes.merge( :postcode => @new_postcode )
    ]
    @client.save.should be_true

    @client.reload
    @addressA.reload
    @addressB.reload
    
    @addressA.postcode.should   == @new_postcode
    @addressB.postcode.should   == @new_postcode
    
  end
  
  
  it 'should update address fields through addresses_attributes (using hash format)' do
    
    # Same as previous test but this time using a hash that is more like the data submitted by a form:

    @client.addresses << @addressA
    @client.addresses << @addressB
    @client.save
    
    @client.attributes = {
      :addresses_attributes => {
        "0" => @addressA.attributes.merge( :postcode => 'AAAA' ),
        "1" => @addressB.attributes.merge( :postcode => 'BBBB' )
      }
    }
    @client.save.should be_true
    
    @client.reload
    @addressA.reload
    @addressB.reload
    
    @addressA.postcode.should   == 'AAAA'
    @addressB.postcode.should   == 'BBBB'
   
  end
  
  
  
  it 'should update address fields through addresses_attributes (using real data)' do
    
    # Same as previous test but this time using loads of values from real data:

    @client.addresses << @addressA
    @client.addresses << @addressB
    @client.save
    
    @client.attributes = {
      "title_id"=>"1", 
      "forename"=>"James", 
      "name"=>"Armitage", 
      "salutation"=>"Mr Armitage", 
      "addressee"=>"Mr J Armitage", 
      "known_as"=>"James", 
      "tel_work"=>"01258 885333", 
      "tel_mobile1"=>"", 
      "tel_mobile2"=>"", 
      "email1"=>"james@steppestravel.co.uk", 
      "email2"=>"", 
      "primary_address_id"=>@addressA.id, 
      "addresses_attributes"=>{
        "0"=>{"id"=>@addressA.id, "address1"=>"xxxHouse", "address2"=>"Ampney Crucis", "address3"=>"Cirencester", "address4"=>"Gloucestershire", "address5"=>"United Kingdom", "postcode"=>"AAAA", "country_id"=>"1", "tel_home"=>"01285 850005", "fax_home"=>""}, 
        "1"=>{"id"=>@addressB.id, "address1"=>"Narracott House", "address2"=>"Ampney Crucis", "address3"=>"Cirencester", "address4"=>"Gloucestershire", "address5"=>"United Kingdom", "postcode"=>"BBBB", "country_id"=>"1", "tel_home"=>"01285 850005", "fax_home"=>""}
      }, 
      "birth_date"=>nil, 
      "birth_place"=>"", 
      "occupation"=>"", 
      "nationality"=>"", 
      "passport_name"=>"", 
      "passport_number"=>"", 
      "passport_issue_place"=>"", 
      "passport_issue_date"=>nil, 
      "passport_expiry_date"=>nil, 
      "notes_frequent_flyer"=>"", 
      "notes_airline"=>"", 
      "notes_seating"=>"", 
      "notes_food"=>"", 
      "marketing_id"=>"2", 
      "original_source_id"=>"1", 
      "source_id"=>"1", 
      "kind_id"=>"1", 
      "interests_ids"=>[1]
    }
    @client.save.should be_true
    
    @client.reload
    @addressA.reload
    @addressB.reload
    
    @addressA.postcode.should   == 'AAAA'
    @addressB.postcode.should   == 'BBBB'
   
  end


  it 'should add addresses through addresses_ids' do
    
    @client.addresses.should have(0).addresses
    
    @client.addresses_ids = [ @addressA.id, @addressB.id ]
    @client.save.should be_true
    
    @client.addresses.should have(2).addresses
    
  end



  it 'should not affect addresses of clients that share same trip' do
    
    orig_postcode = @addressB.postcode
    orig_postcode.should_not == @new_postcode
    
    @trip.clients_ids = [ @clientA.id, @clientB.id ]
    @trip.save

    @trip.clients.should have(2).clients
    @clientA.trips.should have(1).trips
    @clientB.trips.should have(1).trips

    @clientA.addresses_ids = [ @addressA.id ]
    @clientB.addresses_ids = [ @addressB.id ]
    @clientA.save.should be_true
    @clientB.save.should be_true

    @clientA.addresses.should have(1).addresses
    @clientB.addresses.should have(1).addresses

    @clientA.addresses_attributes = [
      @addressA.attributes.merge( :postcode => @new_postcode )
    ]
    @clientA.save
    @clientA.reload
    @clientB.reload

    @clientA.addresses.should have(1).addresses
    @clientB.addresses.should have(1).addresses

    @clientA.addresses.first.postcode.should == @new_postcode
    @clientB.addresses.first.postcode.should == orig_postcode
    
  end



  it 'should affect addresses of clients that share same address through one client' do
    
    pending

    #  orig_postcode = @addressB.postcode
    #  orig_postcode.should_not == @new_postcode
    #
    #  @clientA.addresses_ids  = [ @addressA.id ]
    #  @clientB.addresses_ids  = [ @addressB.id ]
    #  @clientB.address_client = @clientA
    #  @clientA.save.should be_true
    #  @clientB.save.should be_true
    #
    #  @clientA.addresses.should have(1).addresses
    #  @clientB.addresses.should have(1).addresses
    #
    #  @clientA.addresses_attributes = [
    #    @addressA.attributes.merge( :postcode => @new_postcode )
    #  ]
    #  @clientA.save
    #  @clientA.reload
    #  @clientB.reload
    #
    #  @clientA.addresses.should have(1).addresses
    #  @clientB.addresses.should have(1).addresses
    #
    #  @clientA.addresses.first.postcode.should == @new_postcode
    #  @clientB.addresses.first.postcode.should == @clientA.addresses.first.postcode
    
  end


  
  it 'should assume a default primary address when none specified' do
    
    @client.addresses << @addressA
    @client.addresses << @addressB
    @client.save
    
    # One address should be active:
    @client.reload
    @client.client_addresses.first.is_active.should == true
    @client.addresses.all( ClientAddress.is_active => true ).should have(1).address

    # Make all addresses not active:
    @client.client_addresses.first.is_active = false
    @client.save
    @client.addresses.should have(2).addresses
    #@client.client_addresses.first.is_active.should == true
    #@client.client_addresses.last.is_active.should  == false
    @client.addresses.all( ClientAddress.is_active => true ).should have(1).address

    # Ditch @addressA so that @addressB should become primary:
    @client.addresses_ids = [ @addressB.id ]
    @client.save
    @client.reload
    @client.addresses.should have(1).address
    @client.client_addresses.should have(1).client_address
    @client.client_addresses.first.is_active.should == true

  end


  
  it 'should allow address to be deleted' do
    
    # Same as previous test but this time using a hash that is more like the data submitted by a form:
    
    @client.addresses << @addressA
    @client.addresses << @addressB
    @client.save

    @client.addresses.should have(2).addresses
    @client.client_addresses.should have(2).client_addresses
    @client.client_addresses.first( :address_id => @addressA.id ).is_active.should == true
    
    @client.attributes = {
      :addresses_attributes => {
        "0" => @addressA.attributes.merge( :_delete  => true   ) ,
        "1" => @addressB.attributes.merge( :postcode => 'BBBB' )
      }
    }
    @client.save.should be_true
    
    @client.reload

    @client.addresses.should have(1).addresses
    @client.client_addresses.should have(1).client_addresses
    #@client.client_addresses.first( :address_id => @addressB.id ).is_active.should == true

    @addressB.postcode.should   == 'BBBB'
    
  end
  

  it 'should assume new default primary address when primary is deleted' do

    pending 'Current workaround it to avoid deleting primary address'

    # Could not figure out how to do this using before/after :destroy hooks etc.
    
  end

end