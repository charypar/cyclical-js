# Holds an occurence of a recurrence rule, can compute next and previous and list occurrences
class Schedule.Occurrence

  constructor: (rule, startTime) ->
    @rule = rule
    @startTime = if @rule.match(startTime, startTime) then startTime else @rule.next(startTime, startTime)

  nextOccurrence: (after) =>
    @nextOccurrences(1, after)[0]

  nextOccurrences: (n, after) =>
    return [] if @rule.stop()? && after > @rule.stop()
    time = (if after <= @startTime then @startTime else after)
    time = @rule.next(time, @startTime) unless @rule.match(time, @startTime)

    @_listOccurrences(time, -> (n -= 1) >= 0)

  previousOccurrence: (before) =>
    @previousOccurrences(1, before)[0]

  previousOccurrences: (n, before) =>
    return [] if before <= @startTime
    time = (if !@rule.stop()? || before < @rule.stop() then before else @rule.stop())
    time = @rule.previous(time, @startTime) # go back even if before matches the rule (half-open time intervals, remember?)

    @_listOccurrences(time, 'back', -> (n -= 1) >= 0 ).reverse()

  occurrencesBetween: (t1, t2) =>
    throw "Empty time interval" unless t2 > t1
    return [] if t2 <= @startTime || @rule.stop()? && t1 >= @rule.stop()

    time = (if t1 <= @startTime then @startTime else t1)
    time = @rule.next(time, @startTime) unless @rule.match(time, @startTime)

    @_listOccurrences(time, (t) -> t < t2)

  suboccurrencesBetween: (t1, t2) =>
    occurrences = @occurrencesBetween(new Date(t1 - @duration), t2)
    Schedule.Suboccurrence.find(occurrence: [occ, new Date(+occ + @duration)], interval: [t1, t2]) for occ in occurrences

  all: =>
    if @rule.stop()?
      rule = @rule
      @_listOccurrences(@startTime, (t) -> t < rule.stop())
    else
      n = @rule.count()
      @_listOccurrences(@startTime, -> (n -= 1) >= 0)

  toObject: =>
    @rule.toObject()

  # yields valid occurrences, return false from the block to stop
  _listOccurrences: (from, direction_or_func, func) =>
    throw "From #{from} not matching the rule #{@rule} and start time #{@startTime}" unless @rule.match(from, @startTime)

    if func?
      direction = direction_or_func
    else
      direction = 'forward'
      func = direction_or_func

    results = []

    [n, current] = @_initLoop(from, direction)
    MAX_ITERATIONS = 10000

    loop
      throw "Maximum iterations reached when listing occurrences..." unless MAX_ITERATIONS-- > 0

      # break on schedule span limits
      return results unless (current >= @startTime) && (!@rule.stop()? || current < @rule.stop()) && (!@rule.count()? || (n -= 1) >= 0)

      # break on block condition
      return results unless func(current)

      results.push(current)

      # step
      if direction == 'forward'
        current = @rule.next(current, @startTime)
      else
        current = @rule.previous(current, @startTime)

  _initLoop: (from, direction) =>
    return [0, from] unless @rule.count()? # without count limit, life is easy

    # with it, it's... well...
    if direction == 'forward'
      n = 0
      current = @startTime
      while current < from
        n += 1
        current = @rule.next(current, @startTime)

      # return the n remaining events
      return [(@rule.count() - n), current]
    else
      n = 0
      current = @startTime
      while current < from && (n += 1) < @rule.count()
        current = @rule.next(current, @startTime)

      # return all events (downloop - yaay, I invented a word - will stop on start time)
      return [@rule.count(), current]
