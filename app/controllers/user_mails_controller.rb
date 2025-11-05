class UserMailsController < ApplicationController
  accept_api_auth :index, :show, :create, :update, :destroy, :search

  before_action :find_user, :except => [:search]
  before_action :find_email_address, :only => [:show, :update, :destroy]
  before_action :authorize_global
  before_action :check_cannot_delete_default, :only => [:destroy]

  def index
    respond_to do |format|
      format.json {
        render :json => @user.email_addresses.order(:id).map { |ea| email_address_to_hash(ea) }
      }
    end
  end

  def show
    respond_to do |format|
      format.json {
        render :json => email_address_to_hash(@email_address)
      }
    end
  end

  def create
    @email_address = @user.email_addresses.build(email_address_params)
    @email_address.is_default = false if @email_address.is_default.nil?
    @email_address.notify = 0 if @email_address.notify.nil?
    
    if @email_address.is_default == true
      @user.email_addresses.where(:is_default => true).update_all(:is_default => false)
    end

    if @email_address.save
      respond_to do |format|
        format.json {
          render :json => email_address_to_hash(@email_address), :status => :created
        }
      end
    else
      respond_to do |format|
        format.json {
          render :json => {:errors => @email_address.errors.full_messages}, :status => :unprocessable_entity
        }
      end
    end
  end

  def update
    begin
      update_hash = build_update_hash
      
      if update_hash.has_key?(:is_default) && update_hash[:is_default] == true
        @user.email_addresses.where(:is_default => true).where.not(:id => @email_address.id).update_all(:is_default => false)
      end
      
      if update_hash.any?
        @email_address.update_columns(update_hash)
        @email_address = @user.email_addresses.find(params[:id])
      end
      
      respond_to do |format|
        format.json {
          render :json => {
            :success => true,
            :message => 'E-Mail-Adresse erfolgreich aktualisiert',
            :email_address => email_address_to_hash(@email_address)
          }, :status => :ok
        }
      end
    rescue => e
      Rails.logger.error "Error in UserMailsController#update: #{e.message}\n#{e.backtrace.join("\n")}"
      respond_to do |format|
        format.json {
          render :json => {:success => false, :error => e.message}, :status => :internal_server_error
        }
      end
    end
  end

  def destroy
    if @email_address.destroy
      respond_to do |format|
        format.json {
          render :json => {:message => 'E-Mail-Adresse erfolgreich gelöscht'}, :status => :ok
        }
      end
    else
      respond_to do |format|
        format.json {
          render :json => {:errors => @email_address.errors.full_messages}, :status => :unprocessable_entity
        }
      end
    end
  end

  def search
    email_address = request.headers['X-Search-Email'] || request.headers['X-Email-Address'] || request.headers['X-Email']
    email_address ||= params[:email] || params[:address]
    
    unless email_address.present?
      respond_to do |format|
        format.json {
          render :json => {:error => 'E-Mail-Adresse fehlt. Bitte verwende Header X-Search-Email oder X-Email-Address'}, :status => :bad_request
        }
      end
      return
    end
    
    email_record = EmailAddress.find_by(:address => email_address)
    
    respond_to do |format|
      format.json {
        if email_record
          render :json => {:exists => true, :user_id => email_record.user_id}
        else
          render :json => {:exists => false}
        end
      }
    end
  end

  private

  def find_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_email_address
    @email_address = @user.email_addresses.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def email_address_params
    raw_params = params.to_unsafe_h
    permitted = {}
    
    permitted[:address] = raw_params[:address] if raw_params.has_key?(:address)
    permitted[:is_default] = raw_params[:is_default] if raw_params.has_key?(:is_default)
    permitted[:notify] = raw_params[:notify] if raw_params.has_key?(:notify)
    
    if permitted[:is_default].present?
      permitted[:is_default] = ActiveModel::Type::Boolean.new.cast(permitted[:is_default])
    end
    
    if permitted[:notify].present?
      permitted[:notify] = integer_value(permitted[:notify], 0, 1)
    end
    
    permitted
  end

  def build_update_hash
    update_hash = {}
    
    update_hash[:address] = params[:address] if params[:address].present?
    
    if params.has_key?(:is_default)
      update_hash[:is_default] = boolean_value(params[:is_default])
    end
    
    if params[:notify].present?
      update_hash[:notify] = integer_value(params[:notify], 0, 1)
    end
    
    update_hash
  end

  def boolean_value(value)
    return nil if value.nil?
    return true if value == true || value == 'true' || value == 1 || value == '1'
    return false if value == false || value == 'false' || value == 0 || value == '0'
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def integer_value(value, min, max)
    return nil if value.nil?
    if value == true || value == 'true' || value == 1 || value == '1'
      max
    elsif value == false || value == 'false' || value == 0 || value == '0'
      min
    else
      value.to_i.clamp(min, max)
    end
  end

  def check_cannot_delete_default
    if @email_address.is_default? && @user.email_addresses.where(:is_default => true).count <= 1
      respond_to do |format|
        format.json {
          render :json => {:errors => ['Die Standard-E-Mail-Adresse kann nicht gelöscht werden']}, :status => :unprocessable_entity
        }
      end
      return false
    end
  end

  def email_address_to_hash(email_address)
    return {} if email_address.nil?
    
    hash = {
      :id => email_address.id,
      :address => email_address.address.to_s,
      :is_default => email_address.is_default?,
      :user_id => email_address.user_id
    }
    
    hash[:notify] = email_address.notify if email_address.respond_to?(:notify) && email_address.notify.present?
    
    begin
      hash[:created_at] = email_address.created_at if email_address.respond_to?(:created_at) && email_address.created_at
    rescue
    end
    
    begin
      hash[:updated_at] = email_address.updated_at if email_address.respond_to?(:updated_at) && email_address.updated_at
    rescue
    end
    
    hash
  rescue => e
    Rails.logger.error "Error in email_address_to_hash: #{e.message}"
    begin
      {
        :id => email_address.id,
        :address => email_address.address.to_s,
        :is_default => email_address.is_default?,
        :user_id => email_address.user_id
      }
    rescue
      {
        :id => nil,
        :address => '',
        :is_default => false,
        :user_id => nil
      }
    end
  end
end
