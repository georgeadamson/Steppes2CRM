class TripPnr
  include DataMapper::Resource
 
  property :id,					Serial
	property :trip_id,		Integer,	:index	=> :trip_pnrs
	property :pnr_id,			Integer,	:index	=> :trip_pnrs
	property :pnr_number,	String,		:length	=> 6					# TODO: Use this field instead of pnr_id. Easier to debug data and recover when this table is wiped!

	belongs_to :pnr,	:child_key => [:pnr_id]
	belongs_to :trip,	:child_key => [:trip_id]

  before :save do
    # Store the pnr number alongside to aid troubleshooting
    self.pnr_number = self.pnr.name
  end

end

# TripPnr.auto_migrate!				# Warning: Running this will clear the trip_pnrs table!