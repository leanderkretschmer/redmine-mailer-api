class AssignedContactsController < ApplicationController
  accept_api_auth :show

  before_action :find_issue
  before_action :authorize_global

  def show
    contact = find_assigned_contact(@issue)

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

  private

  def find_issue
    @issue = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_assigned_contact(issue)
    return issue.assigned_contact if issue.respond_to?(:assigned_contact) && issue.assigned_contact.present?
    return issue.contact if issue.respond_to?(:contact) && issue.contact.present?
    if issue.respond_to?(:contacts) && issue.contacts.respond_to?(:first)
      c = issue.contacts.first
      return c if c
    end

    cf = nil
    if issue.respond_to?(:custom_field_values)
      cf = issue.custom_field_values.detect { |cv| cv.respond_to?(:custom_field) && cv.custom_field && cv.custom_field.name.to_s =~ /assigned_contact(_id)?/i }
    end
    id_str = cf && cf.respond_to?(:value) ? cf.value.to_s.strip : ""
    if id_str.present?
      klass = defined?(Contacts::Contact) ? Contacts::Contact : (defined?(Contact) ? Contact : nil)
      return klass.find_by(:id => id_str.to_i) if klass
    end

    nil
  end
end
