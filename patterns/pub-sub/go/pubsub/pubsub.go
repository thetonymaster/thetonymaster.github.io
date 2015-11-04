package pubsub

type operation int

const (
	sub operation = iota
	subOnce
	pub
	unsub
	unsubAll
	closeTopic
	shutdown
)

// PubSub is a collection of topics.
type PubSub struct {
	commandChan chan command
	capacity    int
}

type command struct {
	op     operation
	topics []string
	ch     chan interface{}
	msg    interface{}
}

func New(capacity int) *PubSub {
	ps := &PubSub{make(chan command), capacity}
	go ps.start()
	return ps
}

func (ps *PubSub) Sub(topics ...string) chan interface{} {
	return ps.sub(sub, topics...)
}

func (ps *PubSub) SubOnce(topics ...string) chan interface{} {
	return ps.sub(subOnce, topics...)
}

func (ps *PubSub) sub(op operation, topics ...string) chan interface{} {
	ch := make(chan interface{}, ps.capacity)
	ps.commandChan <- command{op: op, topics: topics, ch: ch}
	return ch
}

func (ps *PubSub) AddSub(ch chan interface{}, topics ...string) {
	ps.commandChan <- command{op: sub, topics: topics, ch: ch}
}

func (ps *PubSub) Pub(msg interface{}, topics ...string) {
	ps.commandChan <- command{op: pub, topics: topics, msg: msg}
}

func (ps *PubSub) Unsub(ch chan interface{}, topics ...string) {
	if len(topics) == 0 {
		ps.commandChan <- command{op: unsubAll, ch: ch}
		return
	}

	ps.commandChan <- command{op: unsub, topics: topics, ch: ch}
}

func (ps *PubSub) Close(topics ...string) {
	ps.commandChan <- command{op: closeTopic, topics: topics}
}

func (ps *PubSub) Shutdown() {
	ps.commandChan <- command{op: shutdown}
}

func (ps *PubSub) start() {
	chanm := channelManager{
		topics:    make(map[string]map[chan interface{}]bool),
		revTopics: make(map[chan interface{}]map[string]bool),
	}

loop:
	for command := range ps.commandChan {
		if command.topics == nil {
			switch command.op {
			case unsubAll:
				chanm.removeChannel(command.ch)

			case shutdown:
				break loop
			}

			continue loop
		}

		for _, topic := range command.topics {
			switch command.op {
			case sub:
				chanm.add(topic, command.ch, false)

			case subOnce:
				chanm.add(topic, command.ch, true)

			case pub:
				chanm.send(topic, command.msg)

			case unsub:
				chanm.remove(topic, command.ch)

			case closeTopic:
				chanm.removeTopic(topic)
			}
		}
	}

	for topic, chans := range chanm.topics {
		for ch := range chans {
			chanm.remove(topic, ch)
		}
	}
}

type channelManager struct {
	topics    map[string]map[chan interface{}]bool
	revTopics map[chan interface{}]map[string]bool
}

func (chanm *channelManager) add(topic string, ch chan interface{}, once bool) {
	if chanm.topics[topic] == nil {
		chanm.topics[topic] = make(map[chan interface{}]bool)
	}
	chanm.topics[topic][ch] = once

	if chanm.revTopics[ch] == nil {
		chanm.revTopics[ch] = make(map[string]bool)
	}
	chanm.revTopics[ch][topic] = true
}

func (chanm *channelManager) send(topic string, msg interface{}) {
	for ch, once := range chanm.topics[topic] {
		ch <- msg
		if once {
			for topic := range chanm.revTopics[ch] {
				chanm.remove(topic, ch)
			}
		}
	}
}

func (chanm *channelManager) removeTopic(topic string) {
	for ch := range chanm.topics[topic] {
		chanm.remove(topic, ch)
	}
}

func (chanm *channelManager) removeChannel(ch chan interface{}) {
	for topic := range chanm.revTopics[ch] {
		chanm.remove(topic, ch)
	}
}

func (chanm *channelManager) remove(topic string, ch chan interface{}) {
	if _, ok := chanm.topics[topic]; !ok {
		return
	}

	if _, ok := chanm.topics[topic][ch]; !ok {
		return
	}

	delete(chanm.topics[topic], ch)
	delete(chanm.revTopics[ch], topic)

	if len(chanm.topics[topic]) == 0 {
		delete(chanm.topics, topic)
	}

	if len(chanm.revTopics[ch]) == 0 {
		close(ch)
		delete(chanm.revTopics, ch)
	}
}
