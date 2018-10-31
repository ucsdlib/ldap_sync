require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'ibm_db'
end

require 'rubygems'
require 'ibm_db'

class User
  def ad_user_name(user_name, email)
    email_arr = email.split('@')
    name =  (email_arr.first.length > 8 && email.include?(user_name)) ? email_arr.first : user_name
    name
  end

  def query
    'SELECT distinct A.networkuserid USERNAME, A.VANITY_EMAIL_LONG USEREMAIL, ' \
    'A2.networkuserid MANAGERADNAME, A2.VANITY_EMAIL_LONG MANAGEREMAIL ' \
    'from ROLES.SUPERVISOR_DEPART_VIEW R LEFT OUTER JOIN AFFILIATES_DW.AFFILIATES_SAFE_ATTRIBUTES A ' \
    'ON R.EMP_PERSON_ID = A.emb_person_id, AFFILIATES_DW.AFFILIATES_SAFE_ATTRIBUTES A2 ' \
    'where R.ACTIVE = 1 and R.ROLE_NAME = \'ER_SUPERVISOR\' AND A2.emb_person_id = R.SUP_PERSON_ID ' \
    'ORDER BY USERNAME'.freeze
  end

  def employee_manager_data
    conn = IBM_DB.connect("DRIVER={IBM DB2 ODBC DRIVER};DATABASE=dw_db;\
                       HOSTNAME=xxx.ucsd.edu;PORT=55000;PROTOCOL=TCPIP;\
                       UID=xxx;PWD=xxx;", "", "")
    if conn
      begin
        if stmt = IBM_DB.exec(conn, query)
          while row = IBM_DB.fetch_assoc(stmt)
            puts "EmployeeAD: #{ad_user_name(row['USERNAME'],row['USEREMAIL'])} - ManagerAD: #{ad_user_name(row['MANAGERADNAME'],row['MANAGEREMAIL'])}"
          end
          IBM_DB.free_result(stmt)
        else
          puts "Statement execution failed: #{IBM_DB.stmt_errormsg}"
        end
        ensure
          IBM_DB.close(conn)
      end
    else
      puts "There was an error in the connection: #{IBM_DB.conn_errormsg}"
    end
  end
end

puts "hello world #{User.new.employee_manager_data}"
