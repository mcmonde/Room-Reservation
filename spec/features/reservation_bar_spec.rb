require 'spec_helper'

describe "GET / reservation bars" do
  before(:each) do
    # Fake a login
    RubyCAS::Filter.fake("bla")
    # Start Time to be 1:00 AM January 1
    t = Time.local(2013, 1, 1, 1, 0, 0)
    Timecop.travel(t)
    # Make the hours "always open"
    create(:special_hour, open_time: "00:00:00", close_time: "00:00:00")
  end
  after(:each) do
    Timecop.return
  end
  describe "floor headers" do
    context "when there are no rooms" do
      before(:each) do
        visit root_path
      end
      it "should display no room headers" do
        expect(page).not_to have_selector('.nav-tabs li')
      end
    end
    context "when there are rooms" do
      before(:each) do
        create(:room, :floor => 1)
        create(:room, :floor => 2)
        visit root_path
      end
      it "should display as many floor headers as there are rooms with those floors" do
        expect(page).to have_selector('.nav-tabs li', :count => 2)
      end
    end
  end

  describe "room bars" do
    before(:each) do
      @room1 = create(:room, :floor => 1)
      @room2 = create(:room, :floor => 2)
      visit root_path
    end
    describe "viewing", :js => true do
      it "should show only the first floor's rooms" do
        expect(page).to have_selector('.room-data-bar', :count => 1)
      end
    end
    describe "clicking a room", :js => true do
      before(:each) do
        find("a[href='#floor-#{@room2.floor}']").click
      end
      it "should display the second room" do
        expect(page).not_to have_content(@room1.name)
        expect(page).to have_content(@room2.name)
      end
    end
    describe "reservation bars" do
      context "when there are no reservations" do
        it "should not show any red bars" do
          expect(page).not_to have_selector(".bar-danger")
        end
      end

      context "when there are reservations", :focus => true do
        before(:each) do
          Timecop.return
          create(:special_hour, open_time: "00:00:00", close_time: "00:00:00")
          r = create(:reservation, :start_time => Time.current.midnight, :end_time => Time.current.midnight+2.hours, :room => @room1)
          visit root_path
        end
        it "should show the red bar for the reservation" do
          expect(page).to have_selector(".bar-danger")
        end
        describe "caching", :caching => true do
          before(:each) do
            expect(page).to have_selector(".bar-danger", :count => 1)
          end
          it "should update the cache when a new reservation is added" do
            puts "Creating Reservation"
            create(:reservation, :start_time => Time.current.midnight+5.hours, :end_time => Time.current.midnight+7.hours, :room => @room1)
            puts "Created Reservation"
            visit root_path
            expect(page).to have_selector(".bar-danger", :count => 2)
          end
          it "should update the cache when the time on a current reservation changes", :js => true do
            reservation = Reservation.first
            reservation.end_time = reservation.end_time + 2.hours
            reservation.save
            current_height = page.evaluate_script("$('.bar-danger').first().height()")
            visit root_path
            # Disable the truncation for testing.
            page.execute_script("window.CalendarManager.truncate_to_now = function(){}")
            new_height = page.evaluate_script("$('.bar-danger').first().height()")
            expect(current_height).not_to eq new_height
          end
          it "should update the cache when the time changes to a whole other day", :js => true do
            reservation = Reservation.first
            reservation.start_time = reservation.start_time - 48.hours
            reservation.end_time = reservation.end_time - 48.hours
            reservation.save
            visit root_path
            expect(page).not_to have_selector(".bar-danger")
          end
          it "should update the cache when a reservation is deleted" do
            Reservation.destroy_all
            visit root_path
            expect(page).not_to have_selector(".bar-danger")
          end
        end

        context "when a bunch of dates are picked", :js => true do
          before(:each) do
            # Disable the truncation for testing.
            page.execute_script("window.CalendarManager.truncate_to_now = function(){}")
            # Add counter for when $.get completes.
            page.execute_script("window.load_count = 0")
            page.execute_script("$.get_alt = $.get")
            page.execute_script("$.get = function(url, data, callback, type){var old_data = data; data = function(data_content){window.load_count++; $('body').addClass('count-'+window.load_count); old_data(data_content);}; $.get_alt(url, data, callback, type)}")
            # Artificially slow down loading the day
            page.execute_script("window.CalendarManager.day_changed_alt = window.CalendarManager.day_changed")
            page.execute_script("window.CalendarManager.day_changed = function(year, month, day){window.setTimeout(function(){window.CalendarManager.day_changed_alt(year,month,day)},100)}")
            all("#datepicker a")[2].click
            # Undo artificial slowdown
            page.execute_script("window.CalendarManager.day_changed = window.CalendarManager.day_changed_alt")
            find("button[data-handler=today]").click()
          end
          it "should load the last one" do
            # Expect 2 calls to load_day
            expect(page).to have_selector("body.count-2")
            expect(page).to have_selector(".bar-danger")
          end
        end
      end
    end
  end
end