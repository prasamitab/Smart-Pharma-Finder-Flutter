

import 'package:flutter/material.dart';
import 'ai_service.dart'; // <-- Import the service layer

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final AiService _aiService = AiService(); // Initialize the service
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hi! I am Eco-Bot. I can help you with medicine disposal rules, point calculation, or safety information.',
      'isUser': false,
    }
  ];
  final TextEditingController _controller = TextEditingController();

  // --- UPDATED _sendMessage FUNCTION ---
  void _sendMessage() async { // Made function async
    if (_controller.text.isEmpty) return;
    
    final userMessage = _controller.text;
    
    // 1. Add user's message and show "thinking" status
    setState(() {
      _messages.add({'text': userMessage, 'isUser': true});
      _controller.clear();
      // Temporarily add a thinking indicator
      _messages.add({'text': 'Eco-Bot is typing...', 'isUser': false, 'isThinking': true}); 
    });

    // 2. Get response from the service
    final aiResponse = await _aiService.getSafetyGuidance(userMessage);

    // 3. Update the UI with the final response
    setState(() {
      // Remove the "thinking" status (which is the last message)
      _messages.removeLast(); 
      // Add the final, contextual response
      _messages.add({'text': aiResponse, 'isUser': false, 'isThinking': false});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco-Bot Safety Guidance'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: _messages.length,
              itemBuilder: (ctx, index) => _buildMessageBubble(
                _messages[index]['text'] as String,
                _messages[index]['isUser'] as bool,
                _messages[index]['isThinking'] ?? false, // Check for thinking status
              ),
            ),
          ),
          
          // Input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Ask Eco-Bot a question...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isUser, bool isThinking) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.teal.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: isThinking
            ? const SizedBox(
                width: 20, 
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)
              )
            : Text(
                message,
                style: TextStyle(color: isUser ? Colors.teal.shade900 : Colors.black87),
              ),
      ),
    );
  }
}