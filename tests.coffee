class DummyComponent extends BaseComponent
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

ClassyTestCase.addTest new BasicTestCase()
