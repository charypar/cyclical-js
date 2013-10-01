# this is here to correctly parse dates provided by the server in ISO 8601 date format, which apparently the date.js library is too 
# smart to do right... sigh.
#
# Based on Colin Snover's implementation which can be found at https://github.com/csnover/js-iso8601

Date.parseISO8601 = (string) ->
  regex = /^(\d{4}|[+\-]\d{6})(?:-(\d{2})(?:-(\d{2}))?)?(?:T(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{3}))?)?(?:(Z)|([+\-])(\d{2})(?::(\d{2}))?)?)?$/
  return null unless parts = regex.exec(string)
  
  for i in [1,4,5,6,7,10,11]
    parts[i] = +parts[i] || 0 # convert to numbers and put zeros for undefined
    
  parts[2] = (+parts[2] || 1) - 1; # empty month
  parts[3] = (+parts[3] || 1); # empty day
  
  # handle timzeone ofset
  if parts[8] isnt 'Z' and parts[9]?
    minutes = parts[10]*60 + parts[11]
    minutes = -minutes if parts[9] is '+'
    parts[5] += minutes
  
  # create date
  new Date(Date.UTC(parts[1..7]...))
  
  