class VirtualCabinet
  #include DataMapper::Resource

  # This generates a VirtualCabinet Command File in the folder corresponding to the specified user.
  # VirtualCabinet watches for file changes and will open the Client or Tour docs in VirtualCabinet on the User's PC.

  # This method is named "create" simply to be consistent with datamapper:
  def self.create( user, client_or_tour, trip_id = nil )

    if client_or_tour.is_a? Tour

      # Group Tour
      sql_statement = 'EXEC sp_vcab_command_file @username=?, @tour_id=?, @trip_id=?'

    else

      # Client
      sql_statement = 'EXEC sp_vcab_command_file @username=?, @client_id=?, @trip_id=?'
      
    end

    result = repository(:default).adapter.select( sql_statement, user.id, client_or_tour.id, trip_id )
      
  end

  class << self 
    alias :open :create
  end

end
