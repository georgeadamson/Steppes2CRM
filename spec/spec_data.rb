
def valid_company_attributes
  {
    :name     => 'Steppes Test',
    :initials => 'ST'
  }
end


def valid_country_attributes

  company      = Company.first_or_create( { :name => valid_company_attributes[:name] }, valid_company_attributes )
  world_region = WorldRegion.first_or_create( { :name => 'Dummy Region' }, { :name => 'Dummy Region' } )
  mailing_zone = MailingZone.first_or_create( { :name => 'Dummy Zone'   }, { :name => 'Dummy Zone'   } )

  {
    :code          => 'C1',
    :name          => 'Country 1',
    :companies_ids => [company.id],
    :world_region  => world_region,
    :mailing_zone  => mailing_zone
  }

end

def valid_airport_attributes
  {
    :name     => 'Aeropuerto de las Américas',
    :code     => 'SDQ',
    :city     => 'Santo Domingo',
    :tax      => 0,
    :country  => Country.first_or_create( { :code => valid_country_attributes[:code] }, valid_country_attributes )
  }
end


def valid_client_attributes
  {
    :title              => Title.first_or_create( { :name => 'Mr' }, { :name => 'Mr' } ),
    :name               => 'Client 1',
    :forename           => 'Test',
    :marketing_id       => 1,
    :type_id            => 1,
    :original_source_id => 1,
    :address_client_id  => 1
  }
end


def valid_address_attributes
  {
    :address1   => 'House name or number',
    :address2   => 'Locality',
    :address3   => 'Region',
    :address4   => 'Town or city',
    :address5   => 'County or state',
    :address6   => 'Address 6 unused',
    :postcode   => 'AB1 1AB',
    :country    => Country.first_or_create( { :code => valid_country_attributes[:code] }, valid_country_attributes ),
    :tel_home   => '0123456789',
    :fax_home   => '+44 (0)123456789'
  }
end

def valid_address_attributes2
  {
    :address1   => 'Another House name or number',
    :address2   => 'Another Locality',
    :address3   => 'Another Region',
    :address4   => 'Another Town or city',
    :address5   => 'Another County or state',
    :address6   => 'Another Address 6 unused',
    :postcode   => 'AB2 2AB',
    :country    => Country.first_or_create( { :code => valid_country_attributes[:code] }, valid_country_attributes ),
    :tel_home   => '2 0123456789',
    :fax_home   => '2 +44 (0)123456789'
  }
end



def valid_tour_attributes
  {
    :name       => 'Test tour',
    :notes      => 'Just some notes',
    :company_id => 1
  }
end


# @trip = Trip.new(:name=>'Test trip',:start_date=>Date.today,:end_date=>Date.today+10,:company_id=>1,:user_id=>1)
def valid_trip_attributes
  {
    :name                       => 'Test trip',
    :start_date                 => Time.now,
    :end_date                   => 10.days.from_now,
    :company_id                 => 1,
    :user_id                    => 1,
    :price_per_adult            => 1000,
    :price_per_child            => 900,
    :price_per_infant           => 800,
    :price_per_adult_biz_supp   => 100,
    :price_per_child_biz_supp   => 100,
    :price_per_infant_biz_supp  => 100
  }
end


def valid_flight_attributes
  {
    :name                 => 'Test flight',
    :type_id              => 1,
    :supplier_id          => 1,
    :handler_id           => 1,
    :exchange_rate        => 0.8,
    :margin               => 25,
    :margin_type          => '%',
    :start_date           => Time.now,
    :end_date             => 5.days.from_now,
    :depart_airport_id    => 1,
    :arrive_airport_id    => 2,
    :adults               => 2,
    :children             => 2,
    :infants              => 2,
    :singles              => 2,
    :cost_per_adult       => 1200,
    :cost_per_child       => 120,
    :cost_per_infant      => 12,
    :cost_per_single      => 9,
    :biz_supp_per_adult   => 900,
    :biz_supp_per_child   => 90,
    :biz_supp_per_infant  => 9,
    :biz_supp_margin      => 10,
    :biz_supp_margin_type => '%',
    :taxes                => 40
  }
end





# Sample PNR data with VALID flights and a VOID-flight:
def valid_pnr_attributes
  {
    :name								=> 'ABCDEF',														# Must match MUC line in the raw data. Deliberately using fake PNR Number in case we accidentally run specs on live data and overwrite a real PNR!
    :booking_date				=> Date.parse('2010-03-15'),						# Must match D- line in the raw data below.
    :reminder_date			=> Date.parse('2010-03-20'),						# Must match TKTL line in the raw data below.
    :first_flight_date	=> DateTime.parse('2010-05-01T13:15'),	# Must match earliest U- line in the raw data below.
    :file_date					=> DateTime.parse('2010-03-15'),				# Don't match this hard-coded value when testing data loaded from a pnr file!!!
    :file_name					=> 'MOCK_PNR_FOR_AUTO_TESTS.txt',
    :flight_count				=> 2,																		# Must match number of valid U- lines in the raw data.
    :client_count				=> 1,																		# Must match number of valid I- lines line in the raw data.
			:data								=> "AIR-BLK207;IM;;233;1500012976;1A1203214;001001
AMD 1500000001;1/1;              
GW4464979;1A1203214
MUC1A ABCDEF002;0101;LONU12102;91497221;LONU12102;91497221;LONU12102;91497221;LONU12102;91497221;;;;;;;;;;;;;;;;;;;;;;BA NOSYNC
A-
B-BT
C-    / 8888GGSU-8888GGSU----
D-100315;100315;100315
U-001X;002OLHR;LONDON LHR       ;GIG;RIO JANEIRO GIG  ;BA    0249 S S 01MAY1315 2055 01MAY;HK01;HK01;M ;0;777;;;;5 ;;ET;1140 ;N;;5730;;GB;BR;1 
U-000X;000OGIG;RIO DE JANEIRO IN;GRU;GUARULHOS INTL   ;VOID;BR;BR              
U-002X;003OGIG;RIO JANEIRO GIG  ;LHR;LONDON LHR       ;BA    0248 S S 15MAY2225 1340 16MAY;HK01;HK01;M ;0;777;;;;1 ;;ET;1115 ;N;;5730;;BR;GB;5 
I-001;01ARMITAGE/JAMESMR;;APSTEPPES TRAVEL 01285 885333 JAMES;;
OSI BA  LMSB
K-
L-
M-
O-
Q-
TKTL20MAR/LONU12102
    ENDX"
  }
end


# Same as valid_pnr_attributes but with modified flights:
#(Flights 005 & 008 added, Flight 002 removed, flight 001 just has DIFFERENT DATES AND TIMES)
def updated_pnr_attributes
  {
    :name								=> 'ABCDEF',														# Must match MUC line in the raw data. Deliberately using fake PNR Number in case we accidentally run specs on live data and overwrite a real PNR!
    :booking_date				=> Date.parse('2010-03-15'),						# Must match D- line in the raw data.
    :reminder_date			=> Date.parse('2010-03-20'),						# Must match TKTL line in the raw data.
    :first_flight_date	=> DateTime.parse('2010-05-01T13:15'),	# Must match earliest U- line in the raw data.
    :file_date					=> DateTime.parse('2010-03-16'),				# MORE RECENT than valid_pnr_attributes
    :file_name					=> 'MOCK_PNR_FOR_AUTO_TESTS2.txt',
    :flight_count				=> 3,																		# Must match number of valid U- lines in the raw data.
    :client_count				=> 1,																		# Must match number of valid I- lines line in the raw data.
			:data								=> "AIR-BLK207;IM;;233;1500012976;1A1203214;001001
AMD 1500000001;1/1;              
GW4464979;1A1203214
MUC1A ABCDEF002;0101;LONU12102;91497221;LONU12102;91497221;LONU12102;91497221;LONU12102;91497221;;;;;;;;;;;;;;;;;;;;;;BA NOSYNC
A-
B-BT
C-    / 8888GGSU-8888GGSU----
D-100315;100315;100315
U-001X;002OLHR;LONDON LHR       ;GIG;RIO JANEIRO GIG  ;BA    0249 S S 02MAY1416 2156 02MAY;HK01;HK01;M ;0;777;;;;5 ;;ET;1140 ;N;;5730;;GB;BR;1 
U-005X;004OGRU;SAO PAULO GRU    ;EZE;BUENOS AIRES EZE ;LA    6460 Y Y 03MAY0830 1120 03MAY;HK01;HK01;;0;332;;;;1 ;;ET;0250 ;N;;1066;;BR;AR;A 
U-000X;000OJRO;KILIMANJARO      ;NBO;JOMO KENYATTA    ;VOID;TZ;KE              
U-008X;005ONBO;NAIROBI KENYATTA ;LHR;LONDON LHR       ;KQ    0104 T T 20JUN1050 1750 20JUN;HK01;HK01;M ;0;772;;;;;;ET;0900 ;N;;4248;;KE;GB;4 
I-001;01ARMITAGE/JAMESMR;;APSTEPPES TRAVEL 01285 885333 JAMES;;
OSI BA  LMSB
K-
L-
M-
O-
Q-
TKTL20MAR/LONU12102
    ENDX"
  }
end

alias valid_pnr_attributes2 updated_pnr_attributes






  def valid_invoice_attributes 
    {
      :name         => '',
      :amount       => 100,
      :deposit      => 0,
      :trip_id      => 1,
      :client_id    => 1,
      :user_id      => 1,
      :is_deposit   => false,
      :company_id   => @company.id,
      :narrative    => 'Lorem ipsum...',
      :invoice_date => Date.today,      # AKA created_at
      #:due_date     => nil,             # Will default to trip.start_date - company.due_days
      :skip_doc_generation => true      # <-- Prevents docs from being created automatically during tests!
    }
  end



  def valid_user_attributes
    {
      :forename               => 'Test',			
      :name                   => 'Tester',					
      :login                  => 'tester',					
      :company_id             => 1,			
      :is_active              => true,			
      :preferred_name         => 'Tester',
      :password               => 'password',
      :password_confirmation  => 'password'
    }
  end



  def valid_brochure_request_attributes

    title    = Title.first_or_create(   { :name => 'Mr'  },  :name => 'Mr' )
    client   = Client.first_or_create(  { :name => 'Client 1'  }, { :title => title, :name => 'Client 1', :forename => 'Test', :marketing_id => 1, :type_id => 1, :original_source_id => 1, :address_client_id => 1 } )
    company  = Company.first_or_create( { :initials => 'tst' }, { :initials => 'tst' } )
    
    initials = company.initials
    doc_type = DocumentType.get( DocumentType::BROCHURE )

    {
      :notes                  => 'Notes about this brochure request',                
      :custom_text            => 'Some copy to add to the letter',          
      :document_template_file => "#{ initials }_#{ doc_type.template_file_name }",   # Eg: SV_Letter_Brochure_Enquiry.doc
      #:requested_date         => Time.now, # This should default to Time.now   
      :generated_date         => nil,       
      :client                 => client,            
      :company_id             => company.id,           
      :user_id                => User.first.id,
      :skip_doc_generation    => true
    }

  end



  # Only used to set up dummy data for reports etc.
  # Because of the number of hooks and dependencies, make sure you use MoneyIn.create! (with exclamation mark)
  # Real money_in data should be created by invoicing a trip etc.
  def valid_money_in_attributes
    {
      :name                 => 'ST1',
      :trip_id              => 1,           
      :client_id            => 1,         
      :amount               => 1000,            
      :biz_supp_amount      => 1000,   
      :single_supp_amount   => 1000,
      :adjustment_amount    => 1000, 
      :adjustment_name      => 1000,   
      :total_amount         => 1000,      
      :amount_received      => 1000,   
      :due_date             => '2010-02-03',          
      :received_date        => '2010-01-02',     
      :is_deposit           => false,        
      :is_received          => false,       
      :payment_method       => '',
      :narrative            => 'Description of invoice', 
      :company_id           => 1,
      :user_id              => 1,
      :document_id          => 1
    }
  end






  def seed_lookup_tables

    User.create( valid_user_attributes )

    # Trip statuses:
    TripState.create( :name => 'Unconfirmed' )  # 1
    TripState.create( :name => 'Confirmed'   )  # 2
    TripState.create( :name => 'Completed'   )  # 3
    TripState.create( :name => 'Abandonned'  )  # 4
    TripState.create( :name => 'Cancelled'   )  # 5

    # Trip statuses:
    TripType.create( :name => 'Tailor made'     )  # 1
    TripType.create( :name => 'Tour template'   )  # 2
    TripType.create( :name => 'Private group'   )  # 3
    TripType.create( :name => 'Fixed Departure' )  # 4

    # DocumentType.copy :production, :test
    # The command above should work but had to be done manually instead:
    DocumentType.create( :name => 'Itinerary',              :template_file_name => 'Itinerary.doc' )
    DocumentType.create( :name => 'Main Invoice',           :template_file_name => 'Invoice.doc' )
    DocumentType.create( :name => 'Credit Note',            :template_file_name => 'CreditNote.doc' )
    DocumentType.create( :name => 'Supplementary Invoice',  :template_file_name => 'InvoiceSupp.doc' )
    DocumentType.create( :name => 'Contact Sheet',          :template_file_name => 'ContactSheet.doc' )
    DocumentType.create( :name => 'Control Sheet',          :template_file_name => 'ControlSheet.doc' )
    DocumentType.create( :name => 'Voucher',                :template_file_name => 'Voucher.doc' )
    DocumentType.create( :name => 'Letter',                 :template_file_name => 'Letter.doc' )
    DocumentType.create( :name => 'Draft Main Invoice',     :template_file_name => '(unused).doc' )
    DocumentType.create( :name => 'Non-ATOL Invoice',       :template_file_name => 'InvoiceNonATOL.doc' )
    DocumentType.create( :name => 'Quick Itinerary',        :template_file_name => 'ItineraryQuick.doc' )
    DocumentType.create( :name => 'Brochure',               :template_file_name => 'Letter_Brochure_Enquiry.doc' )

  end