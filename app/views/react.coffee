CE = React.createElement

MainComponent = React.createClass(
  postMessage: (message, mode)->
    [url, data] = @detectPostParameter(message, mode)
    $.ajax(
      url: url
      type: 'post'
      dataType: 'json'
      data: data
    ).then((data) =>
      switch mode?.mode
        when 'edit'
          if data.reply_to? && data.reply_to != ''
# リプライなので本人の移動のみ
            @reject(data)
            @insert(data)
          else
# 親なので子を含めた大移動
            @reject(data, true)
            @loadMessages(@lastScore())
        when 'reply'
          @insert(data)
        else
          @loadMessages(@lastScore())
      @setState(mode: null, message: '')
    ).fail((data) ->
      @loadMessages(@lastScore())
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
      @addNewMessages(data)
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
      @reject(data)
    ).fail((data) ->
      console.log(data)
    )
  editMessage: (message)->
    @setState(mode: { mode: 'edit', id: message.id }, message: message.message)
  replyMessage: (message)->
    @setState(mode: { mode: 'reply', id: message.id })
  insert: (message)->
    now = @state.messages
    targetIndex = _.findIndex(now, (target)->
      console.log target.score, message.score
      target.score < message.score
    )
    now = _.slice(now, 0, targetIndex).concat(message).concat(_.slice(now, targetIndex))
    @setState(messages: now)
  reject: (message, children = false)->
    score = _.find(@state.messages, ((obj)-> obj.id == message.id)).score
    detector = if children
      (objScore, score)->
        console.log score - 1, objScore, score
        score - 1 < objScore && objScore <= score
    else
      (objScore, score)->
        console.log objScore, score
        objScore == score
    @setState(messages: _.reject(@state.messages, (obj)->
      detector(obj.score, score)
    ))
  detectPostParameter: (message, mode = {})->
    switch mode.mode
      when 'edit'
        ["/messages/#{mode.id}", { message: message, _method: 'put' }]
      when 'reply'
        ['/messages/new', { message: message, reply_to: mode.id }]
      else
        ['/messages/new', { message: message }]
  addNewMessages: (messages)->
    console.log messages
    @setState(messages: messages.reverse().concat(@state.messages))
  lastId: ->
    @state.messages[0]?.id
  lastScore: ->
    @state.messages[0]?.score
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
    replies: {}
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
  writeHeader: ()->
    if @props.message?.reply_to != ''
      '▲' + @props.message.written_at
    else
      @props.message.written_at
  render: () ->
    CE('li', { className: "message-list message" },
      CE('time', { className: "message-list time" }, @writeHeader()),
      CE('div', {
        className: "message-list body",
        dangerouslySetInnerHTML: { __html: marked(@props.message.message) }
      }),
      CE('div', { className: "message-list footer" },
        CE('a', { className: "text-success message-list reply", href: "#", onClick: @reply },
          CE(Fa, { icon: 'reply' }),
          'reply'
        )
        CE('a', { className: "text-primary message-list edit", href: "#", onClick: @edit },
          CE(Fa, { icon: 'pencil' }),
          'edit'
        )
        CE('a', { className: "text-danger message-list delete", href: "#", onClick: @delete },
          CE(Fa, { icon: 'trash-o' }),
          'delete'
        )
      )
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