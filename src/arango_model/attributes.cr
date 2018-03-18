require "json"
require "./settings"
require "./database_types"

module ArangoModel::Attributes
  TYPES = [Nil, String, Bool, Int32, Int64, Float32, Float64, Time, Bytes, JSON::Any, Array(String), Hash(String, String)]
  {% begin %}
    alias Type = Union({{*TYPES}})
  {% end %}
  # Type = Any
  TIME_FORMAT_REGEX = /\d{4,}-\d{2,}-\d{2,}\s\d{2,}:\d{2,}:\d{2,}/

  # extend Settings

  macro included
    macro inherited
      ATTRIBUTES = {} of Nil => Nil
    end
  end

  # specify the fields you want to define and types
  macro attribute(decl)
    {% ATTRIBUTES[decl.var] = decl.type %}
  end

  # include created_at and updated_at that will automatically be updated
  macro timestamps
    {% SETTINGS[:timestamps] = true %}
  end

  macro __process_attributes
    # Create the properties
    {% for name, type in ATTRIBUTES %}
      property {{name.id}} : Union({{type.id}} | Nil)
    {% end %}
    {% if SETTINGS[:timestamps] %}
      property created_at : Time?
      property updated_at : Time?
    {% end %}

    # keep a hash of the attributes to be used for mapping
    def self.attributes(attributes = [] of String)
      {% for name, type in ATTRIBUTES %}
        attributes << "{{name.id}}"
      {% end %}
      {% if SETTINGS[:timestamps] %}
        attributes << "created_at"
        attributes << "updated_at"
      {% end %}
      return attributes
    end

    # keep a hash of the attributes to be used for mapping
    def attributes(attributes = {} of String => Type)
      {% for name, type in ATTRIBUTES %}
        attributes["{{name.id}}"] = self.{{name.id}}
      {% end %}
      {% if SETTINGS[:timestamps] %}
        attributes["created_at"] = self.created_at
        attributes["updated_at"] = self.updated_at
      {% end %}
      attributes["_id"] = self._id
      return attributes
    end

    # keep a hash of the params that will be passed to the adapter.
    def params
      parsed_params = [] of DatabaseTypes::Any
      {% for name, type in ATTRIBUTES %}
        {% if type.id == Time.id %}
          parsed_params << {{name.id}}.try(&.to_s("%F %X"))
        {% else %}
          parsed_params << {{name.id}}
        {% end %}
      {% end %}
      {% if SETTINGS[:timestamps] %}
        parsed_params << created_at.not_nil!.to_s("%F %X")
        parsed_params << updated_at.not_nil!.to_s("%F %X")
      {% end %}
      return parsed_params
    end

    def to_h
      # attributes = {} of String => String | Nil | Int32 | Array(String) | Hash(String, String)
      attributes = {} of String => ArangoModel::DatabaseTypes::Any

      attributes["{{PRIMARY[:name]}}"] = {{PRIMARY[:name]}}

      {% for name, type in ATTRIBUTES %}
        {% if type.id == Time.id %}
          attributes["{{name}}"] = {{name.id}}.try(&.to_s("%F %X"))
        {% elsif type.id == Slice.id %}
          attributes["{{name}}"] = {{name.id}}.try(&.to_s(""))
        {% else %}
          attributes["{{name}}"] = {{name.id}}
        {% end %}
      {% end %}
      {% if SETTINGS[:timestamps] %}
        attributes["created_at"] = created_at.try(&.to_s("%F %X"))
        attributes["updated_at"] = updated_at.try(&.to_s("%F %X"))
      {% end %}

      return attributes
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "{{PRIMARY[:name]}}", {{PRIMARY[:name]}}

        {% for name, type in ATTRIBUTES %}
          %attribute, %value = "{{name.id}}", {{name.id}}
          {% if type.id == Time.id %}
            json.field %attribute, %value.try(&.to_s(%F %X))
          {% elsif type.id == Slice.id %}
            json.field %attribute, %value.id.try(&.to_s(""))
          {% else %}
            json.field %attribute, %value
          {% end %}
        {% end %}

        {% if SETTINGS[:timestamps] %}
          json.field "created_at", created_at.try(&.to_s("%F %X"))
          json.field "updated_at", updated_at.try(&.to_s("%F %X"))
        {% end %}
      end
    end

    def set_attributes(args : Hash(String | Symbol, Type))
      args.each do |k, v|
        cast_to_attribute(k, v.as(Type))
      end
    end

    def set_attributes(**args)
      set_attributes(args.to_h)
    end

    # Casts params and sets attributes
    private def cast_to_attribute(name, value : Type)
      case name.to_s
        {% for _name, type in ATTRIBUTES %}
        when "{{_name.id}}"
          return @{{_name.id}} = nil if value.nil?
          {% if type.id == Int32.id %}
            @{{_name.id}} = value.is_a?(String) ? value.to_i32 : value.is_a?(Int64) ? value.to_s.to_i32 : value.as(Int32)
          {% elsif type.id == Int64.id %}
            @{{_name.id}} = value.is_a?(String) ? value.to_i64 : value.as(Int64)
          {% elsif type.id == Float32.id %}
            @{{_name.id}} = value.is_a?(String) ? value.to_f32 : value.is_a?(Float64) ? value.to_s.to_f32 : value.as(Float32)
          {% elsif type.id == Float64.id %}
            @{{_name.id}} = value.is_a?(String) ? value.to_f64 : value.as(Float64)
          {% elsif type.id == Bool.id %}
            @{{_name.id}} = ["1", "yes", "true", true].includes?(value)
          {% elsif type.id == Time.id %}
            if value.is_a?(Time)
               @{{_name.id}} = value.to_utc
             elsif value.to_s =~ TIME_FORMAT_REGEX
               @{{_name.id}} = Time.parse(value.to_s, "%F %X").to_utc
             end
          {% else %}
            @{{_name.id}} = value.to_s
          {% end %}
        {% end %}
      end
    end
  end
end
