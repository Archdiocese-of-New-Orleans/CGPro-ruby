require 'communigate'

class Cli < CommuniGate
  
  def set_account_password(account, password)
    setaccountpassword(account, 'PASSWORD', password)
  end
  
  def delete_domain(name, force = false)
    if force
      deletedomain(name, "force")
    else
      deletedomain(name)
    end
  end
end
