class BaseComponentDebug
  @startComponent: (component) ->
    name = component.componentName() or 'unnamed'
    console.group name
    console.log '%o', component

  @endComponent: (component) ->
    console.groupEnd()

  @startMarkedComponent: (component) ->
    name = component.componentName() or 'unnamed'
    console.group '%c%s', 'text-decoration: underline', name
    console.log '%o', component

  @endMarkedComponent: (component) ->
    @endComponent component

  @dumpComponentSubtree: (rootComponent, _markComponent=(->)) ->
    return unless rootComponent

    marked = _markComponent rootComponent

    if marked
      @startMarkedComponent rootComponent
    else
      @startComponent rootComponent

    for child in rootComponent.componentChildren()
      @dumpComponentSubtree child, _markComponent

    if marked
      @endMarkedComponent rootComponent
    else
      @endComponent rootComponent

    return

  @componentRoot: (component) ->
    while componentParent = component.componentParent()
      component = componentParent

    component

  @dumpComponentTree: (component) ->
    return unless component

    @dumpComponentSubtree @componentRoot(component), (c) -> c is component
