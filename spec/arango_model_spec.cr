require "./spec_helper"

class Ninja < ArangoModel::Base
  attribute name : String
  attribute epithet : String
  attribute age : Int32
  attribute weapons : Array(String) = [] of String
  attribute enemies : JSON::Any
end

describe ArangoModel do
  it "should be an instance of ActiveModel" do
    Ninja.new.should_not be_nil
  end

  it "should support a string attribute" do
    ninja = Ninja.new name: "Hiro"
    ninja.name.should eq("Hiro")
  end

  it "should support an integer attribute" do
    ninja = Ninja.new age: 25
    ninja.age.should eq(25)
  end

  it "should support an array attribute" do
    (ninja=Ninja.new).weapons = %w[ katana shuriken ]
    (ninja.weapons || [] of String).first.should eq("katana")
    (ninja.weapons || [] of String).last.should eq("shuriken")
  end

  it "should support a json attribute" do
    ninja = Ninja.new
    ninja.enemies = JSON::Any.new([{"name" => "Hiro"}, {"name" => "Shane"}].to_json)
    ninja.enemies.should eq("[{\"name\":\"Hiro\"},{\"name\":\"Shane\"}]")
  end
end
