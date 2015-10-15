CE = React.createElement

MainComponent = React.createClass(
  postMessage: (message, mode)->
    [url, data] = @detectPostParameter(message, mode)
    $.ajax(
      url: url
      type: 'post'
      data: data
    ).then((data) =>
      if mode?.mode == 'edit'
        @reject(mode.id)
      @loadMessages(@state.messages[0]?.id)
      @setState(mode: null, message: '')
    ).fail((data) ->
      console.log(data)
      @loadMessages(@state.messages[0]?.id)
    )
  loadMessages: (from)->
    data = if from?
      { from: from }
    else
      {}
    $.ajax(
      url: '/messages/index',
      type: 'get',
      dataType: 'json'
      data: data
    ).done((data) =>
      @setState(messages: data.reverse().concat(@state.messages))
    ).fail((data) ->
      console.log(data)
    )
  deleteMessage: (message)->
    id = message.id
    $.ajax(
      url: "/messages/#{id}",
      type: 'post',
      dataType: 'json'
      data:
        _method: 'delete'
    ).done((data) =>
      @reject(data.id)
    ).fail((data) ->
      console.log(data)
    )
  editMessage: (message)->
    @setState(mode: { mode: 'edit', id: message.id }, message: message.message)
  replyMessage: (message)->
    @setState(mode: { mode: 'reply', id: message.id })
  reject: (id)->
    @setState(messages: _.reject(@state.messages, (obj)->
      obj.id == id
    ))
  detectPostParameter: (message, mode = {})->
    switch mode.mode
      when 'edit'
        ["/messages/#{mode.id}", { message: message, _method: 'put' }]
      when 'reply'
        ['/messages/new', { message: message, reply: id }]
      else
        ['/messages/new', { message: message }]
  componentDidMount: ()->
    @loadMessages()
  app: ()->
    deleteMessage: @deleteMessage
    editMessage: @editMessage
    loadMessages: @loadMessages
    postMessage: @postMessage
    replyMessage: @replyMessage
  getInitialState: ()->
    messages: []
    message: ''
  render: () ->
    CE('div', { className: "short-message-store" },
      CE(MessageFormComponent, { app: @app(), mode: @state.mode, message: @state.message }),
      CE(MessageListComponent, { app: @app(), messages: @state.messages }),
    )
)

MessageListComponent = React.createClass(
  render: () ->
    messages = _.map(@props.messages, (el, i)=>
      CE(MessageComponent,
        { app: @props.app, message: el }
      )
    )
    CE('ul', { className: "message-list list" }, messages)
)

MessageComponent = React.createClass(
  edit: (e)->
    e.preventDefault()
    @props.app.editMessage(@props.message)
  delete: (e)->
    e.preventDefault()
    @props.app.deleteMessage(@props.message)
  reply: (e)->
    e.preventDefault()
    @props.app.replyMessage(@props.message)
  render: () ->
    CE('li', { className: "message-list message" },
      CE('div', {
        className: "message-list body",
        dangerouslySetInnerHTML: { __html: marked(@props.message.message) }
      }),
      CE('a', { className: "text-primary message-list edit", href: "#", onClick: @edit },
        CE(Fa, { icon: 'pencil' }),
        CE('time', { className: "message-list time" }, @props.message.written_at)
      )
      CE('a', { className: "text-danger message-list delete", href: "#", onClick: @delete }, CE(Fa, { icon: 'trash-o' }))
    )
)

MessageFormComponent = React.createClass(
  onClick: (e)->
    e.preventDefault()
    @props.app.postMessage(@state.message, @props.mode)
  modeText: ()->
    if @props.mode
      "#{@props.mode.mode}:#{@props.mode.id}"
    else
      'new message'
  statize: (e)->
    @setState(message: e.target.value)
  componentWillReceiveProps: (props)->
    @setState(message: props.message)
  getInitialState: ()->
    message: ''
  render: () ->
    CE('form', { className: "message-box form" },
      CE('div', { className: "control-group" },
        CE('input', { className: "form-control message-box", ref: 'mode', disabled: true, value: @modeText() })
      ),
      CE('div', { className: "control-group" },
        CE('textarea', {
          className: "form-control message-box textarea",
          ref: 'messageArea',
          value: @state.message,
          onChange: @statize
        })
      ),
      CE('div', { className: "message-box submit-area" },
        CE('button', { className: "btn btn-primary btn-lg message-box submit", onClick: @onClick },
          "Yap!"
        )
      )
    )
)

Fa = React.createClass(
  render: ()->
    classes = ['fa']
    classes.push("fa-#{@props.icon}")
    classes.push("fa-#{@props.scale}x") if @props.scale?
    classes.push('fa-fw') if !@props.fixedWidth? || @props.fixedWidth == false
    classes.push('fa-li') if @props.list
    classes.push('fa-border') if @props.border
    classes.push("fa-pull-#{@props.pull}") if @props.pull?
    classes.push("fa-#{@props.animation}") if @props.animation?
    classes.push("fa-rotate-#{@props.rotate}") if @props.rotate?
    classes.push("fa-flip-#{@props.animation}") if @props.flip?

    CE('i', { className: classes.join(' ') })
)

ReactDOM.render(
  CE(MainComponent, null),
  document.getElementById('react')
)