module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    coffee: {
      compile: {
        files: {
          'build/cyclical.js': [
            'lib/date_from_json.js.coffee',
            'lib/schedule.js.coffee',
            'lib/schedule/rule.js.coffee',
            'lib/schedule/rules/*.js.coffee',
            'lib/schedule/filters/*.js.coffee',
            'lib/schedule/suboccurrence.js.coffee',
            'lib/schedule/occurrence.js.coffee'
          ],
          'build/cyclical_specs.js': 'test/schedule_spec.js.coffee'
        }
      }
    },

    jasmine: {
      src: [
        'node_modules/datejs/lib/date.js',
        'node_modules/moment/moment.js',
        'node_modules/underscore/underscore-min.js',
        'build/cyclical.js',
      ],
      options: {
        specs: 'build/cyclical_specs.js'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-jasmine');

  grunt.registerTask('default', ['coffee']);
  grunt.registerTask('test', ['default', 'jasmine']);
};
