class DoorEvent
  include DataMapper::Resource

  belongs_to :door
  
  property :id,           Serial
  property :created_at,   DateTime
  property :updated_at,   DateTime
end
