# Comparing arrays of components by reference. This might not be really necessary
# to do, because all operations we officially support modify length of the array
# (add a new component or remove an old one). But if somebody is modifying the
# reactive variable directly we want a sane behavior. The default ReactiveVar
# equality always returns false when comparing any non-primitive values.
arrayReferenceEquals = (a, b) ->
  return false if a.length isnt b.length

  for i in [0...a.length]
    return false if a[i] isnt b[i]

  true

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
    assert.equal componentClass.componentName(), componentName

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
    # Instance method is just a getter, not a setter as well.
    @constructor.componentName()

  componentChildren: ->
    @_componentChildren ?= new ReactiveVar [], arrayReferenceEquals
    @_componentChildren.get()

  addComponentChild: (componentChild) ->
    @_componentChildren ?= new ReactiveVar [], arrayReferenceEquals
    @_componentChildren.set Tracker.nonreactive =>
      @_componentChildren.get().concat [componentChild]

    # To allow chaining.
    @

  removeComponentChild: (componentChild) ->
    @_componentChildren ?= new ReactiveVar [], arrayReferenceEquals
    @_componentChildren.set Tracker.nonreactive =>
      _.without @_componentChildren.get(), componentChild

    # To allow chaining.
    @

  componentParent: (componentParent) ->
    # We use reference equality here. This makes reactivity not invalidate the
    # computation if the same component instance (by reference) is set as a parent.
    @_componentParent ?= new ReactiveVar null, (a, b) -> a is b

    # Setter.
    unless _.isUndefined componentParent
      @_componentParent.set componentParent
      # To allow chaining.
      return @

    # Getter.
    @_componentParent.get()

  @renderComponent: (componentParent) ->
    throw new Error "Not implemented"

  renderComponent: (componentParent) ->
    throw new Error "Not implemented"
