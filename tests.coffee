class DummyComponent extends BaseComponent
  constructor: (field) ->
    super()
    @field = field

  fieldValue: ->
    @field

  @renderComponent: ->
    new @().renderComponent()

  renderComponent: ->
    "Hello world."

BaseComponent.register 'DummyComponent', DummyComponent

class SelfRegisterComponent extends DummyComponent
  # Alternative way of registering components.
  @register 'SelfRegisterComponent'

class UnregisteredComponent extends DummyComponent

# Name has to be set manually.
UnregisteredComponent.componentName 'UnregisteredComponent'

class SelfNameUnregisteredComponent extends DummyComponent
  # Alternative way of setting the name manually.
  @componentName 'SelfNameUnregisteredComponent'

class MyNamespace

class MyNamespace.MyComponent extends DummyComponent
  # Alternative way of registering components.
  @register 'MyNamespace.MyComponent'

class MyNamespaceComponent extends DummyComponent
  # Probably you could simply have MyNamespace class as a component, but
  # we want to test if these can be disjoint. Registry should not modify
  # components and use them as a namespace.
  @register 'MyNamespace'

class BasicTestCase extends ClassyTestCase
  @testName: 'base-component - basic'

  testBase: =>
    result = BaseComponent.getComponent('DummyComponent').renderComponent()

    @assertEqual result, "Hello world."

    result = new (BaseComponent.getComponent('DummyComponent'))().renderComponent()

    @assertEqual result, "Hello world."

  testGetComponent: =>
    @assertEqual BaseComponent.getComponent('DummyComponent'), DummyComponent
    @assertEqual BaseComponent.getComponent('unknown'), null

  testComponentName: =>
    @assertEqual DummyComponent.componentName(), 'DummyComponent'
    @assertEqual BaseComponent.componentName(), null

  testSelfRegister: =>
    @assertTrue BaseComponent.getComponent 'SelfRegisterComponent'

  testUnregisteredComponent: =>
    result = UnregisteredComponent.renderComponent()

    @assertEqual result, "Hello world."

    result = new UnregisteredComponent().renderComponent()

    @assertEqual result, "Hello world."

    result = SelfNameUnregisteredComponent.renderComponent()

    @assertEqual result, "Hello world."

    result = new SelfNameUnregisteredComponent().renderComponent()

    @assertEqual result, "Hello world."

  testNamespace: =>
    # To test if a component with the same name as a namespace is reachable.

    result = BaseComponent.getComponent('MyNamespace').renderComponent()

    @assertEqual result, "Hello world."

    result = new (BaseComponent.getComponent('MyNamespace'))().renderComponent()

    @assertEqual result, "Hello world."

    # And a namespaced component.

    result = BaseComponent.getComponent('MyNamespace.MyComponent').renderComponent()

    @assertEqual result, "Hello world."

    result = new (BaseComponent.getComponent('MyNamespace.MyComponent'))().renderComponent()

    @assertEqual result, "Hello world."

    # And a namespaced component with explicit namespace.

    result = BaseComponent.getComponent(BaseComponent.components.MyNamespace, 'MyComponent').renderComponent()

    @assertEqual result, "Hello world."

    result = new (BaseComponent.getComponent(BaseComponent.components.MyNamespace, 'MyComponent'))().renderComponent()

    @assertEqual result, "Hello world."

  testErrors: =>
    @assertThrows =>
      BaseComponent.register()
    ,
      /Component name is required for registration/

    @assertThrows =>
      BaseComponent.register 'DummyComponent', null
    ,
      /Component 'DummyComponent' already registered/

    @assertThrows =>
      BaseComponent.register 'OtherDummyComponent', DummyComponent
    ,
      /Component 'OtherDummyComponent' already registered under the name 'DummyComponent'/

    @assertThrows =>
      BaseComponent.getComponent {}
    ,
      /Component name '\[object Object\]' is not a string/

  testChildren: =>
    component = new DummyComponent 'foobar'
    parentComponent = new UnregisteredComponent()

    results = []
    handle = Tracker.autorun =>
      results.push parentComponent.childComponents()

    resultsWith = []
    handleWith = Tracker.autorun =>
      resultsWith.push parentComponent.childComponentsWith(field: 'foobar')

    component.parentComponent parentComponent
    parentComponent.addChildComponent component

    @assertEqual component.parentComponent(), parentComponent
    @assertEqual parentComponent.childComponents(), [component]
    @assertEqual parentComponent.childComponents(component), [component]
    @assertEqual parentComponent.childComponents(parentComponent), []
    @assertEqual parentComponent.childComponents(DummyComponent), [component]
    @assertEqual parentComponent.childComponents(UnregisteredComponent), []
    @assertEqual parentComponent.childComponents('DummyComponent'), [component]
    @assertEqual parentComponent.childComponents('UnregisteredComponent'), []
    @assertEqual parentComponent.childComponentsWith('field'), [component]
    @assertEqual parentComponent.childComponentsWith('fieldValue'), [component]
    @assertEqual parentComponent.childComponentsWith('nonexisting'), []
    @assertEqual parentComponent.childComponentsWith(field: 'foobar'), [component]
    @assertEqual parentComponent.childComponentsWith(field: 'faabar'), []
    @assertEqual parentComponent.childComponentsWith(fieldValue: 'foobar'), [component]
    @assertEqual parentComponent.childComponentsWith(fieldValue: 'faabar'), []

    self = @

    @assertEqual parentComponent.childComponentsWith(
      (child) ->
        self.assertEqual @, parentComponent
        self.assertEqual child, component
        true
    ), [component]
    @assertEqual parentComponent.childComponentsWith((child) -> false), []

    Tracker.flush()

    component.parentComponent null
    parentComponent.removeChildComponent component

    @assertEqual component.parentComponent(), null
    @assertEqual parentComponent.childComponents(), []
    @assertEqual parentComponent.childComponents(component), []
    @assertEqual parentComponent.childComponents(DummyComponent), []
    @assertEqual parentComponent.childComponents(UnregisteredComponent), []
    @assertEqual parentComponent.childComponents('DummyComponent'), []
    @assertEqual parentComponent.childComponents('UnregisteredComponent'), []
    @assertEqual parentComponent.childComponentsWith('field'), []
    @assertEqual parentComponent.childComponentsWith('fieldValue'), []
    @assertEqual parentComponent.childComponentsWith('nonexisting'), []
    @assertEqual parentComponent.childComponentsWith(field: 'foobar'), []
    @assertEqual parentComponent.childComponentsWith(field: 'faabar'), []
    @assertEqual parentComponent.childComponentsWith(fieldValue: 'foobar'), []
    @assertEqual parentComponent.childComponentsWith(fieldValue: 'faabar'), []

    Tracker.flush()

    componentZoobar = new DummyComponent 'zoobar'

    componentZoobar.parentComponent parentComponent
    parentComponent.addChildComponent componentZoobar

    Tracker.flush()

    handle.stop()
    handleWith.stop()

    @assertEqual results, [
      []
      [component]
      []
      [componentZoobar]
    ]

    @assertEqual resultsWith, [
      []
      [component]
      []
      # One less entry than in "results" because "foobar" does not match "zoobar", and the
      # result is the same, an empty array, so reactive computation is not invalidated.
    ]

ClassyTestCase.addTest new BasicTestCase()
