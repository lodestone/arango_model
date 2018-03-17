require "json"
require "./error"
require "./settings"
require "./collection"
require "./attributes"
# require "./callbacks"
# require "./querying"
# require "./persistence"
# require "./validators"
# require "./version"
# require "./associations"
# require "./embedded_document"


class ArangoModel::Document
  # include Associations
  # include Callbacks
  include Attributes
  include Settings
  include Collection
  # include Persistence
  # include Validators

  # extend Querying

  @errors = [] of ArangoModel::Error

  def errors
    @errors
  end

  macro inherited
    macro finished
      __process_collection
      __process_attributes
      # __process_querying
      # __process_persistence

      def inspect(io)
        sts = [] of String
        sts << " _id: #{self._id.nil? ? "nil" : self._id.inspect}"
        attributes.each do |attribute_name, attribute_value|
          next if attribute_name == "_id"
          sts << " #{attribute_name}: #{attribute_value.nil? ? "nil" : attribute_value.inspect}"
        end
        io << "#{self.class} {#{sts.join(",")}}"
      end
    end
  end

  def initialize(**args : Object)
    set_attributes(args.to_h)
  end

  def initialize(args : Hash(Symbol | String, String | JSON::Type))
    set_attributes(args)
  end

  def initialize
  end

  # def self.drop
  #   clear
  # end

  # def equals?(val : Document)
  #   self.to_h.to_s == val.to_h.to_s
  # end
end
