class DummyComponent extends BaseComponent
  constructor: (field) ->
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

  testChildren: =>
    component = new DummyComponent 'foobar'
    parentComponent = new UnregisteredComponent()

    results = []
    handle = Tracker.autorun =>
      results.push parentComponent.componentChildren()

    resultsWith = []
    handleWith = Tracker.autorun =>
      resultsWith.push parentComponent.componentChildrenWith(field: 'foobar')

    component.componentParent parentComponent
    parentComponent.addComponentChild component

    @assertEqual component.componentParent(), parentComponent
    @assertEqual parentComponent.componentChildren(), [component]
    @assertEqual parentComponent.componentChildren(component), [component]
    @assertEqual parentComponent.componentChildren(parentComponent), []
    @assertEqual parentComponent.componentChildren(DummyComponent), [component]
    @assertEqual parentComponent.componentChildren(UnregisteredComponent), []
    @assertEqual parentComponent.componentChildren('DummyComponent'), [component]
    @assertEqual parentComponent.componentChildren('UnregisteredComponent'), []
    @assertEqual parentComponent.componentChildrenWith('field'), [component]
    @assertEqual parentComponent.componentChildrenWith('fieldValue'), [component]
    @assertEqual parentComponent.componentChildrenWith('nonexisting'), []
    @assertEqual parentComponent.componentChildrenWith(field: 'foobar'), [component]
    @assertEqual parentComponent.componentChildrenWith(field: 'faabar'), []
    @assertEqual parentComponent.componentChildrenWith(fieldValue: 'foobar'), [component]
    @assertEqual parentComponent.componentChildrenWith(fieldValue: 'faabar'), []

    self = @

    @assertEqual parentComponent.componentChildrenWith(
      (child) ->
        self.assertEqual @, parentComponent
        self.assertEqual child, component
        true
    ), [component]
    @assertEqual parentComponent.componentChildrenWith((child) -> false), []

    Tracker.flush()

    component.componentParent null
    parentComponent.removeComponentChild component

    @assertEqual component.componentParent(), null
    @assertEqual parentComponent.componentChildren(), []
    @assertEqual parentComponent.componentChildren(component), []
    @assertEqual parentComponent.componentChildren(DummyComponent), []
    @assertEqual parentComponent.componentChildren(UnregisteredComponent), []
    @assertEqual parentComponent.componentChildren('DummyComponent'), []
    @assertEqual parentComponent.componentChildren('UnregisteredComponent'), []
    @assertEqual parentComponent.componentChildrenWith('field'), []
    @assertEqual parentComponent.componentChildrenWith('fieldValue'), []
    @assertEqual parentComponent.componentChildrenWith('nonexisting'), []
    @assertEqual parentComponent.componentChildrenWith(field: 'foobar'), []
    @assertEqual parentComponent.componentChildrenWith(field: 'faabar'), []
    @assertEqual parentComponent.componentChildrenWith(fieldValue: 'foobar'), []
    @assertEqual parentComponent.componentChildrenWith(fieldValue: 'faabar'), []

    Tracker.flush()

    componentZoobar = new DummyComponent 'zoobar'

    componentZoobar.componentParent parentComponent
    parentComponent.addComponentChild componentZoobar

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
