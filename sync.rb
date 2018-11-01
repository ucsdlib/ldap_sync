require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  ruby '2.5.3'
  gem 'ibm_db', '~> 4.0.0'
  gem 'net-ldap', '~> 0.16.1'
  gem 'rails', '5.1.6'
end

require 'rubygems'
require 'ibm_db'
require 'net/ldap'

class User
  def sync_employees
    db_connection

    if @conn
      begin
        if stmt = IBM_DB.exec(@conn, query)
          while row = IBM_DB.fetch_assoc(stmt)
            update_manager(row)
          end
          IBM_DB.free_result(stmt)
        else
          puts "Statement execution failed: #{IBM_DB.stmt_errormsg}"
        end
        ensure
          IBM_DB.close(@conn)
      end
    else
      puts "There was an error in the connection: #{IBM_DB.conn_errormsg}"
    end
  end

  def db_connection
    @conn ||= IBM_DB.connect("DRIVER={IBM DB2 ODBC DRIVER};DATABASE=dw_db;\
                       HOSTNAME=#{ENV['DB2_HOST']};PORT=55000;PROTOCOL=TCPIP;\
                       UID=#{ENV['DB2_USERNAME']};PWD=#{ENV['DB2_PASSWORD']};", "", "")
  end

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

  def ldap_connection
    @ldap_connection ||= Net::LDAP.new(
      host: ENV['LDAP_HOST'],
      port: ENV['LDAP_PORT'],
      base: ENV['LDAP_BASE'],
      encryption: { method: :simple_tls },
      auth: {
          method: :simple,
          username: ENV['LDAP_USERNAME'],
          password: ENV['LDAP_PASSWORD']
      }
    )
  end

  def validate_ldap_response
    msg = <<~MESSAGE
      Response Code: ldap_connection.get_operation_result.code
      Message: ldap_connection.get_operation_result.message
    MESSAGE
    raise msg unless ldap_connection.get_operation_result.code.zero?
  end

  def update_manager(row)
    # puts "EmployeeAD: #{ad_user_name(row['USERNAME'],row['USEREMAIL'])} - ManagerAD: #{ad_user_name(row['MANAGERADNAME'],row['MANAGEREMAIL'])}"    
    dn = "CN=#{ad_user_name(row['USERNAME'],row['USEREMAIL'])}"
    ldap_connection.replace_attribute dn, :manager, ad_user_name(row['MANAGERADNAME'],row['MANAGEREMAIL'])
    validate_ldap_response
  end
end

User.new.sync_employees
