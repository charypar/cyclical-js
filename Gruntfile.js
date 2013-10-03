module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    coffee: {
      compile: {
        files: {
          'build/<%= pkg.name %>.js': [
            'lib/date_from_json.js.coffee',
            'lib/schedule.js.coffee',
            'lib/schedule/rule.js.coffee',
            'lib/schedule/rules/*.js.coffee',
            'lib/schedule/filters/*.js.coffee',
            'lib/schedule/suboccurrence.js.coffee',
            'lib/schedule/occurrence.js.coffee'
          ],
          'build/specs.js': 'test/schedule_spec.js.coffee'
        }
      }
    },

    copy: {
      compile: {
        files: [
          {
            src: 'build/<%= pkg.name %>.js',
            dest: '<%= pkg.name %>.js'
          }
        ]
      },
      dist: {
        files: [
          {
            src: 'build/<%= pkg.name %>.js',
            dest: 'dist/<%= pkg.name %>.<%= pkg.version %>.js'
          }
        ]
      }
    },

    uglify: {
      dist: {
        files: {
          'dist/<%= pkg.name %>.<%= pkg.version %>.min.js': ['dist/<%= pkg.name %>.<%= pkg.version %>.js']
        }
      }
    },

    jasmine: {
      src: [
        'node_modules/datejs/lib/date.js',
        'node_modules/moment/moment.js',
        'build/<%= pkg.name %>.js',
      ],
      options: {
        specs: 'build/specs.js'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-jasmine');

  grunt.registerTask('default', ['coffee', 'copy:compile']);
  grunt.registerTask('test', ['default', 'jasmine']);
  grunt.registerTask('dist', ['default', 'copy', 'uglify']);
};
