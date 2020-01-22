require 'json'

# define a set of classes for representing login credentials of various types.
#

module CredentialBase
  def credential
    @cred_items ||= {}
  end

  def to_h
    credential
  end

  def from_h(h_obj)
    # copy only keys that already exist in items by default
    # override if you don't like this :)
    #
    unless h_obj.nil?
      credential.keys.each do |key|
        if h_obj.keys.include?(key)
          credential[key] = h_obj.fetch(key)
        end
      end
    end
  end

  def from_json(json_str)
    from_h(JSON.parse(json_str, symbolize_names:true))
  end

  def to_json
    JSON.dump(to_h)
  end

  def copy(other_credential)
    @cred_items = other_credential.credential.clone
  end
end


# TODO: redo this class using OpenStruct - much cleaner to modify!!!

module UserLoginCredential
  include CredentialBase

  def user_login
    credential.merge!({ :user_name  => nil,
                        :user_group => nil,
                        :user_pwd   => nil } )
    credential
  end

  def set_user_login(user_name, user_pwd, user_group=nil)
    if user_name.nil? || user_pwd.nil?
      raise ArgumentError, 'ERR: user name / pwd not set!'
    end
    user_group = user_name if user_group.nil?
    credential.merge!( { :user_name  => user_name,
                         :user_group => user_group,
                         :user_pwd   => user_pwd } )
    credential
  end

  def set_user_group(group_id)
    credential[:user_group] = group_id
    credential
  end

  def user_name
    credential.fetch(:user_name, nil)
  end

  def user_pwd
    credential.fetch(:user_pwd, nil)
  end

  def user_group
    credential.fetch(:user_group, nil)
  end

  def to_s
    "user name: #{user_name}(#{user_group})"
  end
end

