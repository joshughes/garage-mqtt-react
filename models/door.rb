class Door
  include DataMapper::Resource

  has n, :door_events

  property :id,           Serial
  property :open?,        Boolean
  property :created_at,   DateTime
  property :updated_at,   DateTime
end
