require "arangocr"
require "yaml"

class ArangoModel::Adapter
  property database : Arango::Database
  property client : Arango::Client
  property database_url : String = "http://127.0.0.1:8529"
  property database_name : String = "arango_database"
  DATABASE_YML = "config/database.yml"

  def initialize
    # @database_url = "http://127.0.0.1:8529"
    # @database_name = "arango_database"
    if ENV["DATABASE_URL"]?
      @database_url = ENV["DATABASE_URL"]
    elsif File.exists?(DATABASE_YML)
      yaml = YAML.parse(File.read DATABASE_YML)
      @database_url = yaml["database_url"].to_s if yaml["database_url"]?
      @database_name = yaml["database_name"].to_s if yaml["database_name"]?
    end
    @client = Arango::Client.new database_url, "root", ""
    @database_name = ENV["DATABASE_NAME"] if ENV["DATABASE_NAME"]?
    @database = @client.database(@database_name)
  end
end
