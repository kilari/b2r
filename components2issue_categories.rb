bzred.red_exec_sql("DELETE FROM issue_categories")
bzred.bz_select_sql("SELECT name,initialowner,product_id FROM components") do |row|
name = row[0]
assigned_to_id = row[1]
project_id = row[2]
bzred.red_exec_sql("INSERT INTO issue_categories (project_id,name,assigned_to_id) values (?, ?,?)",project_id,name,assigned_to_id)
end
