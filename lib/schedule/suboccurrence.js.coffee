# Holds suboccurrence of a schedule, i.e. time interval which is a subinterval of a single occurrence.
# This is used to find actual time spans to display in a given time interval (for example in a calendar)
class Schedule.Suboccurrence
  constructor: (attrs) ->
    @start = attrs.start
    @end = attrs.end
    @isOccurrenceStart = attrs.isOccurrenceStart
    @isOccurrenceEnd = attrs.isOccurrenceEnd

# factory method for finding suboccurrence of a single occurrence with an interval, with the ability to return nil
# This might be a totally bad idea, I'm not sure right now really... 
Schedule.Suboccurrence.find = (attrs) ->
  throw "Missing occurrence" unless (occurrence = attrs.occurrence).length?
  throw "Missing interval" unless (interval = attrs.interval).length?

  return null if occurrence[1] <= interval[0] || occurrence[0] >= interval[2]

  suboccurrence = {}

  if occurrence[0] < interval[0]
    suboccurrence.start = interval[0]
    suboccurrence.isOccurrenceStart = false
  else
    suboccurrence.start = occurrence[0]
    suboccurrence.isOccurrenceStart = true

  if occurrence[1] > interval[1]
    suboccurrence.end = interval[1]
    suboccurrence.isOccurrenceEnd = false
  else
    suboccurrence.end = occurrence[1]
    suboccurrence.isOccurrenceEnd = true
    
  new Schedule.Suboccurrence(suboccurrence)
