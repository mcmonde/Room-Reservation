jQuery ->
  window.CalendarManager = new CalendarManager
class CalendarManager
  constructor: ->
    this.initialize_calendar()
  initialize_calendar: ->
    @datepicker = $("#datepicker")
    @datepicker.datepicker(onSelect: this.selected_date, showButtonPanel: true, minDate: @datepicker.data("min-date"))
    $(document).on("click","button[data-handler=today]",this.go_to_today)
    cached_date = this.get_date_from_cookie()
    @datepicker.datepicker("setDate","#{cached_date[1]}/#{cached_date[2]}/#{cached_date[0]}")
    date = @datepicker.datepicker("getDate")
    @date_selected = [date.getFullYear(), date.getMonth()+1, date.getDate()]
    this.truncate_to_now()
    this.color_reservations("#{@date_selected[0]}-#{@date_selected[1]}-#{@date_selected[2]}")
    this.bind_pop_state()
  go_to_today: =>
    day = @datepicker.datepicker("option", "minDate")
    if day? && day != ""
      @datepicker.datepicker("setDate", day)
    else
      @datepicker.datepicker("setDate","+0")
    current_date = @datepicker.datepicker("getDate")
    this.selected_date(current_date,@datepicker)
    return
  truncate_to_now: =>
    start_time = moment($(".room-data-wrap").data("start")).tz("America/Los_Angeles")
    current_time = moment().tz("America/Los_Angeles")
    difference = current_time - start_time
    current_hour = Math.floor(difference/1000/60/60)
    bar_length = current_hour*60*60/180
    hour_elements = $(".tab-content div").filter( -> $(this).data("hour") < current_hour)
    $(".tab-content div").filter( -> $(this).data("hour")?).show()
    $("div").filter( -> $(this).data("old-height")?).each (key, item) ->
      $(this).height($(this).data("old-height"))
    return if current_hour < 0 || (current_time - start_time) > 24*60*60*1000
    $(".tab-pane").show()
    $(".room-data").each (key, item) =>
      $(item).data("old-height", $(item).height())
      $(item).height($(item).height() - bar_length)
    $(".bar").each (key, item) =>
      item = $(item)
      start_offset = item.parent().offset().top
      start_at = item.offset().top - start_offset
      end_at = item.height()+start_at
      if start_at < bar_length
        if end_at > bar_length
          if(item.data("start")? && item.hasClass("bar-success"))
            current_time.second(0)
            current_time.minute(Math.ceil(current_time.minute()/10)*10)
            item.data("start",current_time.toISOString())
            item.attr("data-start", current_time.toISOString())
          item.height(end_at - bar_length)
        else
          item.data("remove", true)
    $(".bar").filter(-> $(this).data("remove") == true).remove()
    $(".room-data-bar").height($(".room-data-bar").height()-bar_length)
    hour_elements.hide()
    $("#dayviewTable").data("old-height", $("#dayviewTable").height())
    $("#dayviewTable").height($("#dayviewTable").height() - bar_length)
    $(".tab-pane").attr("style",null)
    return
  refresh_view: ->
    current_date = @datepicker.datepicker("getDate")
    this.selected_date(current_date,@datepicker)
  selected_date: (dateText, inst) =>
    date = @datepicker.datepicker("getDate")
    @date_selected = [date.getFullYear(), date.getMonth()+1, date.getDate()]
    this.day_changed(date.getFullYear(), date.getMonth()+1, date.getDate())
    return
  day_changed: (year, month, day) =>
    # Set cookies
    this.update_cookie(year, month, day)
    this.load_day(year, month, day)
    # Highlight day on map
    $(".day").removeClass("day-selected")
    $(".day[day=#{day}]").addClass("day-selected")
  load_day: (year, month, day) ->
    $('#loading-spinner').show() unless @background_loading
    cookie_requested = this.get_date_from_cookie()
    history.pushState?({}, '', "/day/#{year}-#{month}-#{day}") unless @push == false
    @push = true
    $.get("/home/day/#{encodeURIComponent("#{year}-#{month}-#{day}")}", (data) =>
      return unless @date_selected.toString() == [year, month, day].toString()
      new_room_list = $(data)
      for i in [0..new_room_list.length-1]
        div = $(new_room_list[i])
        id = div.attr('id')
        html = div.html()
        $('#' + id).html(html)
      $('#loading-spinner').hide()
      window.FilterManager.apply_filters()
      window.TooltipManager.set_tooltips()
      this.truncate_to_now()
      this.color_reservations("#{year}-#{month}-#{day}")
      window.ReservationPopupManager.hide_popup() unless @background_loading
      window.CancelPopupManager.hide_popup() unless @background_loading
      @background_loading = false
      window.FayeManager?.subscribe_to_date("#{year}-#{month}-#{day}")
    )
    return
  color_reservations: (date)->
    $.getJSON("/reservations?date=#{date}", (reservations) =>
      user = User.current().get_value("onid")
      for reservation in reservations
        element = $("*[data-id=#{reservation.id}]")
        element.removeClass("bar-danger")
        element.addClass("bar-info")
        if reservation.user_onid == user
          element.attr("data-original-title","Click to Cancel")
        else
          element.data("user-onid", reservation.user_onid)
          element.attr("data-original-title", "#{reservation.user_onid}: Click to Cancel")
    )
    return
  get_date_from_cookie: ->
    result = $.cookie('date')
    unless result?
      min_date = @datepicker.datepicker("option", "minDate").split("/")
      result = "#{min_date[2]}-#{min_date[0]}-#{min_date[1]}"
    result = result.split('-')
    return [parseInt(result[0]),parseInt(result[1]), parseInt(result[2])]
  update_cookie: (year, month, day) ->
    $.cookie('date', "#{year}-#{month}-#{day}", {expires: 30, path: '/'})
  go_to_date: (year, month, day, loading) ->
    @datepicker.datepicker("setDate", "#{month}/#{day}/#{year}")
    current_date = @datepicker.datepicker("getDate")
    @push = false
    @background_loading = loading
    this.selected_date(current_date,@datepicker)
  bind_pop_state: ->
    $(window).on("popstate", (e)=>
      date = location.pathname.split("/").pop().split("-")
      this.go_to_date(date[0], date[1], date[2])
    )