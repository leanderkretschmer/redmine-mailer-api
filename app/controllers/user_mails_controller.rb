# Controller für User Mails API
# Verwaltet die CRUD-Operationen für User-E-Mails über die API

class UserMailsController < ApplicationController
  accept_api_auth :index, :show, :create, :update, :destroy

  before_action :find_user
  before_action :find_email_address, :only => [:show, :update, :destroy]
  before_action :authorize_global
  
  # Verhindere das Löschen der letzten Standard-E-Mail
  before_action :check_cannot_delete_default, :only => [:destroy]

  def index
    @email_addresses = @user.email_addresses.order(:id)
    
    respond_to do |format|
      format.json {
        render :json => @email_addresses.map { |ea| email_address_to_hash(ea) }
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
    
    # Wenn diese E-Mail als Standard gesetzt wird, müssen alle anderen Standard-E-Mails deaktiviert werden
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
    # Wenn diese E-Mail als Standard gesetzt wird, müssen alle anderen Standard-E-Mails deaktiviert werden
    if params[:is_default] == true || params[:is_default] == 'true'
      @user.email_addresses.where(:is_default => true).where.not(:id => @email_address.id).update_all(:is_default => false)
    end
    
    if @email_address.update(email_address_params)
      respond_to do |format|
        format.json {
          render :json => email_address_to_hash(@email_address)
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
    params.permit(:address, :is_default)
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
    hash = {
      :id => email_address.id,
      :address => email_address.address,
      :is_default => email_address.is_default?,
      :user_id => email_address.user_id
    }
    
    # Füge Timestamps hinzu, falls sie vorhanden sind
    hash[:created_at] = email_address.created_at if email_address.respond_to?(:created_at) && email_address.created_at
    hash[:updated_at] = email_address.updated_at if email_address.respond_to?(:updated_at) && email_address.updated_at
    
    hash
  end
end

