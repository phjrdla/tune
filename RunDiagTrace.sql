begin
 dbms_sqldiag.dump_trace(p_sql_id => 'dss9qt8m1jw4t',
                         p_child_number => 0,
						 p_component=>'Compiler'
						 p_file_id=>'MY_SUPER_SLOW');						   
end;
/