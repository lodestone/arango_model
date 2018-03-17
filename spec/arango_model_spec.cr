require "./spec_helper"

class Ninja < ArangoModel::Base
  # DEFAULT_JSON = {"t" => "x"}
  attribute name : String
  attribute epithet : String
  attribute age : Int32
  attribute enemies : Array(String) = [] of String
  attribute properties : JSON::Any
  # attribute enemies : JSON::Any
end

describe ArangoModel do
  it "should be an instance of ActiveModel" do
    Ninja.new.should_not be_nil
  end

  it "should have a string attribute" do
    ninja = Ninja.new name: "Hiro"
    ninja.name.should eq("Hiro")
  end

  it "should have an integer attribute" do
    ninja = Ninja.new age: 25
    ninja.age.should eq(25)
  end

  it "should generally work okay" do
    (ninja=Ninja.new).enemies = %w[ Joe Barry ]
    (ninja.enemies || [] of String).first.should eq("Joe")
    (ninja.enemies || [] of String).last.should eq("Barry")
  end

  it "should support json" do
    ninja = Ninja.new
    ninja.properties = JSON::Any.new({"this" => "that"}.to_json)
    ninja.properties.should eq("{\"this\":\"that\"}")
  end

  # it "should have an array attribute" do
  #   ninja = Ninja.new
  #   ninja.enemies = {larry: "Larry from accounting", neighbor: "The snooty neighbor"}
  #   p ninja.enemies
  #   if !ninja.enemies.nil?
  #     ninja.enemies[0].should eq("Larry from accounting")
  #     ninja.enemies[1].should eq("The snooty neighbor")
  #   end
  # end
end
