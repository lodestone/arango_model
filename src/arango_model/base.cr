require "active-model"

module ArangoModel
  class Base < ActiveModel::Model
    # def initialize(args = {} of String => (Array(String) | JSON::Any | String))
    #   # p args.keys
    # end
    def initialize(@args = {} of String => (Array(String) | JSON::Any | String))
    end

    def save
      self
    end

    def self.create(args = {} of String => (Array(String) | JSON::Any | String))
      self.new(**args)
    end

    def self.find(args)
    end

    def inspect
      "#<#{self.class}:0x#{self.object_id.to_s(16)}\t   #{attributes.map{|k,v| "\n  @#{k}: #{v.inspect}" }.join(", ")}>"
    end
  end
end
