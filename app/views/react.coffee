CE = React.createElement

MainComponent = React.createClass(
  postMessage: (message)->
    $.ajax(
      url: '/messages/new',
      type: 'post',
      data:
        message: message
    ).then((data) =>
      @loadMessages(@state.messages[0]?.id)
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
  deleteMessage: (id)->
    $.ajax(
      url: "/messages/#{id}",
      type: 'post',
      dataType: 'json'
      data:
        _method: 'delete'
    ).done((data) =>
      console.log 'deleted'
      @setState(messages: _.reject(@state.messages, (obj)->
        obj.id == data.id
      ))
    ).fail((data) ->
      console.log(data)
    )
  editMessage: (id)->
  replyMessage: (id)->
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
  render: () ->
    CE('div', { className: "commentBox" },
      CE(MessageFormComponent, { app: @app() }),
      CE(MessageListComponent, { app: @app(), messages: @state.messages }),
    )
)

MessageListComponent = React.createClass(
  render: () ->
    messages = _.map(@props.messages, (el, i)=>
      CE(MessageComponent,
        { app: @props.app, id: el.id, message: el.message, written_at: el.written_at }
      )
    )
    CE('ul', { className: "commentBox" }, messages)
)

MessageComponent = React.createClass(
  edit: (e)->
    e.preventDefault()
    @props.app.editMessage(@props.id)
  delete: (e)->
    e.preventDefault()
    @props.app.deleteMessage(@props.id)
  reply: (e)->
    e.preventDefault()
    @props.app.replyMessage(@props.id)
  render: () ->
    CE('li', { className: "commentBox" },
      CE('div', { className: "messages body" }, @props.message),
      CE('time', { className: "messages time" }, @props.written_at)
      CE('a', { className: "text-primary messages edit", href: "#", onClick: @edit }, CE(Fa, { icon: 'pencil' }))
      CE('a', { className: "text-danger messages delete", href: "#", onClick: @delete }, CE(Fa, { icon: 'trash-o' }))
    )
)

MessageFormComponent = React.createClass(
  onClick: (e)->
    e.preventDefault()
    @props.app.postMessage(@textarea().value).then ()=>
      @textarea().value = ''
  textarea: ()->
    ReactDOM.findDOMNode(@refs.messageArea)
  render: () ->
    console.log(@props)
    CE('form', { className: "commentBox" },
      CE('div', { className: "control-group" },
        CE('textarea', { className: "form-control message-box textarea", ref: 'messageArea' })
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