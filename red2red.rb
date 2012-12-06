require "rubygems"
require "mysql"
require "r2rset"
require 'ruby-debug'
class ConnectionInfo
  attr_accessor :host
  attr_accessor :user
  attr_accessor :password
  attr_accessor :dbname

  def initialize(host, user, password, dbname)
    @host = host
    @user = user
    @password = password
    @dbname = dbname
  end
end

class BugzillaToRedmine
  def initialize
    @source = ConnectionInfo.new(S_HOST, S_USER, S_PASSWORD, S_DB)
    @dest = ConnectionInfo.new(D_HOST, D_USER, D_PASSWORD, D_DB)
    @old_project_id = 8
    @new_project_id = 11
  end
 
def open_connections
    @sdb = self.open_connection(@source)
    @ddb = self.open_connection(@dest)
  end

  def log(s)
    puts s
  end

  def close_connections
    self.log "closing database connections"
    @bugzilladb.close
    @redminedb.close
  end
  
   def move_trackers
     s_sql="select * from trackers"
     i_sql= "INSERT into trackers (name,is_in_chlog,position,is_in_roadmap) VALUES (?,?,?,?)"
     red_select_sql(s_sql){|row| red_exec_sql(i_sql,row[1],row[2],row[3],row[4])}
   end

  def move_status
    s_sql="select * from issue_statuses"
    i_sql= "INSERT into issue_statuses (name,is_closed,is_default,position,default_done_ratio) VALUES (?,?,?,?,?)"
    red_select_sql(s_sql){|row| red_exec_sql(i_sql,row[1],row[2],row[3],row[4],row[5])}
  end

  def move_issues
    issue_id_mapping
    t={1=>12,3=>13,5=>14,6=>15,7=>16,8=>17} ##Tracker Id mapping
    s={1=>13,2=>14,3=>15,4=>16,5=>17,6=>18} ##Status ID mapping
    u = {3=>6,6=>28,14=>27} ##User ID mapping
    s_sql="select * from issues where project_id=#{@old_project_id}"
    i_sql= "INSERT into issues (tracker_id,project_id,subject,description,due_date,category_id,status_id,assigned_to_id,priority_id,fixed_version_id,author_id,lock_version,created_on,updated_on,start_date,done_ratio,estimated_hours,parent_id,lft,rgt,is_private) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
    red_select_sql(s_sql){|row| 
      unless u[row[8]].nil? || u[row[11]].nil?
        red_exec_sql(i_sql,t[row[1]],@new_project_id,row[3],row[4],row[5],row[6],s[row[7]],u[row[8]],row[9],row[10],u[row[11]],row[12],row[13],row[14],row[15],row[16],row[17],row[18],1,2,row[21])
      else
        red_exec_sql(i_sql,t[row[1]],@new_project_id,row[3],row[4],row[5],row[6],s[row[7]],row[8],row[9],row[10],row[11],row[12],row[13],row[14],row[15],row[16],row[17],row[18],1,2,row[21])
      end

    }
   
  end

  def move_jour
    u = {3=>6,6=>28,14=>27} ##User ID mapping
    @issue_ids.each{|key,value|
      s_sql="select * from journals where journalized_id=#{key}"
      i_sql='INSERT into journals (journalized_id,journalized_type,user_id,notes,created_on) VALUES (?,?,?,?,?)'
      red_select_sql(s_sql){|row|
        unless u[row[3]].nil?
          red_exec_sql(i_sql,value,row[2],u[row[3]],row[4],row[5])
        else
          red_exec_sql(i_sql,value,row[2],row[3],row[4],row[5])
	end
        last_insert_id=0
        last_id("SELECT LAST_INSERT_ID()"){|r| last_insert_id=r[0]} ##FETCH THE LAST INSERT ID TO BE USED FOR JOURNAL DETAILS
        s_sql1 = "select * from journal_details where journal_id=#{row[0]}"
        i_sql1 = "INSERT into journal_details (journal_id,property,prop_key,old_value,value) VALUES (?,?,?,?,?)"
        red_select_sql(s_sql1){|row1|
          red_exec_sql(i_sql1,last_insert_id,row1[2],row1[3],row1[4],row1[5])
        }
      }
    }
  end


  def attachments
    s_sql="select * from attachments"
    i_sql='INSERT into attachments (container_id,container_type,filename,disk_filename,filesize,content_type,digest,downloads,author_id,created_on,description) VALUES (?,?,?,?,?,?,?,?,?,?,?)'
    red_select_sql(s_sql){|row|
    red_exec_sql(i_sql,@issue_ids[row[1]],row[2],row[3],row[4],row[5],row[6],row[7],row[8],row[9],row[10],row[11]) unless @issue_ids[row[1]].nil?
    }
  end

  def documents
    s_sql="select * from documents where project_id=#{@old_project_id}"
    i_sql='INSERT into documents (project_id,category_id,title,description,created_on) VALUES (?,?,?,?,?)'
    red_select_sql(s_sql){|row|
    red_exec_sql(i_sql,@new_project_id,row[2],row[3],row[4],row[5])
    }
  end

  def boards
    s_sql="select * from boards where project_id=#{@old_project_id}"
    i_sql='INSERT into boards (project_id,name,description,position,topics_count,messages_count,last_message_id,parent_id) VALUES (?,?,?,?,?,?,?,?)'
    red_select_sql(s_sql){|row|
    red_exec_sql(i_sql,@new_project_id,row[2],row[3],row[4],row[5],row[6],row[7],row[8])
    }
  end

  def migrate_boards
    u = {3=>6,6=>28,14=>27}
    s_sql="select * from boards where project_id=#{@old_project_id}"
    i_sql='INSERT into boards (project_id,name,description,position,topics_count,messages_count,last_message_id,parent_id) VALUES (?,?,?,?,?,?,?,?)'
    red_select_sql(s_sql){|row|
      red_exec_sql(i_sql,@new_project_id,row[2],row[3],row[4],row[5],row[6],row[7],row[8])
      s_sql1 = "SELECT * from messages where board_id=#{row[0]}"
      i_sql1 = "INSERT into messages(board_id,parent_id,subject,content,author_id,replies_count,last_reply_id,created_on,updated_on,locked,sticky) VALUES (?,?,?,?,?,?,?,?,?,?,?)"
      _new_board_id = 0
      last_id("SELECT LAST_INSERT_ID()"){|r| _new_board_id=r[0]}
      red_select_sql(s_sql1){|row1|
        unless u[row1[5]].nil?
          red_exec_sql(i_sql1,_new_board_id,row1[2],row1[3],row1[4],u[row1[5]],row1[6],row1[7],row1[8],row1[9],row1[10],row1[11])  
        else
          red_exec_sql(i_sql1,_new_board_id,row1[2],row1[3],row1[4],row1[5],row1[6],row1[7],row1[8],row1[9],row1[10],row1[11])  
        end      
      }  
    }
  end

  def migrate_wikis
    u = {3=>6,6=>28,14=>27}
    s_sql = "SELECT * from wikis where project_id=#{@old_project_id}"
    i_sql = "INSERT into wikis (project_id,start_page,status) VALUES (?,?,?)"
    _old_wiki_id=0
    _new_wiki_id=0
    red_select_sql(s_sql){|row|
      red_exec_sql(i_sql,@new_project_id,row[2],row[3])
      _old_wiki_id = row[0]
      last_id("SELECT LAST_INSERT_ID()"){|r| _new_wiki_id=r[0]}
    }

    s_sql1 = "SELECT * from wiki_pages where wiki_id=#{_old_wiki_id}"
    i_sql1 = "INSERT into wiki_pages (wiki_id,title,created_on,protected,parent_id) VALUES (?,?,?,?,?)"
    red_select_sql(s_sql1){|row|
      red_exec_sql(i_sql1,_new_wiki_id,row[2],row[3],row[4],row[5])
      _new_page_id = 0
      _new_content_id = 0
      last_id("SELECT LAST_INSERT_ID()"){|r| _new_page_id=r[0]}
      s_sql2 = "SELECT * from wiki_contents where page_id=#{row[0]}"
      i_sql2 = "INSERT into wiki_contents (page_id,author_id,text,comments,updated_on,version) VALUES (?,?,?,?,?,?)"
      red_select_sql(s_sql2){|row1|
        unless u[row1[2]].nil?
          red_exec_sql(i_sql2,_new_page_id,u[row1[2]],row1[3],row1[4],row1[5],row1[6])
        else
          red_exec_sql(i_sql2,_new_page_id,row1[2],row1[3],row1[4],row1[5],row1[6])
        end
        last_id("SELECT LAST_INSERT_ID()"){|r| _new_content_id=r[0]} 

        s_sql3 = "SELECT * from wiki_content_versions where wiki_content_id=#{row1[0]}"
        i_sql3 = "INSERT into wiki_content_versions (wiki_content_id,page_id,author_id,data,compression,comments,updated_on,version) VALUES (?,?,?,?,?,?,?,?)"
        red_select_sql(s_sql3){|row2|
          unless u[row2[3]].nil?
            red_exec_sql(i_sql3,_new_content_id,row2[2],u[row2[3]],row2[4],row2[5],row2[6],row2[7],row2[8])
          else
            red_exec_sql(i_sql3,_new_content_id,row2[2],row2[3],row2[4],row2[5],row2[6],row2[7],row2[8])
          end
        } 
      }
    }

    s_sql4 = "SELECT * from wiki_redirects where wiki_id=#{_old_wiki_id}"
    i_sql4 = "INSERT into wiki_redirects (wiki_id,title,redirects_to,created_on) VALUES (?,?,?,?)"
    red_select_sql(s_sql4){|row|
      red_exec_sql(i_sql4,_new_wiki_id,row[2],row[3],row[4])
    }
  end


  def move_issue_relation
    s_sql="select * from issue_relations"
    i_sql='INSERT into issue_relations (issue_from_id,issue_to_id,relation_type,delay) VALUES (?,?,?,?)'
    red_select_sql(s_sql){|row| 
    red_exec_sql(i_sql,h[row[1]],h[row[2]],row[3],row[4])
    }
  end
  
  def issue_id_mapping
    s_sql = "SELECT id from issues where project_id=#{@old_project_id}"
    ids=[]
    red_select_sql(s_sql){ |row| ids<<row[0] }
    last_uniq_id=0
    last_id("SELECT id FROM issues ORDER BY ID DESC LIMIT 1"){|r| last_uniq_id = r[0]}
    @issue_ids = {}
#debugger
    ids.each{|x| @issue_ids[x] = last_uniq_id + 1; last_uniq_id +=1}
  end
  
  def open_connection(info)
    self.log "opening #{info.inspect}"
    return Mysql::new(info.host, info.user, info.password, info.dbname)
  end

  def red_exec_sql(sql, *args)
    self.log("redmine: #{sql} args=#{args.join(',')}")
    statement = @ddb.prepare(sql)
    statement.execute(*args)
    statement.close()
  end

  def last_id(sql, *args, &block)
    self.log("redmine: #{sql} args=#{args.join(',')}")
    statement = @ddb.prepare(sql)
    statement.execute(*args)
    while row = statement.fetch do
      yield row
    end
    statement.close()
  end

  def red_select_sql(sql, *args, &block)
    self.log("redmine: #{sql} args=#{args.join(',')}")
    statement = @sdb.prepare(sql)
    statement.execute(*args)
    while row = statement.fetch do
      yield row
    end
    statement.close()
  end

end
