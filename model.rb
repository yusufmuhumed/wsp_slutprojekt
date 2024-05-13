require "sqlite3"
require "bcrypt"
require 'sinatra/flash'

module Model
   # Connects to the database.
   #
   # @param path [String] The path to the database.
   # @return [SQLite3::Database] The SQLite database object
   def connect_to_db(path)
      db = SQLite3::Database.new(path)
      db.results_as_hash = true
      return db
      
   end
   # Retrieves a list of character names.
   #
   # @return [Array<String>] List of character names.
   def list_name()
      db= connect_to_db('db/onepiece.db')
      result = db.execute("SELECT name FROM Characters")
      return result
   
   end
   # Retrieves information of all characters.
   #
   # @return [Array<Hash>] List of character information.
   def list_characters_info()
      db = SQLite3::Database.new('db/onepiece.db')
      characters = db.execute("SELECT * FROM Characters")
      return characters
   end
   # Retrieves user information.
   #
   # @param username [String] The username.
   # @param email [String] The email address.
   # @return [Hash] User information.
   def user(username,email)
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT * FROM users WHERE user_name =? OR user_mail=? ",username,email).first
      return result
   end

   # Checks if the user is an admin.
   #
   # @param user [String] The username.
   # @return [Hash] Admin status.
   def user_admin(user)
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT admin FROM users WHERE user_name=?",user).first
      p result
      return result
   end

   # Handles user login.
   #
   # @param result [Hash] User information.
   # @param password [String] The password.
   # @return [Integer, Boolean] The user ID if login successful, otherwise false.
   def login(result,password)
      if result != nil
         pwdigest= result["user_pwd"]
         id= result["id"]
         if BCrypt::Password.new(pwdigest) == password
            return id
         else
            return false
         end

      else
         return false

      end

   end


   
   def name_already_in_list(nameId,userId)
      db = SQLite3::Database.new('db/onepiece.db')
      result = db.execute("SELECT UsersId FROM CharactersUsersRelations WHERE CharactersId =? AND UsersId=?",nameId,userId)
      p result
      if result.length <= 0 && result.length <= 1
         return false
      else
         return true
      end
   end

   def is_name_a_character(name)
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT name FROM Characters WHERE name =? ",name)
      p result
      if result == [] 
         return false
      else
         return true
      end

   end

   # Registers a new user.
   #
   # @param username [String] The username.
   # @param password [String] The password.
   # @param email [String] The email address.
   # @param password_confirm [String] The confirmation password.
   # @return [Integer, String] The user ID if registration successful, otherwise an error message.
   def register(username,password,email,password_confirm)
      if username == "" 
         return "you need to fill in a username to register your user"
      end
      
      if email == ""
         return "you need to fill in your email address to register your user"

      end
      
      if password == ""
         return "you need to fill in a password to register your user"

      end

      if password.length() <= 7
         return "password needs to be 7 or more letters. Please fill in a different password."
      end
      if password == password_confirm
         password_digest= BCrypt::Password.create(password)
         db =SQLite3::Database.new('db/onepiece.db')
         result = db.execute("SELECT id FROM users WHERE user_name=? ",username).flatten
         result2 = db.execute("SELECT id FROM users WHERE user_mail=?",email).flatten
         p result
         p result2
         if result == [] && result2 == []
            db.execute("INSERT INTO users (user_name,user_pwd,user_mail) VALUES(?,?,?)",username,password_digest,email)
            id = db.execute("SELECT id FROM users WHERE user_name=? ",username).first[0]
            p id
            return id

         elsif result =! nil && result2 =! nil
            message= "username or email already exist. Please find another username"
            p message
            return "username or email already exist. Please find another username"
         elsif result =! nil && result2.empty?
            message= "username already exist. Please find another username"
            p message

            return "username already exist. Please find another username"

         else
            p message
            message = "email already in use. Please use another email to register a new user."
            return message

         end


   
      else
         message = "password not matching"
         return message
      
      end
   end

   # Retrieves characters ranked by likes.
   #
   # @return [Array<Hash>] List of characters ranked by likes.
   def ranks()
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT * FROM Characters ORDER BY likes DESC")
      return result
   end

   # Retrieves details of a character.
   #
   # @param id [Integer] The character ID.
   # @return [Hash] Character details.
   def character(id)
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT * FROM Characters WHERE id = ?",id).first
      return result
   end

   # Increments the like count of a character.
   #
   # @param id [Integer] The character ID.
   # @param user_id [Integer] The user ID.
   # @return [Void]
   def like(id,user_id)
      db = connect_to_db('db/onepiece.db')
      db.execute("UPDATE characters SET likes = likes + 1 WHERE id = ?", id)
      db.execute("INSERT INTO likes (character_id,user_id) VALUES(?,?)",id,user_id)
   end

   # Decrements the like count of a character.
   #
   # @param id [Integer] The character ID.
   # @param user_id [Integer] The user ID.
   # @return [Void]
   def unlike(id,user_id)
      db = connect_to_db('db/onepiece.db')
      db.execute("UPDATE Characters SET likes = likes - 1 WHERE id = ?", id)
      db.execute("DELETE FROM likes WHERE character_id=? AND user_id=?",id,user_id)
      
   end

   # Retrieves characters liked by a user.
   #
   # @param user_id [Integer] The user ID.
   # @return [Array<Integer>] List of character IDs liked by the user.
   def liked_characters(user_id)
      db = SQLite3::Database.new('db/onepiece.db')
      result = db.execute("SELECT character_id FROM likes WHERE user_id=?", user_id).flatten
      return result
   end


   # Searches for characters by name.
   #
   # @param name [String] The character name.
   # @return [Array<Hash>] List of character details matching the search.
   def search(name)
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT * FROM Characters WHERE name LIKE ?", (name + '%'))
      return result
   end
   # Retrieves character details by name.
   #
   # @param name [String] The character name.
   # @return [Hash] Character details.
   def select_name_where(name)
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT * FROM Characters WHERE name = ?",name).first
      return result
   end
   # Retrieves the user's lists.
   #
   # @param user_id [Integer] The user ID.
   # @return [Array<Hash>] List of user's lists.
   def user_list(user_id)
      db = connect_to_db('db/onepiece.db')
      results = db.execute("SELECT users.user_name, Characters.name
      FROM((CharactersUsersRelations
         INNER JOIN users ON CharactersUsersRelations.UsersId = users.id)
         INNER JOIN Characters ON CharactersUsersRelations.CharactersId = Characters.id)
      WHERE UsersId = ?", user_id)
      return results
   end

   # Adds a character to the user's list.
   #
   # @param name [String] The character name.
   # @param userId [Integer] The user ID.
   # @return [Void]
   def add_character_to_list(name,userId)
      db = SQLite3::Database.new('db/onepiece.db')
      if is_name_a_character(name)
         nameId = db.execute("SELECT id FROM Characters WHERE name = ?",name).first[0]
         if name_already_in_list(nameId,userId) 
            p "name already in list"
            flash[:notice] = "Charcater already in list"

         else
            db.execute("INSERT INTO CharactersUsersRelations (CharactersId,UsersId) VALUES(?,?)",nameId,userId)
         end
      else
         p "character dosen't exist"
         flash[:notice] = "Character dosen't exist"

      
      end
   end

   def name_to_id(name)
      db = connect_to_db('db/onepiece.db')
      nameId = db.execute("SELECT id FROM Characters WHERE name=?",name).first['id']
      return nameId
   end

   def name_to_id2(name)
      db = connect_to_db('db/onepiece.db')
      nameId = db.execute("SELECT id FROM Characters WHERE name=?",name).first
      return nameId
   end

   # Deletes a character from the user's list.
   #
   # @param nameId [Integer] The character ID.
   # @param userId [Integer] The user ID.
   # @return [Void]
   def delete_character_from_list(nameId,userId)
      db = SQLite3::Database.new('db/onepiece.db')
      db.execute("DELETE FROM CharactersUsersRelations WHERE CharactersId=? AND UsersId=?",nameId,userId)
   end
   # Checks if the user owns the list element.
   #
   # @param current_userid [Integer] The current user ID.
   # @param objectid [Integer] The object ID.
   # @return [Boolean] True if user owns the list element, otherwise false.
   def list_delete_authorization(current_userid,objectid)
      db = SQLite3::Database.new('db/onepiece.db')
      objectuserid = db.execute("SELECT UsersId FROM CharactersUsersRelations WHERE CharactersId=?",objectid).first.flatten[0]
      p objectuserid
      if current_userid == objectuserid
         return true
      else
         return false
      end

   end
   # Checks if the user is authorized to delete/edit characters.
   #
   # @param current_userid [Integer] The current user ID.
   # @return [Boolean] True if user is authorized, otherwise false.
   def character_delete_edit_authorization(current_userid)
      db = SQLite3::Database.new('db/onepiece.db')
      admin = db.execute("SELECT admin FROM users WHERE id=?",current_userid).first.flatten[0]
      if admin == 1
         return true
      else
         return false
      end

   end

   # Deletes a character.
   #
   # @param name [Integer] The character id.
   # @return [Void]
   def delete_character(id)
      db = connect_to_db('db/onepiece.db')
      db.execute("DELETE FROM Characters WHERE id=?",id)
   end



   # Edits a character.
   #
   # @param name [String] The character name.
   # @param chapter [String] The chapter.
   # @param episode [String] The episode.
   # @param year [String] The year.
   # @param note [String] Additional notes.
   # @param bounty [String] The bounty.
   # @param id [Integer] The character ID.
   # @return [Void]
   def edit_character(name,chapter,episode,year,note,bounty,id)
      db = connect_to_db('db/onepiece.db')
      db.execute("UPDATE Characters SET name = ?, chapter = ?, episode = ?, year = ?, note = ?, Bounty = ?    
      WHERE  id=?",name,chapter,episode,year,note,bounty,id)
      p "after update:"
      r= db.execute("SELECT * FROM Characters WHERE id=?",id)
      p r
   end

   # Adds a new character to the database.
   #
   # @param name [String] The character name.
   # @param chapter [String] The chapter.
   # @param episode [String] The episode.
   # @param year [String] The year.
   # @param note [String] Additional notes.
   # @param bounty [String] The bounty.
   # @param like [Integer] The like count.
   # @return [Void]
   def add_character_to_db(name,chapter,episode,year,note,bounty,like)
      db = connect_to_db('db/onepiece.db')
      db.execute("INSERT INTO Characters (name,chapter,episode,year,note,bounty,likes) VALUES(?,?,?,?,?,?,?)",name,chapter,episode,year,note,bounty,like)
   end

   # Retrieves characters liked by a user.
   # @param user_id [Integer] The user ID.
   # @return [Array<Integer>] List of character IDs liked by the user.

   def user_likes(user_id)
      db =  SQLite3::Database.new('db/onepiece.db')
      result=db.execute("SELECT character_id FROM likes where user_id=?",user_id).flatten
      p result
      return result

      
   end

   

end

