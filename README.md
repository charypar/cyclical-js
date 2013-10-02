# Cyclical.js

Recurring events library for JavaScript calendar applications.

## About

Cyclical lets you list recurring events with complex recurrence rules like "every 4 years, the first Tuesday after a Monday in November" in a simple way. The API is inspired by [ice_cube](https://github.com/seejohnrun/ice_cube) and uses method chaining for natural rule specification.

You can find out if a given time matches the schedule, list event occurrences or add event duration and list suboccurrences in a given interval, which is handy when you need to trim event occurences to the interval (like rendering a day in a week view of a calendar with events crossing midnight).

Cyclical was originally extracted from a browser based calendar application and is written in [Coffeescript](http://coffeescript.org/). The plan is to translate it to plain JavaScript in the future.

### Missing features and TODO

*  Rule exception dates
*  Hourly and secondly rules
*  Switch from datejs to [moment.js](http://momentjs.com/)
*  Remove the underscore.js dependency
*  Translate to plain JavaScript

## Install

You can install Cyclical using npm

```
npm install cyclical
```

or download ```dist/cyclical.x.js``` or ```dist/cyclical.x.min.js``` file.

### Dependencies

Cyclical currently depends on [date.js](http://www.datejs.com/) and [underscore.js](http://underscorejs.org/). See ```package.json``` for specific versions.

## Usage

The central thing in Cyclical is the ```Schedule```. Let's take the example of U.S. Presidential Election day from RFC 5545:

```javascript
  date = new Date(1997, 8, 2, 9, 0, 0);
  schedule = new Schedule(date, Schedule.Rule.yearly(4).month(11).weekday('tue').monthdays(2, 3, 4, 5, 6, 7, 8));

  election_dates = schedule.first(3);
```

### Creating schedules

Each schedule has a base ```date``` and a recurrence rule. The four supported rules are:

*  daily
*  weekly
*  monthly
*  yearly

with corresponding factory methods on ```Schedule.Rule```. The factory methods take a single argument - the repetition interval.

The basic recurrence rule matches the original date, i.e. for a yearly rule, the occurences will always happen on the same date. To specify a more complex pattern, you can use filters.

Filters replace the single value (day, month) with a set of values that match. For example, instead of only matching the day of month in of the base date, with the ```monthdays``` filter, you can match multiple month days.

Available filters are:

*  weekday(s)
*  monthday(s)
*  yearday(s)
*  month(s)

Each filter methord takes variable arguments containing integers or string (incl. shortcuts) for a given date component.

You can limit the schedule either by a number of events (using the ```count``` method) or an end date (using the ```stop``` method).

### Querying occurrences and suboccurrences

TODO. See ```lib/schedule.js.coffee```

### Serialization

TODO. See ```lib/schedule.js.coffee```

### More examples

TODO

## License

Cyclical is released under the [MIT License](http://www.opensource.org/licenses/MIT).
