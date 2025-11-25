class AssignedContactsController < ApplicationController
  accept_api_auth :show, :update

  before_action :find_issue
  before_action :authorize_global

  def show
    record = AssignedContact.find_by(:issue_id => @issue.id)
    contact = resolve_contact(record && record.contact_id)

    respond_to do |format|
      format.json {
        if contact
          render :json => {
            :issue_id => @issue.id,
            :contact_id => contact.id,
            :contact_name => (contact.respond_to?(:name) ? contact.name.to_s : contact.to_s)
          }
        else
          render :json => {
            :issue_id => @issue.id,
            :exists => false
          }
        end
      }
    end
  end

  def update
    contact_id = params[:contact_id]
    unless contact_id.present?
      respond_to do |format|
        format.json {
          render :json => {:error => 'contact_id ist erforderlich'}, :status => :bad_request
        }
      end
      return
    end

    record = AssignedContact.find_or_initialize_by(:issue_id => @issue.id)
    record.contact_id = contact_id.to_i

    if record.save
      contact = resolve_contact(record.contact_id)
      respond_to do |format|
        format.json {
          render :json => {
            :success => true,
            :issue_id => @issue.id,
            :contact_id => record.contact_id,
            :contact_name => (contact && contact.respond_to?(:name) ? contact.name.to_s : (contact ? contact.to_s : nil))
          }, :status => :ok
        }
      end
    else
      respond_to do |format|
        format.json {
          render :json => {:errors => record.errors.full_messages}, :status => :unprocessable_entity
        }
      end
    end
  end

  private

  def find_issue
    @issue = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def resolve_contact(contact_id)
    return nil unless contact_id.present?
    klass = defined?(Contacts::Contact) ? Contacts::Contact : (defined?(Contact) ? Contact : nil)
    return klass.find_by(:id => contact_id.to_i) if klass
    nil
  end
end
