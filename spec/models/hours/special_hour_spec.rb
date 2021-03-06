require 'spec_helper'

describe Hours::SpecialHour do
  subject {Hours::SpecialHour}
  describe "#time_info" do
    before(:each) do
      Timecop.travel(Date.new(2013,8,19))
      @current_term = create(:special_hour, start_date: Time.current.yesterday.midnight, end_date: Time.current.midnight)
    end
    context "when given a date with no results" do
      it "should return an empty hash" do
        Hours::SpecialHour.time_info(Date.today-30.days).should == {}
      end
    end
    context "when given a date inside the interval" do
      it "should return the start and end time for that day" do
        expect(Hours::SpecialHour.time_info(Date.today)).to eq({Date.today => {'open' => "1:00 pm", 'close' => "10:00 pm"}})
      end
      it "should give the start and end time for both periods" do
        expect(Hours::SpecialHour.time_info(Date.yesterday)).to eq({Date.yesterday => {'open' => "1:00 pm", 'close' => "10:00 pm"}})
      end
    end
    context "when the special hour spans multiple days" do
      before(:each) do
        @hour = create(:special_hour,
                       start_date: Date.new(2013,8,31).at_beginning_of_day,
                       end_date: Date.new(2013,9,2).at_beginning_of_day,
                       open_time: "01:00:00",
                       close_time: "01:00:00"
                      )
      end
      it "should say those times for each day" do
        3.times do |n|
          expect(subject.time_info(Date.new(2013,8,31)+n.days)).to eq({(Date.new(2013,8,31)+n.days) => {'open' => '1:00 am', 'close' => '1:00 am'}})
        end
      end
    end
  end
end
