require "./document"

module ArangoModel::Persistence
  macro __process_persistence
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}

    # The save method will check to see if the primary exists yet. If it does it
    # will call the update method, otherwise it will call the create method.
    # This will update the timestamps apropriately.
    def save
      begin
        # __run_before_save
        if _id
          # __run_before_update
          @updated_at = Time.now
          @@collection.document.update(to_json)
          # doc = Arango::Document.new(client: @@adapter.client, database: @@adapter.database_name, collection: @@collection_name)
          # doc.update(to_json)
          # __run_after_update
        else
          # __run_before_create
          @created_at = Time.now
          @updated_at = Time.now
          self._id = IdGenerator.generate
          @@collection.document.create(to_json)
          # __run_after_create
        end
        # __run_after_save
        return true
      rescue ex
        if message = ex.message
          puts "Save Exception:"
          puts "  Message: '#{message}'"
          puts "  Object: #{self.inspect}"
          @errors << ArangoModel::Error.new(:base, message)
        end
        return false
      end
    end

    # Destroy will remove this from the database.
    def destroy
      begin
        # __run_before_destroy
        @@adapter.delete(@@collection_name, @@primary_name, {{primary_name}})
        # __run_after_destroy
        return true
      rescue ex
        if message = ex.message
          puts "Destroy Exception: #{message}"
          errors << ArangoModel::Error.new(:base, message)
        end
        return false
      end
    end
  end
end

# class N < ArangoModel::Document
#   include ArangoModel::Persistence
# end
#
# n = N.new
#
# p n.save
