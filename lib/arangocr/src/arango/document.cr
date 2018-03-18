require "./client"

class Arango::Document
  @client : Arango::Client

  getter client

  def initialize(@client, @database : String, @collection : String); end

  def get(id : String)
    @client.get("/_db/#{@database}/_api/document/#{@collection}/#{id}")
  end

  def head(id : String)
    @client.head("/_db/#{@database}/_api/document/#{@collection}/#{id}")
  end

  def create(body : Hash | Array | String, urlParams = "")
    @client.post("/_db/#{@database}/_api/document/#{@collection}?#{urlParams}", body)
  end

  def update(body : Hash | Array | String, urlParams = "")
    @client.patch("/_db/#{@database}/_api/document/#{@collection}?#{urlParams}", body)
  end

  def delete(id : String)
    @client.delete("/_db/#{@database}/_api/document/#{@collection}/#{id}")
  end

  def delete(ids : Array)
    @client.delete("/_db/#{@database}/_api/document/#{@collection}", ids)
  end
end
