def migrate_keyword
bzred.red_exec_sql("DELETE FROM custom_values")
bzred.bz_select_sql("SELECT bug_id,keywords FROM bugs") do |row|
customized_type = "Issue"
custom_field_id = 1
customized_id = row[0]
value = row[1]
bzred.red_exec_sql("INSERT INTO custom_values (customized_type,custom_field_id,customized_id,value) values (?,?,?,?)",customized_type,custom_field_id,customized_id,value)
end
end

def migrate_whiteboard
bzred.bz_select_sql("SELECT bug_id,status_whiteboard FROM bugs") do |row|
customized_type = "Issue"
custom_field_id = 3
customized_id = row[0]
value = row[1]
bzred.red_exec_sql("INSERT INTO custom_values (customized_type,custom_field_id,customized_id,value) values (?,?,?,?)",customized_type,custom_field_id,customized_id,value)
end
end

def migrate_custom_version
bzred.bz_select_sql("SELECT bug_id,version FROM bugs") do |row|
customized_type = "Issue"
custom_field_id = 4
customized_id = row[0]
value = row[1]
bzred.red_exec_sql("INSERT INTO custom_values (customized_type,custom_field_id,customized_id,value) values (?,?,?,?)",customized_type,custom_field_id,customized_id,value)
end
end

