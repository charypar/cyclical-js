#= require schedule

describe "Schedule", ->
  it "should create instances with start date", ->
    t = new Date()
    s = new Schedule(t)

    expect(Date.equals(s.startTime, t)).toBeTruthy()
  
  # basic API for listing occurences
  describe "single date schedule", ->
    beforeEach ->
      @time = new Date(2011, 11, 1, 0, 0, 0)
      @schedule = new Schedule(@time)
  
    it "should accept end time and return suboccurrence", ->
      @schedule.endTime = new Date(2011, 11, 1, 1)
      expect(Date.equals(@schedule.endTime, new Date(2011, 11, 1, 1))).toBeTruthy()
      
      so = @schedule.suboccurrencesBetween(new Date(2011, 11, 1, 0, 30), new Date(2011, 11, 2))[0]
      
      expect(Date.equals(so.start, new Date(2011, 11, 1, 0, 30))).toBeTruthy()
      expect(so.isOccurrenceStart).toBeFalsy()
      expect(Date.equals(so.end, @schedule.endTime)).toBeTruthy()
      expect(so.isOccurrenceEnd).toBeTruthy()

    it "should list the single occurrence", ->
      expect(Date.equals(@schedule.first(1)[0], new Date(2011, 11, 1))).toBeTruthy()

    it "should find next occurrence", ->
      t = new Date(2011, 11, 1)

      expect(Date.equals(@schedule.nextOccurrence((new Date(t)).add(-1).second()), t)).toBeTruthy()
      expect(@schedule.nextOccurrence((new Date(t)).add(1).second())).toBeNull()
      
      expect(Date.equals(@schedule.nextOccurrence(t), t)).toBeTruthy()

    it "should find previous occurrence", ->
      t = new Date(2011, 11, 1)

      expect(Date.equals(@schedule.previousOccurrence((new Date(t)).add(1).second()), t)).toBeTruthy()
      expect(@schedule.previousOccurrence((new Date(t)).add(-1).second())).toBeNull()
      
      expect(@schedule.previousOccurrence(t)).toBeNull()

    it "should list occurrences between dates", ->
      t = new Date(2011, 11, 1)
      
      tenma = (new Date(t)).add(-10).minutes()
      onesa = (new Date(t)).add(-1).second()
      expect(@schedule.occurrencesBetween(tenma, onesa).length).toEqual(0)

      tenmf = (new Date(t)).add(10).minutes()
      onesf = (new Date(t)).add(1).second()
      expect(@schedule.occurrencesBetween(onesf, tenmf).length).toEqual(0)
      
      from = (new Date(t)).add(-1).second()
      to = (new Date(t)).add(1).second()
      expect(Date.equals(@schedule.occurrencesBetween(from, to)[0], t)).toBeTruthy()
      
      expect(@schedule.occurrencesBetween(tenma, t).length).toEqual(0)
      expect(Date.equals(@schedule.occurrencesBetween(t, tenmf)[0], t)).toBeTruthy()
    
    it "should list occurrences up to a date", ->
      t = new Date(2011, 11, 1)
      
      expect(@schedule.occurrences((new Date(t)).add(-1).second()).length).toEqual(0)
      expect(@schedule.occurrences(t).length).toEqual(0)
      expect(Date.equals(@schedule.occurrences((new Date(t)).add(1).second())[0], t)).toBeTruthy()

    it "should list all occurrences", ->
      expect(Date.equals(@schedule.occurrences()[0], new Date(2011, 11, 1))).toBeTruthy()

  describe "advanced case", ->
    beforeEach ->
      @time = new Date(2011, 8, 1, 10)
      @schedule = new Schedule(@time, Schedule.Rule.monthly(2).weekdays(mon: 2).count(5))
    
    it "should list first 3 occurrences", ->
      expected = [new Date(2011, 8, 12, 10), new Date(2011, 10, 14, 10), new Date(2012, 0, 9, 10)]
      occ = @schedule.first(3)

      expect(occ.length).toEqual(expected.length)
      for i in [0...(expected.length)]
        expect(Date.equals(occ[i], expected[i])).toBeTruthy()
      
    it "should find next occurrence", ->
      occ = @schedule.nextOccurrence(new Date(2011, 9, 1))
      expect(Date.equals(occ, new Date(2011, 10, 14, 10))).toBeTruthy()
      
      occ = @schedule.nextOccurrence(new Date(2011, 10, 14))
      expect(Date.equals(occ, new Date(2011, 10, 14, 10))).toBeTruthy()
      
      occ = @schedule.nextOccurrence(new Date(2011, 10, 14, 10))
      expect(Date.equals(occ, new Date(2011, 10, 14, 10))).toBeTruthy()
      
      occ = @schedule.nextOccurrence(new Date(2011, 10, 14, 10, 0, 1))
      expect(Date.equals(occ, new Date(2012, 0, 9, 10))).toBeTruthy()
 
    it "should find previous occurrence", ->
      occ = @schedule.previousOccurrence(new Date(2011, 11, 1))
      expect(Date.equals(occ, new Date(2011, 10, 14, 10))).toBeTruthy()
      
      occ = @schedule.previousOccurrence(new Date(2011, 10, 14, 10, 0, 1))
      expect(Date.equals(occ, new Date(2011, 10, 14, 10))).toBeTruthy()
      
      occ = @schedule.previousOccurrence(new Date(2011, 10, 14, 10))
      expect(Date.equals(occ, new Date(2011, 8, 12, 10))).toBeTruthy()

    it "should list occurrences between dates", ->
      occ = @schedule.occurrencesBetween(new Date(2011, 9, 1), new Date(2011, 10, 14, 10, 0, 1))
      expect(Date.equals(occ[0], new Date(2011, 10, 14, 10))).toBeTruthy()

      occ = @schedule.occurrencesBetween(new Date(2011, 10, 14, 10), new Date(2011, 10, 14, 11))
      expect(Date.equals(occ[0], new Date(2011, 10, 14, 10))).toBeTruthy()
                                  
      occ = @schedule.occurrencesBetween(new Date(2011, 10, 14, 10, 0, 1), new Date(2011, 11, 1))
      expect(occ.length).toEqual(0)
      
      occ = @schedule.occurrencesBetween(new Date(2011, 10, 1), new Date(2011, 10, 14, 10))
      expect(occ.length).toEqual(0)

    it "should list occurrences upto a date", ->
      expected = [new Date(2011, 8, 12, 10), new Date(2011, 10, 14, 10), new Date(2012, 0, 9, 10)]
      
      occ = @schedule.occurrences(new Date(2012, 0, 9, 10))
      expect(occ.length).toEqual(2)
      for i in [0..1]
        expect(Date.equals(occ[i], expected[i])).toBeTruthy()
      
      occ = @schedule.occurrences(new Date(2012, 0, 9, 10, 0, 1))
      expect(occ.length).toEqual(expected.length)
      for i in [0...(expected.length)]
        expect(Date.equals(occ[i], expected[i])).toBeTruthy()
   
    it "should list all occurrences", ->
      expected = [new Date(2011, 8, 12, 10), new Date(2011, 10, 14, 10), 
                  new Date(2012, 0, 9, 10), new Date(2012, 2, 12, 10), new Date(2012, 4, 14, 10)]
      occ = @schedule.occurrences()

      expect(occ.length).toEqual(expected.length)
      for i in [0...(expected.length)]
        expect(Date.equals(occ[i], expected[i])).toBeTruthy()

  describe "multiple-day schedule", ->
    beforeEach ->
      @time = new Date(2011, 10, 1, 15)
      @schedule = new Schedule(@time, Schedule.Rule.daily(4).count(5))
      @schedule.setEndTime(new Date(2011, 10, 3, 8)) # two days later at 8 AM

    it "should return single occurrence span between dates", ->
      so = @schedule.suboccurrencesBetween(new Date(2011, 10, 1), new Date(2011, 10, 2))[0]
      
      expect(Date.equals(so.start, new Date(2011, 10, 1, 15))).toBeTruthy()
      expect(Date.equals(so.end, new Date(2011, 10, 2))).toBeTruthy()
      expect(so.isOccurrenceStart).toBeTruthy()
      expect(so.isOccurrenceEnd).toBeFalsy()
      
      so = @schedule.suboccurrencesBetween(new Date(2011, 10, 1), new Date(2011, 10, 3, 10))[0]
      
      expect(Date.equals(so.start, new Date(2011, 10, 1, 15))).toBeTruthy()
      expect(Date.equals(so.end, new Date(2011, 10, 3, 8))).toBeTruthy()
      expect(so.isOccurrenceStart).toBeTruthy()
      expect(so.isOccurrenceEnd).toBeTruthy()

      so = @schedule.suboccurrencesBetween(new Date(2011, 10, 2, 5), new Date(2011, 10, 3, 10))[0]
       
      expect(Date.equals(so.start, new Date(2011, 10, 2, 5))).toBeTruthy()
      expect(Date.equals(so.end, new Date(2011, 10, 3, 8))).toBeTruthy()
      expect(so.isOccurrenceStart).toBeFalsy()
      expect(so.isOccurrenceEnd).toBeTruthy()
      
      expect(@schedule.suboccurrencesBetween(new Date(2011, 10, 3, 9), new Date(2011, 10, 4, 11)).length).toEqual(0)

    
    it "should return multiple occurrence spans", ->
      so = @schedule.suboccurrencesBetween(new Date(2011, 10, 1), new Date(2011, 10, 8))
      
      expect(so.length).toEqual(2)
      
      expect(Date.equals(so[0].start, new Date(2011, 10, 1, 15))).toBeTruthy()
      expect(Date.equals(so[0].end, new Date(2011, 10, 3, 8))).toBeTruthy()
      expect(so[0].isOccurrenceStart).toBeTruthy()
      expect(so[0].isOccurrenceEnd).toBeTruthy()

      expect(Date.equals(so[1].start, new Date(2011, 10, 5, 15))).toBeTruthy()
      expect(Date.equals(so[1].end, new Date(2011, 10, 7, 8))).toBeTruthy()
      expect(so[1].isOccurrenceStart).toBeTruthy()
      expect(so[1].isOccurrenceEnd).toBeTruthy()
   
  describe "self overlapping schedule", ->
    beforeEach ->
      @time = new Date(2011, 10, 1, 15)
      @schedule = new Schedule(@time, Schedule.Rule.daily().count(5))
      @schedule.setEndTime(new Date(2011, 10, 3, 8)) # two days later at 8 AM
    
    it "should find two occurrences in a single day", ->
      s = @schedule.suboccurrencesBetween(new Date(2011, 10, 2), new Date(2011, 10, 3))
    
      expect(s.length).toEqual(2)
      
      expect(Date.equals(s[0].start, new Date(2011, 10, 2))).toBeTruthy()
      expect(s[0].isOccurrenceStart).toBeFalsy()
      expect(Date.equals(s[0].end, new Date(2011, 10, 3))).toBeTruthy()
      expect(s[0].isOccurrenceEnd).toBeFalsy()
      
      expect(Date.equals(s[1].start, new Date(2011, 10, 2, 15))).toBeTruthy()
      expect(s[1].isOccurrenceStart).toBeTruthy()
      expect(Date.equals(s[1].end, new Date(2011, 10, 3))).toBeTruthy()
      expect(s[1].isOccurrenceEnd).toBeFalsy()
   
  # Examples from RFC 5545 except excluded and included dates
  describe "rfc 5545 examples", -> 
    beforeEach ->
      @time = new Date(1997, 8, 2, 9, 0, 0)

    describe "daily for 10 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.daily().count(10))
        
      it "should list occurences", ->
        expected = (new Date(1997, 8, d, 9, 0, 0) for d in [2..11])
        occ = @schedule.occurrences()
      
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
      
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Daily, end after 10 times")

    describe "daily until December 24, 1997", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.daily().stop(new Date(1997, 11, 24)))

      it "should list occurrences", ->
        expected = (new Date(1997, 8, i, 9, 0, 0) for i in [2..30])
        expected = expected.concat(new Date(1997, 9, i, 9, 0, 0) for i in [1..31])
        expected = expected.concat(new Date(1997, 10, i, 9, 0, 0) for i in [1..30])
        expected = expected.concat(new Date(1997, 11, i, 9, 0, 0) for i in [1..23])
        occ = @schedule.occurrences()
        
        for i in [0...(expected.length)]
          jasmine.log(occ[i], expected[i])
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
      
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Daily, until December 24, 1997")
    
    describe "every other day - forever", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.daily(2))
      
      it "should list first 45 occurrences", ->
        expected = (new Date(1997, 8, 2*i, 9, 0, 0) for i in [1..15])
        expected = expected.concat(new Date(1997, 9, 2*i, 9, 0, 0) for i in [1..15])
        expected = expected.concat(new Date(1997, 10, 2*i - 1, 9, 0, 0) for i in [1..15])
        occ1 = @schedule.first(45)
        occ2 = @schedule.occurrences(new Date(1997, 11, 1))
        
        for i in [0...(expected.length)]
          expect(Date.equals(occ1[i], expected[i])).toBeTruthy()
          expect(Date.equals(occ2[i], expected[i])).toBeTruthy()
      
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 2 days")
  
    describe "every 10 days, 5 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.daily(10).count(5))
      
      it "should list occurrences", ->
        expected = (new Date(1997, 8, i, 9, 0, 0) for i in [2, 12, 22])
        expected = expected.concat(new Date(1997, 9, i, 9, 0, 0) for i in [2, 12])
        occ = @schedule.occurrences()
        
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
      
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 10 days, end after 5 times")
    
    describe "every day in January, for 3 years", ->
      beforeEach ->
        @schedule_1 = new Schedule(new Date(1998, 0, 1, 9), Schedule.Rule.daily().month('january').stop(new Date(2000, 0, 31, 14)))
        
        rule = Schedule.Rule.yearly().month('january').weekdays(1, 'tu', 'we', 'th', 5, 6, 'su').stop(new Date(2000, 0, 31, 14))
        @schedule_2 = new Schedule(new Date(1998, 0, 1, 9), rule)
              
      it "should list occurrences", ->
        expected = (new Date(1998, 0, i, 9) for i in [1..31])
        expected = expected.concat(new Date(1999, 0, i, 9) for i in [1..31])
        expected = expected.concat(new Date(2000, 0, i, 9) for i in [1..31])
        
        occ = @schedule_1.occurrences()
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

        occ = @schedule_2.occurrences()
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
      
      it "should output correct string", ->
        expect(@schedule_1.toString()).toEqual("Daily, in January, until January 31, 2000")
        expect(@schedule_2.toString()).toEqual("Every year, in January, on sunday, monday, tuesday, wednesday, thursday, friday and saturday, until January 31, 2000")

    describe "weekly for 10 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.weekly().count(10))
      
      it "should list occurrences", ->
        expected = (new Date(1997, 8, i, 9) for i in [2, 9, 16, 23, 30])
        expected = expected.concat(new Date(1997, 9, i, 9) for i in [7, 14, 21, 28])
        expected = expected.concat([new Date(1997, 10, 4, 9)])
        occ = @schedule.occurrences()
        
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
          
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Weekly, end after 10 times")

    describe "weekly until December 24, 1997", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.weekly().stop(new Date(1997, 11, 24)))
      
      it "should list occurrences", ->
        expected = (new Date(1997, 8, i, 9) for i in [2, 9, 16, 23, 30])
        expected = expected.concat(new Date(1997, 9, i, 9) for i in [7, 14, 21, 28])
        expected = expected.concat(new Date(1997, 10, i, 9) for i in [4, 11, 18, 25])
        expected = expected.concat(new Date(1997, 11, i, 9) for i in [2, 9, 16, 23])
        occ = @schedule.occurrences()
        
        jasmine.log(occ)
        jasmine.log(expected)
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Weekly, until December 24, 1997")

    describe "every other week forever", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.weekly(2))
      
      it "should list first 14 occurrences", ->
        expected = (new Date(1997, 8, i, 9) for i in [2, 16, 30])
        expected = expected.concat(new Date(1997, 9, i, 9) for i in [14, 28])
        expected = expected.concat(new Date(1997, 10, i, 9) for i in [11, 25])
        expected = expected.concat(new Date(1997, 11, i, 9) for i in [9, 23])
        expected = expected.concat(new Date(1998, 0, i, 9) for i in [6, 20])
        expected = expected.concat(new Date(1998, 1, i, 9) for i in [3, 17])
        occ = @schedule.first(13)

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 2 weeks")

    describe "weekly on tuesday and thursday for five weeks", ->
      beforeEach ->
        @stop_schedule = new Schedule(@time, Schedule.Rule.weekly().weekdays('tue', 'thu').stop(new Date(1997, 9, 7)))
        @count_schedule = new Schedule(@time, Schedule.Rule.weekly().weekdays('tue', 'thu').count(10))
      
      it "should list occurrences", ->
        expected = (new Date(1997, 8, i, 9) for i in [2, 4, 9, 11, 16, 18, 23, 25, 30])
        expected = expected.concat([new Date(1997, 9, 2, 9)])
        
        occ = @stop_schedule.occurrences()
        
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
        
        occ = @count_schedule.occurrences()
       
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
    
      it "should output correct string", ->
        expect(@stop_schedule.toString()).toEqual("Weekly, on tuesday and thursday, until October 7, 1997")
        expect(@count_schedule.toString()).toEqual("Weekly, on tuesday and thursday, end after 10 times")
    
    describe "every other week on Monday, Wednesday, and Friday until December 24, 1997", ->
      # starting on Monday, September 1, 1997
      beforeEach ->
        @time = new Date(1997, 8, 1, 9)
        @schedule = new Schedule(@time, Schedule.Rule.weekly(2).weekdays('mon', 'wed', 'fri').stop(new Date(1997, 11, 24)))
      
      it "should list occurrences", ->
        expected = (new Date(1997, 8, i, 9) for i in [1, 3, 5, 15, 17, 19, 29])
        expected = expected.concat(new Date(1997, 9, i, 9) for i in [1, 3, 13, 15, 17, 27, 29, 31])
        expected = expected.concat(new Date(1997, 10, i, 9) for i in [10, 12, 14, 24, 26, 28])
        expected = expected.concat(new Date(1997, 11, i, 9) for i in [8, 10, 12, 22])
        occ = @schedule.occurrences()
        
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
     
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 2 weeks, on monday, wednesday and friday, until December 24, 1997")
 
     
    describe "every other week on Tuesday and Thursday, for 8 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.weekly(2).weekdays('tu', 'th').count(8))
      
      it "should list occurrences", ->
        expected = (new Date(1997, 8, i, 9) for i in [2, 4, 16, 18, 30])
        expected = expected.concat(new Date(1997, 9, i, 9) for i in [2, 14, 16])
        occ = @schedule.occurrences()

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 2 weeks, on tuesday and thursday, end after 8 times")

    describe "monthly on the first friday for 10 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.monthly().weekdays(friday: 1).count(10))
  
      it "should list occurrences", ->
        expected = (new Date(1997, d[0], d[1], 9) for d in [[8, 5], [9, 3], [10, 7], [11, 5]])
        expected = expected.concat(new Date(1998, d[0], d[1], 9) for d in [[0, 2], [1, 6], [2, 6], [3, 3], [4, 1], [5, 5]])
        occ = @schedule.occurrences()

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
          
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every month, on 1. friday, end after 10 times")
  

    describe "monthly on the first friday until December 24, 1997", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.monthly().weekdays(friday: 1).stop(new Date(1997, 11, 24)))
  
      it "should list occurrences", ->
        expected = (new Date(1997, d[0], d[1], 9) for d in [[8, 5], [9, 3], [10, 7], [11, 5]])
        occ = @schedule.occurrences()

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every month, on 1. friday, until December 24, 1997")

    describe "every other month on the first and last Sunday of the month for 10 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.monthly(2).weekdays(sunday: [1, -1]).count(10))
      
      it "should list occurrences", ->
        expected = (new Date(1997, d[0], d[1], 9) for d in [[8, 7], [8, 28], [10, 2], [10, 30]])
        expected = expected.concat(new Date(1998, d[0], d[1], 9) for d in [[0, 4], [0, 25], [2, 1], [2, 29], [4, 3], [4, 31]])
        occ = @schedule.occurrences()

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
    
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 2 months, on -1., 1. sunday, end after 10 times")

    
    describe "monthly on the second-to-last monday of the month for 6 months", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.monthly().weekdays(monday: -2).count(6))
      
      it "should list occurrences", ->
        expected = (new Date(1997, d[0], d[1], 9) for d in [[8, 22], [9, 20], [10, 17], [11, 22]])
        expected = expected.concat(new Date(1998, d[0], d[1], 9) for d in [[0, 19], [1, 16]])
        occ = @schedule.occurrences()

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every month, on -2. monday, end after 6 times")

    describe "monthly on the third-to-the-last day of the month, forever", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.monthly().monthday(-3))
      
      it "should list 6 occurrences", ->
        expected = (new Date(1997, d[0], d[1], 9) for d in [[8, 28], [9, 29], [10, 28], [11, 29]])
        expected = expected.concat(new Date(1998, d[0], d[1], 9) for d in [[0, 29], [1, 26]])
        occ = @schedule.first(6)

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every month, on -3. day")

    describe "monthly on the 2nd and 15th of the month for 10 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.monthly().monthdays(2, 15).count(10))
      
      it "should list occurrences", ->
        expected = (new Date(1997, d[0], d[1], 9) for d in [[8, 2], [8, 15], [9, 2], [9, 15], [10, 2], [10, 15], [11, 2], [11, 15]])
        expected = expected.concat(new Date(1998, d[0], d[1], 9) for d in [[0, 2], [0, 15]])
        occ = @schedule.occurrences()

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
    
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every month, on 2. and 15. day, end after 10 times")
    
    describe "monthly on the first and last day of the month for 10 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.monthly().monthdays(1, -1).count(10))
      
      it "should list occurrences", ->
        expected = (new Date(1997, d[0], d[1], 9) for d in [[8, 30], [9, 1], [9, 31], [10, 1], [10, 30], [11, 1], [11, 31]])
        expected = expected.concat(new Date(1998, d[0], d[1], 9) for d in [[0, 1], [0, 31], [1, 1]])
        occ = @schedule.occurrences()

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every month, on -1. and 1. day, end after 10 times")

    describe "every 18 months on the 10th thru 15th of the month for 10 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.monthly(18).monthdays(10, 11, 12, 13, 14, 15).count(10))
    
      it "should list occurrences", ->
        expected = (new Date(1997, 8, d, 9) for d in [10..15])
        expected = expected.concat(new Date(1999, 2, d, 9) for d in [10..13])
        occ = @schedule.occurrences()
        
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 18 months, on 10., 11., 12., 13., 14. and 15. day, end after 10 times")

    describe "every Tuesday, every other month", ->
      beforeEach ->
        @schedule = new Schedule(@time, Schedule.Rule.monthly(2).weekdays('tue'))
      
      it "should list 18 occurrences", ->
        expected = (new Date(1997, 8, d, 9) for d in [2, 9, 16, 23, 30])
        expected = expected.concat(new Date(1997, 10, d, 9) for d in [4, 11, 18, 25])
        expected = expected.concat(new Date(1998, 0, d, 9) for d in [6, 13, 20, 27])
        expected = expected.concat(new Date(1998, 2, d, 9) for d in [3, 10, 17, 24, 31])
        occ = @schedule.first(18)

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
  
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 2 months, on tuesday")   
   
    describe "yearly in June and July for 10 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(new Date(1997, 5, 10, 9), Schedule.Rule.yearly().months(6, 7).count(10))
      
      it "shoul lists occurrences", ->
        expected = []
        for y in [1997, 1998, 1999, 2000, 2001]
          expected.push(new Date(y, 5, 10, 9))
          expected.push(new Date(y, 6, 10, 9))
        occ = @schedule.occurrences()
        
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every year, in June and July, end after 10 times")   
  
    describe "every other year on January, February, and March for 10 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(new Date(1997, 2, 10, 9), Schedule.Rule.yearly(2).months(1, 2, 3).count(10))
      
      it "should list occurrences", ->
        expected = [new Date(1997, 2, 10, 9)] 
        for y in  [1999, 2001, 2003]
          for m in [0, 1, 2]
            expected.push(new Date(y, m, 10, 9))
        occ = @schedule.occurrences()
        
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
          
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 2 years, in January, February and March, end after 10 times")   
  
    describe "every third year on the 1st, 100th, and 200th day for 10 occurrences", ->
      beforeEach ->
        @schedule = new Schedule(new Date(1997, 0, 1, 9), Schedule.Rule.yearly(3).yeardays(1, 100, 200).count(10))
      
      it "should list occurrences", ->
        expected = (new Date(d[0], d[1], d[2], d[3]) for d in [[1997, 0, 1, 9], [1997, 3, 10, 9], [1997, 6, 19, 9], [2000, 0, 1, 9], [2000, 3, 9, 9], 
                                                               [2000, 6, 18, 9], [2003, 0, 1, 9], [2003, 3, 10, 9], [2003, 6, 19, 9], [2006, 0, 1, 9]])
        occ = @schedule.occurrences()

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
      
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 3 years, on 1., 100. and 200. day, end after 10 times")
    
    describe "every 20th Monday of the year, forever", ->
      beforeEach ->
        @schedule = new Schedule(new Date(1997, 4, 19, 9), Schedule.Rule.yearly().weekdays(mon: 20))

      it "should list 3 occurrences", ->
        expected = [new Date(1997, 4, 19, 9), new Date(1998, 4, 18, 9), new Date(1999, 4, 17, 9)]
        occ = @schedule.first(3)

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
    
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every year, on 20. monday")
    
    # skipped: Monday of week number 20 (where the default start of the week is Monday), forever
    
    describe "every Thursday in March, forever", ->
      beforeEach ->
        @schedule = new Schedule(new Date(1997, 2, 13, 9), Schedule.Rule.yearly().month('march').weekday('thursday'))
      
      it "should list 11 occurrences", ->
        expected = (new Date(1997, 2, d, 9) for d in [13, 20, 27])
        expected = expected.concat(new Date(1998, 2, d, 9) for d in [5, 12, 19, 26])
        expected = expected.concat(new Date(1999, 2, d, 9) for d in [4, 11, 18, 25])
        occ = @schedule.first(11)

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
      
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every year, in March, on thursday")

    describe "every Thursday, but only during June, July, and August, forever", ->
      beforeEach ->
        @schedule = new Schedule(new Date(1997, 5, 5, 9), Schedule.Rule.yearly().months(6, 7, 8).weekday('thu'))
      
      it "should list first X occurrences", ->
        expected = (new Date(1997, 5, d, 9) for d in [5, 12, 19, 26])
        expected = expected.concat(new Date(1997, 6, d, 9) for d in [3, 10, 17, 24, 31])
        expected = expected.concat(new Date(1997, 7, d, 9) for d in [7, 14, 21, 28])
        expected = expected.concat(new Date(1998, 5, d, 9) for d in [4, 11, 18, 25])
        expected = expected.concat(new Date(1998, 6, d, 9) for d in [2, 9, 16, 23, 30])
        expected = expected.concat(new Date(1998, 7, d, 9) for d in [6, 13, 20, 27])
        expected = expected.concat(new Date(1999, 5, d, 9) for d in [3, 10, 17, 24])
        expected = expected.concat(new Date(1999, 6, d, 9) for d in [1, 8, 15, 22, 29])
        expected = expected.concat(new Date(1999, 7, d, 9) for d in [5, 12, 19, 26])
        occ = @schedule.first(39)

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every year, in June, July and August, on thursday")

    describe "every Friday the 13th, forever", ->
      beforeEach ->
        @schedule = new Schedule(new Date(1997, 8, 2, 9), Schedule.Rule.monthly().weekday('fri').monthday(13))
      
      it "should list 5 occurrences", ->
        expected = [new Date(1998, 1, 13, 9), new Date(1998, 2, 13, 9), new Date(1998, 10, 13, 9),
                    new Date(1999, 7, 13, 9), new Date(2000, 9, 13, 9)]
        occ = @schedule.first(5)
    
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
      
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every month, on friday, on 13. day")
    
    describe "the first Saturday that follows the first Sunday of the month, forever", ->
      beforeEach ->
        @schedule = new Schedule(new Date(1997, 8, 13, 9), Schedule.Rule.monthly().weekday('sat').monthdays(7, 8, 9, 10, 11, 12, 13))
      
      it "should list 10 occurrences", ->
        expected = (new Date(1997, d[0], d[1], 9) for d in [[8, 13], [9, 11], [10, 8], [11, 13]])
        expected = expected.concat(new Date(1998, d[0], d[1], 9) for d in [[0, 10], [1, 7], [2, 7], [3, 11], [4, 9], [5, 13]])
        occ = @schedule.first(10)

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every month, on saturday, on 7., 8., 9., 10., 11., 12. and 13. day")
     
    describe "every 4 years, the first Tuesday after a Monday in November, forever (U.S. Presidential Election day):", ->
      beforeEach ->
        @schedule = new Schedule(new Date(1996, 10, 5, 9), Schedule.Rule.yearly(4).month(11).weekday('tue').monthdays(2, 3, 4, 5, 6, 7, 8))
      
      it "should list first 3 election days", ->
        expected = [new Date(1996, 10, 5, 9), new Date(2000, 10, 7, 9), new Date(2004, 10, 2, 9)]
        occ = @schedule.first(3)

        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()
          
      it "should output correct string", ->
        expect(@schedule.toString()).toEqual("Every 4 years, in November, on tuesday, on 2., 3., 4., 5., 6., 7. and 8. day")
     
    # skipped most of the the rest - i.e. we're missing implementation of BYSETPOS and less-than-a-day recurrence rules
    
    describe "ignoring an invalid date (i.e., February 30)", ->
      beforeEach ->
        @schedule = new Schedule(new Date(2007, 0, 15, 9), Schedule.Rule.monthly().monthdays(15, 30).count(5))
      
      it "should list occurrences", ->
        expected = (new Date(2007, d[0], d[1], 9) for d in [[0, 15], [0, 30], [1, 15], [2, 15], [2, 30]])
        occ = @schedule.occurrences()
        
        expect(occ.length).toEqual(expected.length)
        for i in [0...(expected.length)]
          expect(Date.equals(occ[i], expected[i])).toBeTruthy()

  describe "serialization", ->
    beforeEach ->
      @schedule = new Schedule(new Date(2000, 0, 1, 10), Schedule.Rule.monthly().monthdays(1).count(10))
      @schedule.setEndTime(new Date(2000, 0, 1, 10, 10))
    
    it "should do a hash round trip", ->
      o = @schedule.toObject()
      s = Schedule.fromObject(o)
      
      expect(s.startTime).toEqual(@schedule.startTime)
      expect(s.endTime).toEqual(@schedule.endTime)
      
      expect(s.rule() instanceof Schedule.Rules.MonthlyRule).toBeTruthy()
      expect(s.rule().step().seconds).toEqual(@schedule.rule().step().seconds)
     
    it "should do a JSON round trip", ->
      j = @schedule.toJSON()
      s = Schedule.fromJSON(j)
      
      expect(s.startTime).toEqual(@schedule.startTime)
      expect(s.endTime).toEqual(@schedule.endTime)
      
      expect(s.rule() instanceof Schedule.Rules.MonthlyRule).toBeTruthy()
      expect(s.rule().step().seconds).toEqual(@schedule.rule().step().seconds)
