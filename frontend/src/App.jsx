import React, { useState, useEffect, useRef } from 'react';
import { Send, Loader2 } from 'lucide-react';

import { Link } from 'react-router-dom';

const formatText = (text) => {
  // Handle bold text (**text**)
  text = text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
  
  // Handle italic text (__text__)
  text = text.replace(/__(.*?)__/g, '<em>$1</em>');
  
  return text;
};

const formatMessage = (text) => {
  // First split by numbers if it's a numbered list
  if (text.match(/\d+\./)) {
    const points = text.split(/(?=\d+\.)/);
    return points.map((point, index) => (
      <div key={index} className="mb-2 last:mb-0">
        <div 
          dangerouslySetInnerHTML={{ 
            __html: formatText(point.trim()) 
          }} 
        />
      </div>
    ));
  }

  // If not a numbered list, format the text directly
  return (
    <div 
      dangerouslySetInnerHTML={{ 
        __html: formatText(text) 
      }} 
    />
  );
};

const App = () => {
  const [message, setMessage] = useState('');
  const [chatHistory, setChatHistory] = useState([]);
  const [isChatActive, setIsChatActive] = useState(true);
  const [loading, setLoading] = useState(false);
  const [conversationId, setConversationId] = useState(null);
  const chatContainerRef = useRef(null);

  useEffect(() => {
    if (chatContainerRef.current) {
      chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight;
    }
  }, [chatHistory]);

  useEffect(() => {
    if (!conversationId) {
      setConversationId(Date.now().toString());
    }
  }, [conversationId]);

  const sendMessage = async (event) => {
    event.preventDefault();
    if (message.trim() === '') return;

    setLoading(true);
    setChatHistory((prevHistory) => [
      ...prevHistory,
      { sender: 'user', text: message },
    ]);

    try {
      const response = await fetch(`http://localhost:8000/chat/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message,
          conversation_id: conversationId,
        }),
      });

      if (!response.ok) {
        throw new Error('Error with API request');
      }

      const data = await response.json();
      setChatHistory((prevHistory) => [
        ...prevHistory,
        { sender: 'ai', text: data.response },
      ]);
      setMessage('');
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 flex flex-col items-center justify-center bg-gradient-to-br from-zinc-900 to-black p-2 sm:p-4 md:p-6">
      {/* Title outside the container */}
      <h1 className="text-4xl sm:text-5xl md:text-6xl font-black text-white mb-6 font-['Montserrat'] tracking-wide">
        Aieth - Personal Health Assistant
      </h1>

      <div className="w-full h-[85vh] sm:h-auto sm:max-h-[70vh] max-w-[95%] md:max-w-2xl bg-zinc-800/50 backdrop-blur-xl rounded-lg sm:rounded-2xl shadow-xl border border-zinc-700/50 flex flex-col">
        {/* Chat Container */}
        <div
          ref={chatContainerRef}
          className="flex-1 overflow-y-auto p-3 sm:p-4 md:p-6 space-y-4 sm:space-y-6 scrollbar-thin scrollbar-thumb-zinc-700 scrollbar-track-transparent min-h-0"
        >
          {chatHistory.map((msg, index) => (
            <div
              key={index}
              className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-[85%] sm:max-w-[75%] px-3 py-2 sm:px-4 sm:py-3 rounded-xl sm:rounded-2xl ${
                  msg.sender === 'user'
                    ? 'bg-blue-600 text-white'
                    : 'bg-zinc-700/50 backdrop-blur-sm text-zinc-100'
                } shadow-lg transition-all duration-300 hover:scale-[1.02]`}
              >
                <div className="text-xs sm:text-sm md:text-base leading-relaxed [&>div>strong]:font-bold [&>div>em]:italic">
                  {formatMessage(msg.text)}
                </div>
              </div>
            </div>
          ))}

          {loading && (
            <div className="flex justify-start">
              <div className="max-w-[85%] sm:max-w-[75%] px-3 py-2 sm:px-4 sm:py-3 rounded-xl sm:rounded-2xl bg-zinc-700/30 text-zinc-300">
                <div className="flex items-center gap-2">
                  <Loader2 className="h-3 w-3 sm:h-4 sm:w-4 animate-spin" />
                  <span className="text-xs sm:text-sm">AI is thinking...</span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Input Form */}
        {isChatActive && (
          <div className="p-3 sm:p-4 md:p-6 border-t border-zinc-700/50 mt-auto">
            <form onSubmit={sendMessage} className="flex gap-2 sm:gap-4">
              <input
                type="text"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                className="flex-1 bg-zinc-700/30 text-white rounded-lg sm:rounded-xl px-3 py-2 sm:px-4 sm:py-3 focus:outline-none focus:ring-2 focus:ring-blue-500/50 placeholder-zinc-500 text-xs sm:text-sm transition-all duration-200"
                placeholder="Type your message..."
              />
              <button
                type="submit"
                disabled={loading || !message.trim()}
                className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 sm:px-4 sm:py-2 rounded-lg sm:rounded-xl transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 group"
              >
                <Send className="h-3 w-3 sm:h-4 sm:w-4 transition-transform group-hover:translate-x-0.5" />
                <span className="hidden sm:inline text-sm">Send</span>
              </button>
            </form>
          </div>
        )}
      </div>
      <button className="fixed bottom-6 right-6 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg sm:rounded-xl transition-all duration-200 flex items-center gap-2 group">
        Contact Doctor
      </button>

    </div>
  );
};

export default App;