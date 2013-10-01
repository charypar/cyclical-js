#= require_self
#= require schedule/rule

#= require schedule/rules/daily_rule
#= require schedule/rules/weekly_rule
#= require schedule/rules/monthly_rule
#= require schedule/rules/yearly_rule

#= require schedule/occurrence

class window.Schedule

  constructor: (startTime, rule) ->
    @occurrence = new Schedule.Occurrence(rule, startTime) if rule?
    @startTime = if @occurrence then @occurrence.startTime else startTime

  setRule: (rule) =>
    @occurrence = if rule? then null else new Schedule.Occurrence(rule, @startTime)
    @occurrence.duration = if @endTime then (@endTime - @startTime) else 0

  rule: () =>
    if @occurrence? then @occurrence.rule else null

  setEndTime: (time) =>
    throw "End time is before start time" if time < @startTime
    @endTime = time
    @occurrence.duration = (time - @startTime) if @occurrence?

    time

  # query interface

  first: (n) =>
    return [@startTime] unless @occurrence?

    @occurrence.nextOccurrences(n, @startTime)

  # first occurrence in [time, infinity)
  nextOccurrence: (time) =>
    return (if @startTime < time then null else @startTime) unless @occurrence?

    @occurrence.nextOccurrence(time)

  # last occurrence in (-infinity, time)
  previousOccurrence: (time) =>
    return (if @startTime >= time then null else @startTime) unless @occurrence?

    @occurrence.previousOccurrence(time)

  occurrences: (endTime) =>
    throw "You have to specify end time for an infinite schedule occurrence listing" if !endTime? && @occurrence && @occurrence.rule.isInfinite()

    if endTime?
      @occurrencesBetween(@startTime, endTime)
    else
      return [@startTime] unless @occurrence?

      @occurrence.all()

  # occurrences in [t1, t2)
  occurrencesBetween: (t1, t2) =>
    return (if (@startTime < t1 || @startTime >= t2) then [] else [@startTime]) unless @occurrence?

    @occurrence.occurrencesBetween(t1, t2)

  suboccurrencesBetween: (t1, t2) =>
    throw "Schedule must have an end time to compute suboccurrences" unless @endTime?

    return [Schedule.Suboccurrence.find(occurrence: [@startTime, @endTime], interval: [t1, t2])] unless @occurrence?

    @occurrence.suboccurrencesBetween(t1, t2)

  toObject: =>
    o = if @occurrence? then @occurrence.toObject() else {}

    o.start = @startTime
    o.end = @endTime if @endTime?

    o

  toJSON: =>
    JSON.stringify(@toObject())

  toString: =>
    @rule().toString()

Schedule.fromObject = (object) =>
  startTime = object.start
  endTime = object.end

  rule = if object.freq && object.interval then Schedule.Rule.fromObject(object) else null

  s = new Schedule(startTime, rule)
  s.setEndTime(endTime)

  s

Schedule.fromJSON = (json) =>
  o = JSON.parse(json)

  o.start =  Date.parseISO8601(o.start) if o.start?
  o.end =  Date.parseISO8601(o.end) if o.end?
  o.stop =  Date.parseISO8601(o.stop) if o.stop?

  Schedule.fromObject(o)

Schedule.Rules = {}
Schedule.Filters = {}
