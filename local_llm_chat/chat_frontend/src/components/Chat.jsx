import { useState } from 'react';
import './Chat.css';
import { config } from '../config';


function Chat() {
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const sendMessage = async () => {
    if (!inputValue.trim()) return;

    const userMessage = inputValue;
    setInputValue('');
    setMessages(prev => [...prev, { role: 'user', content: userMessage }]);
    setIsLoading(true);

    try {
      const chatURL = `${config.backendUrl}/chat`
      const response = await fetch(chatURL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ prompt: userMessage }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      const content = data.response;
      setMessages(prev => [...prev, { role: 'assistant', content: content }]);
    } catch (error) {
      console.error('Error sending message:', error);
      setMessages(prev => [
        ...prev,
        { role: 'error', content: `Error: ${error.message}` },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="chat-container">
      <div className="chat-header">
        <h2>Chat with local LLM</h2>
      </div>

      <div className="chat-messages">
        {messages.map((msg, index) => (
          <div key={index} className={`message message-${msg.role}`}>
            <div className="message-role">{msg.role}</div>
            <div className="message-content">
              {typeof msg.content === 'object'
                ? <pre>{JSON.stringify(msg.content, null, 2)}</pre>
                : msg.content
              }
            </div>
          </div>
        ))}
        {isLoading && (
          <div className="message message-loading">
            <div className="message-role">assistant</div>
            <div className="message-content">Thinking...</div>
          </div>
        )}
      </div>

      <div className="chat-input-container">
        <input
          type="text"
          className="chat-input"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder="Type your message..."
          disabled={isLoading}
        />
        <button
          className="chat-send-button"
          onClick={sendMessage}
          disabled={isLoading || !inputValue.trim()}
        >
          Send
        </button>
      </div>
    </div>
  );
}

export default Chat;
