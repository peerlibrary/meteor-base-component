Package.describe({
  name: 'peerlibrary:base-component',
  summary: "Base component for reusable Meteor components",
  version: '0.17.0',
  git: 'https://github.com/peerlibrary/meteor-base-component.git',
  documentation: null
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.8.1');

  // Core dependencies.
  api.use([
    'coffeescript@2.4.1',
    'reactive-var',
    'tracker',
    'underscore'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:assert@0.3.0',
    'peerlibrary:reactive-field@0.6.0',
    'peerlibrary:computed-field@0.10.0'
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
    'coffeescript@2.4.1',
    'templating@1.3.2',
    'jquery@1.11.11',
    'reactive-var',
    'tracker'
  ]);

  // Internal dependencies.
  api.use([
    'peerlibrary:base-component'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.4.0'
  ]);

  api.addFiles([
    'tests.coffee'
   ], 'client');
});
