class BaseComponent
  @components: {}

  @register: (componentName, componentClass) ->
    throw new Error "Component name is required for registration." unless componentName

    # To allow calling @register 'name' from inside a class body.
    componentClass ?= @

    throw new Error "Component '#{ componentName }' already registered." if componentName of @components

    # The last condition is to make sure we do not throw the exception when registering a subclass.
    # Subclassed components have at this stage the same component as the parent component, so we have
    # to check if they are the same class. If not, this is not an error, it is a subclass.
    if componentClass.componentName() and componentClass.componentName() isnt componentName and @components[componentClass.componentName()] is componentClass
      throw new Error "Component '#{ componentName }' already registered under the name '#{ componentClass.componentName() }'."

    componentClass.componentName componentName
    assert componentClass.componentName() is componentName

    @components[componentName] = componentClass

    # To allow chaining.
    @

  @getComponent: (componentName) ->
    @components[componentName] or null

  # Component name is set in the register class method. If not using a registered component and a component name is
  # wanted, component name has to be set manually or this class method should be overridden with a custom implementation.
  # Care should be taken that unregistered components have their own name and not the name of their parent class, which
  # they would have by default. Probably component name should be set in the constructor for such classes, or by calling
  # componentName class method manually on the new class of this new component.
  @componentName: (componentName) ->
    # Setter.
    if componentName
      @_componentName = componentName
      # To allow chaining.
      return @

    # Getter.
    @_componentName or null

  # We allow access to the component name through a method so that it can be accessed in templates in an easy way.
  componentName: ->
    @constructor.componentName()

  @renderComponent: ->
    throw new Error "Not implemented."

  renderComponent: ->
    throw new Error "Not implemented."
