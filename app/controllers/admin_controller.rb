class AdminController < ApplicationController
  before_filter :require_login
  before_filter :require_admin
  layout 'admin'
  respond_to :html

  def index
  end

  protected

  private

  def require_admin
    render :status => :unauthorized, :text => 'Only admin can access' unless can?(:manage, :all)
  end

  def require_staff
    render :status => :unauthorized, :text => 'Only staff can access' unless current_user.staff?
  end

end
