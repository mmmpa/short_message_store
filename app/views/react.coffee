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
          @reject(data)
          @insert(data)
          @moveReplies(data)
        when 'reply'
          @insert(data)
        else
          @loadMessages(@lastId())
      @setState(mode: null, message: '')
    ).fail((data) =>
      @loadMessages(@lastId())
    )

  moveReplies: (message)->
    $.ajax(
      url: "replies/#{message.id}",
      type: 'get',
      dataType: 'json'
    ).done((data) =>
      _.each(data, (reply)=>
        @reject(reply)
        @insert(reply)
      )
    ).fail((data) ->)

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
    ).fail((data) ->)

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
    ).fail((data) ->)

  disposeMessage: ()->
    @setState(mode: null, message: '')

  editMessage: (message)->
    @setState(mode: { mode: 'edit', id: message.id }, message: message.message)

  replyMessage: (message)->
    @setState(mode: { mode: 'reply', id: message.id })

  insert: (message)->
    now = @state.messages
    targetIndex = _.findIndex(now, (target)->
      target.score < message.score
    )
    switch
      when targetIndex == 0
        now.unshift(message)
      when targetIndex == -1
        now.push(message)
      else
        now = _.slice(now, 0, targetIndex).concat(message).concat(_.slice(now, targetIndex))

    @setState(messages: now)

  reject: (message)->
    @setState(messages: _.reject(@state.messages, (obj)->
      obj.id == message.id
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
    @setState(messages: messages.reverse().concat(@state.messages))

  lastId: ->
    @state.messages[0]?.id

  lastScore: ->
    @state.messages[0]?.score

  componentDidMount: ()->
    @loadMessages()

  app: ()->
    deleteMessage: @deleteMessage
    disposeMessage: @disposeMessage
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
    window.scroll(0, 0)

  delete: (e)->
    e.preventDefault()
    @props.app.deleteMessage(@props.message)

  reply: (e)->
    e.preventDefault()
    @props.app.replyMessage(@props.message)
    window.scroll(0, 0)

  writeHeader: ()->
    if @props.message.reply_to && @props.message.reply_to != ''
      '▲' + @props.message.written_at
    else
      @props.message.written_at

  render: () ->
    CE('li', { className: "message-list message col-xs-12 col-md-6 col-lg-4" },
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

FormStatus = {
  READY: 'ready'
  WAIT: 'input'
  AWAKE: 'awake'
}

MessageFormComponent = React.createClass(
  dispose: (e)->
    e.preventDefault()
    @props.app.disposeMessage()
  yap: (e)->
    e.preventDefault()
    timer_id = @startYap()
    @props.app.postMessage(
      @state.message, @props.mode
    ).done(()=>
      @finishYap(timer_id)
    ).fail(() =>
      @finishYap(timer_id)
    )

  startYap: ()->
    @setState(yapable: false, postState: FormStatus.WAIT)
    timer = setTimeout(()=>
      @setState(postState: FormStatus.AWAKE)
    , 2000)

  finishYap: (timer_id)->
    clearTimeout(timer_id)
    @setState(yapable: true, postState: FormStatus.READY)

  modeText: ()->
    if @props.mode
      "#{@props.mode.mode}:#{@props.mode.id}"
    else
      'new message'

  statize: (e)->
    @setState(message: e.doc.getValue())

  codeMirrorConfig: ()->
    lineNumbers: true
    mode: 'gfm',
    lineWrapping: true
    placeholder: 'メッセージを入力'
    theme: 'summerfruit'

  componentWillReceiveProps: (props)->
    @setState(message: props.message)
    @cm.doc.setValue(props.message)

  componentDidMount: ->
    @cm = CodeMirror.fromTextArea(@refs.messageArea.getDOMNode(), @codeMirrorConfig())
    @cm.on('change', @statize)
    @cm.setSize('100%', '100%')

  getInitialState: ()->
    message: ''
    yapable: true
    postState: FormStatus.READY

  detectButtonMessage: ()->
    switch @state.postState
      when FormStatus.READY
        [
          CE(Fa, { icon: 'paw' })
          ' Yap!'
        ]
      when FormStatus.WAIT
        [
          CE(Fa, { icon: 'spinner', animation: 'pulse' })
          ' Sending...'
        ]
      when FormStatus.AWAKE
        [
          CE(Fa, { icon: 'spinner', animation: 'pulse' })
          ' Awaking Heroku...'
        ]

  render: () ->
    CE('form', { className: "message-box form" },
      CE('div', { className: "control-group message-box mode-area" },
        CE('input', {
          className: "form-control message-box mode",
          ref: 'mode',
          disabled: true,
          value: @modeText()
        }),
        CE('button', {
            className: "btn btn-danger message-box cancel",
            onClick: @dispose
          },
          CE(Fa, { icon: 'trash-o' })
        )
      ),
      CE('div', { className: "control-group" },
        CE('textarea', {
          className: "form-control message-box textarea",
          ref: 'messageArea'
        })
      ),
      CE('div', { className: "message-box submit-area" },
        CE('button', {
            className: "btn btn-primary btn-lg message-box submit",
            onClick: @yap,
            disabled: !@state.yapable
          },
          @detectButtonMessage()
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