def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
   end

def list
   db = SQLite3::Database.new('db/onepiece.db')
   db.results_as_hash = true
   result = db.execute("SELECT name FROM Characters")
   return result
 
end
