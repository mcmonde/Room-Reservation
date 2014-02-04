class Admin::LogsController < AdminController
  def index
    @reservations = AdminReservationsDecorator.new(filtered_reservations.page(params[:page]).per(per_page))
  end

  protected

  def reservations
    Reservation.all.with_deleted.joins(:room).order("#{sort_field} #{sort_order}")
  end

  def filtered_reservations
    reservations = self.reservations
    facets.each do |facet, value|
      if facet == :start_time
        reservations = reservations.where("start_time >= ?", value)
      elsif facet == :end_time
        reservations = reservations.where("end_time <= ?", value)
      else
        reservations = reservations.where(facet => value)
      end
    end
    reservations
  end
  def facets
    @facets ||= Hash[(params[:facets] || {}).map{|facet, value|
      facet.downcase.to_sym == :room ? [:"rooms.name",value] : [facet.downcase.to_sym, value]
    }.select{|x| safe_filter_fields.include?(x[0])}]
  end

  def safe_filter_fields
    [:user_onid, :"rooms.name", :reserver_onid, :start_time, :end_time]
  end

  def per_page
    20
  end

  def sort_field
    @sort_field ||= begin
      params[:sort_field] ||= :start_time
      sort_field = params[:sort_field] || :start_time
      sort_field = "rooms.name" if sort_field == "room"
      sort_field
    end
  end

  def sort_order
    return params[:sort_order] || "DESC"
  end
end
