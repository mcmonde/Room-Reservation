class ReservationsController < ApplicationController
  respond_to :json, :html
  include_root_in_json = false
  before_filter :require_login, :only => [:create, :destroy]
  before_filter RubyCAS::Filter, :only => :index

  def index
    @reservations = ReservationFacade.new(current_user).reservations
    respond_with @reservations
  end

  def current_user_reservations
    result = current_user.reservations
    result = Reservation.all if can?(:destroy, Reservation.new)
    if params[:date]
      date = Time.zone.parse(params[:date])
      result = result.where("start_time <= ? AND end_time >= ?", date.tomorrow.midnight, date.midnight)
    end
    respond_with(Array.wrap(result))
  end

  # Returns availability in seconds given a time
  def availability
    available_time = max_availability
    start_time = Time.zone.parse(params[:start])
    room = Room.find(params[:room_id])
    availability_checker = AvailabilityChecker.new(room, start_time, start_time+max_availability)
    unless availability_checker.available?
      available_time = availability_checker.events.first.start_time - start_time
      available_time = 0 if available_time < 0
    end
    respond_with({:availability => available_time.to_i})
  end

  def create
    reserver = Reserver.new(reserver_params)
    reserver.save
    respond_with(reserver, :location => root_path, :responder => JsonResponder, :serializer => ReservationSerializer)
  end

  def destroy
    reservation = Reservation.find(params[:id])
    canceller = Canceller.new(reservation, current_user)
    canceller.save
    respond_with(canceller, :location => root_path, :responder => JsonResponder)
  end


  protected

  def reserver_params
    params[:reserver] = params[:reserver].merge(:reserver_onid => current_user.onid)
    params.require(:reserver).permit(:reserver_onid, :user_onid, :start_time, :room_id, :end_time, :description, :key_card_key)
  end

  # @TODO: Make this configurable
  def max_availability
    6.hours
  end

  def default_serializer_options
    {
        root: false
    }
  end
end
