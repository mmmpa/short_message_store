CE = React.createElement

MainComponent = React.createClass(
  postMessage: (message)->
    $.ajax(
      url: '/messages/new',
      type: 'post',
      data:
        message: message
    ).then((data) =>
      @loadMessages()
    ).fail((data) ->
      console.log(data)
    )
  loadMessages: ()->
    $.ajax(
      url: '/messages/index',
      type: 'get',
      dataType: 'json'
      data: {}
    ).done((data) =>
      @setState(messages: data.reverse())
    ).fail((data) ->
      console.log(data)
    )
  componentDidMount: ()->
    @loadMessages()
  app: ()->
    loadMessages: @loadMessages
    postMessage: @postMessage
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
    messages = []
    @props.messages.forEach((el, i)->
      messages.push CE(
        MessageComponent,
        { message: el.message, written_at: el.written_at }
      )
    )
    CE('ul', { className: "commentBox" }, messages)
)

MessageComponent = React.createClass(
  render: () ->
    CE('li', { className: "commentBox" },
      CE('div', { className: "messages body" }, @props.message),
      CE('time', { className: "messages time" }, @props.written_at)
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

ReactDOM.render(
  CE(MainComponent, null),
  document.getElementById('react')
)