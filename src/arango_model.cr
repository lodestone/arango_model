require "active-model"
require "arangocr"
# require "./arango_model/document"
require "./arango_model/*"

module ArangoModel
end

class Fighter < ArangoModel::Document
  attribute _id : String
  attribute name : String
  attribute age : Int32
  attribute weapons : String | Array(String)
  attribute deleted_at : Time
  attribute dead : Bool
  timestamps
end

p Fighter.new
# exit 0

class Ninja < ArangoModel::Document
  attribute _id : String
  attribute name : String
  attribute age : Int32
  attribute weapons : String | Array(String)
  attribute enemies : String | JSON::Any | Hash(String, String)
end

json = JSON.parse({"name" => "Kano"}.to_json)
# p Ninja.new("Nakamura", 25, nil, json)
# p Ninja.new({"name" => "Willson", "enemies" => json})
p Ninja.new(name: "Milena", enemies: json)

# ------------------------------------------
# Story:
# nakamura = Ninja.create({
#   "name" => "Jack Nakamura",
#   "age" =>  25,
#   "weapons" => %w[ katana shuriken ]
# })
# p nakamura

# puts Ninja.new.methods.sort
chuck = Ninja.create({name: "Chuck", age: 55, weapons: %w[ feet ], enemies: nil})
p chuck
Ninja.create({name: "Raiden"})
Ninja.create({name: "Joseph", age: 12, weapons: %w[ fists ], enemies: { "x" => "y" }})
# Ninja.create({name: "Jonny", enemies: {"one" => "two"}})

# ------------------------------------------

client = Arango::Client.new("http://127.0.0.1:8529", "root", "")
database = client.database("arango_model_test")

puts "All Databases"
puts database.all

puts "\nCurrent Database"
puts database.current

p ninjas = database.collection("ninjas")

#
# willson = Ninja.new
# willson.name = "Hiro Willson"
# willson.age = 32
# willson.weapons = %w[ wakazashi katana ]
# willson.enemies = [ nakamura ]
#
# nakamura.enemies = [ willson ]
# nakamura.save
puts "\nInsert one document"
data = [] of Hash(String, String)
(1..10).each do |i|
  data.push({"fn" => "#{i} Olivier", "ln" => "#{i} BONNAURE"})
end
p ninjas.document.create(data)

puts "\nRead all Keys"
p ninjas.all_keys

# puts "\nRun AQL query (cursor)"
# aql = database.aql
# cursor = aql.cursor({"query" => "FOR d IN demo RETURN d"})
# puts cursor["result"].size
# while (cursor["hasMore"] == true)
#   cursor = aql.next(cursor["id"].to_s)
#   puts cursor["result"].size
# end

puts "\nTruncate collection demo"
puts ninjas.truncate

puts "\nDelete collection demo"
puts ninjas.delete

puts "\nDelete database"
puts database.delete
