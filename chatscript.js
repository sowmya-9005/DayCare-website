document.addEventListener('DOMContentLoaded', function () {
  const chatbotToggle = document.getElementById('chatbot-toggle');
  const chatbotWindow = document.getElementById('chatbot-window');
  const chatbotClose = document.getElementById('chatbot-close');
  const chatbotMessages = document.getElementById('chatbot-messages');
  const chatbotInput = document.getElementById('chatbot-input');
  const sendMessageBtn = document.getElementById('chatbot-send');

  // Ensure chatbot starts hidden
  chatbotWindow.style.display = 'none';

  function addMessage(text, sender) {
    const message = document.createElement('div');
    message.className = sender === 'user' ? 'user-message' : 'bot-message';
    message.textContent = text;
    chatbotMessages.appendChild(message);
    chatbotMessages.scrollTo({ top: chatbotMessages.scrollHeight, behavior: 'smooth' });
  }

  async function processMessage(msg) {
    try {
      const res = await fetch('http://localhost:5000/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: msg })
      });

      const data = await res.json();
      addMessage(data.response, 'bot');
    } catch (err) {
      addMessage("Oops! Something went wrong. Please try again later.", 'bot');
      console.error(err);
    }
  }

  function handleSend() {
    const message = chatbotInput.value.trim();
    if (message) {
      addMessage(message, 'user');
      processMessage(message);
      chatbotInput.value = '';
    }
  }

  // Toggle chatbot visibility
  chatbotToggle.addEventListener('click', () => {
    if (chatbotWindow.style.display === 'none') {
      chatbotWindow.style.display = 'flex';
      if (chatbotMessages.children.length === 0) {
        setTimeout(() => processMessage('hello'), 500);
      }
    } else {
      chatbotWindow.style.display = 'none';
    }
  });

  // Close button
  chatbotClose.addEventListener('click', () => {
    chatbotWindow.style.display = 'none';
  });

  // Send message on click
  sendMessageBtn.addEventListener('click', handleSend);

  // Send message on Enter key
  chatbotInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') handleSend();
  });
});
