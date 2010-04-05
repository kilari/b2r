require "rubygems"
require "mysql"
require "r2rset"
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
  
  def move_issues
s_sql="select * from issues where project_id=2"

i_sql= "INSERT into issues (id,tracker_id,project_id,subject,description,due_date,category_id,status_id,assigned_to_id,priority_id,fixed_version_id,author_id,lock_version,created_on,updated_on,start_date,done_ratio,estimated_hours) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"

bzred.red_select_sql(s_sql){|row| bzred.red_exec_sql(i_sql,row[1],5,row[3],row[4],row[5],row[6],row[7],row[8],row[9],row[10],row[11],row[12],row[13],row[14],row[15],row[16],row[17])}
end

def move_jour
h={}
i=1
(10..40).each do |x| 
h[i]=x;i+=1
end
s_sql="select * from journals"
i_sql='INSERT into journals (journalized_id,journalized_type,user_id,notes,created_on) VALUES (?,?,?,?,?)'

bzred.red_select_sql(s_sql){|row| 

bzred.red_exec_sql(i_sql,h[row[1]],5,row[3],row[4],row[5])

}
end

def move_issue_relation

s_sql="select * from issue_relations"
i_sql='INSERT into issue_relations (issue_from_id,issue_to_id,relation_type,delay) VALUES (?,?,?,?)'
bzred.red_select_sql(s_sql){|row| 
bzred.red_exec_sql(i_sql,h[row[1]],h[row[2]],row[3],row[4])
}
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
