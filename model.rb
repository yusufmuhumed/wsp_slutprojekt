require "sqlite3"


def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
   end

def list_name()
   db = SQLite3::Database.new('db/onepiece.db')
   db.results_as_hash = true
   result = db.execute("SELECT name FROM Characters")
   return result
 
end

def user_admin(user)
   db = SQLite3::Database.new('db/onepiece.db')
   db.results_as_hash = true
   result = db.execute("SELECT admin FROM users WHERE user_name=?",user).first
   return result
end

# username="yusuf"
# user_status= user_admin("yusuf")
# p user_status

# p user_status["admin"]





