Package.describe({
  name: 'peerlibrary:base-component',
  summary: "Base component for reusable Meteor components",
  version: '0.16.0',
  git: 'https://github.com/peerlibrary/meteor-base-component.git',
  documentation: null
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.0.3.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'reactive-var',
    'tracker',
    'underscore'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:assert@0.2.5',
    'peerlibrary:reactive-field@0.1.0',
    'peerlibrary:computed-field@0.3.1'
  ]);

  api.export('BaseComponent');
  // TODO: Move to a separate package. Possibly one with debugOnly set to true.
  api.export('BaseComponentDebug');

  api.addFiles([
    'lib.coffee',
    'debug.coffee'
  ]);
});

Package.onTest(function (api) {
  // Core dependencies.
  api.use([
    'coffeescript',
    'templating',
    'jquery',
    'reactive-var',
    'tracker'
  ]);

  // Internal dependencies.
  api.use([
    'peerlibrary:base-component'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.2.19'
  ]);

  api.addFiles([
    'tests.coffee'
   ], 'client');
});
