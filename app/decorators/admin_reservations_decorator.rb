class AdminReservationsDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_pages, :limit_value

  def decorator_class
    AdminReservationDecorator
  end
end