bzred.bz_select_sql("SELECT bug_id,who FROM cc") do |row|
watchable_type = "Issue"
watchable_id = row[0]
user_id = row[1]
bzred.red_exec_sql("INSERT INTO watchers (watchable_type,watchable_id,user_id) values (?, ?,?)",watchable_type,watchable_id,user_id)
end

