# Controller für User Mails API
# Verwaltet die CRUD-Operationen für User-E-Mails über die API

class UserMailsController < ApplicationController
  accept_api_auth :index, :show, :create, :update, :destroy, :search

  before_action :find_user, :except => [:search]
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
    @email_address.notify = 0 if @email_address.notify.nil?
    
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
    begin
      # Wenn diese E-Mail als Standard gesetzt wird, müssen alle anderen Standard-E-Mails deaktiviert werden
      if params[:is_default] == true || params[:is_default] == 'true' || params[:is_default] == 1 || params[:is_default] == '1'
        @user.email_addresses.where(:is_default => true).where.not(:id => @email_address.id).update_all(:is_default => false)
      end
      
      # Setze Attribute direkt aus params
      update_hash = {}
      
      if params[:address].present?
        update_hash[:address] = params[:address]
      end
      
      if params[:is_default].present?
        is_default_value = params[:is_default]
        # Konvertiere zu Boolean
        if is_default_value == true || is_default_value == 'true' || is_default_value == 1 || is_default_value == '1'
          update_hash[:is_default] = true
        elsif is_default_value == false || is_default_value == 'false' || is_default_value == 0 || is_default_value == '0'
          update_hash[:is_default] = false
        end
      end
      
      if params[:notify].present?
        notify_value = params[:notify]
        # Konvertiere zu Integer (0 oder 1)
        if notify_value == true || notify_value == 'true' || notify_value == 1 || notify_value == '1'
          update_hash[:notify] = 1
        elsif notify_value == false || notify_value == 'false' || notify_value == 0 || notify_value == '0'
          update_hash[:notify] = 0
        end
      end
      
      # Verwende update_columns um Callbacks zu umgehen
      if update_hash.any?
        @email_address.update_columns(update_hash)
        # Lade das Objekt neu aus der Datenbank
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
          render :json => {
            :success => false,
            :error => e.message
          }, :status => :internal_server_error
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
    # E-Mail-Adresse aus Header lesen (X-Search-Email oder X-Email-Address)
    email_address = request.headers['X-Search-Email'] || request.headers['X-Email-Address'] || request.headers['X-Email']
    
    # Fallback auf Query-Parameter für Rückwärtskompatibilität
    email_address ||= params[:email] || params[:address]
    
    unless email_address.present?
      respond_to do |format|
        format.json {
          render :json => {:error => 'E-Mail-Adresse fehlt. Bitte verwende Header X-Search-Email oder X-Email-Address'}, :status => :bad_request
        }
      end
      return
    end
    
    # Suche nach der E-Mail-Adresse
    email_record = EmailAddress.find_by(:address => email_address)
    
    respond_to do |format|
      format.json {
        if email_record
          render :json => {
            :exists => true,
            :user_id => email_record.user_id
          }
        else
          render :json => {
            :exists => false
          }
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
    # Verwende to_unsafe_h für direkten Zugriff auf Parameter
    raw_params = params.to_unsafe_h
    
    permitted = {}
    
    # Kopiere nur erlaubte Parameter
    permitted[:address] = raw_params[:address] if raw_params.has_key?(:address)
    permitted[:is_default] = raw_params[:is_default] if raw_params.has_key?(:is_default)
    permitted[:notify] = raw_params[:notify] if raw_params.has_key?(:notify)
    
    # Konvertiere is_default zu Boolean, falls es als String kommt
    if permitted[:is_default].present?
      permitted[:is_default] = ActiveModel::Type::Boolean.new.cast(permitted[:is_default])
    end
    
    # Konvertiere notify zu Integer (0 oder 1)
    if permitted[:notify].present?
      notify_value = permitted[:notify]
      if notify_value == true || notify_value == 'true' || notify_value == 1 || notify_value == '1'
        permitted[:notify] = 1
      elsif notify_value == false || notify_value == 'false' || notify_value == 0 || notify_value == '0'
        permitted[:notify] = 0
      end
    end
    
    permitted
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
    
    begin
      hash = {
        :id => email_address.id,
        :address => email_address.address.to_s,
        :is_default => email_address.is_default?,
        :user_id => email_address.user_id
      }
      
      # Füge notify hinzu, falls vorhanden
      begin
        hash[:notify] = email_address.notify if email_address.respond_to?(:notify)
      rescue => e
        # Ignoriere Fehler bei notify
      end
      
      # Füge Timestamps hinzu, falls sie vorhanden sind
      begin
        hash[:created_at] = email_address.created_at if email_address.respond_to?(:created_at) && email_address.created_at
      rescue => e
        # Ignoriere Fehler bei created_at
      end
      
      begin
        hash[:updated_at] = email_address.updated_at if email_address.respond_to?(:updated_at) && email_address.updated_at
      rescue => e
        # Ignoriere Fehler bei updated_at
      end
      
      hash
    rescue => e
      Rails.logger.error "Error in email_address_to_hash: #{e.message}"
      # Fallback: Minimale Hash-Erstellung
      begin
        {
          :id => email_address.id,
          :address => email_address.address.to_s,
          :is_default => email_address.is_default?,
          :user_id => email_address.user_id
        }
      rescue => e2
        {
          :id => nil,
          :address => '',
          :is_default => false,
          :user_id => nil
        }
      end
    end
  end
end

