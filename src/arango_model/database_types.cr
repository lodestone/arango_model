require "json"

module ArangoModel::DatabaseTypes # needed for fields support
  TYPES = [Nil, String, Bool, Int32, Int64, Float32, Float64, Time, Bytes, JSON::Any, Hash(String, String)]
  {% begin %}
    alias Any = Union({{*TYPES}})
  {% end %}
end
