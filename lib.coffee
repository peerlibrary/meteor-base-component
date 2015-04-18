# Comparing arrays of components by reference. This might not be really necessary
# to do, because all operations we officially support modify length of the array
# (add a new component or remove an old one). But if somebody is modifying the
# reactive variable directly we want a sane behavior. The default ReactiveVar
# equality always returns false when comparing any non-primitive values. Because
# the order of components in the children array is arbitrary we could further
# improve this comparison to compare arrays as sets, ignoring the order. Or we
# could have some canonical order of components in the array.
arrayReferenceEquals = (a, b) ->
  return false if a.length isnt b.length

  for i in [0...a.length]
    return false if a[i] isnt b[i]

  true

# Similar idea to https://github.com/awwx/meteor-isolate-value. We want to make
# sure that internal reactive dependency inside function fn really changes the result
# of function fn before we trigger an outside reactive computation invalidation. The
# downside is that function fn is called twice if the result changes (once to
# check if the outside reactive computation should be invalidated and the second time
# when the outside reactive computation is rerun afterwards). Function fn should not
# have any side effects.
isolateValue = (fn) ->
  # If not called in a reactive computation, do nothing special.
  return fn() unless Tracker.active

  lastValue = null
  dependency = new Tracker.Dependency()

  # This autorun is nested in the outside autorun so it gets stopped
  # automatically when the outside autorun gets invalidated.
  Tracker.autorun (computation) ->
    value = fn()

    if computation.firstRun
      lastValue = value
    else
      # We use arrayReferenceEquals here for our use case, because
      # we are using it with a component children array.
      dependency.changed() unless arrayReferenceEquals value, lastValue

  dependency.depend()

  lastValue

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
    @_componentInternals ?= {}

    # Setter.
    if componentName
      @_componentInternals.componentName = componentName
      # To allow chaining.
      return @

    # Getter.
    @_componentInternals.componentName or null

  # We allow access to the component name through a method so that it can be accessed in templates in an easy way.
  componentName: ->
    # Instance method is just a getter, not a setter as well.
    @constructor.componentName()

  # The order of components is arbitrary and does not necessary match siblings relations in DOM.
  # nameOrComponent is optional and it limits the returned children only to those.
  componentChildren: (nameOrComponent) ->
    @_componentInternals ?= {}
    @_componentInternals.componentChildren ?= new ReactiveVar [], arrayReferenceEquals

    # Quick path. Returns a shallow copy.
    return (child for child in @_componentInternals.componentChildren.get()) unless nameOrComponent

    if _.isString nameOrComponent
      @componentChildrenWith (child, parent) =>
        child.componentName() is nameOrComponent
    else
      @componentChildrenWith (child, parent) =>
        # nameOrComponent is a class.
        return true if child.constructor is nameOrComponent

        # nameOrComponent is an instance, or something else.
        return true if child is nameOrComponent

        false

  # The order of components is arbitrary and does not necessary match siblings relations in DOM.
  # Returns children which pass a predicate function.
  componentChildrenWith: (propertyOrMatcherOrFunction) ->
    if _.isString propertyOrMatcherOrFunction
      property = propertyOrMatcherOrFunction
      propertyOrMatcherOrFunction = (child, parent) =>
        property of child

    else if not _.isFunction propertyOrMatcherOrFunction
      assert _.isObject propertyOrMatcherOrFunction
      matcher = propertyOrMatcherOrFunction
      propertyOrMatcherOrFunction = (child, parent) =>
        for property, value of matcher
          return false unless property of child

          if _.isFunction child[property]
            return false unless child[property]() is value
          else
            return false unless child[property] is value

        true

    isolateValue =>
      child for child in @componentChildren() when propertyOrMatcherOrFunction.call @, child, @

  addComponentChild: (componentChild) ->
    @_componentInternals ?= {}
    @_componentInternals.componentChildren ?= new ReactiveVar [], arrayReferenceEquals
    @_componentInternals.componentChildren.set Tracker.nonreactive =>
      @_componentInternals.componentChildren.get().concat [componentChild]

    # To allow chaining.
    @

  removeComponentChild: (componentChild) ->
    @_componentInternals ?= {}
    @_componentInternals.componentChildren ?= new ReactiveVar [], arrayReferenceEquals
    @_componentInternals.componentChildren.set Tracker.nonreactive =>
      _.without @_componentInternals.componentChildren.get(), componentChild

    # To allow chaining.
    @

  componentParent: (componentParent) ->
    @_componentInternals ?= {}
    # We use reference equality here. This makes reactivity not invalidate the
    # computation if the same component instance (by reference) is set as a parent.
    @_componentInternals.componentParent ?= new ReactiveVar null, (a, b) -> a is b

    # Setter.
    unless _.isUndefined componentParent
      @_componentInternals.componentParent.set componentParent
      # To allow chaining.
      return @

    # Getter.
    @_componentInternals.componentParent.get()

  @renderComponent: (componentParent) ->
    throw new Error "Not implemented"

  renderComponent: (componentParent) ->
    throw new Error "Not implemented"

  @extendComponent: (constructor, methods) ->
    currentClass = @

    unless _.isFunction constructor
      methods = constructor
      constructor = ->
        constructor.__super__.constructor.apply @, arguments

    constructor:: = Object.create currentClass::
    constructor::constructor = constructor

    # We use "own" here because this is how CoffeeScript extends the class.
    for own property, value of currentClass
      constructor[property] = value
    constructor.__super__ = currentClass::

    # We expect the plain object of methods here, but if something
    # else is passed, we use only "own" properties.
    for own property, value of methods or {}
      constructor::[property] = value

    constructor
